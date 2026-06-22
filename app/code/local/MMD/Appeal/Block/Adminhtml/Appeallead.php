<?php
class MMD_Appeal_Block_Adminhtml_Appeallead extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_corporatelead';
        $this->_blockGroup = 'mmd_appeal';
        $this->_headerText = Mage::helper('mmd_appeal')->__('Assessment Appeals');
        parent::__construct();
        $this->_removeButton('add');
    }
}
