<?php
/**
 * Transactions grid — adds a Branch column (via joined store_id from
 * sales_flat_order) and filters by the active Branchscope store.
 */
class MMD_Enhancedsalesgrid_Block_Sales_Transactions_Grid extends Mage_Adminhtml_Block_Sales_Transactions_Grid
{
    protected function _prepareCollection()
    {
        parent::_prepareCollection();
        $collection = $this->getCollection();
        if (!$collection) {
            return $this;
        }

        // Join sales_flat_order EAGERLY here, under our own alias
        // `mmd_so` (so it can't collide with the `so` alias core adds
        // lazily in _renderFilters for the Order-ID column).
        //
        // Why not addOrderInformation('store_id') + where('so.store_id')?
        // Core defers that join to _renderFilters() (load time), but the
        // grid asks the collection for getSize() — the COUNT(*) query for
        // the pager — BEFORE the collection loads. The count select then
        // carries `WHERE so.store_id = ?` with no `so` join → SQLSTATE
        // 1054 "Unknown column 'so.store_id'", which blanked the entire
        // Transactions grid. Adding the join here puts it in BOTH the
        // count and the data query (getSelectCountSql keeps FROM/joins).
        $collection->getSelect()->joinLeft(
            array('mmd_so' => $collection->getTable('sales/order')),
            'mmd_so.entity_id = main_table.order_id',
            array('mmd_store_id' => 'store_id')
        );

        $storeId = (int) Mage::helper('branchscope')->getActiveStoreId();
        if ($storeId > 0) {
            $collection->getSelect()->where('mmd_so.store_id = ?', $storeId);
        }
        return $this;
    }

    protected function _prepareColumns()
    {
        parent::_prepareColumns();

        $branchOptions = array();
        foreach (Mage::getModel('core/store')->getCollection() as $_s) {
            if ((int) $_s->getId() === 0) { continue; }
            $branchOptions[(int) $_s->getId()] =
                preg_replace('/\s*Store View\s*$/i', '', $_s->getName());
        }

        $this->addColumnAfter('store_id', array(
            'header'       => Mage::helper('sales')->__('Branch'),
            'index'        => 'mmd_store_id',
            'type'         => 'options',
            'width'        => '110px',
            'options'      => $branchOptions,
            'filter_index' => 'mmd_so.store_id',
        ), 'increment_id');

        return $this;
    }
}
