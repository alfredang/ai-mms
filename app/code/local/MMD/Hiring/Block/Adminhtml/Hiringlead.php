<?php
class MMD_Hiring_Block_Adminhtml_Hiringlead extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_corporatelead';
        $this->_blockGroup = 'mmd_hiring';
        $this->_headerText = Mage::helper('mmd_hiring')->__('Job Application Leads');
        parent::__construct();
        $this->_removeButton('add');
    }
}
