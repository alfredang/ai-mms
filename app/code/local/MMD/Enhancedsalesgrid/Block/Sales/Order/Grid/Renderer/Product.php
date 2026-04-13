<?php
class MMD_Enhancedsalesgrid_Block_Sales_Order_Grid_Renderer_Product extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Text
{
    /**
    * Render product details
    *
    * @param   Varien_Object $row
    * @return  string
    */
    public function render(Varien_Object $row)
    {
        return nl2br($row->getProductsOrdered());
    }
}