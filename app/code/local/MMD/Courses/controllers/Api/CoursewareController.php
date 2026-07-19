<?php
/**
 * Courseware URL read/write API — used by the courseware repos' /lms-push
 * commands to publish Google Drive links onto a course after a build.
 *
 * GET  /courses/api_courseware?sku=<sku>
 *   Returns the stored courseware URLs for one course.
 *
 * POST /courses/api_courseware
 *   Body (JSON or form-encoded): sku plus any of the writable fields below.
 *   Only the keys actually present are written, so a caller can update one
 *   link without blanking the rest. Returns the full row after the write.
 *
 *   Header:  X-API-Key: <shared secret>
 *
 * Writable fields:
 *   trainer_slides_url   the slide deck (PPT)
 *   learner_slides_url   the slide deck PDF
 *   lesson_plan_url      the Lesson Plan PDF
 *   learner_guide_url    the Learner Guide PDF
 *   lab_url              the labs / Activities FOLDER (not a single file)
 *   courseware_link      the course's Drive folder root
 *   brochure_link        the course brochure
 *
 * Auth: X-API-Key compared against courses/general/wsq_schedule_api_key —
 *       the same shared secret as the other /courses/api_* endpoints.
 *       Blank stored key disables the endpoint (503).
 *
 * Scope: SG store (store_id=1), matching the sibling read-only endpoints.
 *
 * Note on writes: this endpoint upserts course_courseware directly rather than
 * going through the admin CoursesaveController, which expects a full course
 * form post. The table is a plain per-product key/value row, so a scoped
 * upsert is both simpler and safer than replaying a form save.
 */
class MMD_Courses_Api_CoursewareController extends Mage_Core_Controller_Front_Action
{
    const SG_STORE_ID         = 1;
    const CONFIG_PATH_API_KEY = 'courses/general/wsq_schedule_api_key';

    /** Fields a caller may write. Anything else in the body is ignored. */
    private static $_writable = array(
        'trainer_slides_url',
        'learner_slides_url',
        'lesson_plan_url',
        'learner_guide_url',
        'lab_url',
        'courseware_link',
        'brochure_link',
    );

    public function indexAction()
    {
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        if ($expected === '') {
            return $this->_json(503, array('ok' => false, 'error' => 'api_disabled',
                'message' => 'API key not configured.'));
        }
        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, array('ok' => false, 'error' => 'unauthorized',
                'message' => 'Invalid or missing X-API-Key.'));
        }

        $isPost = $this->getRequest()->isPost();
        $input  = $isPost ? $this->_readBody() : array();

        $sku = trim((string) ($input['sku'] ?? $this->getRequest()->getParam('sku', '')));
        if ($sku === '') {
            return $this->_json(400, array('ok' => false, 'error' => 'missing_sku',
                'message' => 'Pass sku=<course_code> (e.g. C524).'));
        }

        try {
            $product = Mage::getModel('catalog/product')->setStoreId(self::SG_STORE_ID)
                ->loadByAttribute('sku', $sku);
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, array('ok' => false, 'error' => 'internal_error',
                'message' => $e->getMessage()));
        }
        if (!$product || !$product->getId()) {
            return $this->_json(404, array('ok' => false, 'error' => 'not_found',
                'message' => 'No course with sku=' . $sku . ' exists in the SG catalog.'));
        }
        $productId = (int) $product->getId();

        if ($isPost) {
            $updates = array();
            foreach (self::$_writable as $field) {
                if (array_key_exists($field, $input)) {
                    $updates[$field] = (string) $input[$field];
                }
            }
            if (!$updates) {
                return $this->_json(400, array('ok' => false, 'error' => 'nothing_to_write',
                    'message' => 'Body contained none of: ' . implode(', ', self::$_writable)));
            }
            foreach ($updates as $field => $value) {
                if ($value !== '' && !preg_match('~^https://~i', $value)) {
                    return $this->_json(400, array('ok' => false, 'error' => 'bad_url',
                        'message' => "$field must be an https:// URL (got: " . substr($value, 0, 80) . ')'));
                }
                if (strlen($value) > 1000) {
                    return $this->_json(400, array('ok' => false, 'error' => 'url_too_long',
                        'message' => "$field exceeds the 1000-character column limit."));
                }
            }
            try {
                $this->_upsert($productId, $updates);
            } catch (Exception $e) {
                Mage::logException($e);
                return $this->_json(500, array('ok' => false, 'error' => 'write_failed',
                    'message' => $e->getMessage()));
            }
        }

        return $this->_json(200, array(
            'ok'         => true,
            'sku'        => $sku,
            'product_id' => $productId,
            'name'       => (string) $product->getName(),
            'written'    => $isPost ? array_keys($updates) : array(),
            'courseware' => $this->_row($productId),
        ));
    }

    /** JSON body if the caller sent one, otherwise the form-encoded post. */
    private function _readBody()
    {
        $raw = (string) file_get_contents('php://input');
        if ($raw !== '') {
            $decoded = json_decode($raw, true);
            if (is_array($decoded)) {
                return $decoded;
            }
        }
        return (array) $this->getRequest()->getPost();
    }

    private function _upsert($productId, array $updates)
    {
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $read  = Mage::getSingleton('core/resource')->getConnection('core_read');
        $existing = $read->fetchOne(
            "SELECT id FROM course_courseware WHERE product_id = ?", array($productId));
        if ($existing) {
            $write->update('course_courseware', $updates, array('id = ?' => (int) $existing));
        } else {
            $updates['product_id'] = $productId;
            $write->insert('course_courseware', $updates);
        }
    }

    private function _row($productId)
    {
        $read = Mage::getSingleton('core/resource')->getConnection('core_read');
        $row = $read->fetchRow(
            "SELECT * FROM course_courseware WHERE product_id = ? LIMIT 1", array($productId));
        $out = array();
        foreach (self::$_writable as $field) {
            $out[$field] = isset($row[$field]) ? (string) $row[$field] : '';
        }
        return $out;
    }

    private function _json($status, array $body)
    {
        $this->getResponse()
            ->setHttpResponseCode($status)
            ->setHeader('Content-Type', 'application/json; charset=utf-8', true)
            ->setHeader('Cache-Control', 'no-store', true)
            ->setBody(json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        return $this;
    }
}
