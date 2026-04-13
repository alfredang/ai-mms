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
abstract class MMD_Checkoutoptions_Model_Field_Abstract extends Mage_Core_Model_Abstract
{
    protected $_eventObject = 'field';
    
    protected $_attribute;
    
    protected $_fieldType;
    
    public function getFieldType()
    {
        return $this->_fieldType;
    }
    
    public function getAttribute()
    {
        if(is_null($this->_attribute) && $this->getAttributeId())
        {
            $this->_attribute = Mage::getModel('eav/entity_attribute')->load($this->getAttributeId());
        }
        return $this->_attribute;
    }
    
    public function getAttributeCode()
    {
        return $this->getAttribute()->getAttributeCode();
    }
}