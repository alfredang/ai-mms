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
class MMD_Checkoutoptions_Model_Order_Field extends MMD_Checkoutoptions_Model_Field_Abstract
{
    protected $_eventPrefix = 'mmdcfm_order_field';
    
    protected $_fieldType = 'order';

    protected function _construct()
    {
        $this->_init('checkoutoptions/order_field');
    }
}