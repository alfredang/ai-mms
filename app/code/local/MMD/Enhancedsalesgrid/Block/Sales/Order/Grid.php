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

        // q-filter handling moved to MMD_Enhancedsalesgrid_Model_Observer::
        // salesOrderGridCollectionLoadBefore. Mage_Adminhtml_Block_Widget_Grid::
        // _prepareCollection (which parent::_prepareCollection() above ends up
        // calling) already invokes $collection->load() — so any where() added
        // here lands AFTER the row-load query has executed. The observer fires
        // strictly before the SQL runs, so the WHERE actually filters.
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
        if ($this->_isExport && Mage::app()->getDefaultStoreView()->getCode() === 'malaysia') {
            return $this->_prepareMalaysiaExportColumns();
        }
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
     * Malaysia CSV / Excel export — the accounting columns for the 8% SST (Mr Saeid, 15 Oct 2026), in his order.
     * No payment columns: Malaysia is booking-only and payments are recorded offline by the Malaysia team.
     * The my_* fields are added by the observer for Malaysia export requests only; the on-screen grid and the
     * Singapore export keep the columns above.
     */
    protected function _prepareMalaysiaExportColumns()
    {
        $h = Mage::helper('sales');
        $cols = array(
            'real_order_id'   => array('Reg #', 'increment_id'),
            'created_at'      => array('Reg Date', 'created_at', 'datetime'),
            'billing_name'    => array('Learner Name', 'billing_name'),
            'customer_email'  => array('Learner Email', 'customer_email'),
            'my_reg_type'     => array('Registration Type', 'my_payment_info', 'text', '_myRegType'),
            'my_company'      => array('Company Name', 'my_payment_info', 'text', '_myCompany'),
            'my_course_codes' => array('Course Code', 'my_course_codes'),
            'products_ordered'=> array('Course Title', 'products_ordered', 'text', '_myCourseTitle'),
            'product_options' => array('Course Date', 'product_options', 'text', '_myPlain'),
            'my_participants' => array('Participants', 'my_participants', 'text', '_myInt'),
            'my_subtotal'     => array('Subtotal (before discount)', 'my_subtotal', 'text', '_myMoney'),
            'discount_amount' => array('Discount', 'discount_amount', 'text', '_myMoney'),
            'my_net'          => array('Subtotal after Discount', 'my_subtotal', 'text', '_myNet'),
            'my_tax_percent'  => array('SST Rate', 'my_tax_percent', 'text', '_myRate'),
            'tax_amount'      => array('SST Amount', 'tax_amount', 'text', '_myMoney'),
            'grand_total'     => array('Estimated Total (incl. SST)', 'grand_total', 'text', '_myMoney'),
            'my_payment_method' => array('Payment Method', 'my_payment_method'),
            'status'          => array('Registration Status', 'status', 'options'),
        );
        foreach ($cols as $id => $c) {
            $col = array('header' => $h->__($c[0]), 'index' => $c[1], 'type' => isset($c[2]) ? $c[2] : 'text');
            if (isset($c[3])) {
                $col['frame_callback'] = array($this, $c[3]);
            }
            if ($id === 'product_options') {
                $col['renderer'] = 'MMD_Enhancedsalesgrid_Block_Sales_Order_Grid_Renderer_Options';
            }
            if ($id === 'status') {
                $col['options'] = Mage::getSingleton('sales/order_config')->getStatuses();
            }
            $this->addColumn($id, $col);
        }
        return $this;
    }

    protected function _myInfo($row)
    {
        $info = @unserialize((string) $row->getData('my_payment_info'), array('allowed_classes' => false));
        return is_array($info) ? $info : array();
    }

    public function _myRegType($v, $row)
    {
        $info = $this->_myInfo($row);
        $type = isset($info['registration_type']) ? $info['registration_type'] : '';
        return $type === 'company' ? 'Company-sponsored' : ($type === 'individual' ? 'Self-sponsored' : '');
    }

    public function _myCompany($v, $row)
    {
        $info = $this->_myInfo($row);
        return isset($info['company_name']) ? trim($info['company_name']) : '';
    }

    public function _myCourseTitle($v, $row)
    {
        // "1 x AI for Accounting (C104)" -> "AI for Accounting"
        $titles = array();
        foreach (preg_split('/\R/', (string) $row->getData('products_ordered')) as $line) {
            $titles[] = trim(preg_replace(array('/^\d+\s+x\s+/', '/\s+\([^()]*\)$/'), '', $line));
        }
        return implode(', ', array_filter($titles));
    }

    public function _myPlain($v)
    {
        // Course Date renderer output ("13/14 May 2026<br/>…", "------") -> plain text
        $v = html_entity_decode(str_replace('<br/>', ', ', (string) $v), ENT_QUOTES, 'UTF-8');
        return $v === '------' ? '' : $v;
    }

    public function _myInt($v)
    {
        return (string) (int) round((float) $v);
    }

    public function _myMoney($v)
    {
        return number_format((float) $v, 2, '.', '');
    }

    public function _myNet($v, $row)
    {
        return $this->_myMoney((float) $row->getData('my_subtotal') + (float) $row->getData('discount_amount'));
    }

    public function _myRate($v)
    {
        return (float) $v > 0 ? rtrim(rtrim(number_format((float) $v, 2, '.', ''), '0'), '.') . '%' : '0%';
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
