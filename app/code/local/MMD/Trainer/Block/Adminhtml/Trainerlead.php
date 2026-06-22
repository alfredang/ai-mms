<?php
class MMD_Trainer_Block_Adminhtml_Trainerlead extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_trainerlead';
        $this->_blockGroup = 'mmd_trainer';
        $this->_headerText = Mage::helper('mmd_trainer')->__('Trainer Application Leads');
        parent::__construct();
        $this->_removeButton('add');
    }
}
