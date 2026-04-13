<?php
/**
 * Abstract module's subsystem model 
 *
 * @method string getStatus()
 * @method MMD_Mmdsys_Model_Module_Abstract setStatus(string $status)
 *
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
abstract class MMD_Mmdsys_Model_Module_Abstract extends MMD_Mmdsys_Abstract_Model
{
    const STATUS_UNKNOWN     = 'unknown';
    const STATUS_INSTALLED   = 'installed';
    const STATUS_UNINSTALLED = 'uninstalled';
    
    /**
     * @var MMD_Mmdsys_Model_Module
     */
    protected $_module;
    
    /**
     * Init model
     * 
     * @return MMD_Mmdsys_Model_Module_Abstract
     */
    public function init()
    {
        $this->setStatusUnknown();
        return $this;
    }
    
    /**
     * Add a number of errors to the module's errors storage
     * 
     * @param array $errors
     * @return MMD_Mmdsys_Model_Module_Abstract
     */
    public function addErrors( array $errors )
    {
        $this->getModule()->addErrors($errors);
        return $this;
    }
    
    /**
     * Add an error to the module's errors storage 
     *
     * @param string $error
     * @return MMD_Mmdsys_Model_Module_Abstract
     */
    public function addError( $error )
    {
        $this->getModule()->addError($error);
        return $this;
    }
    
    /**
     * Get all unique errors from the module's storage and optionally clear the storage
     * 
     * @param bool $clear
     * @return array
     */
    public function getErrors( $clear = false )
    {
        return $this->getModule()->getErrors($clear);
    }

    /**
     * Get platform instance
     * 
     * @return MMD_Mmdsys_Model_Platform
     */
    public function getPlatform()
    {
        return $this->tool()->platform();
    }
    
    /**
     * @param MMD_Mmdsys_Model_Module $module
     * @return MMD_Mmdsys_Model_Module_Install
     */
    public function setModule( MMD_Mmdsys_Model_Module $module )
    {
        $this->_module = $module;
        return $this;
    }
    
    /**
     * @return MMD_Mmdsys_Model_Module
     */
    public function getModule()
    {
        return $this->_module;
    }
    
    /**
     * Change current model status to the `installed` state
     * 
     * @return MMD_Mmdsys_Model_Module_Install
     */
    public function setStatusInstalled()
    {
        return $this->setStatus(self::STATUS_INSTALLED);
    }
    
    /**
     * Change current model status to the `unknown` state
     * 
     * @return MMD_Mmdsys_Model_Module_Install
     */
    public function setStatusUnknown()
    {
        return $this->setStatus(self::STATUS_UNKNOWN);
    }
    
    /**
     * Change current model status to the `ininstalled` state
     * 
     * @return MMD_Mmdsys_Model_Module_Install
     */
    public function setStatusUninstalled()
    {
        return $this->setStatus(self::STATUS_UNINSTALLED);
    }
    
    /**
     * Check whether module's status is `installed`
     * 
     * @return bool
     */
    public function isInstalled()
    {
        return $this->getStatus() == self::STATUS_INSTALLED;
    }
    
    /**
     * Check whether module's status is `unknown`
     * 
     * @return bool
     */
    public function isUnknown()
    {
        return $this->getStatus() == self::STATUS_UNKNOWN;
    }
    
    /**
     * Check whether module's status is `uninstalled`
     * 
     * @return bool
     */
    public function isUninstalled()
    {
        return $this->getStatus() == self::STATUS_UNINSTALLED;
    }
    
    /**
     * Check license status
     * 
     * @return MMD_Mmdsys_Model_Module_Abstract
     */
    abstract public function checkStatus();
}
