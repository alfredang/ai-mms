<?php
class MMD_RoleManager_Model_Observer
{
    /**
     * On admin login, load user roles into session.
     * If multiple roles, flag for role selection page.
     * If single role, apply immediately.
     */
    public function onAdminLogin(Varien_Event_Observer $observer)
    {
        try {
            $user    = $observer->getEvent()->getUser();
            $helper  = Mage::helper('mmd_rolemanager');
            $session = Mage::getSingleton('admin/session');

            $roles = $helper->getUserRolesFromDb($user->getId());
            $session->setUserRoles($roles);

            if (count($roles) > 1) {
                // Multiple roles — need role selection page
                $session->setNeedsRoleSelect(true);
                $session->unsActiveRoleCode();
            } else {
                // Single role — apply immediately
                $session->setNeedsRoleSelect(false);
                $session->setActiveRoleCode($roles[0]);
                $helper->applyRoleAcl($user->getId(), $roles[0]);
            }
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }

    /**
     * Inject our dark content stylesheet into TinyMCE's iframe so that text
     * being edited matches the dark admin theme around it. Without this,
     * Magento's WYSIWYG opens with a default white iframe (black-on-white)
     * which is jarring in the dark UI. Hook is dispatched by
     * Mage_Cms_Model_Wysiwyg_Config::getConfig() right before the JS config
     * is rendered.
     */
    public function onWysiwygConfigPrepare(Varien_Event_Observer $observer)
    {
        try {
            $config = $observer->getEvent()->getConfig();
            if (!$config) {
                return;
            }
            $cssUrl = Mage::getBaseUrl('skin') . 'adminhtml/default/default/wysiwyg-dark.css';
            $existing = (string) $config->getData('content_css');
            // content_css can take a comma-separated list — append rather than
            // overwrite so any per-store frontend stylesheet is preserved.
            $config->setData(
                'content_css',
                $existing === '' ? $cssUrl : $existing . ',' . $cssUrl
            );
            // body_class doubles as a CSS hook in case the frontend stylesheet
            // wants to know it's being rendered inside the admin editor.
            $bodyClass = trim((string) $config->getData('body_class') . ' wysiwyg-dark');
            $config->setData('body_class', $bodyClass);
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }

    /**
     * Before every admin controller action, redirect to role selection
     * if user hasn't chosen a role yet.
     */
    public function onPredispatch(Varien_Event_Observer $observer)
    {
        try {
            $session = Mage::getSingleton('admin/session');
            if (!$session->isLoggedIn()) {
                return;
            }

            $needsSelect = $session->getNeedsRoleSelect();
            if (!$needsSelect) {
                return;
            }

            $controller = $observer->getEvent()->getControllerAction();
            $actionName = $controller->getFullActionName();

            // Allow role selection and logout actions
            $allowed = array(
                'adminhtml_roleselect_index',
                'adminhtml_roleselect_choose',
                'adminhtml_index_logout',
            );
            if (in_array($actionName, $allowed)) {
                return;
            }

            // Redirect to role selection
            $controller->getResponse()->setRedirect(
                Mage::helper('adminhtml')->getUrl('adminhtml/roleselect/index')
            );
            $controller->setFlag('', Mage_Core_Controller_Varien_Action::FLAG_NO_DISPATCH, true);
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }
}
