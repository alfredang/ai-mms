<?php
class MMD_WorkflowGuides_Adminhtml_WorkflowguidesController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::helper('mmd_workflowguides')->isAllowed();
    }

    public function indexAction()
    {
        $this->loadLayout()
             ->_title($this->__('Workflow Guides'));
        $this->renderLayout();
    }
}
