<?php
/**
* @author MMD Team
* @copyright Copyright (c) 2012-2011 MMD (http://magemobiledesign.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Helper_Mode extends Mage_Core_Helper_Abstract
{
    public function isMulti()
    {
        return ('multi' == Mage::getStoreConfig('catalogmanagement/editing/mode'));
    }
}