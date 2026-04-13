<?php

abstract class MMD_Mmdsys_Abstract_Resource_Eav_Setup extends Mage_Eav_Model_Entity_Setup 
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