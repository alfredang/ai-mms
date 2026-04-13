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
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */

class MMD_Aitoptionstemplate_Block_Template_Edit_Tab_General extends Mage_Adminhtml_Block_Widget_Form
{
    protected function _prepareForm()
    {
    	$model = Mage::registry('current_mmdoptionstemplate_template');
    	
    	$form = new Varien_Data_Form();

        $form->setHtmlIdPrefix('template_');
        
        $fieldset = $form->addFieldset('base_fieldset', array('legend'=>Mage::helper('mmdoptionstemplate')->__('General Information')));

        if ($model->getId()) {
            $fieldset->addField('template_id', 'hidden', array(
                'name' => 'template_id',
            ));
        }
        
        $fieldset->addField('title', 'text', array(
            'name' => 'title',
            'label' => Mage::helper('mmdoptionstemplate')->__('Title'),
            'title' => Mage::helper('mmdoptionstemplate')->__('Title'),
            'required' => true,
        ));
        
        $fieldset->addField('description', 'textarea', array(
            'name' => 'description',
            'label' => Mage::helper('mmdoptionstemplate')->__('Description'),
            'title' => Mage::helper('mmdoptionstemplate')->__('Description'),
            'style' => 'width: 98%; height: 100px;',
        ));
    	
         $fieldset->addField('is_active', 'select', array(
            'label'     => Mage::helper('salesrule')->__('Status'),
            'title'     => Mage::helper('salesrule')->__('Status'),
            'name'      => 'is_active',
            'required' => true,
            'options'    => array(
                '1' => Mage::helper('salesrule')->__('Active'),
                '0' => Mage::helper('salesrule')->__('Inactive'),
            ),
        ));

        $form->setValues($model->getData());

        $this->setForm($form);
        
        return parent::_prepareForm();
    }
}