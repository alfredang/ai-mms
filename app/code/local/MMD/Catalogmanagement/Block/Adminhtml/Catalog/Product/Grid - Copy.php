<?php
/**
* @author Amasty Team
* @copyright Copyright (c) 2010-2011 Amasty (http://www.amasty.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Block_Adminhtml_Catalog_Product_Grid extends Mage_Adminhtml_Block_Catalog_Product_Grid
{
   protected function _prepareMassaction()
   {
        parent::_prepareMassaction();
        Mage::dispatchEvent('am_product_grid_massaction', array('grid' => $this)); 
   } 
}