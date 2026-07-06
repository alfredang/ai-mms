<?php
class MMD_RoleManager_Adminhtml_RoleselectController extends Mage_Adminhtml_Controller_Action
{
    /**
     * Show role selection page
     */
    public function indexAction()
    {
        $session = Mage::getSingleton('admin/session');
        if (!$session->isLoggedIn()) {
            $this->_redirect('adminhtml/index/login');
            return;
        }

        // ALWAYS render the selector — never redirect to the dashboard.
        // The old "!needsRoleSelect -> redirect dashboard" branch was one leg
        // of a redirect PING-PONG: under the DB-session write race the
        // dashboard's predispatch could still read needsRoleSelect=true and
        // bounce here, while this redirect read false and bounced back —
        // browsers gave up after ~20 hops (blank page / "infinite loop",
        // 2026-07-06/07 incidents). Rendering is always safe: a user who
        // already chose simply sees the selector and can pick again.
        $this->getResponse()->setBody($this->_getRoleSelectHtml());
    }

    /**
     * Handle role selection
     */
    public function chooseAction()
    {
        $session  = Mage::getSingleton('admin/session');
        $helper   = Mage::helper('mmd_rolemanager');
        $roleCode = $this->getRequest()->getParam('role_code');
        $user     = $session->getUser();

        if (!$user) {
            $this->_redirect('adminhtml/index/login');
            return;
        }

        // Validate user has this role
        $userRoles = $helper->getUserRolesFromDb($user->getId());
        if (!in_array($roleCode, $userRoles)) {
            $session->addError('Invalid role selected.');
            $this->_redirect('*/*/index');
            return;
        }

        // Apply role
        $session->setActiveRoleCode($roleCode);
        $session->setNeedsRoleSelect(false);
        $session->setUserRoles($userRoles);
        $helper->applyRoleAcl($user->getId(), $roleCode);

        // Clear menu cache
        Mage::app()->cleanCache(array('BACKEND_MAINMENU'));

        // Force the session write to COMMIT before the redirect goes out.
        // PHP normally writes the session at shutdown, AFTER the response —
        // a fast browser then requests /dashboard while the DB session row
        // still says needsRoleSelect=true, and the predispatch observer
        // bounces it straight back here ("have to click the role twice",
        // reported 2026-07-07; same race behind the 2026-07-06 redirect loop).
        session_write_close();

        $this->_redirect('adminhtml/dashboard');
    }

    /**
     * Build the role selection HTML (standalone page, no layout)
     */
    protected function _getRoleSelectHtml()
    {
        $session = Mage::getSingleton('admin/session');
        $helper  = Mage::helper('mmd_rolemanager');
        $user    = $session->getUser();
        $roles   = $helper->getUserRoles();
        $logoUrl = Mage::getBaseUrl('skin') . 'adminhtml/default/default/images/admin-logo.png';
        $fullName = $user->getFirstname() . ' ' . $user->getLastname();
        $logoutUrl = Mage::helper('adminhtml')->getUrl('adminhtml/index/logout');
        $chooseUrl = Mage::helper('adminhtml')->getUrl('adminhtml/roleselect/choose');
        $formKey = Mage::getSingleton('core/session')->getFormKey();

        ob_start();
        include Mage::getDesign()->getTemplateFilename('rolemanager/role-select.phtml');
        return ob_get_clean();
    }

    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isLoggedIn();
    }
}
