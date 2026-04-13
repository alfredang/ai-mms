<?php

class Stripe_Payments_Block_Form_Method extends Mage_Payment_Block_Form_Cc
{
    public $stripe;

    protected function _construct()
    {
        parent::_construct();
        $this->setTemplate('stripe/payments/form/method.phtml');

        $this->stripe = Mage::getModel('stripe_payments/method');

        $this->cardAutoDetect = $this->stripe->store->getConfig('payment/stripe_payments/card_autodetect');
    }

    public function autoDetectCard()
    {
        return $this->cardAutoDetect && $this->cardAutoDetect > 0;
    }

    public function showAcceptedCardTypes()
    {
        return $this->cardAutoDetect == 1;
    }

    public function getOnCardNumberChangedAnimation()
    {
        switch ($this->cardAutoDetect)
        {
            case 1: return 'onCardNumberChangedFade';
            case 2: return 'onCardNumberChangedSlide';
            default: return '';
        }
    }

    public function getOnKeyUpCardNumber()
    {
        if ($this->autoDetectCard())
        {
            $callback = $this->getOnCardNumberChangedAnimation();
            return "onkeyup=\"$callback(this)\"";
        }

        return '';
    }

    public function getAcceptedCardTypes()
    {
        $types = Mage::getConfig()->getNode('global/payment/stripe_payments/cc_types')->asArray();
        $acceptedTypes = $this->stripe->store->getConfig('payment/stripe_payments/cctypes');

        uasort($types, array('Mage_Payment_Model_Config', 'compareCcTypes'));

        foreach ($types as $data)
        {
            if (empty($acceptedTypes)) // Slide animation, returns all possible types
            {
                $cardTypes[$data['code']] = $data['name'];
            }
            else if (isset($data['code']) && isset($data['name']) && strstr($acceptedTypes, $data['code'])) // Fade animation, takes into account selected types
            {
                $cardTypes[$data['code']] = $data['name'];
            }
        }

        return $cardTypes;
    }

    public function getMethodLabelAfterHtml()
    {
        // Add any html you like, like card images in the returned string
        return "";
    }
}
