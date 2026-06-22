<?php
class MMD_CourseFeedback_Block_Adminhtml_Feedbacklead extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_corporatelead';
        $this->_blockGroup = 'mmd_coursefeedback';
        $this->_headerText = Mage::helper('mmd_coursefeedback')->__('Course Feedback');
        parent::__construct();
        $this->_removeButton('add');
    }
}
