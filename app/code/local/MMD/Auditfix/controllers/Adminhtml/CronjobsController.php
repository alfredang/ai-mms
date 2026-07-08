<?php
/**
 * MMD_Auditfix_Adminhtml_CronjobsController
 *
 * Super-admin Cron Jobs monitor (/tigerdragon/cronjobs/):
 *   indexAction — every configured cron job (merged config crontab/jobs) with
 *                 its schedule + last run, a heartbeat check, the recent run
 *                 log from cron_schedule (Magento's own per-run record incl.
 *                 error messages), and a tail of the marketing pipeline log.
 *
 * Sidebar gates by super-admin role (menu.phtml); the page enforces the same
 * ACL resource as Audit Issues.
 */
class MMD_Auditfix_Adminhtml_CronjobsController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/mmd_auditfix');
    }

    public function indexAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('system');
        $this->_title('Cron Jobs');

        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('auditfix/cronjobs.phtml');
        $this->getLayout()->getBlock('content')->append($block);
        $this->renderLayout();
    }
}
