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

class MMD_Checkoutoptions_Block_Orderedit_Edit extends Mage_Adminhtml_Block_Widget_Form_Container
{
    protected $_order_id = null;
    
    public function __construct()
    {
        $oFront = Mage::app()->getFrontController();
        
        $iOrderId = $oFront->getRequest()->getParam('order_id');
             
        $this->_order_id = $iOrderId;   

        parent::__construct();
    }
    
    public function getSaveUrl()
    {
        return $this->getUrl('*/index/ordersave', array('order_id' => $this->_order_id));
    }
    
    public function getBackUrl()
    {
        return $this->getUrl('adminhtml/sales_order/view', array('order_id'=>$this->_order_id));
    }
    
    public function getHeaderText()
    {
        return Mage::helper('checkoutoptions')->__('Edit Order Custom Data');
    }
    
	protected function _prepareLayout()
    {
        $this->setChild('form', $this->getLayout()->createBlock('checkoutoptions/orderedit_edit_form'));
        return Mage_Adminhtml_Block_Widget_Container::_prepareLayout();
    }
    
    
}