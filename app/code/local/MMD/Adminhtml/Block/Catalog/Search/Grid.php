<?php
/**
 * Compact override of the Search Terms grid. Replaces the stock multi-line
 * Store column (website / group / store-view stacked) with a single-line
 * Branch column ("Singapore", "Malaysia", ...) so each search term renders
 * on one row.
 */
class MMD_Adminhtml_Block_Catalog_Search_Grid
    extends Mage_Adminhtml_Block_Catalog_Search_Grid
{
    protected function _prepareColumns()
    {
        parent::_prepareColumns();

        if ($this->getColumn('store_id')) {
            $this->removeColumn('store_id');
        }

        if (!Mage::app()->isSingleStoreMode()) {
            $this->addColumnAfter('store_id', array(
                'header'   => Mage::helper('catalog')->__('Branch'),
                'index'    => 'store_id',
                'renderer' => 'MMD_Adminhtml_Block_Widget_Grid_Column_Renderer_Branch',
                'sortable' => false,
            ), 'search_query');
        }

        return $this;
    }
}
