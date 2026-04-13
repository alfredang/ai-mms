<?php
/**
 * Checkout Fields Manager
 *
 * @category:    MMD
 * @package:     MMD_Checkoutoptions
 * @version      2.9.2
 * @license:     
 * @copyright:   Copyright (c) 2013 MMD, Inc. (http://www.mmd.com)
 */
class MMD_Checkoutoptions_Block_Rewrite_AdminSalesOrderCreateFormAccount  extends Mage_Adminhtml_Block_Sales_Order_Create_Form_Account
{
    protected function _toHtml()
    {
    	$html = parent::_toHtml();
    	$fBlock = $this->getLayout()->createBlock('checkoutoptions/ordercreate_form')->toHtml();
    	return $html.$fBlock;
    }
}