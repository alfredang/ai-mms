<?php
/**
 * Public read-only API: upcoming-class reminder feed for the WhatsApp bot.
 *
 * GET /courses/api_reminders?days_ahead=<n>
 *   Header:  X-API-Key: <shared secret>
 *
 *   Returns every confirmed class starting in exactly N days from today
 *   (where N defaults to 1 = tomorrow), along with the assigned trainer's
 *   name + email + phone and a pre-formatted WhatsApp message the bot can
 *   send verbatim.
 *
 *   Common usage by the bot's scheduler:
 *     - Daily at 6 PM SGT, fetch ?days_ahead=1 (tomorrow's classes)
 *     - For each row in `data.reminders`, send `formatted_message` via
 *       WhatsApp to the trainer's phone number (or skip if phone is blank).
 *
 * Auth: X-API-Key (same key as the other /courses/api_* endpoints).
 *
 * **************************************************************************
 * CRITICAL — READ ONLY. MMS DOES NOT SEND ANYTHING.
 *
 *   This controller returns DATA only. It does not send emails, WhatsApp
 *   messages, or any outbound communication. The decision to actually
 *   deliver a reminder lives entirely on the consumer side (Alisha's
 *   WhatsApp bot). There is no cron job in MMS for this — bot has its
 *   own scheduler.
 *
 *   This separation is deliberate. The 2026-06-03 newsletter incident
 *   showed how dangerous it is for MMS itself to send outbound at scale.
 *   By making MMS a pure data provider, the kill switch lives outside
 *   our system and we can never accidentally spam trainers.
 * **************************************************************************
 *
 * Filter rules for what counts as a "reminder":
 *   - course_runs.course_start_date = today + days_ahead
 *   - course_runs.trainer_option_id IS NOT NULL  (only confirmed classes)
 *   - course_runs.invitation_paused = 0          (admin hasn't paused it)
 *   - Trainer's email must be resolvable (via latest accepted invitation)
 *   - Bot can additionally skip rows where trainer.whatsapp/telephone is
 *     empty if it only sends via WhatsApp.
 */
class MMD_Courses_Api_RemindersController extends Mage_Core_Controller_Front_Action
{
    const CONFIG_PATH_API_KEY         = 'courses/general/wsq_schedule_api_key';
    const CONFIG_PATH_TRAINER_API_KEY = 'courses/general/trainer_reminders_api_key';
    const SG_STORE_ID                 = 1;
    const SG_CLASS_ID_PREFIX          = 'SG';
    const ESCALATION_WHATSAPP         = '+65 8866 6375';

    public function indexAction()
    {
        // Accept EITHER the customer-reply key or the trainer-reminders role
        // key. This endpoint is dual-purpose: the customer-reply bot may
        // also need schedule data, while the trainer-reminders bot has its
        // own role key for audit/rotation independence.
        $keyCustomer = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        $keyTrainer  = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_TRAINER_API_KEY));
        if ($keyCustomer === '' && $keyTrainer === '') {
            return $this->_json(503, $this->_errEnvelope('api_disabled', 'No API keys configured.'));
        }
        $provided = trim((string) $this->getRequest()->getHeader('X-API-Key'));
        $ok = false;
        if ($keyCustomer !== '' && hash_equals($keyCustomer, $provided)) { $ok = true; }
        if ($keyTrainer  !== '' && hash_equals($keyTrainer,  $provided)) { $ok = true; }
        if (!$ok) {
            return $this->_json(401, $this->_errEnvelope('unauthorized', 'Invalid or missing X-API-Key.'));
        }

        // Accept BOTH parameter formats — the bot uses ?target_date=YYYY-MM-DD,
        // the original spec used ?days_ahead=N. If target_date is provided, it
        // wins. Otherwise compute filter date from days_ahead (default 1).
        $targetDate = trim((string) $this->getRequest()->getParam('target_date', ''));
        $daysAhead  = (int)  $this->getRequest()->getParam('days_ahead', 1);

        if ($targetDate !== '') {
            // Strict YYYY-MM-DD validation to avoid SQL injection / malformed dates
            if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $targetDate)) {
                return $this->_json(400, $this->_errEnvelope('bad_request',
                    'target_date must be in YYYY-MM-DD format (e.g. 2026-06-08).'));
            }
            $ts = strtotime($targetDate);
            if ($ts === false) {
                return $this->_json(400, $this->_errEnvelope('bad_request',
                    'target_date is not a valid calendar date.'));
            }
            $filterDate = $targetDate;
            $daysAhead  = (int) round(($ts - strtotime(date('Y-m-d'))) / 86400);
        } else {
            if ($daysAhead < 0 || $daysAhead > 30) {
                return $this->_json(400, $this->_errEnvelope('bad_request',
                    'days_ahead must be between 0 (today) and 30 (one month ahead).'));
            }
            $filterDate = date('Y-m-d', strtotime('+' . $daysAhead . ' days'));
        }

        try {
            // Phase 2 (commit e94c7f8e) introduced account-based trainer
            // assignment alongside the legacy EAV pointer. We include BOTH
            // columns and accept a row as "ready" if either is populated.
            // Per-row trainer info is then resolved via the canonical helper
            // MMD_RoleManager_Helper_Trainer::resolveRunTrainer() so we read
            // the same source of truth as the admin "All Classes" grid.
            $rows = $this->_db()->fetchAll(
                "SELECT cr.run_id, cr.class_id, cr.product_id, cr.course_sku,
                        cr.course_start_date, cr.course_end_date,
                        cr.course_start_time, cr.course_end_time,
                        cr.mode_of_training, cr.venue_building,
                        cr.venue_street, cr.venue_floor, cr.venue_unit,
                        cr.postal_code, cr.room,
                        cr.trainer_user_id, cr.trainer_option_id,
                        COALESCE(pn.value, '(deleted product)') AS course_title,
                        COALESCE(en.enrolled, 0) AS enrolled
                   FROM course_runs cr
              LEFT JOIN catalog_product_entity_varchar pn
                     ON pn.entity_id = cr.product_id
                    AND pn.attribute_id = (SELECT attribute_id FROM eav_attribute
                                            WHERE entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product')
                                              AND attribute_code = 'name' LIMIT 1)
                    AND pn.store_id = 0
              LEFT JOIN (
                    SELECT run_id, COUNT(*) AS enrolled
                      FROM course_run_enrolments
                     GROUP BY run_id
                ) en ON en.run_id = cr.run_id
                  WHERE cr.course_start_date = ?
                    AND cr.class_id LIKE 'SG%'
                    AND ( (cr.trainer_user_id IS NOT NULL AND cr.trainer_user_id > 0)
                       OR (cr.trainer_option_id IS NOT NULL AND cr.trainer_option_id > 0) )
                    AND cr.invitation_paused = 0
                  ORDER BY cr.course_start_date ASC, cr.course_start_time ASC",
                array($filterDate)
            );
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, $this->_errEnvelope('internal_error', $e->getMessage()));
        }

        $reminders     = array();
        $coveredCodes  = array(); // course_sku of every class we've already emitted

        // Phase 1: MMS classes with a confirmed trainer (account or EAV).
        foreach ($rows as $r) {
            $reminders[] = $this->_buildReminder($r, $daysAhead);
            $coveredCodes[(string) $r['course_sku']] = true;
        }

        // Phase 2 + 3: LMS-TMS fallback (added 2026-06-08).
        //   - Phase 2: MMS class exists on date but no trainer assigned, AND
        //              LMS-TMS has an assigned trainer for the same course
        //              code → use LMS trainer info, mark trainer.source.
        //   - Phase 3: LMS-TMS has a class on this date that MMS doesn't
        //              track at all (no matching course_runs row), AND it has
        //              an assigned trainer → synthesize a reminder from LMS
        //              data, mark class_source = "lms-tms".
        // LMS-TMS failure is non-fatal — we just continue with MMS-only data.
        $lmsService = Mage::getModel('courses/lmsTmsCourseRun');
        $lmsByCode  = $lmsService->getRunsByDate($filterDate); // [sku => trainer info]
        $lmsStats   = $lmsService->getLastCallStats();
        // Singapore-only scope: drop any LMS rows whose course_code is not an
        // SG SKU pattern. Per CLAUDE.md, SG SKUs start with "TGS-" (WSQ) or
        // "C" (SG non-WSQ). "M*" is MY/NG/GH/BT/IN — exclude defensively even
        // though LMS-TMS today only carries SG content.
        $lmsByCode  = $this->_filterLmsToSg($lmsByCode);
        $lmsMatched = 0;
        $lmsOnly    = 0;

        if (!empty($lmsByCode)) {
            // Phase 2: find MMS classes on date with NO trainer, fill from LMS.
            $gapRows = $this->_fetchMmsClassesWithoutTrainer($filterDate);
            foreach ($gapRows as $gap) {
                $sku = (string) $gap['course_sku'];
                if (isset($coveredCodes[$sku])) continue;
                if (!isset($lmsByCode[$sku]))    continue;

                $lms = $lmsByCode[$sku];
                $trainerOverride = array(
                    'name'              => (string) $lms['name'],
                    'email'             => (string) $lms['email'],
                    'source'            => 'lms-tms-fallback',
                    'lms_course_run_id' => (string) $lms['lms_course_run_id'],
                );
                $reminders[] = $this->_buildReminder($gap, $daysAhead, $trainerOverride);
                $coveredCodes[$sku] = true;
                $lmsMatched++;
            }

            // Phase 3 DISABLED AGAIN 2026-06-09 — LMS data still drifts from
            // ops reality (Google Calendar = source of truth, but ops asked us
            // to use LMS/MMS only). LMS surfaces classes marked Confirmed with
            // a trainer assigned that aren't actually on the schedule (seen
            // for 13 Jun: 3 LMS rows for 3D Modelling Blender, CKA Training,
            // Accounting Non-Finance Mgrs — none on the actual calendar).
            // Until LMS data drift is fixed upstream, only Phase 1 + Phase 2
            // (MMS-controlled) emit reminders. LMS-only classes are counted
            // for diagnostic but not surfaced.
            foreach ($lmsByCode as $sku => $lms) {
                if (isset($coveredCodes[$sku])) continue;
                $lmsOnly++; // count for diagnostic, do not emit
            }
        }

        // Fallback diagnostic: when reminders count is 0 (or low), surface
        // WHY by listing every class on this date that isn't confirmed.
        // Operators can read this to decide: are trainers genuinely missing,
        // or is the invitation flow stuck somewhere?
        $diagnostic = $this->_buildDiagnostic($filterDate, count($reminders));
        $diagnostic['lms_tms'] = array(
            'attempted'      => (bool) ($lmsStats['attempted'] ?? false),
            'success'        => (bool) ($lmsStats['success']   ?? false),
            'configured'     => (bool) ($lmsStats['configured']?? false),
            'rows_returned'  => (int)  ($lmsStats['rows_returned'] ?? 0),
            'matched_count'  => $lmsMatched,
            'lms_only_count' => $lmsOnly,
            'error'          => (string) ($lmsStats['error'] ?? ''),
        );

        return $this->_json(200, array(
            'source_url'   => 'https://www.tertiarycourses.com.sg/',
            'last_updated' => gmdate('c'),
            'confidence'   => count($reminders) === 0 ? 'low' : 'high',
            'data'         => array(
                'filter_date' => $filterDate,
                'days_ahead'  => $daysAhead,
                'count'       => count($reminders),
                'note'        => 'MMS does NOT send these reminders. Pull this endpoint from your scheduler and decide on the consumer side whether to actually deliver each formatted_message.',
                'reminders'   => $reminders,
                'fallback_check' => $diagnostic,
            ),
        ));
    }

    /**
     * Fallback diagnostic — when the primary reminders array is empty (or
     * suspiciously short), show every class on the target date with its
     * trainer status across all sources we know about:
     *
     *   1. course_runs.trainer_option_id        (confirmed assignment)
     *   2. course_run_trainer_invitations       (accepted / pending / declined)
     *
     * Surfaces a "classes_needing_attention" list so the operator can see
     * exactly which classes need trainer assignment. Each entry includes a
     * recommended next action.
     */
    private function _buildDiagnostic($filterDate, $primaryCount)
    {
        try {
            $allClasses = $this->_db()->fetchAll(
                "SELECT cr.run_id, cr.class_id, cr.course_sku, cr.product_id,
                        cr.trainer_user_id, cr.trainer_option_id,
                        cr.invitation_paused, cr.invitation_replies_blocked,
                        COALESCE(pn.value, '(deleted product)') AS course_title,
                        latest_inv.status AS invitation_status,
                        latest_inv.trainer_name AS invitation_trainer_name,
                        latest_inv.trainer_email AS invitation_trainer_email,
                        latest_inv.sent_at AS invitation_sent_at
                   FROM course_runs cr
              LEFT JOIN catalog_product_entity_varchar pn
                     ON pn.entity_id = cr.product_id
                    AND pn.attribute_id = (SELECT attribute_id FROM eav_attribute
                                            WHERE entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product')
                                              AND attribute_code = 'name' LIMIT 1)
                    AND pn.store_id = 0
              LEFT JOIN (
                    SELECT i.run_id, i.status, i.trainer_name, i.trainer_email, i.sent_at
                      FROM course_run_trainer_invitations i
                     INNER JOIN (
                         SELECT run_id, MAX(id) AS max_id
                           FROM course_run_trainer_invitations
                          GROUP BY run_id
                     ) latest ON latest.run_id = i.run_id AND latest.max_id = i.id
                ) latest_inv ON latest_inv.run_id = cr.run_id
                  WHERE cr.course_start_date = ?
                    AND cr.class_id LIKE 'SG%'
                  ORDER BY cr.run_id ASC",
                array($filterDate)
            );
        } catch (Exception $e) {
            return array(
                'error' => 'diagnostic_query_failed',
                'message' => $e->getMessage(),
            );
        }

        $total = count($allClasses);
        $confirmed       = 0;
        $byAccount       = 0;
        $byEav           = 0;
        $accepted        = 0;
        $pending         = 0;
        $declined        = 0;
        $paused          = 0;
        $noTrainerInfo   = 0;
        $needAttention   = array();

        foreach ($allClasses as $c) {
            $userId = (int) ($c['trainer_user_id']   ?? 0);
            $optId  = (int) ($c['trainer_option_id'] ?? 0);
            $status = (string) ($c['invitation_status'] ?? '');

            $hasTrainer = ($userId > 0) || ($optId > 0);
            if ($hasTrainer) { $confirmed++; }
            if ($userId > 0) { $byAccount++; } elseif ($optId > 0) { $byEav++; }
            if ($status === 'accepted')       { $accepted++; }
            if ($status === 'pending')        { $pending++; }
            if ($status === 'declined')       { $declined++; }
            if ((int) $c['invitation_paused'] === 1) { $paused++; }

            // What does this class need?
            $action = null;
            if ($hasTrainer && (int) $c['invitation_paused'] === 0) {
                // Already counted in primary reminders — no action needed
                continue;
            }
            if ((int) $c['invitation_paused'] === 1) {
                $action = 'invitation_paused — admin needs to unpause this class';
            } elseif ($status === 'pending') {
                $action = 'invitation_pending — waiting on trainer to accept (sent ' . $c['invitation_sent_at'] . ')';
            } elseif ($status === 'declined') {
                $action = 'invitation_declined — admin needs to invite a different trainer';
            } elseif ($status === 'accepted' && !$hasTrainer) {
                $action = 'invitation_accepted_not_synced — admin needs to sync trainer_option_id (data drift bug)';
            } else {
                $action = 'no_trainer_assigned — admin needs to assign a trainer via Class Management';
                $noTrainerInfo++;
            }

            $needAttention[] = array(
                'run_id'                 => (int) $c['run_id'],
                'class_id'               => (string) $c['class_id'],
                'store_code'             => $this->_storeFromClassId($c['class_id']),
                'course_sku'             => (string) $c['course_sku'],
                'course_title'           => (string) $c['course_title'],
                'has_trainer'            => $hasTrainer,
                'trainer_user_id'        => $userId > 0 ? $userId : null,
                'trainer_option_id'      => $optId  > 0 ? $optId  : null,
                'trainer_source'         => $userId > 0 ? 'account' : ($optId > 0 ? 'eav' : null),
                'invitation_status'      => $status ?: 'never_invited',
                'invitation_trainer'     => $c['invitation_trainer_name'] ?: null,
                'invitation_sent_at'     => $c['invitation_sent_at'] ?: null,
                'invitation_paused'      => (int) $c['invitation_paused'] === 1,
                'action_needed'          => $action,
            );
        }

        return array(
            'summary' => sprintf(
                '%d total classes on %s; %d confirmed (in reminders[]); %d need attention',
                $total, $filterDate, $confirmed, count($needAttention)
            ),
            'totals' => array(
                'total_classes_on_date'         => $total,
                'with_confirmed_trainer'        => $confirmed,
                'confirmed_via_account'         => $byAccount,
                'confirmed_via_legacy_eav'      => $byEav,
                'with_accepted_invitation'      => $accepted,
                'with_pending_invitation'       => $pending,
                'with_declined_invitation'      => $declined,
                'invitation_paused'             => $paused,
                'no_trainer_no_invitation'      => $noTrainerInfo,
            ),
            'classes_needing_attention' => $needAttention,
            'interpretation' => $primaryCount === 0
                ? ($total === 0
                    ? 'No classes scheduled for this date. Bot should skip / post "no reminders today".'
                    : 'Classes exist but none are ready. See classes_needing_attention[].action_needed for each.')
                : 'Primary reminders array populated. classes_needing_attention[] shows what else needs fixing.',
        );
    }

    /**
     * Class IDs are formatted "<STORE_CODE>######" (e.g. SG000042, GH000001).
     * Strip the digits to extract the store code.
     */
    private function _storeFromClassId($classId)
    {
        $classId = (string) $classId;
        if ($classId === '') return null;
        if (preg_match('/^([A-Z]{2})/', $classId, $m)) {
            return $m[1]; // SG, MY, GH, NG, BT, IN
        }
        return null;
    }

    private function _buildReminder($r, $daysAhead, array $trainerOverride = null)
    {
        $startDate = $r['course_start_date'];
        $endDate   = $r['course_end_date'] ?: $startDate;
        $startTime = $r['course_start_time'] ?? null;
        $endTime   = $r['course_end_time']   ?? null;
        $time = ($startTime && $endTime)
            ? date('g:i A', strtotime($startTime)) . ' - ' . date('g:i A', strtotime($endTime))
            : '9:30 AM - 5:30 PM';

        $venueText = $this->_venueText($r);
        $modeLabel = $this->_modeLabel($r['mode_of_training']);

        // Trainer resolution: explicit override (used by the LMS-TMS fallback
        // paths in indexAction) wins. Otherwise fall through to the Phase 2
        // canonical helper (admin_user account pointer, EAV legacy fallback).
        if ($trainerOverride !== null) {
            $trainerName   = (string) ($trainerOverride['name']   ?? '');
            $trainerEmail  = (string) ($trainerOverride['email']  ?? '');
            $trainerSource = (string) ($trainerOverride['source'] ?? '');
            $lmsRunId      = (string) ($trainerOverride['lms_course_run_id'] ?? '');
        } else {
            $resolved      = $this->_resolveTrainer($r);
            $trainerName   = $resolved ? (string) ($resolved['name']  ?? '') : '';
            $trainerEmail  = $resolved ? (string) ($resolved['email'] ?? '') : '';
            // Map helper's 'account'/'eav' to bot-facing 'mms-account'/'mms-eav'
            // so the consumer can tell MMS sources apart from LMS-TMS.
            $rawSource     = $resolved ? (string) ($resolved['source'] ?? '') : '';
            $trainerSource = $rawSource === 'account' ? 'mms-account'
                          : ($rawSource === 'eav'     ? 'mms-eav' : '');
            $lmsRunId      = '';
        }

        // Phone is NOT on admin_user or LMS-TMS; look it up in courses_trainers
        // by email as a best-effort. Empty string if we don't have a row.
        $trainerPhone = $this->_trainerPhoneByEmail($trainerEmail);

        $courseUrl = $this->_courseUrl($r['product_id'], $r['course_sku']);

        // Date format: "1 Jun 2026" (day no leading zero, abbr month, 4-digit year)
        $startDateFmt = date('j M Y', strtotime($startDate));
        $endDateFmt   = date('j M Y', strtotime($endDate));

        // Duration in days, inclusive of start and end day
        $durationDays = 1;
        $startTs = strtotime($startDate);
        $endTs   = strtotime($endDate);
        if ($startTs && $endTs && $endTs >= $startTs) {
            $durationDays = (int) floor(($endTs - $startTs) / 86400) + 1;
        }
        $durationText = $durationDays . ' day' . ($durationDays === 1 ? '' : 's');

        // Per Tertiary Infotech standard format — no emojis, official tone.
        // WSQ courses (TGS- prefix) get an extra LMS-TMS portal link for
        // E-Attendance + course materials. Non-WSQ courses (C-prefix SG,
        // M-prefix MY/NG/GH/BT/IN) omit that line — those don't live in
        // LMS-TMS so the link would 404 for trainers.
        $isWsq = (stripos((string) $r['course_sku'], 'TGS-') === 0);
        $formatted = "Dear " . $trainerName . "\n"
            . "This is a gentle reminder for your upcoming training below.\n"
            . "Course Title: " . $r['course_title'] . "\n"
            . "Course Code: " . $r['course_sku'] . "\n"
            . "Course Run ID: " . ($lmsRunId !== '' ? $lmsRunId : (int) $r['run_id']) . "\n"
            . "Start Date: " . $startDateFmt . "\n"
            . "End Date: " . $endDateFmt . "\n"
            . "Course Duration: " . $durationText . "\n"
            . "Mode of Training: " . $modeLabel . "\n"
            . ($isWsq
                ? "To view E-Attendance and course-related materials, please log in below:\nhttps://lms-tms.tertiaryinfotech.com\n"
                : "")
            . "Training Admin, Tertiary Infotech Academy";

        $classSource = !empty($r['_class_source']) ? (string) $r['_class_source'] : 'mms';

        return array(
            'class_id'              => (string) ($r['class_id'] ?? ''),
            'run_id'                => (int)    $r['run_id'],
            'course_code'           => (string) $r['course_sku'],
            'course_name'           => (string) $r['course_title'],
            'course_url'            => $courseUrl,
            'start_date'            => $startDate,
            'end_date'              => $endDate,
            'start_date_formatted'  => $startDateFmt,
            'end_date_formatted'    => $endDateFmt,
            'course_duration_days'  => $durationDays,
            'course_duration_text'  => $durationText,
            'time'                  => $time,
            'mode'                  => $modeLabel,
            'venue'                 => $venueText,
            'enrolled'              => (int) ($r['enrolled'] ?? 0),
            'class_source'          => $classSource,
            'lms_course_run_id'     => $lmsRunId ?: null,
            'trainer'               => array(
                'name'      => $trainerName,
                'email'     => $trainerEmail,
                'telephone' => $trainerPhone,
                'roster_id' => isset($r['roster_id']) ? (int) $r['roster_id'] : null,
                'source'    => $trainerSource,
            ),
            'formatted_message'     => $formatted,
        );
    }

    /**
     * Phase 2 helper: pull MMS classes on date that have NO trainer assigned
     * (neither account nor EAV pointer). These are the candidates for
     * LMS-TMS-driven trainer recovery.
     */
    private function _fetchMmsClassesWithoutTrainer($filterDate)
    {
        try {
            return $this->_db()->fetchAll(
                "SELECT cr.run_id, cr.class_id, cr.product_id, cr.course_sku,
                        cr.course_start_date, cr.course_end_date,
                        cr.course_start_time, cr.course_end_time,
                        cr.mode_of_training, cr.venue_building,
                        cr.venue_street, cr.venue_floor, cr.venue_unit,
                        cr.postal_code, cr.room,
                        cr.trainer_user_id, cr.trainer_option_id,
                        COALESCE(pn.value, '(deleted product)') AS course_title,
                        COALESCE(en.enrolled, 0) AS enrolled
                   FROM course_runs cr
              LEFT JOIN catalog_product_entity_varchar pn
                     ON pn.entity_id = cr.product_id
                    AND pn.attribute_id = (SELECT attribute_id FROM eav_attribute
                                            WHERE entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product')
                                              AND attribute_code = 'name' LIMIT 1)
                    AND pn.store_id = 0
              LEFT JOIN (
                    SELECT run_id, COUNT(*) AS enrolled
                      FROM course_run_enrolments
                     GROUP BY run_id
                ) en ON en.run_id = cr.run_id
                  WHERE cr.course_start_date = ?
                    AND cr.class_id LIKE 'SG%'
                    AND (cr.trainer_user_id   IS NULL OR cr.trainer_user_id   = 0)
                    AND (cr.trainer_option_id IS NULL OR cr.trainer_option_id = 0)
                    AND cr.invitation_paused = 0
                  ORDER BY cr.course_start_date ASC, cr.course_start_time ASC",
                array($filterDate)
            );
        } catch (Exception $e) {
            Mage::logException($e);
            return array();
        }
    }

    /**
     * Defensive SG-only filter on the LMS-TMS course-runs map. Keeps only
     * SKUs that match the SG patterns per CLAUDE.md (TGS-* WSQ, C* non-WSQ).
     */
    private function _filterLmsToSg(array $lmsByCode)
    {
        $sg = array();
        foreach ($lmsByCode as $code => $row) {
            if (preg_match('/^(TGS-|C\d)/i', $code)) {
                $sg[$code] = $row;
            }
        }
        return $sg;
    }

    /**
     * Phase 3 helper: build a course_runs-shaped row from LMS-TMS data, so
     * _buildReminder() can render an LMS-only class with no MMS analogue.
     * LMS doesn't give us start/end time or venue, so those fall through to
     * the default labels in _venueText() / the 9:30 AM placeholder in
     * _buildReminder(). Mode is translated from LMS's string form back to
     * MMS's integer form so _modeLabel() can render it.
     */
    private function _syntheticRowFromLms($sku, array $lms, $filterDate)
    {
        $modeStr = strtolower((string) $lms['mode']);
        // Only Physical or Virtual per ops. LMS-TMS mode strings containing
        // "online"/"virtual"/"live" → Virtual (mode 2); everything else
        // (including legacy "hybrid"/"blended") → Physical (mode 1).
        if (strpos($modeStr, 'online') !== false
            || strpos($modeStr, 'virtual') !== false
            || strpos($modeStr, 'live') !== false) {
            $modeInt = 2;
        } else {
            $modeInt = 1; // default physical / classroom
        }
        // Prefer LMS's end_date_sgt when present (already timezone-converted by
        // the service). Falls back to filterDate so we never emit a malformed
        // date — single-day default is safer than an empty string when LMS
        // happens to return null for end_date.
        $endDate = !empty($lms['end_date_sgt']) ? $lms['end_date_sgt'] : $filterDate;

        return array(
            'run_id'             => 0,
            'class_id'           => '',                 // no MMS class_id
            'product_id'         => 0,                  // no MMS product
            'course_sku'         => (string) $sku,
            'course_title'       => (string) ($lms['course_title'] ?? $sku),
            'course_start_date'  => $filterDate,
            'course_end_date'    => $endDate,
            'course_start_time'  => null,
            'course_end_time'    => null,
            'mode_of_training'   => $modeInt,
            'venue_building'     => null,
            'venue_street'       => null,
            'venue_floor'        => null,
            'venue_unit'         => null,
            'postal_code'        => null,
            'room'               => null,
            'trainer_user_id'    => null,
            'trainer_option_id'  => null,
            'enrolled'           => (int) ($lms['enrolled_count'] ?? 0),
            '_class_source'      => 'lms-tms',
        );
    }

    private function _venueText($r)
    {
        $parts = array_filter(array(
            trim((string) ($r['venue_building'] ?? '')),
            trim((string) ($r['venue_street']   ?? '')),
            trim((string) ($r['room']           ?? '')),
        ));
        if (empty($parts)) {
            return 'Woods Square Tower 1, #07-85/86/87, Singapore 737715';
        }
        return implode(', ', $parts);
    }

    private function _courseUrl($productId, $sku)
    {
        try {
            $product = Mage::getModel('catalog/product')->setStoreId(self::SG_STORE_ID)->load((int) $productId);
            if ($product && $product->getId()) {
                $url = (string) $product->getProductUrl(false);
                if ($url !== '') return $url;
            }
        } catch (Exception $e) { /* fall through */ }
        return 'https://www.tertiarycourses.com.sg/catalogsearch/result/?q=' . rawurlencode($sku);
    }

    /**
     * Delegate to MMD_RoleManager_Helper_Trainer::resolveRunTrainer so the
     * /api_reminders endpoint reads trainer info from the same canonical
     * source as the admin "All Classes" grid. Falls back to a direct lookup
     * if the helper isn't registered (defensive, shouldn't happen on a real
     * deploy).
     */
    private function _resolveTrainer(array $r)
    {
        try {
            $helper = Mage::helper('mmd_rolemanager/trainer');
            if ($helper && method_exists($helper, 'resolveRunTrainer')) {
                return $helper->resolveRunTrainer($r);
            }
        } catch (Exception $e) { /* fall through */ }
        return null;
    }

    private function _trainerPhoneByEmail($email)
    {
        $email = trim((string) $email);
        if ($email === '') return '';
        try {
            $raw = (string) $this->_db()->fetchOne(
                "SELECT telephone FROM courses_trainers WHERE email = ? AND status = 1 AND telephone IS NOT NULL AND telephone <> '' LIMIT 1",
                array($email)
            );
            return $this->_normalizeSgPhone($raw);
        } catch (Exception $e) {
            return '';
        }
    }

    /**
     * HARD RULE — every trainer phone in the API response must be E.164
     * Singapore format (+65########). WhatsApp Business rejects sends to
     * 8-digit local-format numbers, which caused all 8 trainer reminders on
     * 2026-06-08 to go to wrong recipients (the bot was sending raw 8-digit
     * numbers and WhatsApp resolved them to wrong country contacts).
     *
     * Accepts any input format (raw 8-digit, "65xxxxxxxx", "+65 xxxx xxxx",
     * dashes/spaces, etc.) and returns "+65xxxxxxxx" with no separators.
     * Empty / unparseable input returns "".
     */
    private function _normalizeSgPhone($raw)
    {
        $digits = preg_replace('/\D/', '', (string) $raw);
        if ($digits === '') return '';
        // Already has 65 country code prefix (10 digits = 65 + 8 mobile)
        if (strlen($digits) >= 10 && substr($digits, 0, 2) === '65') {
            return '+' . $digits;
        }
        // 8-digit Singapore local format (mobile or landline)
        if (strlen($digits) === 8) {
            return '+65' . $digits;
        }
        // Fallback: assume SG and prepend (covers edge cases like leading 0)
        return '+65' . $digits;
    }

    private function _modeLabel($v)
    {
        // Per Tertiary Infotech standard wording for trainer reminders:
        // Only two modes exist — Physical (in-person classroom) and Virtual
        // (online / remote). mode_of_training = 2 → Virtual, everything else
        // → Physical. Hybrid is NOT a recognised value per ops; any legacy
        // mode = 3 rows fall through to Physical as the safer default.
        return ((int) $v) === 2 ? 'Virtual' : 'Physical';
    }

    private function _db()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_read');
    }

    private function _errEnvelope($code, $message)
    {
        return array(
            'source_url'   => null,
            'last_updated' => gmdate('c'),
            'confidence'   => 'error',
            'error'        => $code,
            'message'      => $message,
        );
    }

    private function _json($status, array $body)
    {
        $this->getResponse()
            ->setHttpResponseCode($status)
            ->setHeader('Content-Type', 'application/json; charset=utf-8', true)
            ->setHeader('Cache-Control', 'public, max-age=300', true)
            ->setBody(json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        return $this;
    }
}
