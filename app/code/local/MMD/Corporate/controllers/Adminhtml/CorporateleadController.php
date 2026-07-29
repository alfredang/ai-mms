<?php
class MMD_Corporate_Adminhtml_CorporateleadController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/mmd_marketing/corporate_leads');
    }
    public function indexAction()
    {
        $this->loadLayout()->_setActiveMenu('mmd_marketing/corporate_leads')
            ->_title($this->__('Marketing'))->_title($this->__('Corporate Application Leads'));
        $this->_addContent($this->getLayout()->createBlock('mmd_corporate/adminhtml_corporatelead'));
        $this->renderLayout();
    }
    public function gridAction()
    {
        $this->loadLayout(false);
        $this->getResponse()->setBody($this->getLayout()->createBlock('mmd_corporate/adminhtml_corporatelead_grid')->toHtml());
    }

    public function massMailerliteAction()
    {
        $ids = $this->getRequest()->getParam('leads');
        if (!is_array($ids) || empty($ids)) {
            Mage::getSingleton('adminhtml/session')->addError($this->__('Please select at least one lead.'));
            $this->_redirect('*/*/');
            return;
        }
        $ml = Mage::helper('mmd_marketing/mailerlite');
        $sent = $skipped = $failed = 0;
        foreach ($ids as $id) {
            $lead = Mage::getModel('mmd_corporate/lead')->load((int) $id);
            if (!$lead->getId()) { continue; }
            $ml->subscribeLead($lead);
            switch ($lead->getMailerliteStatus()) {
                case 'sent':    $sent++;    break;
                case 'skipped':
                case 'unsubscribed':
                case 'blocked':      $skipped++; break;
                default:        $failed++;
            }
        }
        $session = Mage::getSingleton('adminhtml/session');
        if ($sent) { $session->addSuccess($this->__('%d lead(s) sent to MailerLite.', $sent)); }
        if ($skipped) { $session->addNotice($this->__('%d lead(s) skipped (unsubscribed previously, or MailerLite not configured).', $skipped)); }
        if ($failed) { $session->addError($this->__('%d lead(s) failed — see var/log/mailerlite.log.', $failed)); }
        $this->_redirect('*/*/');
    }
}
