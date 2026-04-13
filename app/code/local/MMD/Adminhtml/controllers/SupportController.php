<?php
/**
 * MMD
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the MMD EULA that is bundled with
 * this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://www.magemobiledesign.com/LICENSE-1.0.html
 *
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@magemobiledesign.com so we can send you a copy immediately.
 *
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade the extension
 * to newer versions in the future. If you wish to customize the extension
 * for your needs please refer to http://www.magemobiledesign.com/ for more information
 * or send an email to sales@magemobiledesign.com
 *
 * @category   MMD
 * @package    MMD_Adminhtml
 * @copyright  Copyright (c) 2013 MMD (http://www.magemobiledesign.com/)
 * @license    http://www.magemobiledesign.com/LICENSE-1.0.html
 */

/**
 * MMD Adminhtml extension
 *
 * @category   MMD
 * @package    MMD_Adminhtml
 * @author     MMD Dev Team <developers@magemobiledesign.com>
 */

class MMD_Adminhtml_SupportController extends  Mage_Adminhtml_Controller_Action
{
    public function indexAction()
    {
        $data = $this->getRequest()->getPost();
        $support = Mage::getModel('mmd/support');
        $support
            ->setName($data['name'])
            ->setEmail($data['email'])
            ->setSubject($data['subject'])
            ->setReason(isset($data['other_reason'])?$data['other_reason']:$data['reason'])
            ->setMessage($data['message']);
        try {
            $support->send();
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
            $this->_ajaxResponse($result);
            return;
        }
        $result['message'] = $this->__('Message sent');
        $this->_ajaxResponse($result);
    }

    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('system/config/mmd/support');
    }

    protected function _ajaxResponse($result = array())
    {
        $this->getResponse()->setBody(Zend_Json::encode($result));
        return;
    }

}