<?php
class MMD_Customised_Block_Adminhtml_Customisedlead extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_customisedlead';
        $this->_blockGroup = 'mmd_customised';
        $this->_headerText = Mage::helper('mmd_customised')->__('Customised Application Leads');
        parent::__construct();
        $this->_removeButton('add');
    }
}
