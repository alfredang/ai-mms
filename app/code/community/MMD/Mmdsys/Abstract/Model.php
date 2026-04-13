<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
abstract class MMD_Mmdsys_Abstract_Model extends Mage_Core_Model_Abstract 
implements MMD_Mmdsys_Abstract_Model_Interface
{
    /**
     * @var string
     */
    protected $_objectUid;
    
    /**
     * @return string
     */
    public function getObjectUid()
    {
        if (!$this->_objectUid) {
            $this->_objectUid = md5(uniqid(microtime()));
        }
        return $this->_objectUid;
    }
    
    /**
     * @return MMD_Mmdsys_Abstract_Service
     */
    public function tool()
    {
        return MMD_Mmdsys_Abstract_Service::get($this);
    }
    
    /**
     * @param string $const Constant name
     * @param bool $translate
     * @param array $args
     * 
     * @return string
     */
    protected function _strHelper($const, $translate = true, $args = array())
    {
        return $this->_mmdhelper('Strings')->getString($const, $translate, $args);
    }
    
    /**
     * @param string $type
     * 
     * @return MMD_Mmdsys_Abstract_Helper
     */
    protected function _mmdhelper($type = 'Data')
    {
        return $this->tool()->getHelper($type);
    }
}