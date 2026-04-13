<?php
/**
 * Backward compatibility with some extensions
 * 
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Abstract_Adminhtml_Controller extends Mage_Adminhtml_Controller_Action
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