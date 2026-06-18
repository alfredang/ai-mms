<?php
class MMD_Enhancedsalesgrid_Model_Observer
{

	public function salesOrderGridCollectionLoadBefore(Varien_Event_Observer $observer)
    {

        $collection = $observer->getEvent()->getOrderGridCollection();

        $select = $collection->getSelect();

        // Branch (store) filter for the Registrations grid.
        // Resolution order: ?store= URL param > admin session > Singapore (1).
        // ?store=0 means "All Store Views" (no filter).
        // Legacy ?branch= bookmarks still work via the alias below.
        $req   = Mage::app()->getRequest();
        $route = $req->getRouteName() . '/' . $req->getControllerName() . '/' . $req->getActionName();
        if (strpos($route, 'adminhtml/sales_order/') === 0) {
            // Backwards-compat: translate legacy ?branch= into ?store= on the
            // request object so the helper (and downstream code) sees one
            // canonical param. ?branch=all → ?store=0.
            $rawBranch = $req->getParam('branch', null);
            if ($rawBranch !== null && $req->getParam('store', null) === null) {
                if ((string) $rawBranch === 'all') {
                    $req->setParam('store', 0);
                } elseif (ctype_digit((string) $rawBranch)) {
                    $req->setParam('store', (int) $rawBranch);
                }
            }

            $storeId = (int) Mage::helper('branchscope')->getActiveStoreId();
            if ($storeId > 0) {
                $select->where('main_table.store_id = ?', $storeId);
            }
        }

        // Add the selected columns if they are enabled
        $enabled_options = Mage::getStoreConfig('enhancedsalesgrid/options/columns_to_show');
        $enabled_options = explode(',', $enabled_options);

        if(in_array('products_ordered', $enabled_options) || in_array('products_options', $enabled_options)) {
            $table_sales_flat_order_item = Mage::getSingleton('core/resource')->getTableName('sales/order_item');
            $select->joinLeft(
                $table_sales_flat_order_item,
                'main_table.entity_id = '.$table_sales_flat_order_item.'.order_id',
                array(
                    'product_options',
                    'products_ordered' => 'GROUP_CONCAT(DISTINCT ROUND(qty_ordered), " x ", name, " (", sku, ")" SEPARATOR "'.PHP_EOL.'")',
                    'order_tax_percent' => 'MAX('.$table_sales_flat_order_item.'.tax_percent)',
                )
            );
            //$select->group('main_table.entity_id');
        }

		$feilds = array();
		 if(in_array('subtotal', $enabled_options)) {
           $feilds[]="subtotal";
        }

        if(in_array('customer_email', $enabled_options)) {
		$feilds[]="customer_email";
		}
		 if(in_array('shipping_amount', $enabled_options)) {
		$feilds[]="shipping_amount";
		}
		// Always pull tax + discount so the Tax Rate column renders correctly.
		$feilds[] = 'tax_amount';
		$feilds[] = 'discount_amount';
			
        /* if($feilds) {*/
		 $table_sales_flat_order = Mage::getSingleton('core/resource')->getTableName('sales/order');
            $select->joinLeft(
                $table_sales_flat_order,
                'main_table.entity_id = '.$table_sales_flat_order.'.entity_id',$feilds
                
            );
       /* }*/
		
				
		if(in_array('shipping_address', $enabled_options) || in_array('telephone', $enabled_options)) {
            $shipping_address = Mage::getSingleton('core/resource')->getTableName('sales_flat_order_address');
            $select->joinLeft(
                $shipping_address,
                'main_table.entity_id = '.$shipping_address.'.parent_id AND address_type="shipping"',
                array('telephone','postcode','shipping_address' => 'CONCAT(IF(street IS NULL, "--", street),", ", IF(city IS NULL, "--", city),", ",IF(region IS NULL, "--", region),", ",IF(country_id IS NULL, "--", country_id),", ",IF(postcode IS NULL, "--", postcode))')
            );
            //$select->group('main_table.entity_id');
        }
		
		
				
		if(in_array('payment_method', $enabled_options)) {
            $payment_method = Mage::getSingleton('core/resource')->getTableName('sales_flat_order_payment');
            $select->joinLeft(
                $payment_method,
                'main_table.entity_id = '.$payment_method.'.parent_id',
                array('payment_method' => 'method')
            );
           
        }
		 $select->group('main_table.entity_id');

		$select->distinct(true);

        // General Search (`?q=`) — Reg #, learner name (denormalised
        // on the grid table as billing_name), customer email, and
        // course name (sales_flat_order_item.name). MUST be added
        // here, not in the Grid block's _prepareCollection: Magento's
        // Widget_Grid::_prepareCollection calls $collection->load()
        // BEFORE control returns to the subclass, so a where() added
        // in the block would only land on subsequent getSize() count
        // queries — the main row-list query had already executed
        // unfiltered. This observer fires inside load(), before the
        // SQL runs, so the WHERE actually filters.
        if (strpos($route, 'adminhtml/sales_order/') === 0) {
            $q = trim((string) $req->getParam('q', ''));
            if ($q !== '') {
                $adapter = $collection->getConnection();
                $like = $adapter->quote('%' . $q . '%');
                $select->where(
                    'main_table.increment_id LIKE ' . $like
                    . ' OR sales_flat_order.customer_email LIKE ' . $like
                    . ' OR main_table.billing_name LIKE ' . $like
                    . ' OR sales_flat_order_item.name LIKE ' . $like
                );
            }
        }
    }
}
