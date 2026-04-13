<?php
/**
* @author MMD Team
* @copyright Copyright (c) 2012-2011 MMD (http://magemobiledesign.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Model_System_Config_Source_Mode
{
    public function toOptionArray()
    {
        $options = array(
            array( 'value'  => 'single', 'label' => Mage::helper('catalogmanagement')->__('Single Cell') ),
            array( 'value'  => 'multi', 'label' => Mage::helper('catalogmanagement')->__('Multi Cell') ),
        );
        return $options;
    }
}