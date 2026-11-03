<?php
/**
 * Capability: HRD Corp SBL-KHAS claim documents for a Malaysia class (POST /agent/api_claims).
 * Malaysia site only. Fills the partner's own Word forms (data/claims/: the standard HRD Corp T3 and JD14
 * forms and their Zoom attendance report, layout unchanged); writes nothing to the database.
 *
 *   op: t3           { class_id, mode: virtual|physical, [trainees], [course_title], [employers], [employer] }
 *                    one PSMB/SBL-KHAS/T3/01 attendance list per training day PER EMPLOYER
 *   op: jd14         { class_id, mode: virtual|physical, [venue], [jd14], [course_title], [employers], [employer] }
 *                    one PSMB/SBL-KHAS/JD/14 joint declaration per employer
 *   op: zoom_report  { class_id, date, zoom_csv, [course_title], [trainer_name], [employers], [employer] }
 *                    one Zoom attendance report per employer for that training day
 *
 *   course_title  the HRD Corp approved title (the website name can change after the grant is approved)
 *   trainer_name  the trainer's full legal name for the Zoom report (default: the assigned trainer's account name)
 *   trainees      {email: {nric, sex}} from the partner's participants sheet, for the T3. NRIC is only written into
 *                 the Word file - never echoed in previews/errors and never stored in the database.
 *
 * Partner rules (Saeid, 23 + 26 Oct 2026):
 *  - Only HRD Corp-claimed trainees are listed: a learner on the class roster whose booking for this
 *    course is company-sponsored (employer = the booking's company name), or whose employer the agent
 *    supplies in `employers` {email: company}. Everyone else is treated as self-paying and left off.
 *  - Citizenship is pre-filled "Malaysian"; NRIC and sex come from `trainees` (participants sheet), else blank.
 *  - T3 signature column: "ROT" (Remote Online Training) for virtual classes; blank for physical (signed by hand).
 *  - JD14 fee approved and fee claimed are separate; any field not supplied stays blank for the team.
 *  - Zoom: learners join with their registered email, so rows are matched by email only. Times come
 *    ONLY from the Zoom participant export the agent passes in - never from attendance ticks.
 *    Attendance duration = first join to last leave minus the 12:30-13:30 lunch, rounded down.
 *
 * Files go to var/claim-docs/ behind unguessable links that expire after 7 days
 * (GET /agent/api_claims/download?t=...). A redeploy clears them: re-run the op.
 */
class MMD_AgentApi_Model_Claims extends MMD_AgentApi_Model_Abstract
{
    const PROVIDER     = 'Tertiary Infotech Sdn. Bhd.';
    const PROVIDER_ROC = '1187680-U';
    const SIGNER       = 'Saeid Alizadeh';
    const DESIGNATION  = 'Director';
    const VENUE_PHYSICAL = 'G-3A-02, Corporate Office Suite, KL Gateway, No. 2, Jalan Kerinchi, Gerbang Kerinchi Lestari, 59200 Kuala Lumpur, Malaysia';
    const VENUE_VIRTUAL  = 'Online Training via ZOOM';
    const LUNCH_START  = '12:30';
    const LUNCH_END    = '13:30';
    const LINK_DAYS    = 7;
    const FORM_ROWS    = 9;   // trainee rows on the T3 / Zoom report forms; more -> another copy ("separate attachment")

    protected $_jd14Fields = array('employer_address', 'employer_code', 'approval_no', 'group_approved',
        'group_claimed', 'fee_approved', 'fee_claimed');

    public function preview($op, array $body)
    {
        if (!Mage::helper('mmd_attendance')->isMalaysiaSite()) {
            $this->_err('not_available', 'HRD Corp claim documents are only available on the Malaysia site.', 404);
        }
        switch ($op) {
            case 't3':          return $this->_previewT3($body);
            case 'jd14':        return $this->_previewJd14($body);
            case 'zoom_report': return $this->_previewZoom($body);
            default:
                $this->_err('validation_error', 'Unsupported op "' . $op . '" for api_claims. Use t3, jd14 or zoom_report.', 400);
        }
    }

    public function commit($op, array $body, array $preview)
    {
        $this->_sweep();
        $p = $preview['token_payload'];
        $docs = array();
        switch ($op) {
            case 't3':
                foreach ($p['days'] as $day) {
                    foreach ($p['groups'] as $employer => $trainees) {
                        $pages = array_chunk($trainees, self::FORM_ROWS);
                        foreach ($pages as $i => $page) {
                            $docs[] = $this->_store($this->_buildT3($p, $day, $employer, $page),
                                'T3_' . $p['class_id'] . '_' . $day . '_' . $employer . (count($pages) > 1 ? '_part' . ($i + 1) : ''));
                        }
                    }
                }
                break;
            case 'jd14':
                foreach ($p['groups'] as $employer => $trainees) {
                    $docs[] = $this->_store($this->_buildJd14($p, $employer, $trainees),
                        'JD14_' . $p['class_id'] . '_' . $employer);
                }
                break;
            case 'zoom_report':
                foreach ($p['rows'] as $employer => $rows) {
                    $pages = array_chunk($rows, self::FORM_ROWS);
                    foreach ($pages as $i => $page) {
                        $docs[] = $this->_store($this->_buildZoom($p, $employer, $page, $i * self::FORM_ROWS),
                            'Zoom-attendance_' . $p['class_id'] . '_' . $p['date'] . '_' . $employer . (count($pages) > 1 ? '_part' . ($i + 1) : ''));
                    }
                }
                break;
        }
        return array(
            'target'    => $p['class_id'],
            'reindexed' => array(),
            'after'     => array('documents' => array_map(function ($d) { return $d['file']; }, $docs)),
            'extra'     => array('documents' => $docs),
        );
    }

    /* ---------------------------------------------------------------- previews */

    protected function _previewT3(array $body)
    {
        $ctx  = $this->_context($body);
        $mode = strtolower(trim((string) $this->_opt($body, 'mode', '')));
        if (!in_array($mode, array('virtual', 'physical'), true)) {
            $this->_err('validation_error', 'Field "mode" is required for t3: "virtual" (Zoom, signature column "ROT") or "physical".', 400);
        }

        // NRIC + sex from the participants sheet. Values never appear in any message.
        $claimed = array();
        foreach ($ctx['groups'] as $employer => $trainees) {
            foreach ($trainees as $t) { $claimed[$t['email']] = $t['name']; }
        }
        $people = array();
        foreach ((array) $this->_opt($body, 'trainees', array()) as $e => $info) {
            $e = strtolower(trim((string) $e));
            if (!isset($claimed[$e])) {
                $this->_err('validation_error', 'trainees: ' . $e . ' is not an HRD Corp-claimed trainee of ' . $ctx['class_id'] . '.', 400);
            }
            $info = is_array($info) ? $info : array();
            $nric = preg_replace('/\s+/', '', (string) (isset($info['nric']) ? $info['nric'] : ''));
            if ($nric !== '' && !preg_match('/^\d{6}-?\d{2}-?\d{4}$/', $nric)) {
                $this->_err('validation_error', 'trainees: the NRIC for ' . $e . ' is not a 12-digit MyKad number.', 400);
            }
            $sexIn = strtolower(trim((string) (isset($info['sex']) ? $info['sex'] : '')));
            $sexes = array('' => '', 'm' => 'Male', 'male' => 'Male', 'f' => 'Female', 'female' => 'Female');
            if (!isset($sexes[$sexIn])) {
                $this->_err('validation_error', 'trainees: sex for ' . $e . ' must be Male or Female.', 400);
            }
            $people[$e] = array('nric' => $nric, 'sex' => $sexes[$sexIn]);
        }
        $missing = array();
        foreach ($ctx['groups'] as $employer => $trainees) {
            foreach ($trainees as $i => $t) {
                $p = isset($people[$t['email']]) ? $people[$t['email']] : array('nric' => '', 'sex' => '');
                $ctx['groups'][$employer][$i] += $p;
                if ($p['nric'] === '' || $p['sex'] === '') { $missing[] = $t['name']; }
            }
        }

        $details = array(); $n = 0;
        foreach ($ctx['days'] as $day) {
            foreach ($ctx['groups'] as $employer => $trainees) {
                $copies = (int) ceil(count($trainees) / self::FORM_ROWS);
                $n += $copies;
                $details['T3 ' . $this->_dmy($day) . ' - ' . $employer] = count($trainees) . ' trainee(s)' . $this->_copies($copies);
            }
        }
        $details['NRIC and sex'] = 'given for ' . (count($claimed) - count($missing)) . ' of ' . count($claimed) . ' trainee(s)';
        $warnings = $missing
            ? array('NRIC/sex left blank for: ' . implode(', ', $missing) . ' (pass them in "trainees" from the participants sheet).')
            : array();
        $ctx['mode'] = $mode;
        return $this->_out($ctx, 't3', $details,
            'Will prepare ' . $n . ' T3 attendance list(s) for ' . $ctx['class_id'] . ' (' . $ctx['course'] . '): one per training day per employer. '
            . 'Citizenship is pre-filled "Malaysian"; signature column '
            . ($mode === 'virtual' ? '"ROT" (Remote Online Training).' : 'left blank for trainees to sign.'),
            $warnings, array('mode'));
    }

    protected function _previewJd14(array $body)
    {
        $ctx  = $this->_context($body);
        $mode = strtolower(trim((string) $this->_opt($body, 'mode', '')));
        if (!in_array($mode, array('virtual', 'physical'), true)) {
            $this->_err('validation_error', 'Field "mode" is required for jd14: "virtual" (Zoom) or "physical".', 400);
        }
        $venue = trim((string) $this->_opt($body, 'venue', ''));
        if ($venue === '') {
            $venue = $mode === 'virtual' ? self::VENUE_VIRTUAL : self::VENUE_PHYSICAL;
        }
        $given = $this->_opt($body, 'jd14', array());
        $given = is_array($given) ? $given : array();
        foreach (array_keys($given) as $emp) {
            if (!isset($ctx['groups'][$emp])) {
                $this->_err('validation_error', 'jd14 has details for "' . $emp . '", which is not an employer on this class. '
                    . 'Employers: ' . implode(', ', array_keys($ctx['groups'])) . '.', 400);
            }
        }
        $fields = array(); $details = array(); $warnings = array();
        foreach ($ctx['groups'] as $employer => $trainees) {
            $f = array();
            $in = isset($given[$employer]) && is_array($given[$employer]) ? $given[$employer] : array();
            foreach ($this->_jd14Fields as $k) {
                $f[$k] = isset($in[$k]) ? trim((string) $in[$k]) : '';
            }
            foreach (array('fee_approved', 'fee_claimed') as $k) {
                if ($f[$k] !== '') {
                    $num = str_replace(array(',', 'RM', ' '), '', $f[$k]);
                    if (!is_numeric($num)) {
                        $this->_err('validation_error', 'jd14.' . $k . ' for "' . $employer . '" must be an amount in RM.', 400);
                    }
                    $f[$k] = number_format((float) $num, 2);
                }
            }
            $fields[$employer] = $f;
            $blank = array_keys(array_filter($f, function ($v) { return $v === ''; }));
            $details['JD14 - ' . $employer] = count($trainees) . ' trainee(s)' . ($blank ? '; left blank: ' . implode(', ', $blank) : '');
            if ($blank) {
                $warnings[] = 'JD14 for ' . $employer . ': ' . implode(', ', $blank) . ' left blank for the team to fill in.';
            }
        }
        $ctx['mode'] = $mode; $ctx['venue'] = $venue; $ctx['jd14'] = $fields;
        return $this->_out($ctx, 'jd14', $details,
            'Will prepare ' . count($ctx['groups']) . ' JD14 joint declaration(s) for ' . $ctx['class_id'] . ' (' . $ctx['course'] . '), one per employer. '
            . 'Venue: ' . $venue . '.', $warnings, array('mode', 'venue', 'jd14'));
    }

    protected function _previewZoom(array $body)
    {
        $ctx  = $this->_context($body);
        $date = $this->_require($body, 'date');
        if (!in_array($date, $ctx['days'], true)) {
            $this->_err('validation_error', 'date ' . $date . ' is not a training day of ' . $ctx['class_id']
                . '. Training days: ' . implode(', ', $ctx['days']) . '.', 400);
        }
        $parts = $this->_parseZoomCsv($this->_require($body, 'zoom_csv'), $date);

        $rows = array(); $absent = array(); $details = array();
        $matched = array();
        foreach ($ctx['groups'] as $employer => $trainees) {
            foreach ($trainees as $t) {
                if (!isset($parts['people'][$t['email']])) {
                    $absent[] = $t['name'] . ' (' . $t['email'] . ', ' . $employer . ')';
                    continue;
                }
                $matched[$t['email']] = true;
                $rows[$employer][] = array_merge($parts['people'][$t['email']], array('name' => $t['name'], 'email' => $t['email']));
            }
        }
        if (!$rows) {
            $this->_err('no_matching_attendees', 'None of the HRD Corp-claimed trainees of ' . $ctx['class_id']
                . ' appear in the Zoom export by their registered email.', 422);
        }
        $warnings = array();
        if ($absent) {
            $warnings[] = 'Not found in the Zoom export (left off the report): ' . implode('; ', $absent) . '.';
        }
        $extra = array();
        foreach ($parts['people'] as $email => $pp) {
            if (!isset($matched[$email]) && $email !== strtolower($ctx['trainer_email'])) {
                $extra[] = ($pp['zoom_name'] !== '' ? $pp['zoom_name'] . ' ' : '') . '<' . $email . '>';
            }
        }
        if ($extra) {
            $warnings[] = 'In the Zoom export but not an HRD Corp-claimed trainee of this class (not on the report): ' . implode('; ', $extra) . '.';
        }
        if ($parts['no_email']) {
            $warnings[] = $parts['no_email'] . ' Zoom row(s) have no email and were ignored (learners must join with their registered email).';
        }
        if ($parts['other_dates']) {
            $warnings[] = $parts['other_dates'] . ' Zoom row(s) are not on ' . $date . ' and were ignored.';
        }
        if (!$ctx['trainer_name_given'] && $ctx['trainer'] !== '') {
            $warnings[] = 'Trainer shows the account name "' . $ctx['trainer'] . '". Pass trainer_name for the full legal name if different.';
        }
        foreach ($rows as $employer => $list) {
            $details['Zoom report ' . $this->_dmy($date) . ' - ' . $employer] = count($list) . ' trainee(s)'
                . $this->_copies((int) ceil(count($list) / self::FORM_ROWS)) . ': '
                . implode(', ', array_map(function ($r) { return $r['name'] . ' ' . $r['minutes'] . ' min'; }, $list));
        }
        $ctx['date'] = $date; $ctx['rows'] = $rows; $ctx['csv_sha1'] = sha1((string) $body['zoom_csv']);
        return $this->_out($ctx, 'zoom_report', $details,
            'Will prepare ' . count($rows) . ' Zoom attendance report(s) for ' . $ctx['class_id'] . ' on ' . $this->_dmy($date)
            . ', one per employer. Times are from the Zoom export; duration = first login to last logout minus lunch '
            . self::LUNCH_START . '-' . self::LUNCH_END . ', rounded down.', $warnings, array('date', 'rows', 'csv_sha1'));
    }

    /** Shared preview envelope. The token payload carries everything commit renders from. */
    protected function _out(array $ctx, $op, array $details, $summary, array $warnings, array $keys = array())
    {
        if ($ctx['left_off']) {
            $warnings[] = 'Left off as self-paying (no company-sponsored booking for this course, and no employer given): '
                . implode('; ', $ctx['left_off']) . '.';
        }
        if ($ctx['trainer'] === '') {
            $warnings[] = 'No trainer is assigned to ' . $ctx['class_id'] . ' (the Zoom report shows the trainer).';
        }
        if (!$ctx['course_title_given']) {
            $warnings[] = 'Course title is the website name "' . $ctx['course'] . '". If the HRD Corp approved title is different, '
                . 'pass it as course_title.';
        }
        $payload = array();
        foreach (array_merge(array('class_id', 'course', 'sku', 'days', 'trainer', 'trainer_email', 'groups'), $keys) as $k) {
            $payload[$k] = $ctx[$k];
        }
        return array(
            'target'        => $ctx['class_id'],
            'diff'          => array(array('field' => $op, 'from' => null,
                'to' => count($details) . ' document(s)')),
            'human_summary' => $summary,
            'details'       => $details,
            'warnings'      => $warnings,
            'token_payload' => $payload,
        );
    }

    /* ---------------------------------------------------------------- class context */

    protected function _context(array $body)
    {
        $classId = strtoupper($this->_require($body, 'class_id'));
        $run     = $this->_loadRunByClassId($classId);
        $res     = Mage::getSingleton('core/resource');
        $read    = $res->getConnection('core_read');

        $course = (string) $read->fetchOne(
            "SELECT v.value FROM " . $res->getTableName('catalog_product_entity_varchar') . " v
               JOIN " . $res->getTableName('eav_attribute') . " a ON a.attribute_id = v.attribute_id
              WHERE a.entity_type_id = 4 AND a.attribute_code = 'name' AND v.entity_id = ? AND v.store_id IN (0, ?)
              ORDER BY v.store_id DESC LIMIT 1",
            array((int) $run['product_id'], (int) Mage::app()->getDefaultStoreView()->getId())
        );

        $days = array();
        foreach (Mage::helper('mmd_attendance')->sessionsForRun($run) as $s) {
            if (!empty($s['date']) && !in_array($s['date'], $days, true)) {
                $days[] = $s['date'];
            }
        }
        if (!$days) {
            $this->_err('validation_error', $classId . ' has no training dates.', 422);
        }

        $trainer = Mage::helper('mmd_rolemanager/trainer')->resolveRunTrainer($run);

        $roster = $read->fetchAll(
            "SELECT LOWER(TRIM(learner_email)) email, TRIM(COALESCE(learner_name, '')) name
               FROM " . $res->getTableName('course_run_enrolments') . " WHERE run_id = ? ORDER BY name, email",
            array((int) $run['run_id'])
        );
        if (!$roster) {
            $this->_err('validation_error', $classId . ' has no learners on its roster.', 422);
        }

        $override = array();
        foreach ((array) $this->_opt($body, 'employers', array()) as $e => $company) {
            $override[strtolower(trim((string) $e))] = trim((string) $company);
        }
        $rosterEmails = array_column($roster, 'email');
        foreach (array_keys($override) as $e) {
            if (!in_array($e, $rosterEmails, true)) {
                $this->_err('validation_error', 'employers: ' . $e . ' is not on the roster of ' . $classId . '.', 400);
            }
        }

        $groups = array(); $leftOff = array();
        foreach ($roster as $r) {
            $name = $r['name'] !== '' ? $r['name'] : $r['email'];
            $employer = isset($override[$r['email']]) && $override[$r['email']] !== ''
                ? $override[$r['email']]
                : $this->_bookingEmployer($r['email'], (int) $run['product_id'], (string) $run['course_start_date']);
            if ($employer === '') {
                $leftOff[] = $name . ' (' . $r['email'] . ')';
                continue;
            }
            // As registered, not upper-cased - matches the partner's completed forms (27 Oct).
            $groups[$employer][] = array('name' => $name, 'email' => $r['email']);
        }
        $only = trim((string) $this->_opt($body, 'employer', ''));
        if ($only !== '') {
            if (!isset($groups[$only])) {
                $this->_err('validation_error', 'employer "' . $only . '" is not on this class. Employers: '
                    . ($groups ? implode(', ', array_keys($groups)) : 'none') . '.', 400);
            }
            $groups = array($only => $groups[$only]);
        }
        if (!$groups) {
            $this->_err('no_claimable_trainees', 'No HRD Corp-claimed trainees on ' . $classId
                . ': no learner has a company-sponsored booking for this course. Pass "employers" {email: company} for '
                . 'company-sponsored learners added without a booking.', 422);
        }
        ksort($groups);

        // The website name can change after HRD Corp approves the grant; the forms need the approved title.
        $title       = trim((string) $this->_opt($body, 'course_title', ''));
        $trainerName = trim((string) $this->_opt($body, 'trainer_name', ''));

        return array(
            'class_id' => $classId, 'course' => $title !== '' ? $title : $course, 'course_title_given' => $title !== '',
            'sku' => trim((string) $run['course_sku']),
            'days' => $days, 'groups' => $groups, 'left_off' => $leftOff,
            'trainer' => $trainerName !== '' ? $trainerName : ($trainer ? (string) $trainer['name'] : ''),
            'trainer_name_given' => $trainerName !== '',
            'trainer_email' => $trainer ? (string) $trainer['email'] : '',
        );
    }

    /**
     * Company name on the learner's latest company-sponsored booking for this course ('' if none).
     * A booking whose Course Date starts on the class start date wins over other dates.
     */
    protected function _bookingEmployer($email, $productId, $startYmd)
    {
        $res  = Mage::getSingleton('core/resource');
        $read = $res->getConnection('core_read');
        $rows = $read->fetchAll(
            "SELECT p.additional_information info, oi.product_options opts
               FROM " . $res->getTableName('sales/order') . " o
               JOIN " . $res->getTableName('sales/order_item') . " oi ON oi.order_id = o.entity_id AND oi.parent_item_id IS NULL
               JOIN " . $res->getTableName('sales/order_payment') . " p ON p.parent_id = o.entity_id
              WHERE LOWER(TRIM(o.customer_email)) = ? AND oi.product_id = ? AND o.state NOT IN ('canceled', 'closed')
              ORDER BY o.entity_id DESC LIMIT 20",
            array($email, $productId)
        );
        $svc = Mage::getSingleton('mmd_rolemanager/courseRunEnrolmentService');
        $fallback = '';
        foreach ($rows as $r) {
            $info = @unserialize((string) $r['info']);
            if (!is_array($info) || (isset($info['registration_type']) ? $info['registration_type'] : '') !== MMD_RegistrationOnly_Helper_Data::TYPE_COMPANY) {
                continue;
            }
            $company = trim((string) (isset($info['company_name']) ? $info['company_name'] : ''));
            if ($company === '') {
                continue;
            }
            $opts = @unserialize((string) $r['opts']);
            foreach (isset($opts['options']) ? (array) $opts['options'] : array() as $o) {
                if (isset($o['label']) && trim((string) $o['label']) === 'Course Date') {
                    $raw = isset($o['print_value']) && (string) $o['print_value'] !== '' ? $o['print_value'] : (isset($o['value']) ? $o['value'] : '');
                    $d = $svc ? $svc->_parseDate((string) $raw) : null;
                    if ($d !== null && $d[0] === $startYmd) {
                        return $company;
                    }
                }
            }
            if ($fallback === '') {
                $fallback = $company;
            }
        }
        return $fallback;
    }

    /* ---------------------------------------------------------------- Zoom export */

    /**
     * Parse a Zoom participant export (CSV). Finds the header row with an email, a join and a leave column
     * (the meeting-summary block above it is skipped). Per email: first join, last leave,
     * minutes = (last leave - first join) - lunch overlap, floored. Break Out / Break In are always "N/A" (partner, 29 Oct).
     */
    protected function _parseZoomCsv($csv, $date)
    {
        $csv   = preg_replace('/^\xEF\xBB\xBF/', '', (string) $csv);
        $lines = preg_split('/\r\n|\n|\r/', $csv);
        $head = null; $cols = array();
        foreach ($lines as $i => $line) {
            $h = array_map(function ($c) { return strtolower(trim($c)); }, str_getcsv($line));
            $find = function ($needle) use ($h) {
                foreach ($h as $k => $c) { if (strpos($c, $needle) !== false) return $k; }
                return null;
            };
            if ($find('email') !== null && $find('join') !== null && $find('leave') !== null) {
                $head = $i;
                $cols = array('email' => $find('email'), 'join' => $find('join'), 'leave' => $find('leave'), 'name' => $find('name'));
                break;
            }
        }
        if ($head === null) {
            $this->_err('validation_error', 'zoom_csv: no participant header row with Email, Join time and Leave time columns. '
                . 'Pass the Zoom "Participants" CSV export as text.', 400);
        }

        $segments = array(); $names = array(); $noEmail = 0; $otherDates = 0;
        for ($i = $head + 1, $n = count($lines); $i < $n; $i++) {
            if (trim($lines[$i]) === '') continue;
            $c = str_getcsv($lines[$i]);
            $email = strtolower(trim(isset($c[$cols['email']]) ? $c[$cols['email']] : ''));
            $join  = strtotime(trim(isset($c[$cols['join']]) ? $c[$cols['join']] : ''));
            $leave = strtotime(trim(isset($c[$cols['leave']]) ? $c[$cols['leave']] : ''));
            if ($email === '' || strpos($email, '@') === false) { $noEmail++; continue; }
            if (!$join || !$leave || $leave < $join) {
                $this->_err('validation_error', 'zoom_csv: unreadable join/leave time on line ' . ($i + 1) . '.', 400);
            }
            if (date('Y-m-d', $join) !== $date) { $otherDates++; continue; }
            $segments[$email][] = array($join, $leave);
            if ($cols['name'] !== null && !isset($names[$email])) {
                $names[$email] = trim(preg_replace('/\s*\(.*\)\s*$/', '', (string) $c[$cols['name']]));
            }
        }

        $lunchS = strtotime($date . ' ' . self::LUNCH_START);
        $lunchE = strtotime($date . ' ' . self::LUNCH_END);
        $people = array();
        foreach ($segments as $email => $segs) {
            usort($segs, function ($a, $b) { return $a[0] - $b[0]; });
            $first = $segs[0][0];
            $last  = max(array_column($segs, 1));
            $lunch = max(0, min($last, $lunchE) - max($first, $lunchS));
            $people[$email] = array(
                'zoom_name' => isset($names[$email]) ? $names[$email] : '',
                'login'     => date('h:i:s A', $first),
                'break_out' => 'N/A',
                'break_in'  => 'N/A',
                'logout'    => date('h:i:s A', $last),
                'minutes'   => (int) floor(($last - $first - $lunch) / 60),
            );
        }
        return array('people' => $people, 'no_email' => $noEmail, 'other_dates' => $otherDates);
    }

    /* ---------------------------------------------------------------- documents */

    protected function _buildT3(array $p, $day, $employer, array $trainees)
    {
        $v = array('course' => $p['course'], 'date' => $this->_dmy($day));
        foreach (array_values($trainees) as $i => $t) {
            $v['name' . ($i + 1)]        = $t['name'];
            $v['employer' . ($i + 1)]    = $employer;
            $v['nric' . ($i + 1)]        = isset($t['nric']) ? $t['nric'] : '';
            $v['citizenship' . ($i + 1)] = 'Malaysian';
            $v['sex' . ($i + 1)]         = isset($t['sex']) ? $t['sex'] : '';
            $v['signature' . ($i + 1)]   = $p['mode'] === 'virtual' ? 'ROT' : '';
        }
        return Mage::getModel('mmd_agentapi/claims_docx')->load('t3')->set($v);
    }

    protected function _buildJd14(array $p, $employer, array $trainees)
    {
        $f = $p['jd14'][$employer];
        return Mage::getModel('mmd_agentapi/claims_docx')->load('jd14')->set(array(
            'employer_name'    => $employer,
            'employer_address' => $f['employer_address'],
            'employer_code'    => $f['employer_code'],
            'approval_no'      => $f['approval_no'],
            'group_approved'   => $f['group_approved'],
            'group_claimed'    => $f['group_claimed'],
            'course'           => $p['course'],
            'start'            => $this->_dmy($p['days'][0]),
            'end'              => $this->_dmy(end($p['days'])),
            'venue'            => $p['venue'],
            'trainees'         => (string) count($trainees),
            'fee_approved'     => $f['fee_approved'],
            'fee_claimed'      => $f['fee_claimed'],
        ));
    }

    protected function _buildZoom(array $p, $employer, array $rows, $offset = 0)
    {
        $v = array(
            'course'  => $p['course'],
            'trainer' => $p['trainer'],
            'date'    => $this->_dmy($p['date']),
            'lunch'   => date('g:i a', strtotime(self::LUNCH_START)) . ' - ' . date('g:i a', strtotime(self::LUNCH_END)),
            'company' => $employer,
            // the partner dates the provider sign-off with the training day (completed 27 Oct form)
            'provider_date' => $this->_dmy($p['date']),
        );
        foreach (array_values($rows) as $i => $r) {
            $n = $i + 1;
            $v['no' . $n] = (string) ($offset + $n);
            foreach (array('name', 'email', 'login', 'break_out', 'break_in', 'logout', 'minutes') as $k) {
                $v[$k . $n] = (string) $r[$k];
            }
        }
        return Mage::getModel('mmd_agentapi/claims_docx')->load('zoom_report')->set($v);
    }

    /* ---------------------------------------------------------------- storage */

    protected function _dir()
    {
        $dir = Mage::getBaseDir('var') . DS . 'claim-docs';
        if (!is_dir($dir)) {
            mkdir($dir, 0775, true);
        }
        return $dir;
    }

    /** Save a document behind an unguessable, expiring link. */
    protected function _store(MMD_AgentApi_Model_Claims_Docx $doc, $name)
    {
        $token = bin2hex(random_bytes(16));
        $file  = trim(preg_replace(array('/-{2,}/', '/-?_-?/'), array('-', '_'), preg_replace('/[^A-Za-z0-9_-]+/', '-', $name)), '-_') . '.docx';
        $doc->save($this->_dir() . DS . $token . '.docx');
        $expires = time() + self::LINK_DAYS * 86400;
        file_put_contents($this->_dir() . DS . $token . '.json', json_encode(array('file' => $file, 'expires' => $expires)));
        return array(
            'file'       => $file,
            'url'        => Mage::getUrl('agent/api_claims/download', array('_query' => array('t' => $token), '_nosid' => true)),
            'expires_at' => gmdate('Y-m-d\TH:i:s\Z', $expires),
        );
    }

    /** Delete expired documents. */
    protected function _sweep()
    {
        foreach ((array) glob($this->_dir() . DS . '*.json') as $meta) {
            $m = json_decode((string) @file_get_contents($meta), true);
            if (!is_array($m) || (int) $m['expires'] < time()) {
                @unlink(substr($meta, 0, -5) . '.docx');
                @unlink($meta);
            }
        }
    }

    /** ", on 2 copies of the form" when the 9 trainee rows are not enough. */
    protected function _copies($n)
    {
        return $n > 1 ? ' (on ' . $n . ' copies of the form, 9 per copy)' : '';
    }

    protected function _dmy($ymd)
    {
        return date('d/m/Y', strtotime($ymd));
    }
}
