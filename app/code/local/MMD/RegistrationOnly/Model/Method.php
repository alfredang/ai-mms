<?php
/**
 * "Registration only" payment method: collects no payment, records the Registration Type and,
 * for company-sponsored registrations, the sponsoring company's details in the payment's
 * additional_information. The order stays at the configured status (pending).
 */
class MMD_RegistrationOnly_Model_Method extends Mage_Payment_Model_Method_Abstract
{
    protected $_code          = 'registration';
    protected $_formBlockType = 'mmd_registrationonly/form';
    protected $_infoBlockType = 'mmd_registrationonly/info';

    protected $_canUseCheckout         = true;
    protected $_canUseInternal         = true;
    protected $_canUseForMultishipping = false;

    /** Malaysia only, whatever the config says. */
    public function isAvailable($quote = null)
    {
        $storeId = $quote ? $quote->getStoreId() : null;
        if (Mage::app()->getStore($storeId)->getCode() !== 'malaysia') {
            return false;
        }
        return parent::isAvailable($quote);
    }

    public function assignData($data)
    {
        if (!($data instanceof Varien_Object)) {
            $data = new Varien_Object($data);
        }
        $helper = Mage::helper('mmd_registrationonly');
        $info = $this->getInfoInstance();
        $type = (string) $data->getRegistrationType();
        $info->setAdditionalInformation('registration_type', $type);
        foreach (array_keys($helper->getCompanyFields()) as $key) {
            $value = $type === MMD_RegistrationOnly_Helper_Data::TYPE_COMPANY ? trim((string) $data->getData($key)) : '';
            $info->setAdditionalInformation($key, $value);
        }
        return $this;
    }

    public function validate()
    {
        parent::validate();
        $helper = Mage::helper('mmd_registrationonly');
        $info = $this->getInfoInstance();
        $type = (string) $info->getAdditionalInformation('registration_type');
        if (!array_key_exists($type, $helper->getTypeLabels())) {
            Mage::throwException($helper->__('Please select a Registration Type.'));
        }
        if ($type === MMD_RegistrationOnly_Helper_Data::TYPE_COMPANY) {
            foreach ($helper->getCompanyFields() as $key => $label) {
                if ($key !== 'company_reg_no' && (string) $info->getAdditionalInformation($key) === '') {
                    Mage::throwException($helper->__('Please enter the %s for a company-sponsored registration.', strtolower($label)));
                }
            }
            if (!Zend_Validate::is($info->getAdditionalInformation('contact_email'), 'EmailAddress')) {
                Mage::throwException($helper->__('Please enter a valid contact email.'));
            }
        }
        return $this;
    }
}
