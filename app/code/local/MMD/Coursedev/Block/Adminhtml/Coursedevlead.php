<?php
class MMD_Coursedev_Block_Adminhtml_Coursedevlead extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_coursedevlead';
        $this->_blockGroup = 'mmd_coursedev';
        $this->_headerText = Mage::helper('mmd_coursedev')->__('Course Development Leads');
        parent::__construct();
        $this->_removeButton('add');
    }
}
