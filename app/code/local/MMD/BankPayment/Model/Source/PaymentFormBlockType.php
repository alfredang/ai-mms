<?php
/**
 * Magento
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the Open Software License (OSL 3.0)
 * that is bundled with this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://opensource.org/licenses/osl-3.0.php
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@magentocommerce.com so we can send you a copy immediately.
 *
 * @category   MMD
 * @package    MMD_BankPayment
 * @copyright  Copyright (c) 2013 MMD  (http://magemobiledesign.com)
 */

class MMD_BankPayment_Model_Source_PaymentFormBlockType
{

    protected $_options;
    
    public function toOptionArray()
    {
        if (!$this->_options) {
            $this->_options = array(
                array(
                    'value' => MMD_BankPayment_Model_BankPayment::FORM_BLOCK_TYPE_DEFAULT,
                    'label' => Mage::helper('bankpayment')->__('Show account information in form'),
                    ),
                array(
                    'value' => MMD_BankPayment_Model_BankPayment::FORM_BLOCK_TYPE_CMS,
                    'label' => Mage::helper('bankpayment')->__('Link to CMS page'),
                    )
                );
        }
        return $this->_options;
    }
}