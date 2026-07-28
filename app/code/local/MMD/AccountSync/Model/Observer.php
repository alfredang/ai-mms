<?php
/**
 * Keeps storefront customer accounts and dashboard admin_user accounts unified.
 * Thin event handlers — all logic lives in the helper. Bodies are wrapped so a
 * sync hiccup can never break a customer save or an admin save.
 */
class MMD_AccountSync_Model_Observer
{
    /** customer_save_after: ensure dashboard account + storefront->dashboard password sync. */
    public function onCustomerSaveAfter(Varien_Event_Observer $observer)
    {
        try {
            $customer = $observer->getEvent()->getCustomer();
            if ($customer instanceof Mage_Customer_Model_Customer) {
                Mage::helper('mmd_accountsync')->onCustomerSaved($customer);
            }
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }

    /**
     * Frontend predispatch guard: standalone online registration is disabled.
     * A learner account is only created by placing a course order (checkout
     * builds the account inside saveOrder, which never routes through
     * customer/account/create), so these two routes are bot-only surfaces.
     */
    public function onFrontendPredispatch(Varien_Event_Observer $observer)
    {
        $action = $observer->getEvent()->getControllerAction();
        if (!$action instanceof Mage_Core_Controller_Varien_Action) {
            return;
        }
        $full = strtolower($action->getFullActionName());
        if ($full !== 'customer_account_create' && $full !== 'customer_account_createpost') {
            return;
        }
        $action->setFlag('', Mage_Core_Controller_Varien_Action::FLAG_NO_DISPATCH, true);
        try {
            Mage::getSingleton('customer/session')->addNotice(
                Mage::helper('customer')->__('Online sign-up is by course registration only. Your learner account is created automatically when you register for a course — please choose a course to get started.')
            );
        } catch (Exception $e) {
            Mage::logException($e);
        }
        $action->getResponse()->setRedirect(Mage::getUrl('customer/account/login'));
    }

    /** admin_user_save_after: dashboard->storefront password sync. */
    public function onAdminUserSaveAfter(Varien_Event_Observer $observer)
    {
        try {
            $user = $observer->getEvent()->getObject();
            if ($user instanceof Mage_Admin_Model_User) {
                Mage::helper('mmd_accountsync')->onAdminUserSaved($user);
            }
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }
}
