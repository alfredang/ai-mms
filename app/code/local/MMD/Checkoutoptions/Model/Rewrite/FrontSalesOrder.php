<?php
/**
 * Checkout Fields Manager
 *
 * @category:    MMD
 * @package:     MMD_Checkoutoptions
 * @version      2.9.2
 * @license:     
 * @copyright:   Copyright (c) 2013 MMD, Inc. (http://www.mmd.com)
 */
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Checkoutoptions_Model_Rewrite_FrontSalesOrder extends Mage_Sales_Model_Order
{
    protected $_cfmCustomFields;

    /**
     * Get CFM data for this order
     * 
     * @param bool $forceReload Forces tranport object to be reloaded. Default: false.
     * 
     * @return MMD_Checkoutoptions_Model_Transport
     */    
    public function getCustomFields($forceReload = false)
    {
        if(is_null($this->_cfmCustomFields) || $forceReload)
        {
            $this->_cfmCustomFields = Mage::getModel('checkoutoptions/transport')->loadByOrder($this);
        }
        return $this->_cfmCustomFields;
    }
}