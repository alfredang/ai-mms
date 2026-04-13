<?php
/**
* @author MMD Team
* @copyright Copyright (c) 2012-2011 MMD (http://magemobiledesign.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Adminhtml_AttributeController extends Mage_Adminhtml_Controller_Action
{
    public function saveAction()
    {
        $attributes = Mage::app()->getRequest()->getParam('pattribute', array());

        // will store columns by admin users, if necessary
        $extraKey = '';
        if (Mage::getStoreConfig('catalogmanagement/attr/byadmin'))
        {
            $extraKey = Mage::getSingleton('admin/session')->getUser()->getId();
        }

        $config = Mage::getModel('core/config');
        $config->saveConfig('catalogmanagement/attributes/ongrid' . $extraKey, implode(',', array_keys($attributes)));
        $config->cleanCache();
        
        $backUrl = Mage::app()->getRequest()->getParam('backurl');
        if (!$backUrl)
        {
            $backUrl = Mage::helper('core/url')->getUrl('adminhtml/catalog/product');
        }
        $this->getResponse()->setRedirect($backUrl);
    }
}