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
class MMD_Checkoutoptions_Model_Transport extends Varien_Object
{
    const ORDER_METHOD_NAME    = 'getOrderCustomData';
    const CUSTOMER_METHOD_NAME = 'getCustomerData';
    
    protected $_entityId = 0;
    protected $_entityType = '';
    
    /**
     * Set an appropriate entity id for internal use
     * @param int $entityId
     * @return MMD_Checkoutoptions_Model_Transport
     */
    protected function _setEntityId($entityId)
    {
        $this->_entityId = $entityId;
        return $this;
    }

    /**
     * Get an appropriate entity id for internal use
     * @return int
     */
    protected function _getEntityId()
    {
        return $this->_entityId;
    }
    
    /**
     * Set an appropriate entity type for internal use
     * @param string $entityType
     * @return MMD_Checkoutoptions_Model_Transport
     */
    protected function _setEntityType($entityType)
    {
        $this->_entityType = $entityType;
        return $this;
    }

    /**
     * Get an appropriate entity type for internal use
     * @return string
     */
    protected function _getEntityType()
    {
        return $this->_entityType;
    }

    /**
     * Loads CFM data for certain order
     * 
     * @param Mage_Sales_Model_Order $order
     * 
     * @return MMD_Checkoutoptions_Model_Transport
     */
    public function loadByOrder(Mage_Sales_Model_Order $order)
    {
        return $this->loadByOrderId($order->getId());
    }

    /**
     * Loads CFM data for certain order by its id
     * 
     * @param int $orderId
     * 
     * @return MMD_Checkoutoptions_Model_Transport
     */    
    public function loadByOrderId($orderId)
    {
        $this->_setEntityId($orderId);
        $this->_setEntityType(MMD_Checkoutoptions_Model_Checkoutoptions::TYPE_ORDER);
        return $this->_retrieveFieldsData($orderId, self::ORDER_METHOD_NAME);
    }
    
    /**
     * Loads CFM data for certain customer
     * 
     * @param Mage_Customer_Model_Customer $customer
     * 
     * @return MMD_Checkoutoptions_Model_Transport
     */
    public function loadByCustomer(Mage_Customer_Model_Customer $customer)
    {
        return $this->loadByCustomerId($customer->getId());
    }

    /**
     * Loads CFM data for certain customer by his id
     * 
     * @param int $customerId
     * 
     * @return MMD_Checkoutoptions_Model_Transport
     */    
    public function loadByCustomerId($customerId)
    {
        $this->_setEntityId($customerId);
        $this->_setEntityType(MMD_Checkoutoptions_Model_Checkoutoptions::TYPE_CUSTOMER);
        return $this->_retrieveFieldsData($customerId, self::CUSTOMER_METHOD_NAME);
    }
    
    /**
     * Retrieve and apply CFM data to Varien_Object
     * 
     * @param int $entityId Order or customer entity id
     * @param string $method Name of the method which should be used to get data
     * 
     * @return MMD_Checkoutoptions_Model_Transport
     */ 
    protected function _retrieveFieldsData($entityId, $method)
    {
        if ($entityId) {
            $fieldsData = Mage::getModel('checkoutoptions/checkoutoptions')->$method(
                $entityId,
                Mage::app()->getStore()->getId(),
                Mage::app()->getStore()->isAdmin()
            );
        }
    
        $data = array();
        foreach ($fieldsData as $fieldData) {
            $data[$fieldData['code']] = $fieldData;
        }
        return $this->setData($data);
    }
    
    /**
     * Save current transport data for associated entity
     * 
     * @return MMD_Checkoutoptions_Model_Transport
     * @refactor This method should be refactored as the module resource base will be refactored
     */
    public function save()
    {
        Mage::getModel('MMD_Checkoutoptions_Model_Checkoutoptions')->purgeData($this->_getEntityType(), $this->_getEntityId());
        foreach ($this->getData() as $attributeCode => $fieldData) {
            if ($value = $this->_parseValue($fieldData)) {
                Mage::getModel('checkoutoptions/'.$this->_getEntityType().'_field')->setData(array(
                    'entity_id'    => $this->_getEntityId(),
                    'attribute_id' => (isset($fieldData['id']) ? $fieldData['id'] : Mage::getModel('eav/entity_atribute')->loadByCode('mmd_checkout', $attributeCode)),
                    'value'        => $value
                ))->save();
            }
        }
        return $this;
    }
    
    /**
     * Parses some optional ways of data storage befire saving
     * @param mixed $fieldData
     * @return string
     * @refactor This method should be refactored as the module resource base will be refactored
     */
    protected function _parseValue($fieldData = null)
    {
        $value = '';
        if (!empty($fieldData)) {
            if (is_array($fieldData)) {
                if (isset($fieldData['rawval'])) {
                    if (is_array($fieldData['rawval'])) {
                        $value = implode(',', $fieldData['rawval']);   
                    } else {
                        $value = $fieldData['rawval'];
                    }
                } else {
                    $value = implode(',', $fieldData);
                }
            } else {
                $value = $fieldData;
            }
        }
        return $value;
    }
}