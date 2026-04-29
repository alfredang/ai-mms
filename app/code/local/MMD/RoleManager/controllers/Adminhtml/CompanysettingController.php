<?php
class MMD_RoleManager_Adminhtml_CompanysettingController extends Mage_Adminhtml_Controller_Action
{
    protected function _validateFormKey()
    {
        return true;
    }

    /**
     * Load all company settings from core_config_data.
     * GET → JSON { success: true, settings: { path: value, … } }
     */
    public function loadAction()
    {
        $result = array('success' => true, 'settings' => array());
        try {
            $read = Mage::getSingleton('core/resource')->getConnection('core_read');
            $table = Mage::getSingleton('core/resource')->getTableName('core/config_data');
            $rows = $read->fetchAll(
                "SELECT path, value FROM {$table} WHERE path LIKE 'mmd_company/%' AND scope = 'default' AND scope_id = 0"
            );
            foreach ($rows as $row) {
                $result['settings'][$row['path']] = $row['value'];
            }
        } catch (Exception $e) {
            $result['success'] = false;
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Save company settings to core_config_data.
     * POST: settings = { path: value, … }
     * Returns JSON { success: true }
     */
    public function saveAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) {
                $result['message'] = 'POST required';
                $this->_sendJson($result);
                return;
            }
            $raw = $this->getRequest()->getPost('settings');
            if (is_string($raw)) {
                $settings = json_decode($raw, true);
            } else {
                $settings = $raw;
            }
            if (!is_array($settings) || empty($settings)) {
                $result['message'] = 'No settings provided';
                $this->_sendJson($result);
                return;
            }
            foreach ($settings as $path => $value) {
                // Only allow mmd_company/* paths
                if (strpos($path, 'mmd_company/') !== 0) {
                    continue;
                }
                Mage::getConfig()->saveConfig($path, (string) $value, 'default', 0);
            }
            Mage::app()->cleanCache();
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    protected function _sendJson(array $data)
    {
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($data));
    }

    protected function _isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(array(
            'training_provider', 'admin',
        ));
    }
}
