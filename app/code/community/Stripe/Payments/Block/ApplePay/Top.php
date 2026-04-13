<?php

class Stripe_Payments_Block_ApplePay_Top extends Stripe_Payments_Block_ApplePay_Abstract
{
    protected $_template = 'stripe/payments/form/applepay/top.phtml';

    public function shouldDisplay()
    {
        return parent::shouldDisplay() && parent::location() == 1;
    }
}
