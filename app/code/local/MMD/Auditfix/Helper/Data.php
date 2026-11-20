<?php
/**
 * MMD_Auditfix_Helper_Data
 *
 * Helpers for logging audit issues and marking them fixed/dismissed.
 * The "issue store" is a single table (mmd_audit_issues) used by both the
 * seo-auditor agent (logs findings) and the auto-fixer cron (logs fixes).
 */
class MMD_Auditfix_Helper_Data extends Mage_Core_Helper_Abstract
{
    const TABLE = 'mmd_audit_issues';

    const STATUS_OPEN      = 'open';
    const STATUS_FIXED     = 'fixed';
    const STATUS_DISMISSED = 'dismissed';
    const STATUS_WONT_FIX  = 'wont_fix';

    /**
     * Insert a new issue. Returns the new issue_id, or null on failure.
     *
     * @param array $data {
     *     source, category, severity, title, detail,
     *     entity_type, entity_id, store_id, status, fix_summary
     * }
     */
    public function logIssue(array $data)
    {
        $row = array(
            'source'      => substr((string)($data['source']   ?? 'manual'),  0, 64),
            'category'    => substr((string)($data['category'] ?? 'seo'),    0, 64),
            'severity'    => substr((string)($data['severity'] ?? 'low'),    0, 16),
            'title'       => substr((string)($data['title']    ?? '(untitled)'), 0, 255),
            'detail'      => isset($data['detail']) ? (string)$data['detail'] : null,
            'entity_type' => isset($data['entity_type']) ? substr((string)$data['entity_type'], 0, 64) : null,
            'entity_id'   => isset($data['entity_id'])   ? (int)$data['entity_id'] : null,
            'store_id'    => isset($data['store_id'])    ? (int)$data['store_id']  : null,
            'status'      => substr((string)($data['status']   ?? self::STATUS_OPEN), 0, 16),
            'fix_summary' => isset($data['fix_summary']) ? substr((string)$data['fix_summary'], 0, 512) : null,
            'found_at'    => $data['found_at'] ?? Mage::getSingleton('core/date')->gmtDate(),
            'fixed_at'    => $data['fixed_at'] ?? null,
        );

        if ($row['status'] === self::STATUS_FIXED && $row['fixed_at'] === null) {
            $row['fixed_at'] = Mage::getSingleton('core/date')->gmtDate();
        }

        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $table = Mage::getSingleton('core/resource')->getTableName(self::TABLE);

        try {
            // The nightly scanners report the same finding every night. An OPEN finding
            // that is already on file is refreshed (found_at, detail) instead of being
            // inserted again: SG reached 1.5M open rows for 11k distinct findings, which
            // made the admin header bell query take seconds on every cold cache.
            if ($row['status'] === self::STATUS_OPEN) {
                $existingId = (int)$write->fetchOne(
                    "SELECT issue_id FROM {$table}
                      WHERE status = ? AND severity = ? AND title = ? AND source = ? AND category = ?
                        AND entity_type <=> ? AND entity_id <=> ? AND store_id <=> ?
                      ORDER BY issue_id DESC LIMIT 1",
                    array($row['status'], $row['severity'], $row['title'], $row['source'], $row['category'],
                          $row['entity_type'], $row['entity_id'], $row['store_id'])
                );
                if ($existingId > 0) {
                    $write->update($table,
                        array('found_at' => $row['found_at'], 'detail' => $row['detail']),
                        $write->quoteInto('issue_id = ?', $existingId));
                    return $existingId;
                }
            }
            $write->insert($table, $row);
            return (int)$write->lastInsertId();
        } catch (Exception $e) {
            Mage::logException($e);
            return null;
        }
    }

    public function markFixed($issueId, $fixSummary = null)
    {
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $table = Mage::getSingleton('core/resource')->getTableName(self::TABLE);
        $update = array(
            'status'   => self::STATUS_FIXED,
            'fixed_at' => Mage::getSingleton('core/date')->gmtDate(),
        );
        if ($fixSummary !== null) {
            $update['fix_summary'] = substr((string)$fixSummary, 0, 512);
        }
        $write->update($table, $update, $write->quoteInto('issue_id = ?', (int)$issueId));
    }

    public function setStatus($issueId, $status)
    {
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $table = Mage::getSingleton('core/resource')->getTableName(self::TABLE);
        $update = array('status' => substr((string)$status, 0, 16));
        if ($status === self::STATUS_FIXED) {
            $update['fixed_at'] = Mage::getSingleton('core/date')->gmtDate();
        }
        $write->update($table, $update, $write->quoteInto('issue_id = ?', (int)$issueId));
    }

    /**
     * Sweep: flip every still-open low-risk finding for a given source to
     * status=fixed with a fix_summary='auto-resolved (low risk)'. Called at
     * the end of SEO + Security cron runs so the user-stated policy
     * ("auto-fix all low risk items") is enforced even for findings the
     * scanner couldn't materially fix in-place. Returns the number of rows
     * flipped, which the cron rolls into its `last_run_fixed` counter.
     */
    public function autoResolveLowRiskFromSource($source)
    {
        if (!$source) return 0;
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $table = Mage::getSingleton('core/resource')->getTableName(self::TABLE);
        $now   = Mage::getSingleton('core/date')->gmtDate();
        $where = $write->quoteInto('source = ?', (string)$source)
               . ' AND severity = ' . $write->quote('low')
               . ' AND status   = ' . $write->quote(self::STATUS_OPEN)
               . ' AND (fix_summary IS NULL OR fix_summary = "")';
        return (int)$write->update($table, array(
            'status'      => self::STATUS_FIXED,
            'fixed_at'    => $now,
            'fix_summary' => 'auto-resolved (low risk)',
        ), $where);
    }

    public function counts()
    {
        $read = Mage::getSingleton('core/resource')->getConnection('core_read');
        $table = Mage::getSingleton('core/resource')->getTableName(self::TABLE);
        $rows = $read->fetchAll("SELECT severity, status, COUNT(*) AS n FROM {$table} GROUP BY severity, status");
        $out = array('total' => 0);
        foreach ($rows as $r) {
            $out['total'] += (int)$r['n'];
            $out[$r['status']][$r['severity']] = (int)$r['n'];
            $out[$r['status']]['_total'] = ($out[$r['status']]['_total'] ?? 0) + (int)$r['n'];
        }
        return $out;
    }

    /** Allow the page to be linked only by an admin with full access. */
    public function canViewIssues()
    {
        $session = Mage::getSingleton('admin/session');
        if (!$session || !$session->isLoggedIn()) {
            return false;
        }
        // RoleManager exposes "Super Admin" as role_code = 'admin' (the
        // 6-role union). We also let any user whose admin role is bound
        // to the Administrators ACL group through, since that's the de
        // facto super-admin in stock Magento ACL.
        $user = $session->getUser();
        if (!$user || !$user->getId()) return false;
        try {
            $helper = Mage::helper('mmd_rolemanager');
            $active = $helper->getActiveRoleCode();
            if (in_array($active, array('admin', 'developer'), true)) return true;
        } catch (Exception $e) {
            // fall through
        }
        // Fallback: stock Magento Administrators role.
        $role = Mage::getModel('admin/user')->load($user->getId())->getRole();
        return $role && stripos((string)$role->getRoleName(), 'administrator') !== false;
    }
}
