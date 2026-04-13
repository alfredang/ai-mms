<?php
/**
 * Checkout Fields Manager
 *
 * @category:    MMD
 * @package:     MMD_Checkoutoptions
 * @version      2.9.2
 * @license:     
 * @copyright:   Copyright (c) 2013 MMD, Inc. (http://www.mmd.com)
 */
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */


class MMD_Checkoutoptions_Model_Rewrite_FrontSalesOrderApiV2 extends Mage_Sales_Model_Order_Api_V2
{
    // overwrite parent
    public function info($orderIncrementId)
    {
        $result = parent::info($orderIncrementId);
        
        $result['mmd_order_custom_data'] = array();
        if ($result AND $result['order_id'])
        {
            $iStoreId = $result['store_id'];
            $oCheckoutoptions  = Mage::getModel('checkoutoptions/checkoutoptions');
            $aCustomAtrrList = $oCheckoutoptions->getOrderCustomData($result['order_id'], $iStoreId, true);
                              
			foreach ($aCustomAtrrList as $item) {
				$result['mmd_order_custom_data'][] = $item;
			}
                   
        }

        return $result;
    }
    
    // overwrite parent
    public function items($filters = null)
    {
        $result = parent::items($filters);
        
        if ($result AND is_array($result))
        {
            foreach ($result as $iKey => $aOrder)
            {
                $iStoreId = $aOrder['store_id'];
        
                $oCheckoutoptions  = Mage::getModel('checkoutoptions/checkoutoptions');
        
                $aCustomAtrrList = $oCheckoutoptions->getOrderCustomData($aOrder['order_id'], $iStoreId, true);
                
                foreach ($aCustomAtrrList as $item) {
					$result[$iKey]['mmd_order_custom_data'][] = $item;
				}
				//$result[$iKey]['mmd_order_custom_data'] = serialize($result[$iKey]['mmd_order_custom_data']);
            }
        }

        return $result;
    }
}