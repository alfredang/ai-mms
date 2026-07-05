<?php
class MMD_Wpl_Block_Adminhtml_Wpllead extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_wpllead';
        $this->_blockGroup = 'mmd_wpl';
        $this->_headerText = Mage::helper('mmd_wpl')->__('WPL Development Leads');
        parent::__construct();
        $this->_removeButton('add');
    }
}
