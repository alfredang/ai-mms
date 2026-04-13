<?php

class Stripe_Payments_Model_Method_Multibanco extends Stripe_Payments_Model_Method_Api_Sources
{
    protected $_code = 'stripe_payments_multibanco';
    protected $_name = 'Stripe Multibanco';
    protected $_type = 'multibanco';

    public function getTestEmail()
    {
        $config = $this->stripe->store->getConfig('payment/' . $this->_code . '/test_payment');
        $storeEmail = Mage::getStoreConfig('trans_email/ident_general/email');

        if ($config == 1)
        {
            $fillNever = 'multibanco+fill_never@stripe.com';

            if ($this->isEmailValid($storeEmail))
                return str_replace('@', '+fill_never@', $storeEmail);

            return $fillNever;
        }
        else if ($config == 2)
        {
            $fillNow = 'multibanco+fill_now@stripe.com';

            if ($this->isEmailValid($storeEmail))
                return str_replace('@', '+fill_now@', $storeEmail);

            return $fillNow;
        }

        return false;
    }
}
