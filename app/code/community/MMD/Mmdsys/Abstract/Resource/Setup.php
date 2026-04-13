<?php

abstract class MMD_Mmdsys_Abstract_Resource_Setup extends Mage_Core_Model_Resource_Setup 
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