<?php
class MMD_Enhancedsalesgrid_Block_Sales_Order_Grid extends Mage_Adminhtml_Block_Sales_Order_Grid
{
    	 
	 protected function _getStore()
    {
        $storeId = (int) $this->getRequest()->getParam('store', 0);
        return Mage::app()->getStore($storeId);
    }

    /**
     * Apply the Manage-Courses-style filters from the URL:
     *   ?branch=<store_id>  → branch pill
     *   ?q=<text>           → General Search across Reg #, learner, course
     */
    protected function _prepareCollection()
    {
        parent::_prepareCollection();
        $collection = $this->getCollection();
        if (!$collection) {
            return $this;
        }
        $adapter = $collection->getConnection();

        // Branch (store) filtering is applied in the
        // sales_order_grid_collection_load_before observer so it covers every
        // code path that loads this collection — see MMD_Enhancedsalesgrid_Model_Observer.

        $q = trim((string) $this->getRequest()->getParam('q', ''));
        if ($q !== '') {
            $like = $adapter->quote('%' . $q . '%');
            $collection->getSelect()->where(
                'main_table.increment_id LIKE ' . $like
                . ' OR sales_flat_order.customer_email LIKE ' . $like
                . ' OR sales_flat_order.billing_name LIKE ' . $like
                . ' OR sales_flat_order_item.name LIKE ' . $like
            );
        }
        return $this;
    }

    /**
     * Filter by Course Date inside the serialised product_options blob.
     * The Course Date option is stored as free text like "13/14 May 2026"
     * with no normalised date column, so we approximate the [from, to]
     * range by LIKE-matching every "Mon YYYY" / "Month YYYY" string the
     * range covers (month granularity). Works on MySQL 5.7+.
     */
    protected function _filterCourseDateRange($collection, $column)
    {
        $cond = $column->getFilter()->getValue();
        if (!is_array($cond)) {
            return $this;
        }
        $fromTs = isset($cond['from']) && $cond['from'] ? strtotime($cond['from']) : null;
        $toTs   = isset($cond['to'])   && $cond['to']   ? strtotime($cond['to'])   : null;
        if (!$fromTs && !$toTs) {
            return $this;
        }
        if (!$fromTs) { $fromTs = $toTs; }
        if (!$toTs)   { $toTs   = $fromTs; }

        $shortMonths = array(1=>'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
        $longMonths  = array(1=>'January','February','March','April','May','June','July','August','September','October','November','December');

        $needles = array();
        $cursor  = strtotime(date('Y-m-01', $fromTs));
        $end     = strtotime(date('Y-m-01', $toTs));
        $guard   = 0;
        while ($cursor <= $end && $guard++ < 240) {
            $y = (int) date('Y', $cursor);
            $m = (int) date('n', $cursor);
            $needles[] = $shortMonths[$m] . ' ' . $y;
            $needles[] = $longMonths[$m]  . ' ' . $y;
            $cursor = strtotime('+1 month', $cursor);
        }
        if (!$needles) {
            return $this;
        }

        $adapter = $collection->getConnection();
        $likes   = array();
        foreach (array_unique($needles) as $needle) {
            $likes[] = 'sales_flat_order_item.product_options LIKE '
                . $adapter->quote('%' . $needle . '%');
        }
        $collection->getSelect()->where('(' . implode(' OR ', $likes) . ')');
        return $this;
    }
	 protected function _addCouponCodeMetodToFilter($collection, $column){
                $names = $column->getFilter()->getValue();
                $namesArray = explode(' ', $names);
                $cond = array();
                foreach ($namesArray as $item)
                {
                    $cond[] = 'sales_flat_order_address.street LIKe "%'.$item.'%" OR sales_flat_order_address.city LIKe "%'.$item.'%" OR sales_flat_order_address.region LIKe "%'.$item.'%" OR sales_flat_order_address.postcode LIKe "%'.$item.'%"' ;
                }
                $collection->getSelect()->where("(".implode(' OR ', $cond).")");
                return $this;
                //$collection->printlogquery(true);
                //die;
                
        } 
	protected function _prepareColumns()
    {
        $store = $this->_getStore();

        // 1. Reg #  — no filter (per spec, only the 6 listed columns filter)
        $this->addColumn('real_order_id', array(
            'header'       => Mage::helper('sales')->__('Reg #'),
            'width'        => '80px',
            'type'         => 'text',
            'index'        => 'increment_id',
            'filter'       => false,
            'filter_index' => 'main_table.increment_id',
        ));

        // 2. Reg Date — no filter
        $this->addColumn('created_at', array(
            'header'       => Mage::helper('sales')->__('Reg Date'),
            'index'        => 'created_at',
            'type'         => 'datetime',
            'width'        => '120px',
            'filter'       => false,
            'filter_index' => 'sales_flat_order.created_at',
        ));

        // 3. Learner Name — no filter
        $this->addColumn('billing_name', array(
            'header' => Mage::helper('sales')->__('Learner Name'),
            'index'  => 'billing_name',
            'width'  => '140px',
            'filter' => false,
        ));

        // 4. Learner Email — no filter
        $this->addColumn('customer_email', array(
            'header'       => Mage::helper('sales')->__('Learner Email'),
            'index'        => 'customer_email',
            'type'         => 'text',
            'width'        => '180px',
            'filter'       => false,
            'filter_index' => 'sales_flat_order.customer_email',
        ));

        // 5. Course
        $this->addColumn('products_ordered', array(
            'header'           => Mage::helper('sales')->__('Course'),
            'index'            => 'products_ordered',
            'renderer'         => 'enhancedsalesgrid/sales_order_grid_renderer_product',
            'type'             => 'textarea',
            'width'            => '260px',
            'column_css_class' => 'col-products-ordered',
            'filter_index'     => 'sales_flat_order_item.name',
        ));

        // 6. Course Date (renderer filters product_options to just Course Date).
        // Filter is a from/to date range parsed out of the option text.
        $this->addColumn('product_options', array(
            'header'                    => Mage::helper('sales')->__('Course Date'),
            'index'                     => 'product_options',
            'renderer'                  => 'MMD_Enhancedsalesgrid_Block_Sales_Order_Grid_Renderer_Options',
            'type'                      => 'date',
            'width'                     => '160px',
            'filter_index'              => 'sales_flat_order_item.product_options',
            'filter_condition_callback' => array($this, '_filterCourseDateRange'),
        ));

        // 7. Branch (store) — strip the trailing " Store View" suffix so the
        // column reads "Singapore", "Malaysia", etc.
        $branchOptions = array();
        foreach (Mage::getModel('core/store')->getCollection() as $_store) {
            $name = preg_replace('/\s*Store View\s*$/i', '', $_store->getName());
            $branchOptions[$_store->getId()] = $name;
        }
        $this->addColumn('store_id', array(
            'header'       => Mage::helper('sales')->__('Branch'),
            'index'        => 'store_id',
            'type'         => 'options',
            'width'        => '120px',
            'filter_index' => 'sales_flat_order.store_id',
            'options'      => $branchOptions,
        ));

        // 8. Fee (subtotal)
        $this->addColumn('subtotal', array(
            'header'        => Mage::helper('sales')->__('Fee'),
            'index'         => 'subtotal',
            'type'          => 'price',
            'currency'      => 'price',
            'currency_code' => $store->getBaseCurrency()->getCode(),
            'filter_index'  => 'sales_flat_order.subtotal',
            'width'         => '90px',
            'align'         => 'left',
        ));

        // 9. Tax Rate — derived from (tax_amount / subtotal) * 100
        $this->addColumn('tax_rate', array(
            'header'   => Mage::helper('sales')->__('Tax Rate'),
            'index'    => 'tax_amount',
            'renderer' => 'MMD_Enhancedsalesgrid_Block_Sales_Order_Grid_Renderer_Taxrate',
            'filter'   => false,
            'sortable' => false,
            'width'    => '70px',
            'align'    => 'left',
        ));

        // 10. Fee + Tax (base grand total) — no filter (only the 6 listed
        //     columns are filterable: Branch, Course, Course Date Range,
        //     Course Fee Range, Payment Method, Status).
        $this->addColumn('base_grand_total', array(
            'header'       => Mage::helper('sales')->__('Fee + Tax'),
            'index'        => 'base_grand_total',
            'type'         => 'currency',
            'currency'     => 'base_currency_code',
            'filter'       => false,
            'filter_index' => 'sales_flat_order.base_grand_total',
            'width'        => '90px',
            'align'        => 'left',
        ));

        // 10. Payment Method
        $connection = Mage::getSingleton('core/resource')->getConnection('core_read');
        $sql = "select method from " . Mage::getConfig()->getTablePrefix()
            . "sales_flat_order_payment group by method order by method";
        $rowsArray = $connection->fetchAll($sql);
        $payment_options = array();
        if ($rowsArray) {
            foreach ($rowsArray as $row) {
                $payment_options[$row['method']] = $row['method'];
            }
        }
        $this->addColumn('payment_method', array(
            'header'       => Mage::helper('sales')->__('Payment Method'),
            'index'        => 'payment_method',
            'type'         => 'options',
            'width'        => '110px',
            'options'      => $payment_options,
            'filter_index' => Mage::getConfig()->getTablePrefix() . 'sales_flat_order_payment.method',
        ));

        // 11. Status
        $this->addColumn('status', array(
            'header'       => Mage::helper('sales')->__('Status'),
            'index'        => 'status',
            'filter_index' => 'main_table.status',
            'type'         => 'options',
            'width'        => '90px',
            'options'      => Mage::getSingleton('sales/order_config')->getStatuses(),
        ));

        // 12. Action (View / Cancel)
        if (Mage::getSingleton('admin/session')->isAllowed('sales/order/actions/view')) {
            $this->addColumn('action', array(
                'header'   => Mage::helper('sales')->__('Action'),
                'width'    => '88px',
                'type'     => 'action',
                // No per-grid renderer — `type => action` resolves to
                // the global Mage_Adminhtml_..._Renderer_Action, which is
                // rewritten by MMD_Adminhtml's blocks rewrite to emit
                // icon buttons for every admin grid. Single source of
                // truth lives at
                // app/code/local/MMD/Adminhtml/Block/Widget/Grid/Column/Renderer/Action.php.
                'getter'   => 'getId',
                'actions'  => array(
                    array(
                        'caption' => Mage::helper('sales')->__('View'),
                        'url'     => array('base' => '*/sales_order/view'),
                        'field'   => 'order_id',
                    ),
                    array(
                        'caption' => Mage::helper('sales')->__('Cancel'),
                        'url'     => array('base' => '*/sales_order/cancel'),
                        'field'   => 'order_id',
                        'confirm' => Mage::helper('sales')->__('Cancel this registration?'),
                    ),
                ),
                'filter'    => false,
                'sortable'  => false,
                'index'     => 'stores',
                'is_system' => true,
            ));
        }

        $this->addExportType('*/*/exportCsv', Mage::helper('sales')->__('CSV'));
        $this->addExportType('*/*/exportExcel', Mage::helper('sales')->__('Excel XML'));

        return $this;
    }

    /**
     * Suppress the mass-action ("Actions … Submit") dropdown — the Registrations
     * grid uses per-row View/Cancel links instead.
     */
    protected function _prepareMassaction()
    {
        return $this;
    }
}
