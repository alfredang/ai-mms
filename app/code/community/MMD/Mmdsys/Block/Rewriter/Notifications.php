<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Block_Rewriter_Notifications extends MMD_Mmdsys_Abstract_Adminhtml_Block
{
    /**
     * @return bool
     */
    public function isShow()
    {
        $mmdsysCache = Mage::app()->useCache('mmdsys');
        if (!$mmdsysCache && in_array(1, Mage::app()->useCache())) {
            return true;
        }
        return false;
    }
    
    /**
     * Get cache management url
     *
     * @return string
     */
    public function getManageUrl()
    {
        return $this->getUrl('adminhtml/cache');
    }
    
    /**
     * ACL validation before html generation
     *
     * @return string
     */
    protected function _toHtml()
    {
        if (Mage::getSingleton('admin/session')->isAllowed('system/cache')) {
            return parent::_toHtml();
        }
        return '';
    }
}
