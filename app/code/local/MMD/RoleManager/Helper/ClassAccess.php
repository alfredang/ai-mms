<?php
/** Participant URLs and an internal, run-only login return destination. */
class MMD_RoleManager_Helper_ClassAccess extends Mage_Core_Helper_Abstract
{
    public function origin()
    {
        $origin = rtrim(trim((string) Mage::getStoreConfig('mmd/tms_handover/public_origin')), '/');
        $url = parse_url($origin);
        if (!$url || !filter_var($origin, FILTER_VALIDATE_URL) || empty($url['host']) || isset($url['user']) || isset($url['pass']) || isset($url['query']) || isset($url['fragment'])
            || !empty($url['path']) || (($url['scheme'] ?? '') !== 'https' && !(($url['scheme'] ?? '') === 'http' && in_array($url['host'], array('localhost','127.0.0.1'), true)))) {
            throw new InvalidArgumentException('Configure the canonical participant MMS HTTPS origin.');
        }
        $admin = parse_url(Mage::helper('adminhtml')->getUrl('adminhtml/dashboard', array('_nosecret'=>true,'_nosid'=>true)));
        if (!$admin || strtolower($admin['host'] ?? '') !== strtolower($url['host']) || ($admin['scheme'] ?? '') !== $url['scheme'] || ($admin['port'] ?? null) !== ($url['port'] ?? null))
            throw new InvalidArgumentException('MMS participant and dashboard origins must match so login cookies and role selection remain on the same site.');
        return $origin;
    }
    public function urls($runId)
    {
        if ((int) $runId < 1) throw new InvalidArgumentException('Invalid class identity.');
        $origin = $this->origin();
        return array('participant_login_url' => $origin . '/lmslogin/', 'participant_class_url' => $origin . '/lmslogin/index/class/?run_id=' . (int) $runId);
    }
    public function remember($runId)
    {
        // Never accept an arbitrary URL or a product identifier as a return destination.
        if (!preg_match('/^[1-9][0-9]*$/D', (string) $runId)) throw new InvalidArgumentException('Invalid class link.');
        Mage::getSingleton('core/session')->setMmsClassRunId((int) $runId);
    }
    public function destination($needsRoleSelect = false)
    {
        if ($needsRoleSelect) return Mage::helper('adminhtml')->getUrl('adminhtml/roleselect/index');
        $runId = (int) Mage::getSingleton('core/session')->getMmsClassRunId();
        return $runId ? $this->urls($runId)['participant_class_url'] : Mage::helper('adminhtml')->getUrl('adminhtml/dashboard');
    }
    public function enter($runId)
    {
        $session = Mage::getSingleton('admin/session');
        $handover = Mage::helper('mmd_rolemanager/handover');
        $link = $handover->link($runId);
        $user = $session->getUser();
        if (!$user || !$user->getIsActive() || !$link || !(int) $link['active']) return false;
        $role = $session->getActiveRoleCode();
        if (!$role) return false;
        if (!$handover->canAccessRun($runId, $role, $user->getId(), $user->getEmail())) return false;
        $r = Mage::getSingleton('core/resource');
        $run = $r->getConnection('core_read')->fetchRow('SELECT r.run_id,r.product_id,p.sku FROM ' . $r->getTableName('course_runs') . ' r JOIN ' . $r->getTableName('catalog/product') . ' p ON p.entity_id=r.product_id WHERE r.run_id=?', array((int) $runId));
        if (!$run || strpos(strtoupper(trim($run['sku'])), 'TGS') === 0) return false;
        return Mage::helper('adminhtml')->getUrl('adminhtml/dashboard/index', array('course_id' => (int) $run['product_id'], '_query' => array('run' => (int) $runId)));
    }
}
