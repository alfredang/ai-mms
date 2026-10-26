<?php
/**
 * Account-based trainer helpers (Phase 2).
 *
 * Trainer assignment moved from EAV options to real operator accounts
 * (admin_user with the 'trainer' role). These helpers expose the account pool,
 * the per-course approved list (mmd_product_trainer), and a single resolver
 * that reads a run's assigned trainer from the account pointer first, falling
 * back to the legacy EAV pointer so previously-assigned trainers still resolve.
 */
class MMD_RoleManager_Helper_Trainer extends Mage_Core_Helper_Abstract
{
    /** All active trainer-role accounts, for the Assign Trainer picker. */
    public function getTrainerAccounts()
    {
        $res  = Mage::getSingleton('core/resource');
        $read = $res->getConnection('core_read');
        $au   = $res->getTableName('admin_user');
        $rm   = $res->getTableName('mmd_user_role_map');
        $rows = $read->fetchAll(
            "SELECT u.user_id,
                    TRIM(CONCAT(COALESCE(u.firstname,''),' ',COALESCE(u.lastname,''))) AS name,
                    u.email, u.tel
               FROM `$au` u
               JOIN `$rm` r ON r.user_id = u.user_id AND r.role_code = 'trainer'
              WHERE u.is_active = 1 AND u.email IS NOT NULL AND u.email <> ''
              GROUP BY u.user_id
              ORDER BY name ASC"
        );
        foreach ($rows as &$r) {
            $r['user_id'] = (int)$r['user_id'];
            $r['name'] = trim($r['name']) ?: $r['email'];
            $r['tel']  = (string)$r['tel'];
        }
        return $rows;
    }

    /** Account-based approved trainer list for a product, in sort order. */
    public function getProductTrainerAccounts($productId)
    {
        $res  = Mage::getSingleton('core/resource');
        $read = $res->getConnection('core_read');
        $pt   = $res->getTableName('mmd_product_trainer');
        $au   = $res->getTableName('admin_user');
        $rows = $read->fetchAll(
            "SELECT pt.user_id,
                    TRIM(CONCAT(COALESCE(u.firstname,''),' ',COALESCE(u.lastname,''))) AS name,
                    u.email, u.tel, pt.sort_order, pt.show_on_storefront
               FROM `$pt` pt
               JOIN `$au` u ON u.user_id = pt.user_id
              WHERE pt.product_id = ?
              ORDER BY pt.sort_order ASC, name ASC",
            array((int)$productId)
        );
        foreach ($rows as &$r) {
            $r['user_id'] = (int)$r['user_id'];
            $r['name'] = trim($r['name']) ?: $r['email'];
            $r['tel']  = (string)$r['tel'];
            $r['show_on_storefront'] = $r['show_on_storefront'] === null
                ? null : (int)$r['show_on_storefront'];
        }
        return $rows;
    }

    /**
     * Resolve the assigned trainer for a run row (must contain trainer_user_id
     * and trainer_option_id). Account pointer wins; EAV is the legacy fallback.
     *
     * @return array|null { id, user_id|option_id, name, email, source }
     */
    public function resolveRunTrainer(array $run)
    {
        $res  = Mage::getSingleton('core/resource');
        $read = $res->getConnection('core_read');

        $uid = isset($run['trainer_user_id']) ? (int)$run['trainer_user_id'] : 0;
        if ($uid > 0) {
            $au = $res->getTableName('admin_user');
            $row = $read->fetchRow(
                "SELECT TRIM(CONCAT(COALESCE(firstname,''),' ',COALESCE(lastname,''))) AS name, email
                   FROM `$au` WHERE user_id = ?", array($uid)
            );
            if ($row) {
                return array('id' => $uid, 'user_id' => $uid, 'option_id' => 0,
                    'name' => trim($row['name']) ?: $row['email'], 'email' => $row['email'], 'source' => 'account');
            }
        }

        $oid = isset($run['trainer_option_id']) ? (int)$run['trainer_option_id'] : 0;
        if ($oid > 0) {
            $ov = $res->getTableName('eav_attribute_option_value');
            $ct = $res->getTableName('courses_trainers');
            $name  = (string) $read->fetchOne("SELECT value FROM `$ov` WHERE option_id = ? AND store_id = 0", array($oid));
            $email = (string) $read->fetchOne("SELECT email FROM `$ct` WHERE relation_id = ? AND email IS NOT NULL AND email <> '' AND status = 1 LIMIT 1", array($oid));
            return array('id' => $oid, 'user_id' => 0, 'option_id' => $oid,
                'name' => $name, 'email' => $email, 'source' => 'eav');
        }
        return null;
    }

    /**
     * Batch resolver for grids — given run rows (with trainer_user_id +
     * trainer_option_id), return [ run_id => trainerName ]. Two queries, no N+1.
     */
    public function resolveRunTrainerNames(array $runRows)
    {
        $res  = Mage::getSingleton('core/resource');
        $read = $res->getConnection('core_read');
        $userIds = array(); $optIds = array();
        foreach ($runRows as $r) {
            if (!empty($r['trainer_user_id']))   $userIds[(int)$r['trainer_user_id']] = true;
            elseif (!empty($r['trainer_option_id'])) $optIds[(int)$r['trainer_option_id']] = true;
        }
        $userNames = array(); $optNames = array();
        if ($userIds) {
            $au = $res->getTableName('admin_user');
            $in = implode(',', array_map('intval', array_keys($userIds)));
            foreach ($read->fetchAll("SELECT user_id, TRIM(CONCAT(COALESCE(firstname,''),' ',COALESCE(lastname,''))) AS name, email FROM `$au` WHERE user_id IN ($in)") as $u) {
                $userNames[(int)$u['user_id']] = trim($u['name']) ?: $u['email'];
            }
        }
        if ($optIds) {
            $ov = $res->getTableName('eav_attribute_option_value');
            $in = implode(',', array_map('intval', array_keys($optIds)));
            foreach ($read->fetchAll("SELECT option_id, value FROM `$ov` WHERE option_id IN ($in) AND store_id = 0") as $o) {
                $optNames[(int)$o['option_id']] = $o['value'];
            }
        }
        $out = array();
        foreach ($runRows as $r) {
            $rid = (int)$r['run_id'];
            if (!empty($r['trainer_user_id']) && isset($userNames[(int)$r['trainer_user_id']])) {
                $out[$rid] = $userNames[(int)$r['trainer_user_id']];
            } elseif (!empty($r['trainer_option_id']) && isset($optNames[(int)$r['trainer_option_id']])) {
                $out[$rid] = $optNames[(int)$r['trainer_option_id']];
            } else {
                $out[$rid] = '';
            }
        }
        return $out;
    }
}
