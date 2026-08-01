<?php
class MMD_Hiring_Block_Adminhtml_Hiringlead extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_hiringlead';
        $this->_blockGroup = 'mmd_hiring';
        $h = Mage::helper('mmd_hiring');
        switch ((string) Mage::app()->getRequest()->getParam('type')) {
            case 'interns':   $this->_headerText = $h->__('Interns'); break;
            case 'associate': $this->_headerText = $h->__('Associate Trainers'); break;
            default:          $this->_headerText = $h->__('Full Time Trainers');
        }
        parent::__construct();
        $this->_removeButton('add');
    }
}
