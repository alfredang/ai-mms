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
class MMD_Checkoutoptions_Block_Rewrite_FrontSalesOrderView  extends Mage_Sales_Block_Order_View
{
	public function _construct()
    {
    	parent::_construct();
        $this->setTemplate('mmdcommonfiles/design--frontend--base--default--template--sales--order--view.phtml');
    }
        
    public function getOrderCustomData()
    {
        $iStoreId = $this->getOrder()->getStoreId();

        $oFront = Mage::app()->getFrontController();
        
        $iOrderId = $oFront->getRequest()->getParam('order_id');
        
        $oCheckoutoptions  = Mage::getModel('checkoutoptions/checkoutoptions');

        $aCustomAtrrList = $oCheckoutoptions->getOrderCustomData($iOrderId, $iStoreId, false, true);

        return $aCustomAtrrList;
    }
}
?>