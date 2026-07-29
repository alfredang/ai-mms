<?php
/**
 * Bridges a completed Magento order into the course_runs / course_run_enrolments
 * class model for TGS-prefixed SKUs.
 *
 * Called from MMD_CustomOptions_Model_Observer::quoteSubmitSuccess() after normal
 * order processing. Failures are logged and never bubble up into checkout.
 */
class MMD_RoleManager_Model_CourseRunEnrolmentService
{
    const LOG_FILE = 'tgs_class_enrolment.log';

    /**
     * Main entry point. Accepts one order item and handles the full
     * find-or-create class + idempotent enrolment flow.
     */
    public function assignOrderItem(
        Mage_Sales_Model_Order $order,
        Mage_Sales_Model_Order_Item $item
    ) {
        // Skip child items (bundle components, configurable children).
        if ($item->getParentItemId()) {
            return;
        }

        $sku = strtoupper(trim((string) $item->getSku()));

        // Classes are only formed for non-WSQ / unfunded C-prefix course codes
        // (C010, C6…). TGS- (WSQ, handled by the external app), M- (partner
        // legacy) and any other code never materialise a course_runs row.
        if (!preg_match('/^C[0-9]/', $sku)) {
            return;
        }

        $productId = (int) $item->getProductId();
        if (!$productId) {
            $this->_log("SKU $sku: product_id is empty on order item — skipping");
            return;
        }

        $opts = $this->_extractOptions($item);

        $rawDate = $opts['course_date_value'];
        $rawTime = $opts['course_time_value'];

        if ($rawDate === '') {
            $this->_log("SKU $sku order #{$order->getIncrementId()}: missing Course Date — skipping");
            return;
        }
        if ($rawTime === '') {
            $this->_log("SKU $sku order #{$order->getIncrementId()}: missing Course Time — skipping");
            return;
        }

        $dates = $this->_parseDate($rawDate);
        if ($dates === null) {
            $this->_log("SKU $sku order #{$order->getIncrementId()}: unparseable date \"$rawDate\" — skipping");
            return;
        }

        $times = $this->_parseTime($rawTime);
        if ($times === null) {
            $this->_log("SKU $sku order #{$order->getIncrementId()}: unparseable time \"$rawTime\" — skipping");
            return;
        }

        list($startDate, $endDate)  = $dates;
        list($startTime, $endTime)  = $times;

        $runId = $this->_findOrCreateRun($productId, $sku, $startDate, $endDate, $startTime, $endTime, $item);

        if (!$runId) {
            $this->_log("SKU $sku order #{$order->getIncrementId()}: could not resolve run_id — skipping enrolment");
            return;
        }

        $email = strtolower(trim((string) $order->getCustomerEmail()));
        $name  = trim((string) $order->getCustomerName());
        if ($name === '') {
            $name = trim($order->getCustomerFirstname() . ' ' . $order->getCustomerLastname());
        }

        $this->_insertEnrolment($productId, $runId, $email, $name);
        $this->_ensureCustomerAccount($order, $email, $name);
    }

    // -------------------------------------------------------------------------
    // Option extraction
    // -------------------------------------------------------------------------

    private function _extractOptions(Mage_Sales_Model_Order_Item $item)
    {
        $result = array(
            'course_date_value'          => '',
            'course_time_value'          => '',
            'course_date_option_type_id' => null,
            'course_time_option_type_id' => null,
        );

        $opts = $item->getProductOptions();
        if (!is_array($opts) || empty($opts)) {
            $raw  = (string) $item->getData('product_options');
            $opts = ($raw !== '') ? @unserialize($raw) : array();
        }

        if (!is_array($opts) || !isset($opts['options'])) {
            return $result;
        }

        foreach ($opts['options'] as $o) {
            $label = isset($o['label']) ? trim((string) $o['label']) : '';
            $val   = isset($o['print_value']) && (string) $o['print_value'] !== ''
                ? (string) $o['print_value']
                : (isset($o['value']) ? (string) $o['value'] : '');
            $tid   = isset($o['option_value']) ? (int) $o['option_value'] : null;

            if ($label === 'Course Date') {
                $result['course_date_value']          = $val;
                $result['course_date_option_type_id'] = $tid;
            } elseif ($label === 'Course Time') {
                $result['course_time_value']          = $val;
                $result['course_time_option_type_id'] = $tid;
            }
        }

        return $result;
    }

    // -------------------------------------------------------------------------
    // Date parsing
    // -------------------------------------------------------------------------

    /**
     * Returns array($startDate, $endDate) as 'YYYY-MM-DD' strings, or null on failure.
     *
     * Supported formats (examples):
     *   2026-05-20                        ISO
     *   20/05/2026                        DD/MM/YYYY
     *   20 May 2026                       single day
     *   20 May 2026 (Wed)                 with weekday suffix
     *   20/21 May 2026 Evening (Wed/Thu)  two-day same-month
     *   7/8/10 Mar 2016                   three-day same-month
     *   14/15/21/22 Mar 2026              four-day same-month
     *   15-18 Jul 2019                    hyphen range same-month
     *   16 - 19 Dec 2019                  spaced hyphen range
     *   21.22 Feb 2019                    dot separator
     *   4 & 11 July 2015                  ampersand separator
     *   30 Nov / 1 Dec 2023               cross-month  DD Mon / DD Mon YYYY
     *   30/1 June/July 2018               cross-month  DD/DD Mon/Mon YYYY
     *   3/4Dec 2016                       no space before month name
     *   08 Nov 2021 (Mon) [Zoom only]     with bracket annotation
     *   15 Feb 2018 (Thurs                unclosed parenthesis
     *   12-16 Aug 2019 Mon-Fri 6-9:30pm   trailing day/time suffix
     */
    public function _parseDate($raw)
    {
        $s = trim((string) $raw);

        // ---- Normalise / strip noise ----------------------------------------

        // Strip [...] annotations (e.g. "[Zoom only]").
        $s = preg_replace('/\s*\[[^\]]*\]/', '', $s);
        // Strip (...) blocks including unclosed parens (e.g. "(Thurs", "(Wed(").
        $s = preg_replace('/\s*\([^)]*\)?/', '', $s);
        // Strip trailing weekday suffixes like "Mon-Fri", "Mon-Tues".
        $s = preg_replace('/\s+(Mon|Tue|Wed|Thu|Fri|Sat|Sun)[a-z]*(?:[-\/][A-Za-z]+)*\s*$/i', '', $s);
        // Strip anything after a 4-digit year (catches "Mon-Fri 6-9:30pm" etc.),
        // but NOT a following date range like "28 Dec 2026 - 1 Jan 2027" where the
        // start date carries its own year — the negative lookahead preserves the
        // tail so the cross-year range parser below can see the full label.
        $s = preg_replace('/(\d{4})\s+(?![-\/]\s*\d)\S.*$/', '$1', $s);
        // Strip trailing session-time descriptors.
        $s = trim(preg_replace('/\s+(evening|morning|afternoon|night)\s*$/i', '', $s));
        // Collapse repeated slashes / dashes introduced by malformed labels.
        $s = preg_replace('/\/+/', '/', $s);
        $s = preg_replace('/-\s*-+/', '-', $s);
        // Insert a space between a digit and a letter where missing
        // (e.g. "3/4Dec 2016" → "3/4 Dec 2016", "17-21Jul" → "17-21 Jul").
        $s = preg_replace('/(\d)([A-Za-z])/', '$1 $2', $s);
        // Normalise runs of whitespace.
        $s = trim(preg_replace('/\s+/', ' ', $s));

        // ---- Parsers (most-specific first) ----------------------------------

        // ISO: 2026-05-20
        if (preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', $s, $m)) {
            $d = $this->_makeDate((int)$m[2], (int)$m[3], (int)$m[1]);
            return $d ? array($d, $d) : null;
        }

        // DD/MM/YYYY
        if (preg_match('/^(\d{1,2})\/(\d{2})\/(\d{4})$/', $s, $m)) {
            $d = $this->_makeDate((int)$m[2], (int)$m[1], (int)$m[3]);
            return $d ? array($d, $d) : null;
        }

        // Cross-month: DD Mon / DD Mon YYYY  — "30 Nov / 1 Dec 2023"
        if (preg_match('/^(\d{1,2})\s+([A-Za-z]+)\s*\/\s*(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$/', $s, $m)) {
            $ms = $this->_monthNumber($m[2]);
            $me = $this->_monthNumber($m[4]);
            if (!$ms || !$me) return null;
            $year  = (int) $m[5];
            $start = $this->_makeDate($ms, (int)$m[1], $year);
            $end   = $this->_makeDate($me, (int)$m[3], $me < $ms ? $year + 1 : $year);
            return ($start && $end) ? array($start, $end) : null;
        }

        // Cross-month: DD/DD Mon/Mon YYYY  — "30/1 June/July 2018"
        if (preg_match('/^(\d{1,2})\/(\d{1,2})\s+([A-Za-z]+)\/([A-Za-z]+)\s+(\d{4})$/', $s, $m)) {
            $ms = $this->_monthNumber($m[3]);
            $me = $this->_monthNumber($m[4]);
            if (!$ms || !$me) return null;
            $year  = (int) $m[5];
            $start = $this->_makeDate($ms, (int)$m[1], $year);
            $end   = $this->_makeDate($me, (int)$m[2], $me < $ms ? $year + 1 : $year);
            return ($start && $end) ? array($start, $end) : null;
        }

        // Full hyphen range with a year on BOTH sides: DD Mon YYYY - DD Mon YYYY
        //   "28 Dec 2026 - 1 Jan 2027" (cross-year), "29 Sep 2026 - 2 Oct 2026"
        // Each side carries its own year, so end-year is taken verbatim rather
        // than inferred. Must precede the single-date parsers below, which would
        // otherwise collapse the range to its (single) start date.
        if (preg_match('/^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})\s*-\s*(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$/', $s, $m)) {
            $ms = $this->_monthNumber($m[2]);
            $me = $this->_monthNumber($m[5]);
            if (!$ms || !$me) return null;
            $start = $this->_makeDate($ms, (int)$m[1], (int)$m[3]);
            $end   = $this->_makeDate($me, (int)$m[4], (int)$m[6]);
            return ($start && $end) ? array($start, $end) : null;
        }

        // Hyphen range same-month: DD-DD Mon YYYY — "15-18 Jul 2019", "16 - 19 Dec 2019"
        if (preg_match('/^(\d{1,2})\s*-\s*(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$/', $s, $m)) {
            $month = $this->_monthNumber($m[3]);
            if (!$month) return null;
            $year  = (int) $m[4];
            $start = $this->_makeDate($month, (int)$m[1], $year);
            $end   = $this->_makeDate($month, (int)$m[2], $year);
            return ($start && $end) ? array($start, $end) : null;
        }

        // Slash-separated days same-month: DD[/DD...] Mon YYYY
        //   "20 May 2026", "20/21 May 2026", "7/8/10 Mar 2016", "14/15/21/22 Mar 2026"
        if (preg_match('/^(\d{1,2}(?:\/\d{1,2})*)\s+([A-Za-z]+)\s+(\d{4})$/', $s, $m)) {
            $days  = array_map('intval', explode('/', $m[1]));
            $month = $this->_monthNumber($m[2]);
            if (!$month) return null;
            $year  = (int) $m[3];
            $start = $this->_makeDate($month, $days[0], $year);
            $end   = $this->_makeDate($month, $days[count($days) - 1], $year);
            return ($start && $end) ? array($start, $end) : null;
        }

        // Dot-separated pair same-month: DD.DD Mon YYYY — "21.22 Feb 2019"
        if (preg_match('/^(\d{1,2})\.(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$/', $s, $m)) {
            $month = $this->_monthNumber($m[3]);
            if (!$month) return null;
            $year  = (int) $m[4];
            $start = $this->_makeDate($month, (int)$m[1], $year);
            $end   = $this->_makeDate($month, (int)$m[2], $year);
            return ($start && $end) ? array($start, $end) : null;
        }

        // Ampersand-separated: DD & DD Mon YYYY — "4 & 11 July 2015"
        if (preg_match('/^(\d{1,2})\s*&\s*(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$/', $s, $m)) {
            $month = $this->_monthNumber($m[3]);
            if (!$month) return null;
            $year  = (int) $m[4];
            $start = $this->_makeDate($month, (int)$m[1], $year);
            $end   = $this->_makeDate($month, (int)$m[2], $year);
            return ($start && $end) ? array($start, $end) : null;
        }

        return null;
    }

    private function _monthNumber($abbr)
    {
        static $map = array(
            'jan'=>1,'feb'=>2,'mar'=>3,'apr'=>4,'may'=>5,'jun'=>6,
            'jul'=>7,'aug'=>8,'sep'=>9,'oct'=>10,'nov'=>11,'dec'=>12,
        );
        return isset($map[strtolower(substr($abbr, 0, 3))]) ? $map[strtolower(substr($abbr, 0, 3))] : 0;
    }

    private function _makeDate($month, $day, $year)
    {
        if (!checkdate($month, $day, $year)) return null;
        return sprintf('%04d-%02d-%02d', $year, $month, $day);
    }

    // -------------------------------------------------------------------------
    // Time parsing
    // -------------------------------------------------------------------------

    /**
     * Returns array($startTime, $endTime) as 'HH:MM:SS' strings, or null on failure.
     *
     * Supported formats (from actual Course Time option values):
     *   9:30am - 5:30pm
     *   6pm-9.30pm / 6pm-9:30pm
     *   9am to 5pm           "to" separator
     *   2-5pm / 2 - 5 pm     no am/pm on start — inherit from end
     *   6pm - 9L30pm         typo L for :
     *   9:30pm - 6:30pm      same-meridiem swap — flip start to am
     *   9:30am - 6:30am      same-meridiem swap — flip end to pm
     */
    public function _parseTime($raw)
    {
        $s = trim((string) $raw);
        // Fix typo: digit-L-digit → digit:digit (e.g. "9L30pm" → "9:30pm")
        $s = preg_replace('/(\d)L(\d)/i', '$1:$2', $s);
        // Remove spaces before am/pm: "5 pm" → "5pm"
        $s = preg_replace('/(\d)\s+([ap]m)/i', '$1$2', $s);

        // Split on "-" or word "to" with optional surrounding whitespace.
        $parts = preg_split('/\s*(?:-|\bto\b)\s*/i', $s, 2);
        if (count($parts) !== 2) {
            return null;
        }

        $startRaw = trim($parts[0]);
        $endRaw   = trim($parts[1]);

        // If start has no am/pm but end does, inherit end's meridiem for start.
        if (!preg_match('/[ap]m/i', $startRaw) && preg_match('/([ap]m)/i', $endRaw, $mEnd)) {
            $startRaw .= $mEnd[1];
        }

        $startTime = $this->_parseTimePart($startRaw);
        $endTime   = $this->_parseTimePart($endRaw);

        if ($startTime === null || $endTime === null) {
            return null;
        }

        if ($endTime <= $startTime) {
            // Try flipping start's meridiem (e.g. "9:30pm - 6:30pm" → start becomes 9:30am)
            $startAlt = preg_replace_callback('/([ap])m$/i', static function ($m) {
                return strtolower($m[1]) === 'a' ? 'pm' : 'am';
            }, $startRaw);
            $altStart = $this->_parseTimePart($startAlt);
            if ($altStart !== null && $endTime > $altStart) {
                $startTime = $altStart;
            } else {
                // Try flipping end's meridiem (e.g. "9:30am - 6:30am" → end becomes 6:30pm)
                $endAlt = preg_replace_callback('/([ap])m$/i', static function ($m) {
                    return strtolower($m[1]) === 'a' ? 'pm' : 'am';
                }, $endRaw);
                $altEnd = $this->_parseTimePart($endAlt);
                if ($altEnd !== null && $altEnd > $startTime) {
                    $endTime = $altEnd;
                } else {
                    $this->_log("Time parse: end time \"$endTime\" is not after start time \"$startTime\" for \"$raw\" — skipping");
                    return null;
                }
            }
        }

        return array($startTime, $endTime);
    }

    /**
     * Parses a single time token like "9:30am", "9am", "6pm", "9.30pm".
     * Returns 'HH:MM:SS' or null.
     */
    private function _parseTimePart($token)
    {
        // Normalise dot separator to colon: "9.30pm" → "9:30pm"
        $t = str_replace('.', ':', $token);

        // Match: optional hours, optional :minutes, am/pm
        if (!preg_match('/^(\d{1,2})(?::(\d{2}))?([ap]m)$/i', $t, $m)) {
            return null;
        }

        $hour   = (int) $m[1];
        $minute = isset($m[2]) && $m[2] !== '' ? (int) $m[2] : 0;
        $meridiem = strtolower($m[3]);

        if ($hour < 1 || $hour > 12 || $minute < 0 || $minute > 59) {
            return null;
        }

        // Convert to 24-hour
        if ($meridiem === 'am') {
            if ($hour === 12) $hour = 0;
        } else {
            if ($hour !== 12) $hour += 12;
        }

        return sprintf('%02d:%02d:00', $hour, $minute);
    }

    // -------------------------------------------------------------------------
    // Find or create course_runs row
    // -------------------------------------------------------------------------

    private function _findOrCreateRun(
        $productId, $sku, $startDate, $endDate, $startTime, $endTime,
        Mage_Sales_Model_Order_Item $item
    ) {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $write    = $resource->getConnection('core_write');
        $table    = $resource->getTableName('course_runs');

        // 1. Try to find existing run.
        $runId = (int) $read->fetchOne(
            "SELECT run_id FROM `$table`
             WHERE product_id = ?
               AND course_start_date = ?
               AND course_end_date = ?
               AND course_start_time = ?
               AND course_end_time = ?
             LIMIT 1",
            array($productId, $startDate, $endDate, $startTime, $endTime)
        );

        if ($runId) {
            $this->_log("SKU $sku: reused run_id=$runId ($startDate {$startTime}-{$endTime})");
            return $runId;
        }

        // 2. Derive mode_of_training from selected option if available.
        $modeOfTraining = $this->_extractModeOfTraining($item);

        // 3. Class IDs use the uniform 'C' prefix on every site (C000001…).
        $_classId = MMD_RoleManager_Helper_Data::nextClassId($write, $table, MMD_RoleManager_Helper_Data::CLASS_ID_PREFIX);

        // 4. Insert new run.
        $row = array(
            'class_id'          => $_classId,
            'product_id'        => $productId,
            'course_sku'        => $sku,
            'course_start_date' => $startDate,
            'course_end_date'   => $endDate,
            'course_start_time' => $startTime,
            'course_end_time'   => $endTime,
            'mode_of_training'  => $modeOfTraining,
            'vacancy'           => 'A',
            'created_at'        => now(),
            'created_by'        => 'System',
        );

        try {
            $write->insert($table, $row);
            $runId = (int) $write->lastInsertId();
            $this->_log("SKU $sku: created run_id=$runId class_id=$_classId ($startDate {$startTime}-{$endTime})");
            return $runId;
        } catch (Exception $e) {
            // Duplicate key from a concurrent insert — reselect.
            if (strpos($e->getMessage(), '1062') !== false || strpos($e->getMessage(), 'Duplicate') !== false) {
                $runId = (int) $read->fetchOne(
                    "SELECT run_id FROM `$table`
                     WHERE product_id = ?
                       AND course_start_date = ?
                       AND course_end_date = ?
                       AND course_start_time = ?
                       AND course_end_time = ?
                     LIMIT 1",
                    array($productId, $startDate, $endDate, $startTime, $endTime)
                );
                if ($runId) {
                    $this->_log("SKU $sku: concurrent insert race resolved to run_id=$runId");
                    return $runId;
                }
            }
            throw $e;
        }
    }

    private function _extractModeOfTraining(Mage_Sales_Model_Order_Item $item)
    {
        $opts = $item->getProductOptions();
        if (!is_array($opts) || empty($opts)) {
            $raw  = (string) $item->getData('product_options');
            $opts = ($raw !== '') ? @unserialize($raw) : array();
        }
        if (!is_array($opts) || !isset($opts['options'])) {
            return 1;
        }
        foreach ($opts['options'] as $o) {
            $label = isset($o['label']) ? trim((string) $o['label']) : '';
            if (stripos($label, 'mode of training') !== false || stripos($label, 'mode_of_training') !== false) {
                $val = isset($o['print_value']) ? (string) $o['print_value'] : (isset($o['value']) ? (string) $o['value'] : '');
                $n   = (int) $val;
                if ($n >= 1 && $n <= 4) return $n;
            }
        }
        return 1;
    }

    // -------------------------------------------------------------------------
    // Insert enrolment
    // -------------------------------------------------------------------------

    private function _insertEnrolment($productId, $runId, $email, $name)
    {
        if ($email === '') {
            $this->_log("run_id=$runId: learner email is empty — skipping enrolment");
            return;
        }

        $resource   = Mage::getSingleton('core/resource');
        $write      = $resource->getConnection('core_write');
        $enrolTable = $resource->getTableName('course_run_enrolments');
        $exclTable  = $resource->getTableName('course_learner_excludes');

        $affected = $write->query(
            "INSERT IGNORE INTO `$enrolTable` (product_id, run_id, learner_email, learner_name)
             VALUES (?, ?, ?, ?)",
            array($productId, $runId, $email, $name)
        )->rowCount();

        if ($affected > 0) {
            $this->_log("run_id=$runId: enrolled $email");
            // Remove any prior exclusion row, matching manual Add Learner behaviour.
            try {
                $write->query(
                    "DELETE FROM `$exclTable` WHERE product_id = ? AND learner_email = ?",
                    array($productId, $email)
                );
            } catch (Exception $e) {
                // Table may not exist on all envs; non-fatal.
            }
        } else {
            $this->_log("run_id=$runId: enrolment for $email already present — skipped");
        }
    }

    // -------------------------------------------------------------------------
    // Customer account creation
    // -------------------------------------------------------------------------

    private function _ensureCustomerAccount(Mage_Sales_Model_Order $order, $email, $name)
    {
        if ($email === '') return;

        $websiteId = (int) $order->getStore()->getWebsiteId();
        $storeId   = (int) $order->getStoreId();

        $existing = Mage::getModel('customer/customer')
            ->setWebsiteId($websiteId)
            ->loadByEmail($email);

        if ($existing->getId()) {
            $this->_log("customer account for $email already exists (id={$existing->getId()}) — skipped");
            return;
        }

        $parts     = explode(' ', $name, 2);
        $firstname = trim(isset($parts[0]) ? $parts[0] : '');
        $lastname  = trim(isset($parts[1]) ? $parts[1] : '');
        if ($firstname === '') $firstname = $email;
        if ($lastname  === '') $lastname  = '.';

        try {
            $defaultGroupId = (int) Mage::getStoreConfig(
                Mage_Customer_Model_Group::XML_PATH_DEFAULT_ID, $storeId
            );

            $customer = Mage::getModel('customer/customer');
            $customer->setWebsiteId($websiteId)
                     ->setStoreId($storeId)
                     ->setEmail($email)
                     ->setFirstname($firstname)
                     ->setLastname($lastname)
                     ->setGroupId($defaultGroupId ?: 1)
                     ->setPassword($customer->generatePassword(16))
                     ->setForceConfirmed(true);
            $customer->save();
            $this->_log("created customer account for $email (id={$customer->getId()})");
        } catch (Exception $e) {
            $this->_log("failed to create customer account for $email: " . $e->getMessage());
        }
    }

    // -------------------------------------------------------------------------
    // Logging
    // -------------------------------------------------------------------------

    private function _log($message)
    {
        Mage::log('[CourseRunEnrolmentService] ' . $message, null, self::LOG_FILE, true);
    }
}
