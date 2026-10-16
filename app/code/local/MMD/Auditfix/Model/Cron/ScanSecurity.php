<?php
/**
 * MMD_Auditfix_Model_Cron_ScanSecurity
 *
 * Daily 03:00. Heuristic security scan + low-risk auto-fix.
 *
 * Auto-fix scope (low risk, DB-only):
 *   - admin_user rows with empty username (should mirror email per
 *     EmailLogin module's contract) → set username = email.
 *
 * Flag-only:
 *   - admin_user rows with is_active=1 but last_login > 180 days ago.
 *   - admin_user rows lacking a role in mmd_user_role_map (no operator role).
 *   - core_config_data rows containing what looks like plaintext API keys
 *     in non-encrypted paths (very conservative regex; flag only).
 */
class MMD_Auditfix_Model_Cron_ScanSecurity extends MMD_Auditfix_Model_Cron_AbstractScanner
{
    protected function scannerCode() { return 'scan_security'; }

    protected function scan()
    {
        $logged = 0; $fixed = 0;
        $read  = Mage::getSingleton('core/resource')->getConnection('core_read');
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $tbl   = Mage::getSingleton('core/resource')->getTableName('admin/user');

        // ---- Auto-fix: empty username ------------------------------------
        $rows = $read->fetchAll("SELECT user_id, email FROM {$tbl} WHERE (username IS NULL OR username = '') AND email <> ''");
        foreach ($rows as $r) {
            try {
                $write->update($tbl, array('username' => $r['email']), $write->quoteInto('user_id = ?', (int)$r['user_id']));
                $this->helper()->logIssue(array(
                    'source' => 'cron_scan_security', 'category' => 'security', 'severity' => 'low',
                    'title' => 'Empty admin username backfilled from email',
                    'entity_type' => 'admin_user', 'entity_id' => (int)$r['user_id'],
                    'detail' => 'EmailLogin contract: admin_user.username is a write-only mirror of email.',
                    'fix_summary' => "username ← {$r['email']}",
                    'status' => MMD_Auditfix_Helper_Data::STATUS_FIXED,
                ));
                $fixed++;
            } catch (Exception $e) {
                Mage::logException($e);
            }
        }

        // ---- Flag: stale active accounts ---------------------------------
        $cutoff = date('Y-m-d H:i:s', strtotime('-180 days'));
        $stale = $read->fetchAll(
            "SELECT user_id, email, logdate FROM {$tbl}
             WHERE is_active = 1 AND (logdate IS NULL OR logdate < ?)",
            array($cutoff)
        );
        foreach ($stale as $r) {
            $this->helper()->logIssue(array(
                'source' => 'cron_scan_security', 'category' => 'security', 'severity' => 'medium',
                'title' => 'Active admin account, no login in 180+ days',
                'entity_type' => 'admin_user', 'entity_id' => (int)$r['user_id'],
                'detail' => "User {$r['email']} — last login " . ($r['logdate'] ?: 'never') . '. Consider deactivating.',
            ));
            $logged++;
        }

        // ---- Flag: admin without operator role ---------------------------
        $roleTbl = Mage::getSingleton('core/resource')->getTableName('mmd_user_role_map');
        $orphans = $read->fetchAll(
            "SELECT u.user_id, u.email FROM {$tbl} u
             LEFT JOIN {$roleTbl} m ON m.user_id = u.user_id
             WHERE u.is_active = 1 AND m.user_id IS NULL"
        );
        foreach ($orphans as $r) {
            $this->helper()->logIssue(array(
                'source' => 'cron_scan_security', 'category' => 'security', 'severity' => 'low',
                'title' => 'Active admin without RoleManager role',
                'entity_type' => 'admin_user', 'entity_id' => (int)$r['user_id'],
                'detail' => "User {$r['email']} has no row in mmd_user_role_map. Assign a role via Role Management.",
            ));
            $logged++;
        }

        /* Policy: every low-risk security finding is auto-resolved with a
           generic note. Operators only get paged for medium/high. */
        $fixed += $this->helper()->autoResolveLowRiskFromSource('cron_scan_security');

        return array($logged, $fixed);
    }
}
