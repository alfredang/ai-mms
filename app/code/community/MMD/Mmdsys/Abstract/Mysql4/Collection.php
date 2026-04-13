<?php

abstract class MMD_Mmdsys_Abstract_Mysql4_Collection extends Mage_Core_Model_Mysql4_Collection_Abstract  
implements MMD_Mmdsys_Abstract_Model_Interface
{
    
    /**
     * 
     * @return MMD_Mmdsys_Abstract_Service
     */
    public function tool()
    {
        return MMD_Mmdsys_Abstract_Service::get();
    }
    
}