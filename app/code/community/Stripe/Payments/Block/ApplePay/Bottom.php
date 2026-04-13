<?php

class Stripe_Payments_Block_ApplePay_Bottom extends Stripe_Payments_Block_ApplePay_Abstract
{
    protected $_template = 'stripe/payments/form/applepay/bottom.phtml';

    public function shouldDisplay()
    {
        return parent::shouldDisplay() && parent::location() == 3;
    }
}
