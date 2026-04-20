<?php
class MMD_RoleManager_Adminhtml_SeometadataController extends Mage_Adminhtml_Controller_Action
{
    public function indexAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('dashboard');
        $this->_title('SEO Metadata');

        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('rolemanager/seometadata.phtml');
        $this->getLayout()->getBlock('content')->append($block);
        $this->renderLayout();
    }

    protected function _isAllowed()
    {
        return true;
    }
}
