<?php

/**
 * Class Gene_Braintree_Block_Express_Button
 *
 * @author Aidan Threadgold <braintreesupport@gene.co.uk>
 */
class Gene_Braintree_Block_Express_Setup extends Gene_Braintree_Block_Express_Abstract
{
    /**
     * Braintree token
     *
     * @var string
     */
    protected $_token = null;

    /**
     * Get braintree token
     *
     * @return string
     */
    public function getToken()
    {
        if ($this->_token === null) {
            $this->_token = Mage::getModel('gene_braintree/wrapper_braintree')->init()->generateToken();
        }

        return $this->_token;
    }

    /**
     * Shall we do a single use payment?
     *
     * @return string
     */
    public function getSingleUse()
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
     * Get store currency code.
     *
     * @return string
     */
    public function getStoreCurrency()
    {
        return Mage::app()->getStore()->getCurrentCurrencyCode();
    }

    /**
     * Get the store locale.
     *
     * @return string
     */
    public function getStoreLocale()
    {
        return Mage::app()->getLocale()->getLocaleCode();
    }

    /**
     * Get the current product
     *
     * @return mixed
     */
    public function getProduct()
    {
        return Mage::registry('current_product');
    }

    /**
     * Registry entry to determine if block has been instantiated yet
     *
     * @return bool
     */
    public function hasBeenSetup()
    {
        if (Mage::registry('gene_braintree_btn_loaded')) {
            return true;
        }

        return false;
    }

    /**
     * Registry entry to mark this block as instantiated
     *
     * @param string $html
     *
     * @return string
     */
    public function _afterToHtml($html)
    {
        if (!$this->hasBeenSetup()) {
            Mage::register('gene_braintree_btn_loaded', true);
        }

        return $html;
    }
}
