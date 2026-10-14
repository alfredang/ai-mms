<?php
class MMD_RegistrationOnly_Helper_Data extends Mage_Core_Helper_Abstract
{
    const TYPE_INDIVIDUAL = 'individual';
    const TYPE_COMPANY    = 'company';

    /** Company-sponsored detail fields: payment[<key>] => label. */
    public function getCompanyFields()
    {
        return array(
            'company_name'   => $this->__('Company name'),
            'company_reg_no' => $this->__('Company registration no.'),
            'contact_name'   => $this->__('Contact person (HR / Finance)'),
            'contact_email'  => $this->__('Contact email'),
            'contact_phone'  => $this->__('Contact phone'),
        );
    }

    public function getTypeLabels()
    {
        return array(
            self::TYPE_INDIVIDUAL => $this->__('Individual / Self-sponsored'),
            self::TYPE_COMPANY    => $this->__('Company-sponsored'),
        );
    }

    public function getNoPaymentStatement()
    {
        return $this->__('No payment is collected online. Our team will contact you to confirm the registration, quotation and HRD Corp arrangements where applicable.');
    }
}
