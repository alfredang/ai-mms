<?php
class MMD_RoleManager_Adminhtml_AttendanceController extends Mage_Adminhtml_Controller_Action
{
    protected function _validateFormKey()
    {
        return true;
    }

    /**
     * Fetch the list of enrolled learners for a given (course, session) and their
     * current attendance status.
     *
     * GET: course_id, option_type_id
     * Returns JSON:
     *   {
     *     success: true,
     *     session_label: "27 April 2026 (Mon)",
     *     learners: [ { customer_id, name, email, status } ],
     *   }
     */
    public function listAction()
    {
        $result = array('success' => false);
        try {
            $courseId     = (int) $this->getRequest()->getParam('course_id');
            $optionTypeId = (int) $this->getRequest()->getParam('option_type_id');
            if (!$courseId || !$optionTypeId) {
                throw new Exception('course_id and option_type_id are required');
            }

            $read = Mage::getSingleton('core/resource')->getConnection('core_read');

            // Verify session belongs to course
            $sessionLabel = $read->fetchOne(
                "SELECT ott.title FROM catalog_product_option_type_value ov
                 JOIN catalog_product_option o ON o.option_id = ov.option_id
                 JOIN catalog_product_option_type_title ott ON ott.option_type_id = ov.option_type_id AND ott.store_id = 0
                 WHERE ov.option_type_id = ? AND o.product_id = ?",
                array($optionTypeId, $courseId)
            );
            if (!$sessionLabel) {
                throw new Exception('Session not found for this course');
            }

            // Find all customers who ordered this course WITH this specific session selected.
            // We scan sales_flat_order_item.product_options (serialized PHP) for the option_type_id.
            // A cheaper approximation (used here): any order containing the course product,
            // where the option_value column matches our option_type_id.
            $rows = $read->fetchAll(
                "SELECT DISTINCT o.customer_id, c.email,
                        CONCAT(TRIM(COALESCE(c.firstname,'')), ' ', TRIM(COALESCE(c.lastname,''))) AS name
                 FROM sales_flat_order_item oi
                 JOIN sales_flat_order o ON o.entity_id = oi.order_id
                 JOIN customer_entity c ON c.entity_id = o.customer_id
                 WHERE oi.product_id = ?
                   AND o.customer_id IS NOT NULL
                   AND (oi.product_options LIKE ? OR oi.product_options LIKE ?)
                 ORDER BY name",
                array($courseId, '%i:' . $optionTypeId . ';%', '%"option_value";s:%"' . $optionTypeId . '"%')
            );

            // Also include any previously-marked attendance rows (keeps record if enrolment data changed)
            $marked = $read->fetchPairs(
                "SELECT customer_id, status FROM course_attendance WHERE option_type_id = ?",
                array($optionTypeId)
            );

            // Fallback: if the product_options LIKE match returned nothing, fall back to
            // showing EVERY customer who has any order with this product (user can trim later).
            if (empty($rows)) {
                $rows = $read->fetchAll(
                    "SELECT DISTINCT o.customer_id, c.email,
                            CONCAT(TRIM(COALESCE(c.firstname,'')), ' ', TRIM(COALESCE(c.lastname,''))) AS name
                     FROM sales_flat_order_item oi
                     JOIN sales_flat_order o ON o.entity_id = oi.order_id
                     JOIN customer_entity c ON c.entity_id = o.customer_id
                     WHERE oi.product_id = ? AND o.customer_id IS NOT NULL
                     ORDER BY name",
                    array($courseId)
                );
            }

            $learners = array();
            foreach ($rows as $r) {
                $cid = (int) $r['customer_id'];
                if (!$cid) continue;
                $learners[] = array(
                    'customer_id' => $cid,
                    'name'        => trim($r['name']) ?: $r['email'],
                    'email'       => $r['email'],
                    'status'      => isset($marked[$cid]) ? $marked[$cid] : '',
                );
            }

            $result['success']       = true;
            $result['session_label'] = $sessionLabel;
            $result['learners']      = $learners;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Upsert one or more (customer_id, status) rows for a given session.
     * POST: course_id, option_type_id, attendance (JSON: { customer_id: "present"|"absent", … })
     */
    public function saveAction()
    {
        $result = array('success' => false, 'updated' => 0);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $req = $this->getRequest();
            $courseId     = (int) $req->getParam('course_id');
            $optionTypeId = (int) $req->getParam('option_type_id');
            $attendanceIn = $req->getParam('attendance');
            if (!$courseId || !$optionTypeId) {
                throw new Exception('course_id and option_type_id are required');
            }
            if (is_string($attendanceIn)) {
                $attendance = json_decode($attendanceIn, true);
            } else {
                $attendance = $attendanceIn;
            }
            if (!is_array($attendance)) {
                throw new Exception('attendance must be an object of customer_id => status');
            }

            $resource = Mage::getSingleton('core/resource');
            $read  = $resource->getConnection('core_read');
            $write = $resource->getConnection('core_write');

            // Verify session belongs to course
            $belongs = $read->fetchOne(
                "SELECT 1 FROM catalog_product_option_type_value ov
                 JOIN catalog_product_option o ON o.option_id = ov.option_id
                 WHERE ov.option_type_id = ? AND o.product_id = ?",
                array($optionTypeId, $courseId)
            );
            if (!$belongs) {
                throw new Exception('Session not found for this course');
            }

            $markedById = 0;
            try {
                $u = Mage::getSingleton('admin/session')->getUser();
                if ($u) $markedById = (int) $u->getId();
            } catch (Exception $e) {}

            $updated = 0;
            foreach ($attendance as $cid => $status) {
                $cid    = (int) $cid;
                $status = in_array($status, array('present', 'absent'), true) ? $status : 'absent';
                if (!$cid) continue;

                $existing = $read->fetchOne(
                    "SELECT id FROM course_attendance WHERE option_type_id = ? AND customer_id = ?",
                    array($optionTypeId, $cid)
                );
                if ($existing) {
                    $write->update('course_attendance', array(
                        'status'             => $status,
                        'marked_by_admin_id' => $markedById ?: null,
                    ), array('id = ?' => (int) $existing));
                } else {
                    $write->insert('course_attendance', array(
                        'option_type_id'     => $optionTypeId,
                        'customer_id'        => $cid,
                        'status'             => $status,
                        'marked_by_admin_id' => $markedById ?: null,
                    ));
                }
                $updated++;
            }

            $result['success'] = true;
            $result['updated'] = $updated;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Generate an E-Attendance token/URL for a specific session.
     * POST: course_id, option_type_id
     * Returns JSON: { success, token, code, url }
     */
    public function generateTokenAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $req = $this->getRequest();
            $courseId     = (int) $req->getParam('course_id');
            $optionTypeId = (int) $req->getParam('option_type_id');
            if (!$courseId || !$optionTypeId) {
                throw new Exception('course_id and option_type_id are required');
            }
            $resource = Mage::getSingleton('core/resource');
            $read  = $resource->getConnection('core_read');
            $write = $resource->getConnection('core_write');
            // Verify session belongs to course
            $belongs = $read->fetchOne(
                "SELECT 1 FROM catalog_product_option_type_value ov
                 JOIN catalog_product_option o ON o.option_id = ov.option_id
                 WHERE ov.option_type_id = ? AND o.product_id = ?",
                array($optionTypeId, $courseId)
            );
            if (!$belongs) {
                throw new Exception('Session not found for this course');
            }

            // Deactivate any prior tokens for this session
            $write->update('course_attendance_tokens',
                array('is_active' => 0),
                array('option_type_id = ?' => $optionTypeId)
            );

            $token = bin2hex(random_bytes(16));   // 32 hex chars
            $code  = strtoupper(substr(base_convert(bin2hex(random_bytes(4)), 16, 36), 0, 6));

            $adminId = 0;
            try { $adminId = (int) Mage::getSingleton('admin/session')->getUser()->getId(); } catch (Exception $e) {}

            $write->insert('course_attendance_tokens', array(
                'token'               => $token,
                'code'                => $code,
                'product_id'          => $courseId,
                'option_type_id'      => $optionTypeId,
                'created_by_admin_id' => $adminId ?: null,
                'expires_at'          => date('Y-m-d H:i:s', time() + 6 * 3600), // 6 hours
                'is_active'           => 1,
            ));

            $url = Mage::helper('adminhtml')->getUrl('adminhtml/attendance/checkin', array('token' => $token));
            $result['success'] = true;
            $result['token']   = $token;
            $result['code']    = $code;
            $result['url']     = $url;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * E-Attendance check-in endpoint. The learner opens this URL (while logged in
     * as a frontend customer OR as an admin user whose email matches a customer),
     * and if they're enrolled in the course, gets marked present for that session.
     *
     * GET: ?token=... (or /token/<value>)
     */
    public function checkinAction()
    {
        $token = trim((string) $this->getRequest()->getParam('token'));
        $html = '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Attendance Check-in</title>'
              . '<style>body{font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif;background:#0f172a;color:#f1f5f9;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;padding:24px}'
              . '.card{background:#1e293b;border:1px solid #334155;border-radius:14px;padding:40px;max-width:460px;width:100%;text-align:center;box-shadow:0 20px 40px rgba(0,0,0,.3)}'
              . '.ok{color:#10b981}.err{color:#ef4444}.muted{color:#94a3b8;font-size:13px;margin-top:12px}h1{margin:0 0 16px;font-size:22px}</style></head><body><div class="card">';

        try {
            if ($token === '') throw new Exception('Missing token');
            $read  = Mage::getSingleton('core/resource')->getConnection('core_read');
            $write = Mage::getSingleton('core/resource')->getConnection('core_write');

            $row = $read->fetchRow(
                "SELECT * FROM course_attendance_tokens WHERE token = ? AND is_active = 1",
                array($token)
            );
            if (!$row) throw new Exception('This check-in link is not valid or has expired.');
            if ($row['expires_at'] && strtotime($row['expires_at']) < time()) {
                throw new Exception('This check-in link has expired.');
            }

            // Identify the learner. Prefer frontend customer session, fall back to
            // the admin user's email matched to a customer record.
            $email = '';
            $customerId = 0;
            try {
                $cs = Mage::getSingleton('customer/session');
                if ($cs && $cs->isLoggedIn()) {
                    $customerId = (int) $cs->getCustomerId();
                    $email = strtolower(trim((string) $cs->getCustomer()->getEmail()));
                }
            } catch (Exception $e) {}
            if (!$customerId) {
                try {
                    $as = Mage::getSingleton('admin/session');
                    if ($as && $as->isLoggedIn()) {
                        $email = strtolower(trim((string) $as->getUser()->getEmail()));
                    }
                } catch (Exception $e) {}
            }
            if ($customerId === 0 && $email !== '') {
                $customerId = (int) $read->fetchOne(
                    "SELECT entity_id FROM customer_entity WHERE LOWER(email) = ? LIMIT 1",
                    array($email)
                );
            }
            if (!$customerId) {
                throw new Exception('Please log in first, then re-open the check-in link.');
            }

            // Confirm the learner is enrolled in the course
            $enrolled = $read->fetchOne(
                "SELECT 1 FROM sales_flat_order_item oi
                 JOIN sales_flat_order o ON o.entity_id = oi.order_id
                 WHERE oi.product_id = ? AND o.customer_id = ? LIMIT 1",
                array((int)$row['product_id'], $customerId)
            );
            if (!$enrolled) {
                throw new Exception('You do not appear to be enrolled in this course.');
            }

            // Upsert attendance = present
            $existing = $read->fetchOne(
                "SELECT id FROM course_attendance WHERE option_type_id = ? AND customer_id = ?",
                array((int)$row['option_type_id'], $customerId)
            );
            if ($existing) {
                $write->update('course_attendance',
                    array('status' => 'present'),
                    array('id = ?' => (int)$existing)
                );
            } else {
                $write->insert('course_attendance', array(
                    'option_type_id' => (int)$row['option_type_id'],
                    'customer_id'    => $customerId,
                    'status'         => 'present',
                ));
            }

            $html .= '<h1 class="ok">&#10003; You\'re checked in!</h1>'
                  .  '<div class="muted">Your attendance has been recorded. You may close this page.</div>';
        } catch (Exception $e) {
            $html .= '<h1 class="err">Check-in failed</h1>'
                  .  '<div class="muted">' . htmlspecialchars($e->getMessage()) . '</div>';
        }

        $html .= '</div></body></html>';
        $this->getResponse()
            ->setHeader('Content-Type', 'text/html; charset=utf-8', true)
            ->setBody($html);
    }

    protected function _sendJson(array $data)
    {
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($data));
    }

    protected function _isAllowed()
    {
        return true;
    }
}
