<?php

class MMD_Courses_Block_Adminhtml_Providers_Edit extends Mage_Adminhtml_Block_Widget_Form_Container
{
    public function __construct()
    {
        parent::__construct();
                 
        $this->_objectId = 'id';
        $this->_blockGroup = 'courses';
        $this->_controller = 'adminhtml_providers';
        
        $this->_updateButton('save', 'label', Mage::helper('courses')->__('Save Item'));
        $this->_updateButton('delete', 'label', Mage::helper('courses')->__('Delete Item'));
		
        $this->_addButton('saveandcontinue', array(
            'label'     => Mage::helper('adminhtml')->__('Save And Continue Edit'),
            'onclick'   => 'saveAndContinueEdit()',
            'class'     => 'save',
        ), -100);

        $this->_formScripts[] = "
            function toggleEditor() {
                if (tinyMCE.getInstanceById('providers_content') == null) {
                    tinyMCE.execCommand('mceAddControl', false, 'providers_content');
                } else {
                    tinyMCE.execCommand('mceRemoveControl', false, 'providers_content');
                }
            }

            function saveAndContinueEdit(){
                editForm.submit($('edit_form').action+'back/edit/');
            }
        ";
    }

    public function getHeaderText()
    {
        if( Mage::registry('providers_data') && Mage::registry('providers_data')->getId() ) {
            return Mage::helper('courses')->__("Edit Provider '%s'", $this->htmlEscape(Mage::registry('providers_data')->getTitle()));
        } else {
            return Mage::helper('courses')->__('Add Provider');
        }
    }
}