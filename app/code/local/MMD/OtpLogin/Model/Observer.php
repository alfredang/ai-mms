<?php
class MMD_OtpLogin_Model_Observer
{
    /**
     * Allow OTP send/verify actions without admin login.
     *
     * The core Mage_Admin_Model_Observer::actionPreDispatchAdmin checks
     * $openActions and forwards unauthenticated requests to the login page.
     * This observer intercepts the predispatch event and marks OTP requests
     * as dispatched so the core observer won't redirect them.
     */
    public function allowOtpAction(Varien_Event_Observer $observer)
    {
        $request = Mage::app()->getRequest();
        $controller = $request->getControllerName();
        $action = strtolower($request->getActionName());

        if ($controller === 'otp' && in_array($action, array('send', 'verify'))) {
            $request->setDispatched(true);
        }
    }
}
