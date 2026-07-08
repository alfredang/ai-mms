<?php
/**
 * Franchise Report — Super Admin page (sidebar item below TP Dashboard):
 *  - index      : the report page (completed classes pulled from MY/GH)
 *  - pull       : pull from all configured partners now (JSON summary)
 *  - saveConfig : store MY/GH endpoint URLs + API keys
 * SG-only feature; partner instances never show the sidebar item.
 */
class MMD_RoleManager_Adminhtml_FranchisereportController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(array('admin', 'training_provider'));
    }

    public function indexAction()
    {
        $this->loadLayout();
        $this->_title('Franchise Report');
        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('rolemanager/franchise-report.phtml');
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
