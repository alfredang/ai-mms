<?php

class MMD_FundedPayment_Model_Observer
{
    /** SG store code (store codes are full names). */
    const SG_STORE_CODE = 'singapore';

    /** Payment methods that only apply to funded (TGS-) courses. */
    protected $_fundedMethods = ['cheque', 'citrep', 'sfec'];

    /**
     * payment_method_is_active: on SG, hide the funded-only methods unless the
     * cart contains at least one TGS- (WSQ / CASL / IBF) course. A mixed cart
     * (TGS- + C-) shows every method; a C-only cart hides the funded ones.
     */
    public function filterFundedMethods(Varien_Event_Observer $observer)
    {
        $result = $observer->getEvent()->getResult();
        $method = $observer->getEvent()->getMethodInstance();
        $quote  = $observer->getEvent()->getQuote();

        if (!$result->isAvailable || !$quote || !$method
            || !in_array($method->getCode(), $this->_fundedMethods, true)
        ) {
            return;
        }
        if (Mage::app()->getStore($quote->getStoreId())->getCode() !== self::SG_STORE_CODE) {
            return;
        }

        foreach ($quote->getAllVisibleItems() as $item) {
            if (stripos((string) $item->getSku(), 'TGS-') === 0) {
                return;
            }
        }
        $result->isAvailable = false;
    }
}
