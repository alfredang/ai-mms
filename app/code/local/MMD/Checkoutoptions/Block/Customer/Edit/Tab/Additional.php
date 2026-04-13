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
class MMD_Checkoutoptions_Block_Customer_Edit_Tab_Additional extends Mage_Adminhtml_Block_Widget_Form
{
    public function __construct()
    {
        parent::__construct();
    }
    
    protected function _afterToHtml($html)
    {
        $html = str_replace('__*__', ' <span class="required">*</span>', $html);
        
        return parent::_afterToHtml($html);
    }

    public function initForm()
    {
        $customerId='';
        $attributeValues='';
    	$mainModel = Mage::getModel('checkoutoptions/checkoutoptions');
        $form = new Varien_Data_Form();

        $customer = Mage::registry('current_customer');
        if($customer->getId())
        {
            $customerId = $customer->getId();
        }

        $fieldset = $form->addFieldset('additional_fieldset',
            array('legend'=>Mage::helper('checkoutoptions')->__('Additional Info'))
        );

        $collection = $mainModel->getAttributeCollecton();
        $collection->getSelect()->where('additional_table.mmd_registration_page > 0');                
        $collection->getSelect()->order('additional_table.mmd_registration_position ASC');
        
        if($customerId)
        {
            $temp = $mainModel->getCustomerData($customerId, $customer->getStoreId(),true);
            foreach($temp as $tmp)
            {
                if(in_array($tmp['type'],array('multiselect','checkbox')))
                {
                    $tmp['rawval']=explode(',',$tmp['rawval']);
                }
                $attributeValues[$tmp['code']]=$tmp['rawval'];
            }
        
            $groupId = Mage::getModel('customer/customer')->load($customerId)->getGroupId();
        }

            if(isset($groupId ))
            {
                     foreach($collection as $key => $value)
                     {
                         if(in_array($groupId, Mage::getModel('checkoutoptions/attributecustomergroups')->getGroups($value->getAttributeId())))
                         {
                            $aTmpColl[] = $value;
                         }                         
                     }
                        
            }
            else
            {
                $aTmpColl = $collection;
            }
        
        
        $mainModel->prepareAdminForm($fieldset, /*$collection*/$aTmpColl, 'mmdreg', $attributeValues, true);
        
        if ($customer->isReadonly()) {
            foreach ($customer->getAttributes() as $attribute) {
                $element = $form->getElement($attribute->getAttributeCode());
                if ($element) {
                    $element->setReadonly(true, true);
                }
            }
        }
        
        $this->setForm($form);
        return $this;
    }
}