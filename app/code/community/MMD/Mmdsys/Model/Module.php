<?php
/**
 * Main module model
 *
 * @method bool getAccess()
 * @method bool getValue() 
 * @method string getFile()
 * @method string getLabel()
 * @method string getKey()
 *
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
final class MMD_Mmdsys_Model_Module extends MMD_Mmdsys_Abstract_Model
{
    const PACKAGE_FILE = 'package.xml';
    const DEFAULT_CODEPOOL = 'local';
    
    /**
     * Errors storage
     * 
     * @var array
     */
    protected $_errors = array(); 
    
    /**
     * Status correction necessity flag
     * 
     * @var bool
     */
    protected $_needCorrection = false;
    
    /**
     * @var MMD_Mmdsys_Model_Module_Install
     */
    protected $_install;
    
    /**
     * @var MMD_Mmdsys_Model_Module_Info_Abstract
     */
    protected $_info;
    
    /**
     * @return MMD_Mmdsys_Model_Platform
     */
    public function getPlatform()
    {
        return $this->tool()->platform();
    }
    
    /**
     * Add an error to the storage
     * 
     * @param string $error
     * @return MMD_Mmdsys_Model_Module
     */
    public function addError( $error )
    {
        $this->_errors[] = $error;
        return $this;
    }
    
    /**
     * Add a number of errors to the storage
     * 
     * @param $errors
     * @return MMD_Mmdsys_Model_Module
     */
    public function addErrors( array $errors )
    {
        foreach ($errors as $error)
        {
            $this->addError($error);
        }
        return $this;
    }
    
    /**
     * Get all unique errors from the storage and optionally clear the storage
     * 
     * @param bool $clear Do clear errors storage on complete?
     * @return array
     */
    public function getErrors( $clear = false )
    {
        $result = $this->_errors;
        if ($clear)
        {
            $this->_errors = array();
        }
        return array_unique($result);
    }
    
    /**
     * Add all current errors to the session
     * 
     * @param $translator
     * @param Mage_Adminhtml_Model_Session $session
     * @return bool
     */
    public function produceErrors( $translator , Mage_Adminhtml_Model_Session $session = null )
    {
        if (!$session)
        {
            $session = $this->tool()->getInteractiveSession();
        }
        if (!$session)
        {
            $session = Mage::getSingleton('adminhtml/session');
        }
        /* @var $session Mage_Adminhtml_Model_Session */
        foreach ($this->getErrors() as $error)
        {
            if (!is_array($error))
            {
                $error = (array)$error;
            }
            $msg = array_shift($error);
            $session->addError($translator->__($msg));
        }
        return !empty($this->_errors);
    }

    /**
     * Reload the module from an appropriate install and/or module file.
     * 
     * @return MMD_Mmdsys_Model_Module
     */
    public function reset()
    {
        $this->unsAccess();
        $this->tool()->testMsg('Reset by module file: '.$this->getFile());
        $this->loadByModuleFile($this->getFile());
        return $this;
    }

    /**
     * Load the module using the main module config file form /etc/modules folder
     * 
     * @param string $path Path to the module xml file
     * @param string $key Module key
     * @return MMD_Mmdsys_Model_Module
     */
    public function loadByModuleFile( $path , $key = null )
    {
        if (!$key) {
            $key = basename($path, '.xml');
        }

        $this->addData(array(
            'key'       => $key,
            'available' => true ,
            'file'      => $path ,
        ))->_updateByModuleFile()
          ->_createInstall()
          ->_checkCorrectionStatus();
        return $this;
    }
    
    /**
     * @return MMD_Mmdsys_Model_Module
     */
    protected function _updateByModuleFile()
    {
        if (null === $this->getAccess()) {
            $path = $this->getFile();
            $key  = $this->getKey();
            if (file_exists($path)) {
                $xml  = simplexml_load_file($path);
                $this->tool()->testMsg('Update module by config file: '.$key);
    
                if (!$this->getLabel()) {
                    $this->setLabel((string)$xml->modules->$key->self_name ? (string)$xml->modules->$key->self_name : $key);
                }
                
                $this->setCodepool((string)$xml->modules->$key->codePool);
                
                if (!$this->getPlatform()->getCheckAllowed()) {
                    $access = $this->tool()->filesystem()->checkWriteable($path);
                } else {
                    $access = true;
                }
                $this->setValue('true' == (string)$xml->modules->$key->active)
                     ->setAccess($access);
            } else {
                $this->setValue(false)
                     ->setCodepool(self::DEFAULT_CODEPOOL)
                     ->setAccess(false);
            }
        }
        return $this;
    }
    
    /**
     * Init and return the install model
     * 
     * @return MMD_Mmdsys_Model_Module
     */
    protected function _createInstall()
    {
        if (!$this->_install) {
            $this->_install = new MMD_Mmdsys_Model_Module_Install();
            $this->_install
                ->setModule($this)
                ->init()
                ->checkStatus();
        }
        return $this;
    }
    
    /**
     * Check whether the module needs correction
     * 
     * @return MMD_Mmdsys_Model_Module
     */
    protected function _checkCorrectionStatus()
    {
        if(version_compare($this->tool()->db()->dbVersion(), '2.15.6', 'ge'))
        {
            $dbStatus  = $this->tool()->db()->getStatus($this->getKey());
            $xmlStatus = $this->getValue();
            if($dbStatus !== $xmlStatus)
            {
                $this->_needCorrection = true;
                $this->tool()->platform()->setNeedCorrection();
            }
        }

        return $this;
    }
    
    /**
     * Whether the module needs correction?
     * 
     * @return bool
     */
    public function isNeedCorrection()
    {
        return $this->_needCorrection;
    }
    
    /**
     * @return MMD_Mmdsys_Model_Module_Install
     */
    public function getInstall()
    {
        return $this->_install;
    }

    /**
     * @return MMD_Mmdsys_Model_Module_Info_Abstract
     */
    public function getInfo()
    {
        if (is_null($this->_info) && $this->getKey()) {
            try {
                $this->_info = MMD_Mmdsys_Model_Module_Info_Factory::getModuleInfo($this, $this->getCodepool());
            } catch (MMD_Mmdsys_Model_Module_Info_Exception $e) {
                $this->tool()->testMsg($e->getMessage());
            }
        }
        return $this->_info;
    }
}