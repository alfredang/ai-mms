<?php
class MMD_Enhancedsalesgrid_Model_Source_Fields
{
    /**
     * Retrieve options array
     *
     * @return array
     */
    public function toOptionArray()
    {
        $options = array();

         $options[] = array(
            'label' => 'Customer Email',
            'value' => 'customer_email',
        );
		
		$options[] = array(
            'label' => 'Products Ordered',
            'value' => 'products_ordered',
        );
		$options[] = array(
            'label' => 'Products Options',
            'value' => 'products_options',
        );
$options[] = array(
            'label' => 'Telephone',
            'value' => 'telephone',
        );
		$options[] = array(
            'label' => 'Zip Code',
            'value' => 'postcode',
        );
       $options[] = array(
            'label' => 'Payment Method',
            'value' => 'payment_method',
        );
		$options[] = array(
            'label' => 'Billing Name',
            'value' => 'billing_name',
        );
		
		$options[] = array(
            'label' => 'Shipping Name',
            'value' => 'shipping_name',
        );
		
		 $options[] = array(
            'label' => 'Shipping Address',
            'value' => 'shipping_address',
        );
		
		
		 $options[] = array(
            'label' => 'Total Price',
            'value' => 'subtotal',
        );
		 $options[] = array(
            'label' => 'Shipping Price',
            'value' => 'shipping_amount',
        );
		
		$options[] = array(
            'label' => 'G.T. (Base)',
            'value' => 'grand_total',
        );
		$options[] = array(
            'label' => 'G.T. (Purchased)',
            'value' => 'base_grand_total',
        );
        return $options;
    }
}
