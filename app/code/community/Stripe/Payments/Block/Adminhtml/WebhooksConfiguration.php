<?php

class Stripe_Payments_Block_Adminhtml_WebhooksConfiguration extends Mage_Adminhtml_Block_System_Config_Form_Field
{
    public $webhooksSetup;
    protected $_template = 'stripe/payments/adminhtml/config/webhooks_configuration.phtml';

    protected function _construct()
    {
        $this->helper = Mage::helper('stripe_payments');
        $this->webhooksSetup = Mage::helper('stripe_payments/webhooksSetup');
        $this->store = $this->helper->getAdminConfigStore();

        if (!$this->helper->isConfigured($this->store))
            $this->setTemplate('stripe/payments/adminhtml/config/webhooks_configuration_disabled.phtml');

        return parent::_construct();
    }

    protected function _getElementHtml(Varien_Data_Form_Element_Abstract $element)
    {
        return $this->_toHtml();
    }

    public function getAjaxUrl()
    {
        return Mage::getModel('adminhtml/url')->getUrl('stripe_payments/configure_webhooks/index');
    }

    public function getButtonHtml()
    {
        $button = Mage::app()->getLayout()->createBlock(
            'adminhtml/widget_button'
        )->setData(
            [
                'id' => 'stripe_configure_webhooks',
                'label' => __('Configure'),
            ]
        );

        return $button->toHtml();
    }

    public function getDisabledButtonHtml()
    {
        $button = Mage::app()->getLayout()->createBlock(
            'adminhtml/widget_button'
        )->setData(
            [
                'id' => 'stripe_configure_webhooks',
                'label' => __('Configure'),
                'disabled' => true
            ]
        );

        return $button->toHtml();
    }
}
