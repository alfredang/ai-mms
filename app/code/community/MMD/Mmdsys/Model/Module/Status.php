<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
class MMD_Mmdsys_Model_Module_Status extends MMD_Mmdsys_Abstract_Model
{
    /**
     * @static
     * @var array
     */
    static protected $_statuses = array();
    
    /**
     * @var string
     */
    protected $_eventPrefix = 'mmdsys_module_status';
    
    /**
     * Static fabric interface to update statuses. Returns related status model instance
     * 
     * @static
     * @param string $moduleKey
     * @param bool $status
     * 
     * @return MMD_Mmdsys_Model_Module_Status
     */
    public static function updateStatus($moduleKey, $status)
    {
        if (!array_key_exists($moduleKey, self::$_statuses)) {
            self::$_statuses[$moduleKey] = new self();
            self::$_statuses[$moduleKey]
                ->load($moduleKey, 'module')
                ->setModule($moduleKey);
        }
        self::$_statuses[$moduleKey]
            ->setStatus((int)$status)
            ->save();
        return self::$_statuses[$moduleKey];
    }

    protected function _construct()
    {
        $this->_init('mmdsys/module_status');
    }
    
    /**
     * Prevents events in Mage_Core_Model_Abstract from launching
     * (compatibility with some modules).
     * 
     * @override
     * @return MMD_Mmdsys_Model_Module_Status
     */
    protected function _beforeSave()
    {
        return $this;
    }
    
    /**
     * Actualizes statuses table, clears db cache and prevents events
     * in Mage_Core_Model_Abstractfrom launching
     * (compatibility with some modules).
     * 
     * @return MMD_Mmdsys_Model_Module_Status
     */
    protected function _afterSave()
    {
        $this->getCollection()->clearTable();
        // $this->tool()->getCache()->remove('mmdsys_db_statuses'); // removed from 2.20
        return $this;
    }
}