<?php
class MMD_Enhancedsalesgrid_Block_Sales_Order_Grid extends Mage_Adminhtml_Block_Sales_Order_Grid
{
    	 
	 protected function _getStore()
    {
        $storeId = (int) $this->getRequest()->getParam('store', 0);
        return Mage::app()->getStore($storeId);
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
       
		// Draw the default columns
        //parent::_prepareColumns();
		$store = $this->_getStore();
        // Add the selected columns if they are enabled
        $enabled_options = Mage::getStoreConfig('enhancedsalesgrid/options/columns_to_show');
        $enabled_options = explode(',', $enabled_options);

		 $this->addColumn('real_order_id', array(
            'header'=> Mage::helper('sales')->__('Order #'),
            'width' => '80px',
            'type'  => 'text',
            'index' => 'increment_id',
			'filter_index' => 'main_table.increment_id',
        ));
		 $this->addColumn('created_at', array(
            'header' => Mage::helper('sales')->__('Purchased On'),
            'index' => 'created_at',
            'type' => 'datetime',
            'width' => '100px',
			'filter_index'=>'sales_flat_order.created_at'
        ));
		if(in_array('customer_email', $enabled_options)) {
            $this->addColumn('customer_email', array(
                'header' => Mage::helper('sales')->__('Customer Email'),
                'index' => 'customer_email',
                'type' => 'textarea',
				'width' => '100px',
				'filter_index'=>'sales_flat_order.customer_email'
            ));
        }
		
        if(in_array('products_ordered', $enabled_options)) {
            $this->addColumn('products_ordered', array(
                'header' => Mage::helper('sales')->__('Products Ordered'),
                'index' => 'products_ordered',
                'renderer'  => 'enhancedsalesgrid/sales_order_grid_renderer_product',
                'type' => 'textarea',
                'width' => '200px',
				'filter_index'=>'sales_flat_order_item.name'
            ));
			
			
			
        }
		  if(in_array('products_options', $enabled_options)) {
		
		$this->addColumn('product_options', array(
                'header' => Mage::helper('sales')->__('Products Options'),
                'index' => 'product_options',
                'renderer'  => 'MMD_Enhancedsalesgrid_Block_Sales_Order_Grid_Renderer_Options',				
                'type' => 'textarea',
                'width' => '200px',
				'filter_index'=>'sales_flat_order_item.product_options'
            ));
		  }
        if(in_array('telephone', $enabled_options)) {
            $this->addColumn('telephone', array(
                'header' => Mage::helper('sales')->__('Telephone'),
                'index' => 'telephone',                
                'type' => 'textarea',
                'width' => '100px',				
            ));
        }
		

		 if(in_array('postcode', $enabled_options)) {
            $this->addColumn('postcode', array(
                'header' => Mage::helper('sales')->__('Zip Code'),
                'index' => 'postcode',                
                'type' => 'textarea',
                'width' => '100px',				
            ));
        }
		
		
		
		if(in_array('billing_name', $enabled_options)) {
		
		$this->addColumn('billing_name', array(
            'header' => Mage::helper('sales')->__('Bill to Name'),
            'index' => 'billing_name',
        ));
		}
		
			
		
	/*	if(in_array('shipping_name', $enabled_options)) {
        $this->addColumn('shipping_name', array(
            'header' => Mage::helper('sales')->__('Ship to Name'),
            'index' => 'shipping_name',
        ));
		}
		
		if(in_array('shipping_address', $enabled_options)) {
            $this->addColumn('shipping_address', array(
                'header' => Mage::helper('sales')->__('Shipping Address'),
                'index' => 'shipping_address',                
                'type' => 'textarea',
                'width' => '100px',
				 "filter_condition_callback" => array($this, '_addCouponCodeMetodToFilter'),
            ));
        }*/
		
		
		   $this->addColumnAfter('store_id',array(
              'header' => 'Website',
              'index' => 'store_id',
              'type'  => 'options',
              'width' => '150px',
			  'filter_index'=>'sales_flat_order.store_id',
              'options'   => Mage::getModel('core/store')->getCollection()->toOptionHash(),

      ),'shipping_name');
		
		
		if(in_array('base_grand_total', $enabled_options)) {
		 $this->addColumn('base_grand_total', array(
            'header' => Mage::helper('sales')->__('G.T. (Base)'),
            'index' => 'base_grand_total',
            'type'  => 'currency',
            'currency' => 'base_currency_code',
			'filter_index'=>'sales_flat_order.base_grand_total'
        ));
		}
	if(in_array('grand_total', $enabled_options)) {
        $this->addColumn('grand_total', array(
            'header' => Mage::helper('sales')->__('G.T. (Purchased)'),
            'index' => 'grand_total',
            'type'  => 'currency',
            'currency' => 'order_currency_code',
        ));
	}
	
	
	
	
		if(in_array('shipping_amount', $enabled_options)) {
            $this->addColumn('shipping_amount', array(
                'header' => Mage::helper('sales')->__('Shipping Price'),
                'index' => 'shipping_amount',
                'type' => 'price',
				'currency' => 'price',
				'filter_index'=>'sales_flat_order.shipping_amount',
			    'currency_code' => $store->getBaseCurrency()->getCode(),
            ));
        }
		
		 if(in_array('subtotal', $enabled_options)) {
            $this->addColumn('subtotal', array(
                'header' => Mage::helper('sales')->__('Total Price'),
                'index' => 'subtotal',
                'type' => 'price',
				'currency' => 'price',
			    'currency_code' => $store->getBaseCurrency()->getCode(),
				'filter_index'=>'sales_flat_order.subtotal'
            ));
        }
		
		
		if(in_array('payment_method', $enabled_options)) {
		
		
$connection = Mage::getSingleton('core/resource')->getConnection('core_read');
$sql = "select method from ".Mage::getConfig()->getTablePrefix()."sales_flat_order_payment group by method order by method";
$rowsArray = $connection->fetchAll($sql); // return all rows
  $payment_options = array();
	if($rowsArray)
	{	
		foreach($rowsArray as $row)			{
			
			$payment_options[$row['method']] = $row['method'];
		}
	}   
		
		
		
            $this->addColumn('payment_method', array(
                'header' => Mage::helper('sales')->__('Payment Method'),
                'index' => 'payment_method',                
                'type' => 'options',
                'width' => '100px',
				'options' => $payment_options,
				'filter_index'=>Mage::getConfig()->getTablePrefix().'sales_flat_order_payment.method'
            ));
        }
		
		
		$this->addColumn('status', array(
            'header' => Mage::helper('sales')->__('Status'),
            'index' => 'status',
			'filter_index'=>'main_table.status',
            'type'  => 'options',
            'width' => '70px',
            'options' => Mage::getSingleton('sales/order_config')->getStatuses(),
        ));
		
		
		if (Mage::getSingleton('admin/session')->isAllowed('sales/order/actions/view')) {
            $this->addColumn('action',
                array(
                    'header'    => Mage::helper('sales')->__('Action'),
                    'width'     => '50px',
                    'type'      => 'action',
                    'getter'     => 'getId',
                    'actions'   => array(
                        array(
                            'caption' => Mage::helper('sales')->__('View'),
                            'url'     => array('base'=>'*/sales_order/view'),
                            'field'   => 'order_id'
                        )
                    ),
                    'filter'    => false,
                    'sortable'  => false,
                    'index'     => 'stores',
                    'is_system' => true,
            ));
        }
        $this->addRssList('rss/order/new', Mage::helper('sales')->__('New Order RSS'));

        $this->addExportType('*/*/exportCsv', Mage::helper('sales')->__('CSV'));
        $this->addExportType('*/*/exportExcel', Mage::helper('sales')->__('Excel XML'));
		
		
		
        $this->sortColumnsByOrder();

        return $this;
    }
}
