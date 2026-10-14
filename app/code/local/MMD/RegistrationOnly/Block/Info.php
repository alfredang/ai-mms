<?php
/**
 * Shown in checkout review, account order view, admin order view, order emails (payment_html)
 * and PDFs: the no-payment statement, the Registration
 * Type and, for company-sponsored registrations, the company details.
 */
class MMD_RegistrationOnly_Block_Info extends Mage_Payment_Block_Info
{
    protected function _construct()
    {
        parent::_construct();
        $this->setTemplate('mmd/registrationonly/info.phtml');
    }

    public function toPdf()
    {
        $this->setTemplate('mmd/registrationonly/pdf.phtml');
        return $this->toHtml();
    }

    protected function _prepareSpecificInformation($transport = null)
    {
        if ($this->_paymentSpecificInformation !== null) {
            return $this->_paymentSpecificInformation;
        }
        $transport = parent::_prepareSpecificInformation($transport);
        $helper = Mage::helper('mmd_registrationonly');
        $info = $this->getInfo();
        $type = (string) $info->getAdditionalInformation('registration_type');
        $labels = $helper->getTypeLabels();

        $data = array($helper->__('Payment') => $helper->getNoPaymentStatement());
        if (isset($labels[$type])) {
            $data[$helper->__('Registration Type')] = $labels[$type];
        }
        if ($type === MMD_RegistrationOnly_Helper_Data::TYPE_COMPANY) {
            foreach ($helper->getCompanyFields() as $key => $label) {
                $value = (string) $info->getAdditionalInformation($key);
                if ($value !== '') {
                    $data[$label] = $value;
                }
            }
        }
        return $transport->setData(array_merge($data, $transport->getData()));
    }
}
