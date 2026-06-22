<?php
class MMD_Franchise_Block_Adminhtml_Franchiselead extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_franchiselead';
        $this->_blockGroup = 'mmd_franchise';
        $this->_headerText = Mage::helper('mmd_franchise')->__('Franchisee Leads');
        parent::__construct();
        $this->_removeButton('add');
    }
}
