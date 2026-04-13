<?php

class Hitpay_Pay_Block_Form extends Mage_Payment_Block_Form
{
    protected function _construct()
    {
        $blockName = Mage::getConfig()->getBlockClassName('core/template');
        $block = new $blockName;
        $block->setTemplate('hitpay/logos.phtml')
            ->setPaymentLogos($this->getPaymentImages());
        $this->setMethodLabelAfterHtml($block->toHtml());
        parent::_construct();
    }

    protected function getPaymentImages()
    {
        return Mage::helper('hitpay')->getStoreConfig("payment/hitpay/paymentlogos");
    }
}
