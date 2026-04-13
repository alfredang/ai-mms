<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
class MMD_Mmdsys_Abstract_Block extends Mage_Core_Block_Template 
implements MMD_Mmdsys_Abstract_Model_Interface
{
    /**
     * @return MMD_Mmdsys_Abstract_Service
     */
    public function tool()
    {
        return MMD_Mmdsys_Abstract_Service::get();
    }
}