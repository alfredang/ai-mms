<?php
/**
* @author MMD Team
* @copyright Copyright (c) 2012-2011 MMD (http://magemobiledesign.com)
* @package MMD_Catalogmanagement
*/
class MMD_Catalogmanagement_Block_Adminhtml_Catalog_Product_Grid_Renderer_Thumb extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract
{
    public function render(Varien_Object $row)
    {
        try
        {
            $size    = Mage::helper('catalogmanagement')->getGridThumbSize();

            if (!$row->getThumbnail())
            {
                $product = Mage::getModel('catalog/product')->load($row->getEntityId());
                if ($product)
                {
                    if ($product->getThumbnail())
                    {
                        $row->setThumbnail($product->getThumbnail());
                    }
                }
            }

            $url     = Mage::helper('catalog/image')->init($row, 'thumbnail')->resize($size)->__toString();
            $zoomUrl = '';
            if (Mage::getStoreConfig('catalogmanagement/attr/zoom'))
            {
                $zoomUrl = Mage::helper('catalog/image')->init($row, 'thumbnail')->__toString();
            }
            if ($url)
            {
                $html  = '';
                if ($zoomUrl)
                {
                    $html .= '<a href="' . $zoomUrl . '" rel="lightbox[zoom' . $row->getId() . ']">';
                }
                $html .= '<img src="' . $url . '" alt="" width="' . $size . '" height="' . $size . '" />';
                $html .= '</a>';
                return $html;
            }
        } catch (Exception $e) { /* no file uploaded */ }
        return '';
    }
}