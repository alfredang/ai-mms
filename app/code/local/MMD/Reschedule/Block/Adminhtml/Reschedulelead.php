<?php
class MMD_Reschedule_Block_Adminhtml_Reschedulelead extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_corporatelead';
        $this->_blockGroup = 'mmd_reschedule';
        $this->_headerText = Mage::helper('mmd_reschedule')->__('Class Reschedule Requests');
        parent::__construct();
        $this->_removeButton('add');
    }
}
