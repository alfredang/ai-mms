<?php

class Stripe_Payments_VerificationController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        $request = $this->getRequest();
        $customerId = $request->getParam("customer", null);
        $bankAccountId = $request->getParam("account", null);

        if (empty($customerId) || empty($bankAccountId))
            return $this->norouteAction();

        $amount1 = $request->getParam("amount1", null);
        $amount2 = $request->getParam("amount2", null);
        if (!empty($amount1) && !empty($amount2))
        {
            Mage::helper("stripe_payments")->verify($customerId, $bankAccountId, $amount1, $amount2);
        }

        $this->loadLayout();
        $this->renderLayout();
    }
}
