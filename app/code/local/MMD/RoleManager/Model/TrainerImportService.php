<?php
/**
 * Trainer import from AI-LMS-TMS.
 *
 * Pulls the LMS trainers-export API and syncs them into MMS as operator
 * accounts (admin_user) + roles (mmd_user_role_map):
 *   - email exists  → ensure the 'trainer' role is present (don't disturb
 *                     their existing roles / primary / ACL).
 *   - email is new  → create the account + assign all mapped LMS roles, then
 *                     applyRoleAcl() on the highest-priority role.
 * After the sync it re-runs the courses_trainers email backfill so EAV trainer
 * options that match a (now-present) account by name gain an email — un-sticking
 * classes whose approved trainers previously had none.
 *
 * Idempotent: accounts matched by email, UNIQUE(user_id, role_code) on roles.
 */
class MMD_RoleManager_Model_TrainerImportService
{
    const LOG_FILE          = 'trainer-import.log';
    const URL_CONFIG_PATH   = 'mmd/trainer_import/lms_url';
    const KEY_CONFIG_PATH   = 'mmd/trainer_import/api_key';
    const ENABLED_CONFIG    = 'mmd/trainer_import/auto_enabled';

    /** LMS role name → MMS role code. Finance/Payroll have no MMS equivalent. */
    protected $_roleMap = array(
        'Learner'           => 'learner',
        'Trainer'           => 'trainer',
        'Admin'             => 'admin',
        'Developer'         => 'developer',
        'Training Provider' => 'training_provider',
    );
    protected $_rolePriority = array(
        'learner' => 1, 'trainer' => 2, 'developer' => 3,
        'marketing' => 4, 'admin' => 5, 'training_provider' => 6,
    );

    public function isAutoEnabled()
    {
        return Mage::getStoreConfigFlag(self::ENABLED_CONFIG);
    }
    public function getLmsUrl()
    {
        return rtrim(trim((string) Mage::getStoreConfig(self::URL_CONFIG_PATH)), '/');
    }
    public function getApiKey()
    {
        return trim((string) Mage::getStoreConfig(self::KEY_CONFIG_PATH));
    }
    public function isConfigured()
    {
        return $this->getLmsUrl() !== '' && $this->getApiKey() !== '';
    }

    /**
     * Full pull: fetch from LMS then import. Returns the summary array.
     */
    public function pull($triggeredBy = 'cron')
    {
        if (!$this->isConfigured()) {
            throw new Exception('LMS API URL / key not configured.');
        }
        $trainers = $this->fetchFromLms();
        return $this->importTrainers($trainers, $triggeredBy);
    }

    /**
     * GET the LMS trainers-export endpoint. Returns the decoded `data` array.
     */
    public function fetchFromLms()
    {
        $url = $this->getLmsUrl() . '/api/external/trainers-export';
        $ch  = curl_init($url);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 60,
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_HTTPHEADER     => array('x-api-key: ' . $this->getApiKey(), 'Accept: application/json'),
        ));
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);

        if ($raw === false || $raw === '') {
            throw new Exception('LMS unreachable: ' . ($err ?: 'no response'));
        }
        $rsp = json_decode($raw, true);
        if ($code >= 400 || !is_array($rsp) || empty($rsp['success'])) {
            $msg = is_array($rsp) && isset($rsp['error']) ? $rsp['error'] : ('HTTP ' . $code);
            throw new Exception('LMS export failed: ' . $msg);
        }
        return isset($rsp['data']) && is_array($rsp['data']) ? $rsp['data'] : array();
    }

    /**
     * Core upsert loop. Accepts the decoded trainer array (testable without HTTP).
     *
     * @return array summary
     */
    public function importTrainers(array $trainers, $triggeredBy = 'cron')
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $write    = $resource->getConnection('core_write');
        $roleTbl  = $resource->getTableName('mmd_user_role_map');
        $auTbl    = $resource->getTableName('admin_user');
        $helper   = Mage::helper('mmd_rolemanager');

        $created = 0; $rolesAdded = 0; $skipped = 0; $errors = 0; $errMsgs = array();

        foreach ($trainers as $t) {
            $email = strtolower(trim((string)($t['email'] ?? '')));
            if ($email === '' || strpos($email, '@') === false) { $skipped++; continue; }

            $mmsRoles = $this->_mapRoles(isset($t['roles']) ? (array)$t['roles'] : array());
            if (empty($mmsRoles)) { $mmsRoles = array('trainer'); }

            try {
                $userId = (int) $read->fetchOne(
                    "SELECT user_id FROM `$auTbl` WHERE email = ? LIMIT 1",
                    array($email)
                );

                if ($userId) {
                    // Existing account — only ensure the 'trainer' role is present.
                    $has = (int) $read->fetchOne(
                        "SELECT COUNT(*) FROM `$roleTbl` WHERE user_id = ? AND role_code = 'trainer'",
                        array($userId)
                    );
                    if (!$has) {
                        $write->insert($roleTbl, array(
                            'user_id' => $userId, 'role_code' => 'trainer',
                            'is_primary' => 0, 'created_at' => now(),
                        ));
                        $rolesAdded++;
                    } else {
                        $skipped++;
                    }
                    continue;
                }

                // New account — create + assign all mapped roles.
                list($first, $last) = $this->_splitName((string)($t['full_name'] ?? $email));
                $active = (strtolower((string)($t['account_status'] ?? 'active')) === 'active') ? 1 : 0;

                $user = Mage::getModel('admin/user')->setData(array(
                    'username'  => $email,
                    'firstname' => $first,
                    'lastname'  => $last,
                    'email'     => $email,
                    'password'  => $this->_randomPassword(),
                    'is_active' => $active,
                ));
                $user->save();
                $userId = (int) $user->getId();
                $created++;

                // Optional profile fields.
                $profile = array();
                if (!empty($t['tel']))          $profile['tel']         = substr((string)$t['tel'], 0, 20);
                if (!empty($t['nric']))         $profile['nric_fin']    = substr((string)$t['nric'], 0, 20);
                if (!empty($t['gender']))       $profile['gender']      = substr((string)$t['gender'], 0, 10);
                if (!empty($t['linkedin_url'])) $profile['linkedin_url']= substr((string)$t['linkedin_url'], 0, 255);
                if ($profile) {
                    try { $write->update($auTbl, $profile, array('user_id = ?' => $userId)); } catch (Exception $e) {}
                }

                // Assign roles; primary = highest-priority mapped role.
                $primary = $this->_primaryRole($mmsRoles);
                foreach ($mmsRoles as $code) {
                    $write->insertOnDuplicate($roleTbl, array(
                        'user_id' => $userId, 'role_code' => $code,
                        'is_primary' => ($code === $primary) ? 1 : 0, 'created_at' => now(),
                    ), array('is_primary'));
                    $rolesAdded++;
                }
                $helper->applyRoleAcl($userId, $primary);

            } catch (Exception $e) {
                $errors++;
                $errMsgs[] = $email . ': ' . $e->getMessage();
                Mage::log('Trainer import error for ' . $email . ': ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
            }
        }

        $backfilled = $this->_backfillCoursesTrainerEmails();

        $status = $errors === 0 ? 'success' : ($created + $rolesAdded > 0 ? 'partial' : 'error');
        $message = sprintf('fetched:%d created:%d roles+:%d emails:%d skipped:%d errors:%d',
            count($trainers), $created, $rolesAdded, $backfilled, $skipped, $errors);
        if ($errMsgs) $message .= ' | ' . implode('; ', array_slice($errMsgs, 0, 3));

        $this->_writeLog(array(
            'triggered_by'      => $triggeredBy,
            'fetched'           => count($trainers),
            'accounts_created'  => $created,
            'roles_added'       => $rolesAdded,
            'emails_backfilled' => $backfilled,
            'skipped'           => $skipped,
            'errors'            => $errors,
            'status'            => $status,
            'message'           => $message,
        ));
        Mage::log('Trainer import: ' . $message, Zend_Log::INFO, self::LOG_FILE);

        return array(
            'success' => $errors === 0,
            'message' => $message,
            'fetched' => count($trainers),
            'created' => $created, 'roles_added' => $rolesAdded,
            'emails_backfilled' => $backfilled, 'skipped' => $skipped, 'errors' => $errors,
        );
    }

    // ------------------------------------------------------------------ //

    protected function _mapRoles(array $lmsRoles)
    {
        $out = array();
        foreach ($lmsRoles as $r) {
            $r = trim((string)$r);
            if (isset($this->_roleMap[$r])) $out[$this->_roleMap[$r]] = true;
        }
        return array_keys($out);
    }

    protected function _primaryRole(array $mmsRoles)
    {
        $best = 'trainer'; $bestP = -1;
        foreach ($mmsRoles as $code) {
            $p = isset($this->_rolePriority[$code]) ? $this->_rolePriority[$code] : 0;
            if ($p > $bestP) { $bestP = $p; $best = $code; }
        }
        return $best;
    }

    protected function _splitName($full)
    {
        $full = trim(preg_replace('/\s+/', ' ', $full));
        if ($full === '') return array('Trainer', '-');
        $parts = explode(' ', $full, 2);
        return array($parts[0], isset($parts[1]) && $parts[1] !== '' ? $parts[1] : '-');
    }

    protected function _randomPassword()
    {
        // Magento admin: >=7 chars, letters + numbers. bin2hex gives both.
        return 'Lms' . bin2hex(random_bytes(8)) . '7';
    }

    /**
     * Fill courses_trainers.email for EAV trainer options whose name matches an
     * admin_user (exact or ACTA-stripped). Mirrors migration 187, incremental.
     * Returns rows affected.
     */
    protected function _backfillCoursesTrainerEmails()
    {
        $resource = Mage::getSingleton('core/resource');
        $write    = $resource->getConnection('core_write');
        $eao  = $resource->getTableName('eav_attribute_option');
        $eaov = $resource->getTableName('eav_attribute_option_value');
        $eatt = $resource->getTableName('eav_attribute');
        $ct   = $resource->getTableName('courses_trainers');
        $au   = $resource->getTableName('admin_user');
        $n = 0;
        try {
            // INSERT for options with no courses_trainers row — exact name match.
            $n += $write->query(
                "INSERT INTO `$ct` (relation_id, title, email, status, created_time, update_time)
                 SELECT eao.option_id, TRIM(eov.value), au.email, 1, NOW(), NOW()
                   FROM `$eao` eao
                   JOIN `$eatt` a ON a.attribute_id = eao.attribute_id AND a.attribute_code = 'trainers'
                   JOIN `$eaov` eov ON eov.option_id = eao.option_id AND eov.store_id = 0
                   JOIN `$au` au ON au.user_id = (
                        SELECT MIN(u.user_id) FROM `$au` u
                         WHERE LOWER(TRIM(eov.value)) = LOWER(CONCAT(TRIM(u.firstname),' ',TRIM(u.lastname)))
                           AND u.email IS NOT NULL AND u.email <> '')
                   LEFT JOIN `$ct` c ON c.relation_id = eao.option_id
                  WHERE c.relation_id IS NULL AND eov.value IS NOT NULL AND TRIM(eov.value) <> ''"
            )->rowCount();
            // UPDATE existing rows missing email — exact name match.
            $n += $write->query(
                "UPDATE `$ct` ct
                   JOIN (SELECT MIN(user_id) uid, LOWER(CONCAT(TRIM(firstname),' ',TRIM(lastname))) nm, email
                           FROM `$au` WHERE email IS NOT NULL AND email <> ''
                          GROUP BY LOWER(CONCAT(TRIM(firstname),' ',TRIM(lastname)))) m
                     ON LOWER(TRIM(ct.title)) = m.nm
                    SET ct.email = m.email
                  WHERE (ct.email IS NULL OR ct.email = '') AND ct.relation_id > 0"
            )->rowCount();
        } catch (Exception $e) {
            Mage::log('Email backfill error: ' . $e->getMessage(), Zend_Log::WARN, self::LOG_FILE);
        }
        return $n;
    }

    protected function _writeLog(array $data)
    {
        try {
            $resource = Mage::getSingleton('core/resource');
            $resource->getConnection('core_write')->insert(
                $resource->getTableName('mmd_trainer_import_log'), $data
            );
        } catch (Exception $e) { /* non-fatal */ }
    }
}
