<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Abstract_Adminhtml_Block extends Mage_Adminhtml_Block_Template
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
     * @return MMD_Mmdsys_Abstract_Helper
     */
    protected function _mmdhelper($type = 'Data')
    {
        return $this->tool()->getHelper($type);
    }
}