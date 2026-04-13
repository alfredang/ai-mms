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
class MMD_Checkoutoptions_Block_Edit extends Mage_Adminhtml_Block_Widget_Form_Container
{

	protected function _prepareLayout()
    {
        $this->setChild('form', $this->getLayout()->createBlock($this->_blockGroup . '/' . $this->_mode . '_form'));
        return Mage_Adminhtml_Block_Widget_Container::_prepareLayout();
    }
    
    public function __construct()
    {
    	
        $this->_objectId = 'attribute_id';
        $this->_controller = 'index';
        $this->_blockGroup = 'checkoutoptions';

        parent::__construct();

        if($this->getRequest()->getParam('popup')) {
            $this->_removeButton('back');
            $this->_addButton(
                'close',
                array(
                    'label'     => Mage::helper('catalog')->__('Close Window'),
                    'class'     => 'cancel',
                    'onclick'   => 'window.close()',
                    'level'     => -1
                )
            );
        }

        $this->_updateButton('save', 'label', Mage::helper('catalog')->__('Save Attribute'));

       if (! Mage::registry('checkoutoptions_data')->getIsUserDefined()) {
            $this->_removeButton('delete');
        } else {
            $this->_updateButton('delete', 'label', Mage::helper('catalog')->__('Delete Attribute'));
            $this->_updateButton('delete', 'onclick', "deleteConfirm(
            		'".Mage::helper('adminhtml')->__('Are you sure you want to do this?')."',
            		'".$this->getUrl('*/*/delete/attribute_id/'.$this->getRequest()->getParam('attribute_id')
            		)."')");
        }
    }

    public function getHeaderText()
    {
    	
        if (Mage::registry('checkoutoptions_data')->getId()) {
            return Mage::helper('checkoutoptions')->__('Edit Checkout Attribute "%s"', $this->htmlEscape(Mage::registry('checkoutoptions_data')->getFrontendLabel()));
        }
        else {
            return Mage::helper('checkoutoptions')->__('New Checkout Attribute');
        }
       
    }
	
    public function getValidationUrl()
    {
        return $this->getUrl('*/*/validate', array('_current'=>true));
    }

    public function getSaveUrl()
    {
        return $this->getUrl('*/'.$this->_controller.'/save', array('_current'=>true, 'back'=>null));
    }
}