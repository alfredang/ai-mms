<?php

class Stripe_Payments_Block_ApplePay_Inside extends Stripe_Payments_Block_ApplePay_Abstract
{
    protected $_template = 'stripe/payments/form/applepay/inside.phtml';

    public function shouldDisplay()
    {
        return parent::shouldDisplay() && parent::location() == 2;
    }
}
