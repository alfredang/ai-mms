<?php
class MMD_Reindex_Adminhtml_ReindexlogController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/system/mmd_reindex_logs');
    }

    public function indexAction()
    {
        $this->loadLayout()
            ->_setActiveMenu('system/mmd_reindex_logs')
            ->_title($this->__('System'))->_title($this->__('Reindex Logs'));
        $this->_addContent($this->getLayout()->createBlock('mmd_reindex/adminhtml_reindexlog'));
        $this->renderLayout();
    }

    public function gridAction()
    {
        $this->loadLayout(false);
        $this->getResponse()->setBody(
            $this->getLayout()->createBlock('mmd_reindex/adminhtml_reindexlog_grid')->toHtml()
        );
    }
}
