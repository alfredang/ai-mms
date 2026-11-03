<?php
/**
 * The learner's own LMS data for the native apps — non-WSQ (C-prefix) classes
 * only, matching what the web LMS shows a learner, with two deliberate
 * tightenings: every class read is gated on the learner's own enrolment, and
 * "today" is store-local everywhere (the web My Classes list uses UTC).
 *
 * Sources (see CLAUDE.md "LMS data model"):
 *   classes      course_run_enrolments ⋈ course_runs (C[0-9] SKUs); unpaid
 *                registrations come from sales_flat_order until class
 *                formation materialises them
 *   materials    course_courseware — LEARNER columns only, never trainer ones
 *   attendance   mmd_course_run_attendance via MMD_Attendance's self-mark
 *   survey       MMD_FeedbackForm template + saveSubmission (Magento reviews)
 *   certificates mmd_course_run_certificate (status issued/sent)
 *   billing      sales_flat_order / _item / _invoice
 */
class MMD_MobileApi_Helper_Learner extends Mage_Core_Helper_Abstract
{
    const RUN_SKU_SQL = "^C[0-9]";

    /** Learner-visible courseware columns => label. Trainer columns are never read. */
    protected $_learnerMaterials = array(
        'learner_slides_url' => 'Learner Slides',
        'learner_guide_url'  => 'Learner Guide',
        'lesson_plan_url'    => 'Lesson Plan',
        'lab_url'            => 'Activities / Labs',
    );

    protected $_modes = array(1 => 'Classroom', 2 => 'Live Online', 3 => 'Hybrid');

    // ── Classes ──────────────────────────────────────────────────────────────

    /** @return array{current:array, upcoming:array, past:array} */
    public function classes($email)
    {
        $today = $this->_h()->today();
        $out   = array('current' => array(), 'upcoming' => array(), 'past' => array());

        $runs    = $this->_enrolledRuns($email);
        $certs   = $this->_certificatesByRun($email);
        $surveys = $this->_surveyedRuns($email);
        $images  = $this->_imagesByProduct();
        foreach ($runs as $run) {
            $row = $this->_classRow($run, $today, $images);
            $row['certificate']      = isset($certs[(int) $run['run_id']]) ? $certs[(int) $run['run_id']] : null;
            $row['survey_submitted'] = isset($surveys[(int) $run['run_id']]);
            $out[$row['bucket']][] = $row;
        }
        foreach ($this->_pendingRegistrations($email, $runs) as $row) {
            $row['image_url'] = isset($images[$row['product_id']]) ? $images[$row['product_id']] : '';
            $out[$row['bucket']][] = $row;
        }

        $byStart = function ($a, $b) { return strcmp($a['start_date'], $b['start_date']); };
        usort($out['current'], $byStart);
        usort($out['upcoming'], $byStart);
        usort($out['past'], function ($a, $b) { return strcmp($b['end_date'], $a['end_date']); });
        return $out;
    }

    /** Full detail of one of the learner's classes, or null if not theirs. */
    public function classDetail($email, $runId)
    {
        $run = $this->_enrolledRun($email, $runId);
        if (!$run) {
            return null;
        }
        $today  = $this->_h()->today();
        $row    = $this->_classRow($run, $today, $this->_imagesByProduct());
        $certs  = $this->_certificatesByRun($email);
        $att    = Mage::helper('mmd_attendance');

        // Sessions with this learner's attendance per session.
        $marks = array();
        foreach ($this->_read()->fetchAll(
            'SELECT session_key, is_present FROM ' . $this->_table('mmd_course_run_attendance') .
            ' WHERE run_id = ? AND LOWER(TRIM(learner_email)) = ?',
            array((int) $runId, $email)
        ) as $m) {
            $marks[$m['session_key']] = (int) $m['is_present'] === 1;
        }
        $sessions = array();
        foreach ($att->sessionsForRun($run) as $s) {
            $sessions[] = array(
                'key'     => $s['key'],
                'day'     => (int) $s['day'],
                'part'    => (string) $s['ampm'],
                'date'    => (string) $s['date'],
                'label'   => (string) $s['label'],
                'present' => isset($marks[$s['key']]) ? $marks[$s['key']] : null,
            );
        }

        $ctx        = $att->getSelfMarkContext($runId, $email);
        $currentKey = $ctx ? (string) $ctx['session_key'] : '';
        $currentLbl = '';
        foreach ($sessions as $s) {
            if ($s['key'] === $currentKey) { $currentLbl = $s['label']; break; }
        }

        $row['sessions']   = $sessions;
        $row['attendance'] = array(
            'open'                  => $ctx && $ctx['within_window'] && $currentKey !== '',
            'current_session'       => $currentKey,
            'current_session_label' => $currentLbl,
            'marked_present'        => $ctx ? (bool) $ctx['already_present'] : false,
            'sessions_present'      => count(array_filter($marks)),
            'sessions_total'        => count($sessions),
        );
        $row['materials']   = $this->_materials((int) $run['product_id']);
        $row['documents']   = $this->_documents((int) $run['product_id']);
        $row['survey']      = $this->_surveyState($email, $run, $today);
        $row['certificate'] = isset($certs[(int) $runId]) ? $certs[(int) $runId] : null;
        $row['certificate_rule'] = Mage::helper('mmd_certificate')->attendanceRuleLabel();
        return $row;
    }

    /** Self-mark the current session. Returns array(success, message). */
    public function markAttendance($email, $runId)
    {
        if (!$this->_enrolledRun($email, $runId)) {
            return array('success' => false, 'message' => 'You are not on this class roster. Please contact your trainer.');
        }
        $user = $this->_h()->loadAdminUser($email);
        return Mage::helper('mmd_attendance')->selfMarkPresent((int) $runId, $email, $user ? (int) $user->getId() : null);
    }

    // ── In-house survey ──────────────────────────────────────────────────────

    /** Questions for one of the learner's classes, with class details prefilled. */
    public function survey($email, $runId)
    {
        $run = $this->_enrolledRun($email, $runId);
        if (!$run) {
            return null;
        }
        $fb       = Mage::helper('mmd_feedbackform');
        $template = $fb->getOrCreateTemplate();
        $context  = $fb->contextForRun($fb->loadRun((int) $runId));
        $profile  = $this->_h()->learnerProfile($email);

        $sections = array();
        foreach ($template['sections'] as $section) {
            $fields = array();
            foreach ($section['fields'] as $f) {
                $value = '';
                if (!empty($f['autofill']) && isset($context[$f['autofill']])) {
                    $value = (string) $context[$f['autofill']];
                } elseif ($f['type'] === 'text' && !empty($f['required']) && stripos((string) $f['label'], 'name') !== false) {
                    $value = $profile['full_name'];   // learner's own name, editable
                } elseif ($f['type'] === 'email') {
                    $value = $email;
                }
                $fields[] = array(
                    'id'       => (string) $f['id'],
                    'label'    => (string) $f['label'],
                    'type'     => (string) $f['type'],
                    'required' => !empty($f['required']) && empty($f['readonly']),
                    'readonly' => !empty($f['readonly']),
                    'options'  => array_values(array_filter(array_map('trim', explode(',', (string) (isset($f['options']) ? $f['options'] : ''))))),
                    'value'    => $value,
                );
            }
            $sections[] = array('id' => (string) $section['id'], 'title' => (string) $section['title'], 'fields' => $fields);
        }
        return array(
            'title'    => (string) $template['title'],
            'state'    => $this->_surveyState($email, $run, $this->_h()->today()),
            'sections' => $sections,
        );
    }

    /** Validate + save a survey response. Returns array(success, message). */
    public function submitSurvey($email, $runId, array $answers)
    {
        $run = $this->_enrolledRun($email, $runId);
        if (!$run) {
            return array('success' => false, 'message' => 'You are not on this class roster.');
        }
        $state = $this->_surveyState($email, $run, $this->_h()->today());
        if ($state['submitted']) {
            return array('success' => false, 'message' => 'You have already submitted feedback for this class. Thank you!');
        }
        if (!$state['available']) {
            return array('success' => false, 'message' => $state['message']);
        }

        $fb       = Mage::helper('mmd_feedbackform');
        $template = $fb->getOrCreateTemplate();
        $clean    = array();
        foreach ($template['sections'] as $section) {
            foreach ($section['fields'] as $f) {
                if (!empty($f['readonly']) || !empty($f['autofill'])) continue;
                $v = isset($answers[$f['id']]) ? trim((string) $answers[$f['id']]) : '';
                if ($f['type'] === 'rating1to5' && $v !== '' && ((int) $v < 1 || (int) $v > 5)) {
                    return array('success' => false, 'message' => 'Please rate "' . $f['label'] . '" from 1 to 5.');
                }
                if (!empty($f['required']) && $v === '') {
                    return array('success' => false, 'message' => 'Please answer "' . $f['label'] . '".');
                }
                $clean[$f['id']] = mb_substr($v, 0, 4000);
            }
        }

        // Claim the (run, learner) slot first so a double tap can't save twice.
        // Only the request whose INSERT lands proceeds.
        $tbl  = $this->_table('mmd_mobile_feedback');
        $stmt = $this->_write()->query(
            "INSERT IGNORE INTO `$tbl` (run_id, learner_email, created_at) VALUES (?, ?, ?)",
            array((int) $runId, $email, $this->_h()->utcNow())
        );
        if ($stmt->rowCount() !== 1) {
            return array('success' => false, 'message' => 'You have already submitted feedback for this class. Thank you!');
        }
        $claimed = (int) $this->_write()->lastInsertId();
        try {
            $reviewId = $fb->saveSubmission($fb->loadRun((int) $runId), $template, $clean);
        } catch (Exception $e) {
            $this->_write()->delete($tbl, array('id = ?' => $claimed));
            throw $e;
        }
        $this->_write()->update($tbl, array('review_id' => $reviewId), array('id = ?' => $claimed));
        return array('success' => true, 'message' => 'Thank you! Your feedback has been recorded.');
    }

    // ── Certificates ─────────────────────────────────────────────────────────

    public function certificates($email)
    {
        $rows = $this->_read()->fetchAll(
            'SELECT c.run_id, c.class_id, c.course_sku, c.course_title, c.start_date, c.end_date,
                    c.cert_no, c.token, c.status, c.sent_at
               FROM ' . $this->_table('mmd_course_run_certificate') . ' c
              WHERE LOWER(TRIM(c.learner_email)) = ? AND c.status IN (\'issued\',\'sent\')
                AND c.course_sku REGEXP ?
              ORDER BY c.end_date DESC, c.certificate_id DESC',
            array($email, self::RUN_SKU_SQL)
        );
        $out = array();
        foreach ($rows as $r) {
            $out[] = $this->_certRow($r);
        }
        return $out;
    }

    // ── Billing ──────────────────────────────────────────────────────────────

    public function billing($email)
    {
        $read   = $this->_read();
        $orders = $read->fetchAll(
            'SELECT entity_id, increment_id, created_at, state, status, grand_total, total_paid, total_refunded,
                    order_currency_code
               FROM ' . $this->_table('sales/order') . '
              WHERE LOWER(TRIM(customer_email)) = ?
              ORDER BY created_at DESC LIMIT 100',
            array($email)
        );
        if (!$orders) {
            return array();
        }
        $ids   = array_map('intval', array_column($orders, 'entity_id'));
        $items = array();
        foreach ($read->fetchAll(
            'SELECT order_id, name, sku, qty_ordered, row_total_incl_tax, row_total, product_options
               FROM ' . $this->_table('sales/order_item') . '
              WHERE order_id IN (' . implode(',', $ids) . ') AND parent_item_id IS NULL'
        ) as $it) {
            $items[(int) $it['order_id']][] = $it;
        }
        $invoices = array();
        foreach ($read->fetchAll(
            'SELECT order_id, increment_id FROM ' . $this->_table('sales/invoice') .
            ' WHERE order_id IN (' . implode(',', $ids) . ')'
        ) as $inv) {
            $invoices[(int) $inv['order_id']][] = (string) $inv['increment_id'];
        }
        $methods = array();
        foreach ($read->fetchAll(
            'SELECT parent_id, method FROM ' . $this->_table('sales/order_payment') .
            ' WHERE parent_id IN (' . implode(',', $ids) . ')'
        ) as $p) {
            $methods[(int) $p['parent_id']] = (string) Mage::getStoreConfig('payment/' . $p['method'] . '/title') ?: (string) $p['method'];
        }

        $date = Mage::getModel('core/date');
        $out  = array();
        foreach ($orders as $o) {
            $oid = (int) $o['entity_id'];
            $lines = array();
            foreach (isset($items[$oid]) ? $items[$oid] : array() as $it) {
                if (!preg_match('/^C\d/i', trim((string) $it['sku']))) continue;   // non-WSQ only
                $opts = $this->_itemOptions($it['product_options']);
                $lines[] = array(
                    'title'       => (string) $it['name'],
                    'sku'         => trim((string) $it['sku']),
                    'qty'         => (float) $it['qty_ordered'],
                    'amount'      => round((float) ($it['row_total_incl_tax'] ?: $it['row_total']), 2),
                    'class_date'  => isset($opts['Course Date']) ? $opts['Course Date'] : '',
                    'class_time'  => isset($opts['Course Time']) ? $opts['Course Time'] : '',
                );
            }
            if (!$lines) continue;
            $out[] = array(
                'order_no'       => (string) $o['increment_id'],
                'date'           => $date->date('Y-m-d', strtotime($o['created_at'])),
                'status'         => $this->_paymentStatus($o),
                'status_label'   => $this->_paymentLabel($this->_paymentStatus($o)),
                'total'          => round((float) $o['grand_total'], 2),
                'paid'           => round((float) $o['total_paid'], 2),
                'refunded'       => round((float) $o['total_refunded'], 2),
                'currency'       => (string) $o['order_currency_code'],
                'payment_method' => isset($methods[$oid]) ? $methods[$oid] : '',
                'invoices'       => isset($invoices[$oid]) ? $invoices[$oid] : array(),
                'items'          => $lines,
            );
        }
        return $out;
    }

    // ── Internals ────────────────────────────────────────────────────────────

    protected function _runSelect()
    {
        $nameAttr = (int) $this->_read()->fetchOne(
            "SELECT a.attribute_id FROM " . $this->_table('eav_attribute') . " a
               JOIN " . $this->_table('eav_entity_type') . " t ON t.entity_type_id = a.entity_type_id
              WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'name'"
        );
        return "SELECT cr.run_id, cr.class_id, cr.product_id, TRIM(cr.course_sku) AS course_sku,
                       cr.course_start_date, COALESCE(cr.course_end_date, cr.course_start_date) AS course_end_date,
                       cr.course_start_time, cr.course_end_time, cr.mode_of_training, cr.virtual_link,
                       cr.venue_block, cr.venue_street, cr.venue_building, cr.venue_floor, cr.venue_unit,
                       cr.postal_code, cr.room, cr.trainer_user_id, cr.trainer_option_id,
                       COALESCE(pn.value, cr.course_sku) AS course_title,
                       COALESCE(NULLIF(TRIM(CONCAT(COALESCE(au.firstname,''),' ',COALESCE(au.lastname,''))),''), tov.value, '') AS trainer_name
                  FROM " . $this->_table('course_runs') . " cr
                  JOIN " . $this->_table('course_run_enrolments') . " cre ON cre.run_id = cr.run_id
             LEFT JOIN " . $this->_table('catalog_product_entity_varchar') . " pn
                       ON pn.entity_id = cr.product_id AND pn.store_id = 0 AND pn.attribute_id = $nameAttr
             LEFT JOIN " . $this->_table('admin/user') . " au ON au.user_id = cr.trainer_user_id
             LEFT JOIN " . $this->_table('eav_attribute_option_value') . " tov
                       ON tov.option_id = cr.trainer_option_id AND tov.store_id = 0
                 WHERE LOWER(TRIM(cre.learner_email)) = ?
                   AND TRIM(cr.course_sku) REGEXP '" . self::RUN_SKU_SQL . "'";
    }

    protected function _enrolledRuns($email)
    {
        $handover = Mage::helper('mmd_rolemanager/handover');
        $rows = array();
        foreach ($this->_read()->fetchAll($this->_runSelect() . ' GROUP BY cr.run_id', array($email)) as $r) {
            if ($handover->isActive((int) $r['run_id'])) {
                $rows[] = $r;
            }
        }
        return $rows;
    }

    protected function _enrolledRun($email, $runId)
    {
        $runId = (int) $runId;
        if ($runId <= 0 || !Mage::helper('mmd_rolemanager/handover')->isActive($runId)) {
            return null;
        }
        return $this->_read()->fetchRow($this->_runSelect() . ' AND cr.run_id = ? LIMIT 1', array($email, $runId)) ?: null;
    }

    protected function _classRow(array $r, $today, array $images)
    {
        $start = $this->_ymd($r['course_start_date']);
        $end   = $this->_ymd($r['course_end_date']) ?: $start;
        $mode  = (int) $r['mode_of_training'];
        $venue = array_filter(array_map('trim', array(
            (string) $r['venue_block'], (string) $r['venue_street'],
            trim(($r['venue_floor'] ? '#' . $r['venue_floor'] : '') . ($r['venue_unit'] ? '-' . $r['venue_unit'] : '')),
            (string) $r['venue_building'], (string) $r['postal_code'],
        )));
        $link = trim((string) $r['virtual_link']);
        if ($link === '') {
            $link = (string) $this->_read()->fetchOne(
                'SELECT google_meet_url FROM ' . $this->_table('course_courseware') . ' WHERE product_id = ?',
                array((int) $r['product_id'])
            );
        }
        return array(
            'run_id'       => (int) $r['run_id'],
            'class_id'     => (string) $r['class_id'],
            'product_id'   => (int) $r['product_id'],
            'sku'          => (string) $r['course_sku'],
            'title'        => trim((string) $r['course_title']),
            'start_date'   => $start,
            'end_date'     => $end,
            'start_time'   => $this->_hm($r['course_start_time']),
            'end_time'     => $this->_hm($r['course_end_time']),
            'mode'         => isset($this->_modes[$mode]) ? $this->_modes[$mode] : 'Classroom',
            'venue'        => $mode === 2 ? '' : implode(', ', $venue),
            'room'         => (string) $r['room'],
            'virtual_link' => $mode === 1 ? '' : $link,
            'trainer'      => trim((string) $r['trainer_name']),
            'status'       => 'confirmed',
            'bucket'       => $this->_bucket($start, $end, $today),
            'days'         => $this->_classDays($r, $start, $end),
            'image_url'    => isset($images[(int) $r['product_id']]) ? $images[(int) $r['product_id']] : '',
        );
    }

    /**
     * The actual class dates (Y-m-d) for the calendar. Weekend classes such as
     * "18/19/25/26 Jul" are not a contiguous start..end span, so this uses the
     * attendance module's session list, which knows the explicit day list.
     */
    protected function _classDays(array $run, $start, $end)
    {
        $days = array();
        foreach (Mage::helper('mmd_attendance')->sessionsForRun($run) as $s) {
            if ((string) $s['date'] !== '') $days[$s['date']] = true;
        }
        return $days ? array_keys($days) : $this->_span($start, $end);
    }

    protected function _span($start, $end)
    {
        if ($start === '') return array();
        $out = array();
        $ts  = strtotime($start);
        $last = strtotime($end !== '' ? $end : $start);
        for ($i = 0; $ts <= $last && $i < 14; $i++, $ts = strtotime('+1 day', $ts)) {
            $out[] = date('Y-m-d', $ts);
        }
        return $out;
    }

    protected function _bucket($start, $end, $today)
    {
        if ($start === '') return 'upcoming';     // no date yet: still to come
        if ($start > $today) return 'upcoming';
        if ($end < $today) return 'past';
        return 'current';
    }

    /**
     * Registrations still waiting for payment (class formation only
     * materialises processing/complete orders) — shown as upcoming so a
     * learner sees the class right after registering.
     */
    protected function _pendingRegistrations($email, array $runs)
    {
        $read = $this->_read();
        $rows = $read->fetchAll(
            "SELECT o.increment_id, o.state, oi.product_id, oi.name, TRIM(oi.sku) AS sku, oi.product_options
               FROM " . $this->_table('sales/order') . " o
               JOIN " . $this->_table('sales/order_item') . " oi ON oi.order_id = o.entity_id AND oi.parent_item_id IS NULL
              WHERE LOWER(TRIM(o.customer_email)) = ? AND o.state IN ('new','pending_payment','holded','payment_review')
                AND TRIM(oi.sku) REGEXP '" . self::RUN_SKU_SQL . "'
              ORDER BY o.created_at DESC LIMIT 20",
            array($email)
        );
        $svc   = Mage::getSingleton('mmd_rolemanager/courseRunEnrolmentService');
        $today = $this->_h()->today();
        $have  = array();
        foreach ($runs as $r) {
            $have[(int) $r['product_id'] . '|' . $this->_ymd($r['course_start_date'])] = true;
        }
        $out = array();
        foreach ($rows as $r) {
            $opts  = $this->_itemOptions($r['product_options']);
            $dates = isset($opts['Course Date']) ? $svc->_parseDate($opts['Course Date']) : null;
            $times = isset($opts['Course Time']) ? $svc->_parseTime($opts['Course Time']) : null;
            $start = $dates ? $dates[0] : '';
            $end   = $dates ? $dates[1] : '';
            if ($end !== '' && $end < $today) continue;   // lapsed unpaid registration
            if (isset($have[(int) $r['product_id'] . '|' . $start])) continue;
            $out[] = array(
                'run_id'       => 0,
                'class_id'     => '',
                'product_id'   => (int) $r['product_id'],
                'sku'          => (string) $r['sku'],
                'title'        => (string) $r['name'],
                'start_date'   => $start,
                'end_date'     => $end ?: $start,
                'start_time'   => $times ? substr($times[0], 0, 5) : '',
                'end_time'     => $times ? substr($times[1], 0, 5) : '',
                'mode'         => '',
                'venue'        => '',
                'room'         => '',
                'virtual_link' => '',
                'trainer'      => '',
                'status'       => 'pending_payment',
                'order_no'     => (string) $r['increment_id'],
                'bucket'       => $this->_bucket($start, $end ?: $start, $today),
                'days'         => $this->_span($start, $end ?: $start),
                'certificate'  => null,
                'survey_submitted' => false,
            );
        }
        return $out;
    }

    protected function _materials($productId)
    {
        $cols = array_keys($this->_learnerMaterials);
        $row  = $this->_read()->fetchRow(
            'SELECT ' . implode(',', $cols) . ' FROM ' . $this->_table('course_courseware') . ' WHERE product_id = ?',
            array((int) $productId)
        );
        $out = array();
        foreach ($this->_learnerMaterials as $col => $label) {
            $url = $row ? trim((string) $row[$col]) : '';
            if ($url !== '' && preg_match('#^https?://#i', $url)) {
                $out[] = array('key' => $col, 'title' => $label, 'url' => $url);
            }
        }
        return $out;
    }

    protected function _documents($productId)
    {
        $out = array();
        foreach ($this->_read()->fetchAll(
            'SELECT filename, file_url, created_at FROM ' . $this->_table('course_documents') .
            ' WHERE product_id = ? ORDER BY created_at DESC LIMIT 50',
            array((int) $productId)
        ) as $d) {
            $url = trim((string) $d['file_url']);
            if ($url === '') continue;
            if (!preg_match('#^https?://#i', $url)) {
                $url = rtrim(Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB), '/') . '/' . ltrim($url, '/');
            }
            $out[] = array('title' => (string) $d['filename'], 'url' => $url);
        }
        return $out;
    }

    protected function _surveyState($email, array $run, $today)
    {
        $runId     = (int) $run['run_id'];
        $submitted = (bool) $this->_read()->fetchOne(
            'SELECT id FROM ' . $this->_table('mmd_mobile_feedback') . ' WHERE run_id = ? AND learner_email = ? AND review_id IS NOT NULL',
            array($runId, $email)
        );
        // Classes run by the external TMS collect feedback on their own form.
        $external = '';
        $handover = Mage::helper('mmd_rolemanager/handover');
        if ($handover->isManaged($runId)) {
            $external = (string) $handover->feedbackUrl($runId, '');
        }
        $start = $this->_ymd($run['course_start_date']);
        $available = !$submitted && ($start === '' || $start <= $today);
        return array(
            'available'    => $available,
            'submitted'    => $submitted,
            'external_url' => $external,
            'message'      => $submitted ? 'Thank you — your feedback has been recorded.'
                : ($available ? 'Tell us how the class went.' : 'The feedback survey opens on the first day of class.'),
        );
    }

    protected function _surveyedRuns($email)
    {
        $out = array();
        foreach ($this->_read()->fetchCol(
            'SELECT run_id FROM ' . $this->_table('mmd_mobile_feedback') . ' WHERE learner_email = ? AND review_id IS NOT NULL',
            array($email)
        ) as $id) {
            $out[(int) $id] = true;
        }
        return $out;
    }

    protected function _certificatesByRun($email)
    {
        $out = array();
        foreach ($this->_read()->fetchAll(
            'SELECT run_id, class_id, course_sku, course_title, start_date, end_date, cert_no, token, status, sent_at
               FROM ' . $this->_table('mmd_course_run_certificate') . '
              WHERE LOWER(TRIM(learner_email)) = ? AND status IN (\'issued\',\'sent\')',
            array($email)
        ) as $r) {
            $out[(int) $r['run_id']] = $this->_certRow($r);
        }
        return $out;
    }

    protected function _certRow(array $r)
    {
        return array(
            'run_id'    => (int) $r['run_id'],
            'class_id'  => (string) $r['class_id'],
            'sku'       => trim((string) $r['course_sku']),
            'title'     => (string) $r['course_title'],
            'start_date'=> $this->_ymd($r['start_date']),
            'end_date'  => $this->_ymd($r['end_date']),
            'cert_no'   => (string) $r['cert_no'],
            'issued_on' => $r['sent_at'] ? substr((string) $r['sent_at'], 0, 10) : '',
            'name'      => Mage::helper('mmd_certificate')->certificateName(),
            // Token-gated public download, the same link the certificate email carries.
            'url'       => Mage::getUrl('certificate/download/index', array('_query' => array('token' => (string) $r['token']), '_nosid' => true)),
        );
    }

    /** product_id => cover image URL, from the cached public catalog. */
    protected function _imagesByProduct()
    {
        $out = array();
        try {
            foreach (Mage::helper('mmd_mobileapi/catalog')->courses()['courses'] as $c) {
                if (!empty($c['image_url'])) $out[(int) $c['id']] = $c['image_url'];
            }
        } catch (Exception $e) {
            // images are decoration — never fail a class list over them
        }
        return $out;
    }

    protected function _itemOptions($serialized)
    {
        $opts = @unserialize((string) $serialized);
        $out  = array();
        if (is_array($opts) && !empty($opts['options'])) {
            foreach ($opts['options'] as $o) {
                if (!isset($o['label'])) continue;
                $v = isset($o['print_value']) && (string) $o['print_value'] !== '' ? $o['print_value'] : (isset($o['value']) ? $o['value'] : '');
                $out[trim((string) $o['label'])] = trim(strip_tags((string) $v));
            }
        }
        return $out;
    }

    protected function _paymentStatus(array $o)
    {
        $state = (string) $o['state'];
        if ((float) $o['total_refunded'] > 0 && $state === 'closed') return 'refunded';
        if (in_array($state, array('canceled', 'closed'), true)) return 'cancelled';
        if (in_array($state, array('processing', 'complete'), true)) return 'paid';
        return 'pending';
    }

    protected function _paymentLabel($status)
    {
        $map = array('paid' => 'Paid', 'pending' => 'Pending payment', 'cancelled' => 'Cancelled', 'refunded' => 'Refunded');
        return isset($map[$status]) ? $map[$status] : ucfirst($status);
    }

    protected function _ymd($v)
    {
        $v = (string) $v;
        return ($v === '' || strpos($v, '0000-00-00') === 0) ? '' : substr($v, 0, 10);
    }

    protected function _hm($v)
    {
        $v = (string) $v;
        return ($v === '' || $v === '00:00:00') ? '' : substr($v, 0, 5);
    }

    /** @return MMD_MobileApi_Helper_Data */
    protected function _h()
    {
        return Mage::helper('mmd_mobileapi');
    }

    protected function _read()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_read');
    }

    protected function _write()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_write');
    }

    protected function _table($name)
    {
        return Mage::getSingleton('core/resource')->getTableName($name);
    }
}
