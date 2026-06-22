<?php
class MMD_Corporate_Block_Adminhtml_Corporatelead extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_corporatelead';
        $this->_blockGroup = 'mmd_corporate';
        $this->_headerText = Mage::helper('mmd_corporate')->__('Corporate Application Leads');
        parent::__construct();
        $this->_removeButton('add');
    }
}
