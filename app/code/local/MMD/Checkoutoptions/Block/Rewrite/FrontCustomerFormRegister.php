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
class MMD_Checkoutoptions_Block_Rewrite_FrontCustomerFormRegister extends Mage_Customer_Block_Form_Register
{
    protected $_mainModel;
    
    protected function _construct()
    {
        parent::_construct();
        $this->_mainModel = Mage::getModel('checkoutoptions/checkoutoptions');
    }
    
    protected function _prepareLayout()
    {
        if ($head = $this->getLayout()->getBlock('head')) {
            $head->setCanLoadCalendarJs(true);
        }
        return parent::_prepareLayout();
    }
    
    public function getCustomFieldsList($placeholder)
    {
        return $this->_mainModel->getCustomerAttributeList($placeholder);
    }
    
    public function getAttributeHtml($aField, $sSetName, $sPageType)
    {
        return $this->_mainModel->getAttributeHtml($aField, $sSetName, $sPageType);
    }
}