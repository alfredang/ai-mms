<?php
/**
* @author MMD Team
* @copyright Copyright (c) 2012-2011 MMD (http://magemobiledesign.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Block_Adminhtml_Catalog_Product_Grid_Filter_Multiselect extends Mage_Adminhtml_Block_Widget_Grid_Column_Filter_Select
{
    public function getCondition()
    {
        if ('null' == $this->getValue())
        {
            return array('null' => true);
        }
        return array('finset' => $this->getValue());
    }
}