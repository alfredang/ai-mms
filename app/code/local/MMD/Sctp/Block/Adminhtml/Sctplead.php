<?php
class MMD_Sctp_Block_Adminhtml_Sctplead extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_sctplead';
        $this->_blockGroup = 'mmd_sctp';
        $this->_headerText = Mage::helper('mmd_sctp')->__('SCTP Program Leads');
        parent::__construct();
        $this->_removeButton('add');
    }
}
