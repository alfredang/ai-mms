<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
abstract class MMD_Mmdsys_Abstract_Helper extends Mage_Core_Helper_Abstract 
implements MMD_Mmdsys_Abstract_Model_Interface
{
    /**
     * @return MMD_Mmdsys_Abstract_Service
     */
    public function tool()
    {
        return MMD_Mmdsys_Abstract_Service::get();
    }
    
    /**
     * @return Mage_Adminhtml_Helper_Data
     */
    public function getAdminhtmlHelper()
    {
        return Mage::helper('adminhtml');
    }
}