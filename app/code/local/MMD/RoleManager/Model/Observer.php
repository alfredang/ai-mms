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
     * Before every admin controller action:
     *   1. If the user has multiple roles and hasn't picked one yet,
     *      redirect to role selection.
     *   2. Otherwise enforce the per-role allow-list (`_roleControllerMap`)
     *      so that e.g. a Marketing-only user can't reach
     *      adminhtml/sitemap or adminhtml/customer even when the standard
     *      Magento _isAllowed() check is missing or permissive on that
     *      controller. Defense in depth.
     */
    public function onPredispatch(Varien_Event_Observer $observer)
    {
        try {
            $session = Mage::getSingleton('admin/session');
            if (!$session->isLoggedIn()) {
                return;
            }

            // Refresh the session ACL on every request so live sessions
            // pick up any admin_rule changes (e.g. from migrations or the
            // Role Management UI) without needing a log-out / role switch.
            // Admin_role + admin_rule are small tables; the rebuild cost
            // is negligible compared to the silent-failure surface area
            // of a stale cached ACL.
            $session->setAcl(Mage::getResourceModel('admin/acl')->loadAcl());

            $controller = $observer->getEvent()->getControllerAction();
            $actionName = $controller->getFullActionName();
            $module     = $controller->getRequest()->getModuleName();
            $ctrl       = $controller->getRequest()->getControllerName();
            $key        = $module . '_' . $ctrl;

            // 1. Multi-role users haven't picked yet → push to role select
            if ($session->getNeedsRoleSelect()) {
                $allowedDuringSelect = array(
                    'adminhtml_roleselect_index',
                    'adminhtml_roleselect_choose',
                    'adminhtml_index_logout',
                );
                if (in_array($actionName, $allowedDuringSelect, true)) {
                    return;
                }
                $controller->getResponse()->setRedirect(
                    Mage::helper('adminhtml')->getUrl('adminhtml/roleselect/index')
                );
                $controller->setFlag('', Mage_Core_Controller_Varien_Action::FLAG_NO_DISPATCH, true);
                return;
            }

            // 2. Per-role allow-list. Whitelisted controllers always pass
            //    (login, dashboard, role-select / -switch, own profile,
            //    Magento housekeeping like ajax/system_account block_widget).
            //    Custom MMD controllers do their own _isAllowed checks via
            //    Helper::isRoleAllowed and aren't included here.
            $whitelist = $this->_aclWhitelist();
            if (in_array($key, $whitelist, true)) {
                return;
            }

            // Look up the allowed role list for this controller
            $map = $this->_roleControllerMap();
            if (!isset($map[$key])) {
                return; // not in our map — fall through to Magento default ACL
            }

            $activeRole = Mage::helper('mmd_rolemanager')->getActiveRoleCode();
            if (in_array($activeRole, $map[$key], true)) {
                return; // permitted
            }

            // Block — render the standard Access Denied page
            Mage::getSingleton('adminhtml/session')->addError(
                Mage::helper('adminhtml')->__('Access denied.')
            );
            $controller->getResponse()->setRedirect(
                Mage::helper('adminhtml')->getUrl('adminhtml/index/denied')
            );
            $controller->setFlag('', Mage_Core_Controller_Varien_Action::FLAG_NO_DISPATCH, true);
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }

    /**
     * Controllers that are always available regardless of active role.
     */
    protected function _aclWhitelist()
    {
        return array(
            // Admin login + standard navigation
            'adminhtml_index',
            'adminhtml_dashboard',
            // Role selection / switching / management UI
            'adminhtml_roleselect',
            'adminhtml_roleswitch',
            // Own account
            'adminhtml_system_account',
            // CMS WYSIWYG ajax (variables, widgets, image browser)
            'adminhtml_cms_wysiwyg_images',
            'adminhtml_cms_wysiwyg',
            // Magento housekeeping JSON endpoints used across roles
            'adminhtml_ajax',
            'adminhtml_notification',
            'adminhtml_messages',
            // Adminhtml support paths used internally
            'adminhtml_oauth_authorize',
            'adminhtml_oauth_authorize_simple',
            'adminhtml_oauth_authorize_confirm',
        );
    }

    /**
     * Map of `<module>_<controller>` => list of role codes allowed to reach it.
     * Anything not listed here falls through to Magento's standard ACL check.
     * Custom MMD controllers (coursesave, attendance, etc.) have their own
     * Helper::isRoleAllowed gates and aren't duplicated here.
     */
    protected function _roleControllerMap()
    {
        // Heavy catalog admin (categories / products / attributes) —
        // structural, dev-side. Marketing doesn't reach these.
        $catalogAdmin = array('admin', 'developer', 'training_provider');
        // Marketing-side catalog tools (search terms, reviews, urlrewrite,
        // sitemap, tags / subjects) — exposed in the Marketing sidebar's
        // "Marketing Management" group, so Marketing must reach them too.
        $catalogMkt   = array('admin', 'developer', 'marketing', 'training_provider');
        $cmsRoles     = array('admin', 'marketing', 'training_provider');
        $promoRoles   = array('admin', 'marketing', 'training_provider');
        $salesRoles   = array('admin', 'trainer', 'training_provider');
        $reportRoles  = array('admin', 'trainer', 'training_provider');
        $sysDevRoles  = array('admin', 'developer', 'training_provider');
        $superOnly    = array('training_provider');

        return array(
            // Catalog — heavy admin
            'adminhtml_catalog_category'          => $catalogAdmin,
            'adminhtml_catalog_product'           => $catalogAdmin,
            'adminhtml_catalog_product_attribute' => $catalogAdmin,
            'adminhtml_catalog_product_set'       => $catalogAdmin,
            'adminhtml_googleshopping_items'      => $catalogAdmin,
            // Catalog — also exposed to marketing via the Marketing sidebar
            'adminhtml_catalog_product_review'    => $catalogMkt,
            'adminhtml_catalog_search'            => $catalogMkt,
            'adminhtml_urlrewrite'                => $catalogMkt,
            'adminhtml_sitemap'                   => $catalogMkt,
            'adminhtml_tag'                       => $catalogMkt,
            'adminhtml_tag_product'               => $catalogMkt,
            'adminhtml_tag_customer'              => $catalogMkt,

            // Customer
            'adminhtml_customer'                  => array('admin', 'training_provider'),
            'adminhtml_customer_group'            => array('admin', 'training_provider'),
            'adminhtml_customer_online'           => array('admin', 'training_provider'),

            // Sales
            'adminhtml_sales_order'               => $salesRoles,
            'adminhtml_sales_order_invoice'       => $salesRoles,
            'adminhtml_sales_order_shipment'      => $salesRoles,
            'adminhtml_sales_order_creditmemo'    => $salesRoles,
            'adminhtml_sales_invoice'             => $salesRoles,
            'adminhtml_sales_shipment'            => $salesRoles,
            'adminhtml_sales_creditmemo'          => $salesRoles,
            'adminhtml_sales_billing_agreement'   => array('admin', 'training_provider'),
            'adminhtml_sales_transactions'        => array('admin', 'training_provider'),
            'adminhtml_recurring_profile'         => array('admin', 'training_provider'),
            'adminhtml_promo_quote'               => $promoRoles,
            'adminhtml_promo_catalog'             => $promoRoles,

            // Promotions / CMS / Newsletter — marketing & admin
            'adminhtml_widget_instance'           => $cmsRoles,
            'adminhtml_cms_page'                  => $cmsRoles,
            'adminhtml_cms_block'                 => $cmsRoles,
            'adminhtml_newsletter_problem'        => $cmsRoles,
            'adminhtml_newsletter_queue'          => $cmsRoles,
            'adminhtml_newsletter_subscriber'     => $cmsRoles,
            'adminhtml_newsletter_template'       => $cmsRoles,

            // Reports
            'adminhtml_report'                    => $reportRoles,
            'adminhtml_report_sales'              => $reportRoles,
            'adminhtml_report_shopcart'           => $reportRoles,
            'adminhtml_report_product'            => $reportRoles,
            'adminhtml_report_customer'           => $reportRoles,
            'adminhtml_report_review'             => $reportRoles,
            'adminhtml_report_tag'                => $reportRoles,
            'adminhtml_report_search'             => $reportRoles,
            'adminhtml_report_statistics'         => $reportRoles,

            // System / dev tools
            'adminhtml_system_config'             => $sysDevRoles,
            'adminhtml_system_design'             => $sysDevRoles,
            'adminhtml_system_store'              => array('admin', 'training_provider'),
            'adminhtml_system_email_template'     => $cmsRoles,
            'adminhtml_system_currency'           => array('admin', 'training_provider'),
            'adminhtml_system_currencysymbol'     => array('admin', 'training_provider'),
            'adminhtml_system_variable'           => $cmsRoles,
            'adminhtml_system_storage_media_synchronize' => $sysDevRoles,
            'adminhtml_system_backup'             => $sysDevRoles,
            'adminhtml_cache'                     => $sysDevRoles,
            'adminhtml_index_management'          => $sysDevRoles,
            'adminhtml_log'                       => $sysDevRoles,
            'adminhtml_extensions'                => $sysDevRoles,
            'adminhtml_process'                   => $sysDevRoles,
            'adminhtml_api_user'                  => $sysDevRoles,
            'adminhtml_api_role'                  => $sysDevRoles,
            'adminhtml_api2_role'                 => $sysDevRoles,
            'adminhtml_api2_attribute'            => $sysDevRoles,

            // Permissions — Super Admin only
            'adminhtml_permissions_role'          => $superOnly,
            'adminhtml_permissions_user'          => $superOnly,
            'adminhtml_permissions_block'         => $superOnly,
            'adminhtml_permissions_variable'      => $superOnly,

            // Custom Role Management UI — Super Admin + Admin
            'adminhtml_rolemanagement'            => array('admin', 'training_provider'),

            // Tax (GST in this LMS' Super Admin + Admin sidebars)
            'adminhtml_tax_rule'                  => array('admin', 'training_provider'),
            'adminhtml_tax_class'                 => array('admin', 'training_provider'),
            'adminhtml_tax_rate'                  => array('admin', 'training_provider'),

            // Custom MMD route: Course Schedules ("Manage Templates")
            'mmd_customoptions_options'           => array('admin', 'training_provider'),
        );
    }
}
