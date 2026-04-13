<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
abstract class MMD_Mmdsys_Abstract_Mysql4 extends Mage_Core_Model_Mysql4_Abstract 
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