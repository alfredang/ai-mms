<?php

/**
 * Class Gene_Braintree_Block_Js
 *
 * @author Dave Macaulay <braintreesupport@gene.co.uk>
 */
class Gene_Braintree_Block_Js extends Gene_Braintree_Block_Assets
{
    /**
     * We can use the same token twice
     *
     * @var bool
     */
    private $token = false;

    /**
     * Log whether methods are active
     *
     * @var bool
     */
    private $creditCardActive = null;
    private $payPalActive = null;

    /**
     * Return whether PayPal is active
     *
     * @return bool|null
     */
    protected function isCreditCardActive()
    {
        if (is_null($this->creditCardActive)) {
            $this->creditCardActive = Mage::getModel('gene_braintree/paymentmethod_creditcard')->isAvailable();
        }

        return $this->creditCardActive;
    }

    /**
     * Return whether PayPal is active
     *
     * @return bool|null
     */
    protected function isPayPalActive()
    {
        if (is_null($this->payPalActive)) {
            $this->payPalActive = Mage::getModel('gene_braintree/paymentmethod_paypal')->isAvailable();
        }

        return $this->payPalActive;
    }

    /**
     * is 3D secure enabled?
     *
     * @return string
     */
    protected function is3DEnabled()
    {
        return var_export(Mage::getModel('gene_braintree/paymentmethod_creditcard')->is3DEnabled(), true);
    }

    /**
     * Is 3D secure limited to specific countries?
     *
     * @return bool
     */
    protected function isThreeDSpecificCountries()
    {
        return Mage::getStoreConfigFlag('payment/gene_braintree_creditcard/threedsecure_allowspecific');
    }

    /**
     * Return the countries that 3D secure should be present for
     *
     * @return array|mixed
     */
    protected function getThreeDSpecificCountries()
    {
        if ($this->isThreeDSpecificCountries()) {
            return Mage::getStoreConfig('payment/gene_braintree_creditcard/threedsecure_specificcountry');
        }

        return '';
    }

    /**
     * Return supported credit cards
     *
     * @return array
     */
    protected function getSupportedCardTypes()
    {
        if ($this->isCreditCardActive()) {
            return Mage::getStoreConfig('payment/gene_braintree_creditcard/cctypes');
        }

        return '';
    }

    /**
     * Return the failed action for 3D secure payments
     *
     * @return int
     */
    protected function getThreeDSecureFailedAction()
    {
        if ($this->isCreditCardActive() && $this->is3DEnabled()) {
            return Mage::getStoreConfig('payment/gene_braintree_creditcard/threedsecure_failed_liability');
        }

        return 0;
    }

    /**
     * Return the Kount environment
     *
     * @return mixed|string
     */
    protected function getKountEnvironment()
    {
        $env = Mage::getStoreConfig('payment/gene_braintree_creditcard/kount_environment');
        if ($env) {
            return $env;
        }

        return 'production';
    }

    /**
     * Return the Kount ID
     *
     * @return bool|string
     */
    protected function getKountId()
    {
        $kountId = Mage::getStoreConfig('payment/gene_braintree_creditcard/kount_merchant_id');
        if ($kountId) {
            return $kountId;
        }

        return '';
    }

    /**
     * Generate and return a token
     *
     * @return mixed
     */
    protected function getClientToken()
    {
        if (!$this->token) {
            $this->token = Mage::getSingleton('gene_braintree/wrapper_braintree')->init()->generateToken();
        }

        return $this->token;
    }

    /**
     * Shall we do a single use payment?
     *
     * @return string
     */
    protected function getSingleUse()
    {
        // We prefer to do future payments, so anything else is future
        if (Mage::getSingleton('gene_braintree/paymentmethod_paypal')->getPaymentType() ==
            Gene_Braintree_Model_Source_Paypal_Paymenttype::GENE_BRAINTREE_PAYPAL_SINGLE_PAYMENT
        ) {
            return 'true';
        }

        return 'false';
    }

    /**
     * If we're using future payments should we retrieve a token or just do a singular payment?
     *
     * @return string
     */
    protected function getSingleFutureUse()
    {
        // We prefer to do future payments, so anything else is future
        if (Mage::getSingleton('gene_braintree/paymentmethod_paypal')->getPaymentType() == Gene_Braintree_Model_Source_Paypal_Paymenttype::GENE_BRAINTREE_PAYPAL_FUTURE_PAYMENTS
            && !Mage::getModel('gene_braintree/paymentmethod_paypal')->isVaultEnabled()
        ) {
            return 'true';
        }

        return 'false';
    }

    /**
     * Shall we only use Vault flow when the customer selects to store their PayPal account?
     *
     * @return bool
     */
    public function shouldOnlyVaultOnVault()
    {
        return $this->getSingleUse() == 'false' &&
            Mage::getStoreConfigFlag('payment/gene_braintree_paypal/use_vault_only_on_vault');
    }

    /**
     * Return the locale for PayPal
     *
     * @return mixed
     */
    protected function getLocale()
    {
        return Mage::getStoreConfig('payment/gene_braintree_paypal/locale');
    }

    /**
     * Only render if the payment method is active
     *
     * @return string
     */
    protected function _toHtml()
    {
        // Check the payment method is active, block duplicate rendering of this block
        if (!Mage::registry('gene_js_loaded_' . $this->getTemplate())) {
            Mage::register('gene_js_loaded_' . $this->getTemplate(), true);

            // The parent handles whether or not the module is enabled
            return parent::_toHtml();
        }

        return '';
    }

}