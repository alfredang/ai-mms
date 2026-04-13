<?php
class RS_Cash_Helper_Data extends Mage_Core_Helper_Abstract {
 const XML_PATH_ENABLED   = 'confirmorder/confirmorder/enabled';

    public function isEnabled()
    {
        return Mage::getStoreConfig( self::XML_PATH_ENABLED );
    }

    
}