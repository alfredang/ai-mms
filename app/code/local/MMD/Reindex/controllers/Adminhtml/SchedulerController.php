<?php
class MMD_Reindex_Adminhtml_SchedulerController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/system/mmd_reindex_scheduler');
    }

    public function indexAction()
    {
        $this->loadLayout()
            ->_setActiveMenu('system/mmd_reindex_scheduler')
            ->_title($this->__('System'))->_title($this->__('Reindex Scheduler'));
        $this->_addContent($this->getLayout()->createBlock('mmd_reindex/adminhtml_scheduler'));
        $this->renderLayout();
    }

    public function runAction()
    {
        $session = Mage::getSingleton('adminhtml/session');
        try {
            $res  = Mage::getModel('mmd_reindex/cron')->reindexAll();
            $fail = array_filter($res, function ($v) { return strpos($v, 'fail') === 0; });
            if (!empty($fail)) {
                $session->addError($this->__('Reindex finished with %s error(s) of %s — see var/log/mmd_reindex.log.', count($fail), count($res)));
            } else {
                $session->addSuccess($this->__('Reindex complete — %s index(es) rebuilt.', count($res)));
            }
        } catch (Exception $e) {
            Mage::logException($e);
            $session->addError($e->getMessage());
        }
        $this->_redirect('*/*/');
    }

    public function saveScheduleAction()
    {
        $this->_validateFormKey();
        $expr    = (string) $this->getRequest()->getParam('schedule', '0 3 * * *');
        $allowed = array('', '0 3 * * *', '0 3,15 * * *', '0 3 * * 0', '0 * * * *');
        if (!in_array($expr, $allowed, true)) {
            $expr = '0 3 * * *';
        }
        Mage::getModel('core/config')->saveConfig('crontab/mmd_reindex/schedule', $expr, 'default', 0);
        Mage::app()->getCacheInstance()->cleanType('config');
        Mage::getSingleton('adminhtml/session')->addSuccess($this->__('Reindex schedule updated.'));
        $this->_redirect('*/*/');
    }
}
