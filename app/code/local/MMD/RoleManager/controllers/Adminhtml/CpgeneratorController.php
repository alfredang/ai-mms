<?php
class MMD_RoleManager_Adminhtml_CpgeneratorController extends Mage_Adminhtml_Controller_Action
{
    protected $_allowedKeys = array(
        'coursedetails', 'aboutcourse', 'whatlearn', 'bgparta', 'bgpartb',
        'learningoutcomes', 'instructmethods', 'assessmethods', 'lusequencing',
        'courseoutline', 'entryreq', 'jobroles', 'lessonplan', 'cpvalidation',
    );

    public function indexAction()
    {
        $key = (string) $this->getRequest()->getParam('key', 'coursedetails');
        if (!in_array($key, $this->_allowedKeys, true)) {
            $key = 'coursedetails';
        }

        $this->loadLayout();
        $this->_setActiveMenu('dashboard');
        $this->_title('CP Generator');

        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('rolemanager/cpgenerator.phtml')
            ->setData('cp_key', $key);
        $this->getLayout()->getBlock('content')->append($block);
        $this->renderLayout();
    }

    protected function _isAllowed()
    {
        return true;
    }
}
