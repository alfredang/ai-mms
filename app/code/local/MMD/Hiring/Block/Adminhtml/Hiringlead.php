<?php
class MMD_Hiring_Block_Adminhtml_Hiringlead extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_hiringlead';
        $this->_blockGroup = 'mmd_hiring';
        $this->_headerText = (Mage::app()->getRequest()->getParam('type') === 'interns')
            ? Mage::helper('mmd_hiring')->__('Interns')
            : Mage::helper('mmd_hiring')->__('Hiring');
        parent::__construct();
        $this->_removeButton('add');
    }
}
