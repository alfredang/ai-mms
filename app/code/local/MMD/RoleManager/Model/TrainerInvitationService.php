<?php
/**
 * Trainer invitation service — ported from AI-LMS-TMS trainerInvitationSender.ts.
 *
 * Flow:
 *   1. Admin calls sendNextInvitation($runId) from the Assign Trainer panel.
 *   2. Service resolves the product's trainers list (EAV multiselect option_ids,
 *      in sort_order ASC), looks up each trainer's email from courses_trainers,
 *      and builds a skip-set of already-invited trainers for this run.
 *   3. First eligible trainer (not in skip-set, has email) receives the invitation
 *      email with Accept and Decline button links (token-based, no login required).
 *   4. On accept: course_runs.trainer_option_id is set and a confirmation email
 *      is sent. On decline: a decline email is sent and the next trainer is tried.
 *
 * Email transport: reuses MMD_Email_Helper_Gmail (Gmail OAuth2) — same mechanism
 * as the course registration email. Falls back to Zend_Mail default if Gmail
 * credentials are not configured.
 */
class MMD_RoleManager_Model_TrainerInvitationService
{
    const TABLE_INVITATIONS = 'course_run_trainer_invitations';
    const TABLE_RUNS        = 'course_runs';
    const TABLE_TRAINERS    = 'courses_trainers';
    const LOG_FILE          = 'trainer-invitations.log';
    const COMPANY_SHORT_NAME = 'Tertiary Infotech';

    /** @var Varien_Db_Adapter_Interface */
    protected $_read;
    /** @var Varien_Db_Adapter_Interface */
    protected $_write;
    /** @var Mage_Core_Model_Resource */
    protected $_resource;

    protected function _init()
    {
        if ($this->_resource) return;
        $this->_resource = Mage::getSingleton('core/resource');
        $this->_read     = $this->_resource->getConnection('core_read');
        $this->_write    = $this->_resource->getConnection('core_write');
    }

    /**
     * Send an invitation to the next eligible trainer for the given run.
     *
     * @param int    $runId
     * @param string $overrideTrainerName  Force a specific trainer by name (admin override).
     * @return array { success:bool, message:string, trainer_name?:string, trainer_email?:string }
     */
    public function sendNextInvitation($runId, $overrideTrainerName = '')
    {
        $this->_init();
        $runId = (int) $runId;

        try {
            $run = $this->_loadRun($runId);
            if (!$run) {
                return array('success' => false, 'message' => 'Class run not found.');
            }
            if (Mage::helper('mmd_rolemanager/handover')->isManaged($runId)) {
                return array('success' => false, 'message' => 'TMS owns invitations and trainer assignments for this class.');
            }
            if (!empty($run['invitation_paused'])) {
                return array('success' => false, 'message' => 'Invitations are paused for this class.');
            }

            // Already has an accepted trainer — don't send another invitation.
            $accepted = $this->_read->fetchOne(
                "SELECT id FROM " . $this->_resource->getTableName(self::TABLE_INVITATIONS)
              . " WHERE run_id = ? AND status = 'accepted' LIMIT 1",
                array($runId)
            );
            if ($accepted) {
                return array('success' => false, 'message' => 'This class already has an accepted trainer.');
            }

            $queue   = $this->_buildQueue($run['product_id']);
            $skipSet = $this->_buildSkipSet($runId);

            $trainer = null;
            if ($overrideTrainerName !== '') {
                foreach ($queue as $t) {
                    if (strcasecmp(trim($t['name']), trim($overrideTrainerName)) === 0
                        && !empty($t['email'])) {
                        $trainer = $t;
                        break;
                    }
                }
                if (!$trainer) {
                    return array('success' => false, 'message' => 'Trainer "' . $overrideTrainerName . '" not found or has no email.');
                }
            } else {
                $lastInvited = $this->_getLastInvitedName($runId);
                $startIdx    = 0;
                if ($lastInvited !== '') {
                    foreach ($queue as $i => $t) {
                        if (strcasecmp(trim($t['name']), trim($lastInvited)) === 0) {
                            $startIdx = $i + 1;
                            break;
                        }
                    }
                }
                $n = count($queue);
                for ($i = 0; $i < $n; $i++) {
                    $t = $queue[($startIdx + $i) % $n];
                    if (!isset($skipSet[$t['name']]) && !empty($t['email'])) {
                        $trainer = $t;
                        break;
                    }
                }
            }

            if (!$trainer) {
                return array('success' => false, 'message' => 'No eligible trainer found. All trainers on this course have already been invited.');
            }

            return $this->_dispatchInvitation($run, $trainer);

        } catch (Exception $e) {
            Mage::log('TrainerInvitationService::sendNextInvitation error: ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
            return array('success' => false, 'message' => 'Error: ' . $e->getMessage());
        }
    }

    /**
     * Handle trainer accepting an invitation (via token-based public URL).
     *
     * @param  string $token
     * @return array  { success:bool, message:string, html:string }
     */
    public function handleAccept($token)
    {
        $this->_init();
        $token = (string) $token;

        $inv = $this->_loadInvitationByToken($token);
        if (!$inv) {
            return array('success' => false, 'message' => 'Invalid or expired invitation link.', 'html' => 'invalid');
        }
        if (Mage::helper('mmd_rolemanager/handover')->isManaged($inv['run_id'])) {
            return array('success' => false, 'message' => 'Manage this assignment in TMS.', 'html' => 'inactive');
        }
        if ($inv['status'] === 'accepted') {
            return array('success' => true, 'message' => 'You have already accepted this invitation.', 'html' => 'already_accepted');
        }
        if (!in_array($inv['status'], array('pending', 'resent'), true)) {
            return array('success' => false, 'message' => 'This invitation is no longer active.', 'html' => 'inactive');
        }

        // Check if the run has replies blocked (admin manually confirmed a trainer externally).
        $run = $this->_loadRun((int)$inv['run_id']);
        if ($run && !empty($run['invitation_replies_blocked'])) {
            $this->_write->update(
                $this->_resource->getTableName(self::TABLE_INVITATIONS),
                array('status' => 'blocked', 'responded_at' => now()),
                array('id = ?' => (int)$inv['id'])
            );
            return array('success' => false, 'message' => 'Another trainer has already been assigned to this class.', 'html' => 'blocked');
        }

        // Check if another trainer has already accepted for this run.
        $otherAccepted = $this->_read->fetchOne(
            "SELECT id FROM " . $this->_resource->getTableName(self::TABLE_INVITATIONS)
          . " WHERE run_id = ? AND status = 'accepted' AND id != ? LIMIT 1",
            array((int)$inv['run_id'], (int)$inv['id'])
        );
        if ($otherAccepted) {
            $this->_write->update(
                $this->_resource->getTableName(self::TABLE_INVITATIONS),
                array('status' => 'blocked', 'responded_at' => now()),
                array('id = ?' => (int)$inv['id'])
            );
            return array('success' => false, 'message' => 'Another trainer has already been assigned to this class.', 'html' => 'blocked');
        }

        // Accept: update invitation, set trainer on course_run.
        $this->_write->update(
            $this->_resource->getTableName(self::TABLE_INVITATIONS),
            array('status' => 'accepted', 'responded_at' => now()),
            array('id = ?' => (int)$inv['id'])
        );
        // Set the account-based pointer (Phase 2) or the legacy EAV pointer.
        if (!empty($inv['trainer_user_id'])) {
            $this->_write->update(
                $this->_resource->getTableName(self::TABLE_RUNS),
                array('trainer_user_id' => (int)$inv['trainer_user_id']),
                array('run_id = ?' => (int)$inv['run_id'])
            );
        } elseif (!empty($inv['trainer_option_id'])) {
            $this->_write->update(
                $this->_resource->getTableName(self::TABLE_RUNS),
                array('trainer_option_id' => (int)$inv['trainer_option_id']),
                array('run_id = ?' => (int)$inv['run_id'])
            );
        }

        Mage::log(
            sprintf('Trainer "%s" <%s> accepted invitation for run_id=%d', $inv['trainer_name'], $inv['trainer_email'], $inv['run_id']),
            Zend_Log::INFO, self::LOG_FILE
        );

        $this->_sendConfirmationEmail($inv, 'accept');
        return array('success' => true, 'message' => 'Invitation accepted.', 'html' => 'accepted');
    }

    /**
     * Handle trainer declining an invitation (via token-based public URL).
     *
     * @param  string $token
     * @return array  { success:bool, message:string, html:string }
     */
    public function handleDecline($token)
    {
        $this->_init();
        $token = (string) $token;

        $inv = $this->_loadInvitationByToken($token);
        if (!$inv) {
            return array('success' => false, 'message' => 'Invalid or expired invitation link.', 'html' => 'invalid');
        }
        if (Mage::helper('mmd_rolemanager/handover')->isManaged($inv['run_id'])) {
            return array('success'=>false,'message'=>'Manage this assignment in TMS.','html'=>'inactive');
        }
        if ($inv['status'] === 'declined') {
            return array('success' => true, 'message' => 'You have already declined this invitation.', 'html' => 'already_declined');
        }
        if (!in_array($inv['status'], array('pending', 'resent'), true)) {
            return array('success' => false, 'message' => 'This invitation is no longer active.', 'html' => 'inactive');
        }

        $this->_write->update(
            $this->_resource->getTableName(self::TABLE_INVITATIONS),
            array('status' => 'declined', 'responded_at' => now()),
            array('id = ?' => (int)$inv['id'])
        );

        Mage::log(
            sprintf('Trainer "%s" <%s> declined invitation for run_id=%d', $inv['trainer_name'], $inv['trainer_email'], $inv['run_id']),
            Zend_Log::INFO, self::LOG_FILE
        );

        $this->_sendConfirmationEmail($inv, 'decline');

        // Auto-escalate to next trainer — non-fatal if it fails.
        try {
            $this->sendNextInvitation((int)$inv['run_id']);
        } catch (Exception $e) {
            Mage::log('Auto-escalation failed after decline: ' . $e->getMessage(), Zend_Log::WARN, self::LOG_FILE);
        }

        return array('success' => true, 'message' => 'Invitation declined.', 'html' => 'declined');
    }

    // ------------------------------------------------------------------ //
    // Private helpers
    // ------------------------------------------------------------------ //

    protected function _loadRun($runId)
    {
        return $this->_read->fetchRow(
            "SELECT cr.run_id, cr.product_id, cr.course_sku, cr.class_id,
                    cr.course_start_date, cr.course_end_date,
                    cr.course_start_time, cr.course_end_time,
                    cr.trainer_option_id, cr.trainer_user_id, cr.invitation_paused, cr.invitation_replies_blocked,
                    COALESCE(pv.value, cr.course_sku) AS course_title
               FROM " . $this->_resource->getTableName(self::TABLE_RUNS) . " cr
               LEFT JOIN " . $this->_resource->getTableName('catalog_product_entity_varchar') . " pv
                    ON pv.entity_id = cr.product_id AND pv.store_id = 0
                   AND pv.attribute_id = (
                       SELECT a.attribute_id FROM " . $this->_resource->getTableName('eav_attribute') . " a
                        JOIN " . $this->_resource->getTableName('eav_entity_type') . " t ON t.entity_type_id = a.entity_type_id
                       WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'name'
                   )
              WHERE cr.run_id = ?",
            array($runId)
        ) ?: null;
    }

    /**
     * Ordered list of trainers attached to this product via the `trainers`
     * EAV multiselect attribute.  Each entry: { option_id, name, email }.
     * Order follows EAV sort_order ASC (same order the admin sees in the
     * Assign Trainer dropdown).
     */
    protected function _buildQueue($productId)
    {
        $productId = (int) $productId;

        // Phase 2: prefer the account-based approved list (mmd_product_trainer →
        // admin_user). Each entry carries user_id; option_id is 0. Emails come
        // straight from the account. Only if a product has no account-based
        // trainers do we fall back to the legacy EAV path below.
        $accounts = Mage::helper('mmd_rolemanager/trainer')->getProductTrainerAccounts($productId);
        if (!empty($accounts)) {
            $queue = array();
            foreach ($accounts as $a) {
                $queue[] = array(
                    'user_id'   => (int) $a['user_id'],
                    'option_id' => 0,
                    'name'      => (string) $a['name'],
                    'email'     => (string) $a['email'],
                );
            }
            return $queue;
        }

        // ---- Legacy EAV fallback ----
        // 1. Get trainer option_ids for this product (CSV from EAV text attribute).
        $attrId = (int) $this->_read->fetchOne(
            "SELECT attribute_id FROM " . $this->_resource->getTableName('eav_attribute')
          . " WHERE attribute_code = 'trainers' AND entity_type_id = 4"
        );
        if (!$attrId) return array();

        $csv = (string) $this->_read->fetchOne(
            "SELECT value FROM " . $this->_resource->getTableName('catalog_product_entity_text')
          . " WHERE entity_id = ? AND attribute_id = ? AND store_id = 0",
            array($productId, $attrId)
        );
        if (trim($csv) === '') return array();

        $oids = array_filter(array_map('intval', explode(',', $csv)));
        if (empty($oids)) return array();

        // 2. Load option names ordered by sort_order, then resolve emails.
        $oidsCsv = implode(',', $oids);
        $options = $this->_read->fetchAll(
            "SELECT eao.option_id, eaov.value AS name, eao.sort_order
               FROM " . $this->_resource->getTableName('eav_attribute_option') . " eao
               JOIN " . $this->_resource->getTableName('eav_attribute_option_value') . " eaov
                    ON eaov.option_id = eao.option_id AND eaov.store_id = 0
              WHERE eao.option_id IN ($oidsCsv)
              ORDER BY eao.sort_order ASC, eaov.value ASC"
        );

        // 3. Resolve emails from courses_trainers.relation_id = option_id.
        $emailByOid = array();
        if (!empty($options)) {
            $rows = $this->_read->fetchAll(
                "SELECT relation_id, email FROM " . $this->_resource->getTableName(self::TABLE_TRAINERS)
              . " WHERE relation_id IN ($oidsCsv) AND email IS NOT NULL AND email <> '' AND status = 1"
            );
            foreach ($rows as $r) {
                $emailByOid[(int)$r['relation_id']] = $r['email'];
            }
        }

        $queue = array();
        foreach ($options as $opt) {
            $queue[] = array(
                'user_id'   => 0,
                'option_id' => (int) $opt['option_id'],
                'name'      => (string) $opt['name'],
                'email'     => isset($emailByOid[(int)$opt['option_id']]) ? $emailByOid[(int)$opt['option_id']] : '',
            );
        }
        return $queue;
    }

    /**
     * Names of trainers already invited for this run who should be skipped
     * (pending = outstanding invite, accepted = done, declined/blocked = tried).
     * Returns [ trainer_name => true ] for O(1) lookup.
     */
    protected function _buildSkipSet($runId)
    {
        $rows = $this->_read->fetchCol(
            "SELECT trainer_name FROM " . $this->_resource->getTableName(self::TABLE_INVITATIONS)
          . " WHERE run_id = ? AND status IN ('pending','accepted','declined','blocked')",
            array((int) $runId)
        );
        $set = array();
        foreach ($rows as $name) {
            $set[$name] = true;
        }
        return $set;
    }

    protected function _getLastInvitedName($runId)
    {
        return (string) $this->_read->fetchOne(
            "SELECT trainer_name FROM " . $this->_resource->getTableName(self::TABLE_INVITATIONS)
          . " WHERE run_id = ? ORDER BY created_at DESC LIMIT 1",
            array((int) $runId)
        );
    }

    protected function _loadInvitationByToken($token)
    {
        return $this->_read->fetchRow(
            "SELECT * FROM " . $this->_resource->getTableName(self::TABLE_INVITATIONS)
          . " WHERE token = ? LIMIT 1",
            array($token)
        ) ?: null;
    }

    protected function _generateToken()
    {
        return bin2hex(random_bytes(32));
    }

    protected function _dispatchInvitation(array $run, array $trainer)
    {
        if (Mage::helper('mmd_rolemanager/handover')->isManaged($run['run_id'])) {
            return array('success'=>false,'message'=>'TMS owns invitations for this class.');
        }
        $token   = $this->_generateToken();
        $baseUrl = Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB);
        $acceptUrl  = rtrim($baseUrl, '/') . '/trainer_invite/respond?token=' . $token . '&action=accept';
        $declineUrl = rtrim($baseUrl, '/') . '/trainer_invite/respond?token=' . $token . '&action=decline';

        // Dates as DD Mon YYYY (mirrors LMS en-GB DD-MMM-YYYY).
        $startDate = $run['course_start_date'] ? date('d M Y', strtotime($run['course_start_date'])) : '—';
        $endDate   = $run['course_end_date']   ? date('d M Y', strtotime($run['course_end_date']))   : $startDate;
        // Duration = inclusive day span (LMS shows "X day(s)").
        $duration  = '';
        if ($run['course_start_date'] && $run['course_end_date']) {
            $days = (int) floor((strtotime($run['course_end_date']) - strtotime($run['course_start_date'])) / 86400) + 1;
            $duration = $days . ' day' . ($days === 1 ? '' : 's');
        }
        // Respond-by = now + 2 days, LMS format DD-MM-YYYY, 23:59 PM.
        $confirmBy = date('d-m-Y', strtotime('+2 days')) . ', 23:59 PM';

        // Subject mirrors LMS: "<Short Name> LMS - Trainer Invitation for <Title> (<RunId>)".
        $runId   = $run['class_id'] ?: $run['course_sku'];
        $subject = self::COMPANY_SHORT_NAME . ' LMS - Trainer Invitation for ' . $run['course_title'] . ' (' . $runId . ')';

        $body = $this->_buildInvitationHtml(
            $trainer['name'], $run['course_title'], $run['course_sku'], $runId,
            $startDate, $endDate, $duration, $confirmBy, $acceptUrl, $declineUrl
        );

        // Mark any previous pending invitation for this trainer on this run as resent.
        $this->_write->update(
            $this->_resource->getTableName(self::TABLE_INVITATIONS),
            array('status' => 'resent'),
            array(
                'run_id = ?'       => (int) $run['run_id'],
                'trainer_name = ?' => $trainer['name'],
                'status = ?'       => 'pending',
            )
        );

        $this->_write->insert(
            $this->_resource->getTableName(self::TABLE_INVITATIONS),
            array(
                'run_id'            => (int) $run['run_id'],
                'trainer_option_id' => !empty($trainer['option_id']) ? (int)$trainer['option_id'] : null,
                'trainer_user_id'   => !empty($trainer['user_id'])   ? (int)$trainer['user_id']   : null,
                'trainer_name'      => $trainer['name'],
                'trainer_email'     => $trainer['email'],
                'token'             => $token,
                'status'            => 'pending',
                'email_subject'     => $subject,
                'email_body'        => $body,
                'sent_at'           => now(),
            )
        );

        $sent = $this->_sendRawEmail($trainer['email'], $trainer['name'], $subject, $body);
        if (!$sent) {
            Mage::log('TrainerInvitationService: email send failed for ' . $trainer['email'], Zend_Log::WARN, self::LOG_FILE);
        }

        Mage::log(
            sprintf('Invitation sent to "%s" <%s> for run_id=%d (token=%s)', $trainer['name'], $trainer['email'], $run['run_id'], substr($token, 0, 8) . '...'),
            Zend_Log::INFO, self::LOG_FILE
        );

        return array(
            'success'       => true,
            'message'       => 'Invitation sent to ' . $trainer['name'] . ' (' . $trainer['email'] . ').',
            'trainer_name'  => $trainer['name'],
            'trainer_email' => $trainer['email'],
        );
    }

    protected function _sendConfirmationEmail(array $inv, $type)
    {
        $run = $this->_loadRun((int)$inv['run_id']);
        if (!$run) return;

        $startDate = $run['course_start_date'] ? date('d M Y', strtotime($run['course_start_date'])) : '—';
        $endDate   = $run['course_end_date']   ? date('d M Y', strtotime($run['course_end_date']))   : $startDate;
        $runId     = $run['class_id'] ?: $run['course_sku'];

        if ($type === 'accept') {
            $subject = 'Thank You for Accepting - ' . $run['course_title'] . ' (' . $runId . ')';
            $body    = $this->_buildAcceptHtml($inv['trainer_name'], $run['course_title'], $run['course_sku'], $runId, $startDate, $endDate);
        } else {
            $subject = 'Thank You for Your Response - ' . $run['course_title'] . ' (' . $runId . ')';
            $body    = $this->_buildDeclineHtml($inv['trainer_name']);
        }

        $this->_sendRawEmail($inv['trainer_email'], $inv['trainer_name'], $subject, $body);
    }

    /**
     * Send via Gmail OAuth2 (MMD_Email_Helper_Gmail). Falls back to
     * Zend_Mail default transport if Gmail is not configured.
     */
    protected function _sendRawEmail($toEmail, $toName, $subject, $bodyHtml)
    {
        try {
            /** @var MMD_Email_Helper_Gmail $gmail */
            $gmail = Mage::helper('mmd_email/gmail');
            $gmail->send($toEmail, $subject, $bodyHtml, $toName);
            return true;
        } catch (Exception $e) {
            Mage::log('Gmail send failed, trying Zend_Mail: ' . $e->getMessage(), Zend_Log::WARN, self::LOG_FILE);
        }

        // Fallback: Zend_Mail (uses whatever transport is installed at boot).
        try {
            $mail = new Zend_Mail('UTF-8');
            $mail->addTo($toEmail, $toName);
            $from = Mage::getStoreConfig('trans_email/ident_sales/email');
            $fromName = Mage::getStoreConfig('trans_email/ident_sales/name');
            $mail->setFrom($from ?: 'noreply@tertiarycourses.com.sg', $fromName ?: 'Tertiary Courses');
            $mail->setSubject($subject);
            $mail->setBodyHtml($bodyHtml);
            $mail->send();
            return true;
        } catch (Exception $e) {
            Mage::log('Zend_Mail fallback also failed: ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
            return false;
        }
    }

    // ------------------------------------------------------------------ //
    // HTML email builders
    // ------------------------------------------------------------------ //

    /** Company contact line for email signatures (mirrors LMS). */
    protected function _companyContacts()
    {
        $email = Mage::getStoreConfig('trans_email/ident_support/email') ?: 'enquiry@tertiaryinfotech.com';
        $tel   = '+65 6266 4475';
        $wa    = '6588708198';
        return array('email' => $email, 'tel' => $tel, 'whatsapp' => $wa);
    }

    /** Shared light-theme email signature block (mirrors LMS). */
    protected function _signatureHtml()
    {
        $c = $this->_companyContacts();
        return '<p style="margin:24px 0 0;">Best regards,<br>Support Team<br><strong>' . self::COMPANY_SHORT_NAME . '</strong><br>'
            . 'Tel: ' . htmlspecialchars($c['tel']) . ' | Email: <a href="mailto:' . htmlspecialchars($c['email']) . '" style="color:#2563eb;">' . htmlspecialchars($c['email']) . '</a>'
            . ' | WhatsApp: <a href="https://wa.me/' . htmlspecialchars($c['whatsapp']) . '" style="color:#2563eb;">https://wa.me/' . htmlspecialchars($c['whatsapp']) . '</a></p>';
    }

    /** Light-theme email wrapper (white bg, Arial, automated-email footer) — mirrors LMS. */
    protected function _emailWrap($innerHtml)
    {
        return '<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>'
            . '<body style="margin:0;padding:0;background:#ffffff;">'
            . '<div style="font-family:Arial,sans-serif;font-size:14px;color:#1f2937;line-height:1.55;background-color:#ffffff;max-width:640px;margin:0 auto;padding:24px;">'
            . $innerHtml
            . '<div style="border-top:1px solid #e5e7eb;padding-top:14px;margin-top:28px;">'
            . '<p style="margin:0;font-size:12px;color:#94a3b8;font-style:italic;">This is an automated email. Please do not reply directly to this message.</p>'
            . '</div></div></body></html>';
    }

    protected function _buildInvitationHtml($trainerName, $courseTitle, $courseSku, $runId, $startDate, $endDate, $duration, $confirmBy, $acceptUrl, $declineUrl)
    {
        $e = function($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); };
        $rows = '<p style="margin:18px 0 4px;"><strong>Course Schedule</strong></p>'
            . '<p style="margin:0;"><strong>Course Title:</strong> ' . $e($courseTitle) . '</p>'
            . '<p style="margin:0;"><strong>Course Code:</strong> ' . $e($courseSku) . '</p>'
            . '<p style="margin:0;"><strong>Course Run ID:</strong> ' . $e($runId) . '</p>'
            . '<p style="margin:0;"><strong>Start Date:</strong> ' . $e($startDate) . '</p>'
            . '<p style="margin:0;"><strong>End Date:</strong> ' . $e($endDate) . '</p>'
            . ($duration !== '' ? '<p style="margin:0;"><strong>Total Class Duration:</strong> ' . $e($duration) . '</p>' : '');

        $buttons = '<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:20px 0;"><tr>'
            . '<td style="padding-right:12px;"><a href="' . $e($acceptUrl) . '" style="display:inline-block;background:#16a34a;color:#ffffff;padding:12px 28px;border-radius:6px;text-decoration:none;font-weight:700;font-size:15px;text-align:center;font-family:Arial,sans-serif;">&#10003; Accept Invitation</a></td>'
            . '<td><a href="' . $e($declineUrl) . '" style="display:inline-block;background:#dc2626;color:#ffffff;padding:12px 28px;border-radius:6px;text-decoration:none;font-weight:700;font-size:15px;text-align:center;font-family:Arial,sans-serif;">&#10007; Decline Invitation</a></td>'
            . '</tr></table>';

        $inner = '<p style="margin:0 0 12px;">Hi ' . $e($trainerName) . ',</p>'
            . '<p style="margin:0 0 12px;">We hope this message finds you well. As one of our valued trainers, we are pleased to invite you to conduct the upcoming session of the <strong>' . $e($courseTitle) . '</strong> course.</p>'
            . $rows
            . '<p style="margin:14px 0;"><strong>Note:</strong> Each day represents 8 hours of training (evening classes are around 3 hours each). Detailed timing and dates will be sent upon acceptance.</p>'
            . '<p style="margin:0 0 12px;">To help us finalize the schedule, we kindly ask that you confirm your availability to teach this session by <strong>' . $e($confirmBy) . '</strong>.</p>'
            . '<p style="margin:0 0 12px;">You can confirm simply by clicking the Accept or Decline button below. If you have any questions regarding the course details, logistics, or terms, please do not hesitate to reach out to us.</p>'
            . $buttons
            . '<p style="margin:0 0 12px;">Thank you very much for your time and support. We look forward to your response and hope to work with you on this session.</p>'
            . $this->_signatureHtml();
        return $this->_emailWrap($inner);
    }

    protected function _buildAcceptHtml($trainerName, $courseTitle, $courseSku, $runId, $startDate, $endDate)
    {
        $e = function($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); };
        $inner = '<p style="margin:0 0 12px;">Hi ' . $e($trainerName) . ',</p>'
            . '<p style="margin:0 0 12px;">Thank you for confirming your availability for the upcoming training session. We appreciate your commitment and support.</p>'
            . '<p style="margin:18px 0 4px;"><strong>Course Schedule Confirmation</strong></p>'
            . '<p style="margin:0;"><strong>Course Title:</strong> ' . $e($courseTitle) . '</p>'
            . '<p style="margin:0;"><strong>Course Code:</strong> ' . $e($courseSku) . '</p>'
            . '<p style="margin:0;"><strong>Course Run ID:</strong> ' . $e($runId) . '</p>'
            . '<p style="margin:0;"><strong>Start Date:</strong> ' . $e($startDate) . '</p>'
            . '<p style="margin:0;"><strong>End Date:</strong> ' . $e($endDate) . '</p>'
            . '<p style="margin:14px 0 12px;">Our team will be in touch with the confirmed training details shortly. A reminder will be sent closer to the course date to keep you updated.</p>'
            . '<p style="margin:0 0 12px;">Thank you once again for partnering with us. We look forward to working with you to make this class a success!</p>'
            . $this->_signatureHtml();
        return $this->_emailWrap($inner);
    }

    protected function _buildDeclineHtml($trainerName)
    {
        $e = function($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); };
        $inner = '<p style="margin:0 0 12px;">Hi ' . $e($trainerName) . ',</p>'
            . '<p style="margin:0 0 12px;">Thank you for letting us know. We completely understand and truly appreciate your response.</p>'
            . '<p style="margin:0 0 12px;">While we&rsquo;re sorry to miss you for this session, we sincerely look forward to working with you on future training opportunities.</p>'
            . '<p style="margin:0 0 12px;">Thank you once again for your support and collaboration. We value your partnership and hope to connect again soon.</p>'
            . $this->_signatureHtml();
        return $this->_emailWrap($inner);
    }
}
