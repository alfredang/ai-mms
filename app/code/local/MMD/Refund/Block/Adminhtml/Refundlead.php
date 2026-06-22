<?php
class MMD_Refund_Block_Adminhtml_Refundlead extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_corporatelead';
        $this->_blockGroup = 'mmd_refund';
        $this->_headerText = Mage::helper('mmd_refund')->__('Refund Requests');
        parent::__construct();
        $this->_removeButton('add');
    }
}
