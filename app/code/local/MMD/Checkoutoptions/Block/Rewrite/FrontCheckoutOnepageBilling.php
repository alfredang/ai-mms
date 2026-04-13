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
class MMD_Checkoutoptions_Block_Rewrite_FrontCheckoutOnepageBilling extends Mage_Checkout_Block_Onepage_Billing
{
    protected $_mainModel;
    
    protected function _construct()
    {
        parent::_construct();
        $this->_mainModel = Mage::getModel('checkoutoptions/checkoutoptions');
    }
    
    public function getFieldHtml($aField)
    {
        $sSetName = 'billing';
        
        return $this->_mainModel->getAttributeHtml($aField, $sSetName, 'onepage');
    }
    
    public function getCustomFieldList($iTplPlaceId)
    {
        $iStepId = Mage::helper('checkoutoptions')->getStepId('billing');
        
        if (!$iStepId) return false;

        return $this->_mainModel->getCheckoutAttributeList($iStepId, $iTplPlaceId, 'onepage');
    }
    
    public function getRegCustomFieldList()
    {
        $iStepId = Mage::helper('checkoutoptions')->getStepId('billing');
        
        if (!$iStepId) return false;
        
        $fields = false;
        $fieldsTmp = $this->_mainModel->getCustomerAttributeList();
        
        if($fieldsTmp)
        {
            $fields = array();
            foreach($fieldsTmp as $placeholder)
            {
                foreach ($placeholder as $id => $data)
                {
                    if(!$data['is_searchable'])
                    {
                        $fields[$id]=$data;
                    }
                }
            }
        }
        return $fields;
    }
    
    public function checkStepHasRequired()
    {
        $iStepId = Mage::helper('checkoutoptions')->getStepId('shippinfo');
        
        if (!$iStepId) return false;

        return $this->_mainModel->checkStepHasRequired($iStepId, 'onepage');
    } 
}