<?php
/**
 * Franchise Management — Super Admin page (sidebar item below TP Dashboard):
 *  - index      : report (completed classes pulled from MY/GH) + sync sections
 *  - pull       : pull completed classes from all configured partners (JSON)
 *  - sync       : trigger a course/category/schedule sync ON a partner (JSON).
 *                 One-way SG -> partner: the partner endpoint only runs its
 *                 own pull-from-SG import; nothing can write back to SG.
 *  - saveConfig : store MY/GH endpoint URLs + API keys
 * SG-only feature; partner instances never show the sidebar item.
 */
class MMD_RoleManager_Adminhtml_FranchisereportController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        // SG-only feature. The sidebar link is already hidden on partner
        // instances (menu.phtml), but that alone doesn't stop a direct URL
        // hit — block every action here too, the same way syncAction() was
        // already blocking the actual trigger.
        if (strtolower((string) getenv('MMS_MODE')) === 'country') {
            return false;
        }
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(array('admin', 'training_provider'));
    }

    public function indexAction()
    {
        // ?section= picks the page under the Franchise Management sidebar
        // group: '' = the completed-classes report, or one of the sync pages.
        $titles = array(
            ''           => 'Franchise Report',
            'courses'    => 'Course Sync',
            'categories' => 'Category Sync',
            'schedules'  => 'Schedule Sync',
            'courseware' => 'Courseware Sync',
        );
        $section = strtolower(trim((string) $this->getRequest()->getParam('section')));
        if (!isset($titles[$section])) $section = '';

        $this->loadLayout();
        $this->_title($titles[$section]);
        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('rolemanager/franchise-report.phtml')
            ->setData('section', $section);
        $this->getLayout()->getBlock('content')->append($block);
        $this->renderLayout();
    }

    public function pullAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            /** @var MMD_RoleManager_Model_FranchiseReportService $svc */
            $svc = Mage::getModel('mmd_rolemanager/franchiseReportService');
            if (!$svc->isConfigured()) {
                // Setup state, not an error — the UI renders this neutrally.
                return $this->_json(array(
                    'success' => false,
                    'needs_config' => true,
                    'message' => 'Not connected yet — add a partner URL and API key in Partner Connection Settings, then Pull Now.',
                ));
            }

            $user = Mage::getSingleton('admin/session')->getUser();
            $name = $user ? trim($user->getFirstname() . ' ' . $user->getLastname()) : 'admin';
            $res  = $svc->pullAll($name !== '' ? $name : 'admin');
            $this->_json(array_merge(array('success' => $res['success']), $res));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    /**
     * Trigger a sync on ONE partner: partner=my|gh, op=courses|categories|schedules.
     * SG-only; the partner-side endpoint independently refuses to run outside
     * country mode, so traffic can only ever flow SG -> franchisee.
     */
    public function syncAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();

            if (strtolower((string) getenv('MMS_MODE')) === 'country') {
                throw new Exception('Franchise sync is only available on the SG instance.');
            }

            $partner = strtolower(trim((string) $this->getRequest()->getParam('partner')));
            if (!in_array($partner, array('my', 'gh'), true)) {
                throw new Exception('Unknown partner — use my or gh.');
            }
            $op = strtolower(trim((string) $this->getRequest()->getParam('op')));

            @set_time_limit(0); // partner course sync can take minutes

            $user = Mage::getSingleton('admin/session')->getUser();
            $name = $user ? trim($user->getFirstname() . ' ' . $user->getLastname()) : 'admin';

            /** @var MMD_RoleManager_Model_FranchiseSyncService $svc */
            $svc = Mage::getModel('mmd_rolemanager/franchiseSyncService');
            $res = $svc->trigger($partner, $op, $name !== '' ? $name : 'admin');
            $this->_json(array_merge(array('success' => !empty($res['success']), 'partner' => strtoupper($partner)), $res));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    public function saveConfigAction()
    {
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $this->_validateFormKey();
            foreach (array('my', 'gh') as $cc) {
                $url = trim((string) $this->getRequest()->getParam($cc . '_url'));
                $key = trim((string) $this->getRequest()->getParam($cc . '_key'));
                Mage::getConfig()->saveConfig('mmd/franchise_report/' . $cc . '_url', $url, 'default', 0);
                if ($key !== '') { // blank = keep the stored key
                    Mage::getConfig()->saveConfig('mmd/franchise_report/' . $cc . '_key', $key, 'default', 0);
                }
            }
            Mage::getConfig()->reinit();
            $this->_json(array('success' => true, 'message' => 'Franchise report settings saved.'));
        } catch (Exception $e) {
            $this->_json(array('success' => false, 'message' => $e->getMessage()));
        }
    }

    protected function _json(array $data)
    {
        $this->getResponse()->setHeader('Content-Type', 'application/json', true)->setBody(json_encode($data));
    }
}
