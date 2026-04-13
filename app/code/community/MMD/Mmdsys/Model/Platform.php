<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
final class MMD_Mmdsys_Model_Platform extends MMD_Mmdsys_Abstract_Model
{
    const PLATFORMFILE_SUFFIX = '.platform.xml';
    const CACHE_CLEAR_VERSION = '2.21.0';
    const DEFAULT_VAR_PATH    = 'var';
    
    /**
     * @var MMD_Mmdsys_Model_Platform
     */
    static protected $_instance;
    
    /**
     * @return MMD_Mmdsys_Model_Platform
     */
    static public function getInstance()
    {
        if (!self::$_instance) {
            self::$_instance = new self();
            self::$_instance->preInit();
        }
        return self::$_instance;
    }
    
    protected $_inited = false;
    
    protected $_modulesList; // Module_Name => array( 'module_path' => Module_Path, 'module_file' => Module_File )
    
    protected $_modules = array();
    
    protected $_version;
    
    /**
     * @var MMD_Mmdsys_Model_Service
     */
    protected $_service = array();
    
    protected $_moduleIgnoreList = array('MMD_Mmdinstall' => 0, 'MMD_Mmdsys' => 0, 'MMD_Aitprepare' => 0);
    
    protected $_mmdPrefixList = array('MMD_', 'AdjustWare_');
    
    protected $_moduleDirs = array('MMD', 'AdjustWare');
    
    protected $_needCorrection = false;
    
    protected $_adminError = '';
    
    protected $_adminErrorEventLoaded = false;
    
    protected $_isEnterprise;
    
    public function addAdminError($message)
    {
        $this->_adminError = $message;
        $this->renderAdminError();
    }
    
    public function renderAdminError($eventLoaded = false)
    {
        if ($eventLoaded) {
            $this->_adminErrorEventLoaded = true;
        }
        
        if ($this->_adminErrorEventLoaded && $this->_adminError) {
            $admin = Mage::getSingleton('admin/session');
            if ($admin->isLoggedIn()) {
                $session = Mage::getSingleton('adminhtml/session');
                /* @var $session Mage_Adminhtml_Model_Session */
                $session->addError($this->_adminError);
                $this->_adminError = '';
            }
        }
        return $this;
    }
    
    /**
     * @return array
     */
    public function getModuleDirs()
    {
        return $this->_moduleDirs;
    }
    
    /**
     * @return bool
     */
    public function isBlocked()
    {
        return $this->_block;
    }
    
    /**
     * @return array
     */
    public function getModules()
    {
        if (!$this->_modules) {
            $this->__init();
            $this->_generateModulesList();
        }
        return $this->_modules;
    }
    
    /**
     * @return array
     */
    public function getModuleKeysForced()
    {
        $modules = array();
        foreach($this->_modulesList as $moduleKey => $moduleData) {
            $modules[$moduleKey] = ('true' == (string)Mage::getConfig()->getNode('modules/' . $moduleKey . '/active'));
        }
        return $modules;
    }
    
    /**
     * @param string $key
     * @return MMD_Mmdsys_Model_Module
     */
    public function getModule($key)
    {
        $this->getModules();
        return isset($this->_modules[$key]) ? $this->_modules[$key] : null;
    }
    
    /**
     * @return MMD_Mmdsys_Model_License_Service
     */
    public function getService($for = 'default')
    {
        if (!isset($this->_service[$for])) {
            $this->_service[$for] = new MMD_Mmdsys_Model_Service();
            $this->_service[$for]->setServiceUrl($this->getServiceUrl());
        }
        return $this->_service[$for];
    }
    
    public function getVarPath()
    {
        return $this->hasData('var_path') ? trim($this->getData('var_path'), '\\/') : self::DEFAULT_VAR_PATH;
    }
    
    /**
     * @return string
     */
    public function getServiceUrl()
    {
        if ($url = $this->tool()->getApiUrl()) {
            return $url;
        }
        if ($url = $this->getData('_service_url')) {
            return $url;
        }
        $url = $this->getData('service_url');
        return $url ? $url : Mage::getStoreConfig('mmdsys/service/url');
    }
    
    /**
     * @return string
     */
    public function getVersion()
    {
        if (!$this->_version) {
            $this->_version = (string)Mage::app()->getConfig()->getNode('modules/MMD_Mmdsys/version'); 
        }
        return $this->_version;
    }
    
    public function preInit()
    {
        try {
            $this->_loadConfigFile();
        } catch (Exception $e) {
            $this->tool()->testMsg('Error on attempt of loading platform config file');
        }
    }
    
    protected function __init()
    {
        if (!$this->_inited) {
            $this->_inited = true;
            try {
                $this->_checkNeedCacheCleared();
                $this->reset();
            } catch (MMD_Mmdsys_Model_Core_Filesystem_Exception $exc) {
                $msg = "Error in the file: %s. Probably it does not have write permissions.";
                $this->addAdminError(MMD_Mmdsys_Abstract_Service::get()->getHelper()->__($msg, $exc->getMessage()));
            }
        }
    }
    
    protected function _checkNeedCacheCleared()
    {
        if (!Mage::app()->getUpdateMode() && version_compare($this->tool()->db()->dbVersion(), self::CACHE_CLEAR_VERSION, 'lt')) {
            $this->tool()->clearCache();
        }
    }
    
    /**
     * @return MMD_Mmdsys_Model_Platform
     */
    public function reset()
    {
        $this->_modules = array(); // to reinit all licensed modules after platform registration
        $this->getModules();
        $this->tool()->testMsg('Modules reseted after generating');
        return $this;
    }
    
    /**
     * @param string $moduleKey
     * @return bool
     */
    public function isIgnoredModule($moduleKey)
    {
        return isset($this->_moduleIgnoreList[$moduleKey]);
    }
    
    /**
     * @return MMD_Mmdsys_Model_Platform
     */
    protected function _loadConfigFile()
    {
        $path = $this->tool()->filesystem()->getMmdsysDir() . '/config.php';
        $this->tool()->testMsg('check config path: ' . $path);
        if (file_exists($path)) {
            include $path;
            if (isset($config) && is_array($config)) {
                $this->tool()->testMsg('loaded config:');
                $this->tool()->testMsg($config);
                $this->setData($config);
            }
        }
        return $this;
    }
    
    /**
     * @return MMD_Mmdsys_Model_Platform
     */
    protected function _generateModulesList()
    {
        $this->tool()->testMsg('Try to generate modules list!'); 
        $this->_createModulesList()
             ->_loadAllModules();

        $this->tool()->event('mmdsys_generate_modules_list_after');
        $this->tool()->testMsg('Modules list generated successfully');
        return $this;
    }
    
    /**
     * @return bool
     */
    public function isMagentoEnterprise()
    {
        if (is_null($this->_isEnterprise)) {
            $this->_isEnterprise = false;
            
            if (is_callable('Mage::getEdition')) {
                $this->_isEnterprise = (Mage::getEdition() == 'Enterprise');
            } else {
                $etcDir = $this->tool()->fileSystem()->getEtcDir();
                $eeModuleXmlFile = $etcDir . DS . 'Enterprise_Enterprise.xml';
                if (file_exists($eeModuleXmlFile)) {
                    try {
                        $eeModule = new SimpleXMLElement($eeModuleXmlFile, 0, true);
                        $val = $eeModule->modules->Enterprise_Enterprise->active;
                        $this->_isEnterprise = ((string)$val == 'true');
                    } catch (Exception $e) {}
                }
            }
        }
        return $this->_isEnterprise;
    }
    
    /**
     * Based on /code/local/MMD|AdjustWare subfolders
     * 
     * @return MMD_Mmdsys_Model_Platform
     */
    protected function _createModulesList()
    {
        if (is_null($this->_modulesList)) {
            $this->_modulesList = array();
            
            $mmdModulesDirs = $this->tool()->filesystem()->getMMDModulesDirs();
            foreach ($mmdModulesDirs as $mmdModuleDir) {
                if (@file_exists($mmdModuleDir) && @is_dir($mmdModuleDir)) {
                    $mmdModuleSubdirs = new DirectoryIterator($mmdModuleDir);
                    foreach ($mmdModuleSubdirs as $mmdModuleSubdir) {
                        // skip dots and svn folders
                        if (in_array($mmdModuleSubdir->getFilename(), $this->tool()->filesystem()->getForbiddenDirs())) {
                            continue;
                        }
                        
                        $moduleKey  = basename($mmdModuleDir) . "_" . $mmdModuleSubdir->getFilename();
                        if (!$this->isIgnoredModule($moduleKey)) {
                            $moduleFile = $this->tool()->filesystem()->getEtcDir() . "/{$moduleKey}.xml";
                            $this->_modulesList[$moduleKey] = array(
                                'module_path' => $mmdModuleSubdir->getPathname(),
                                'module_file' => @is_file($moduleFile) ? $moduleFile : null
                            );
                        }
                    }
                }
            }
        }
        return $this;
    }
    
    /**
     * Return list of all MMDs' modules or certain module info
     * 
     * @param string $module Module key
     * @return array
     */
    public function getModulesList($module = '')
    {
        if(!$module) {
            return $this->_modulesList;
        }
        return isset($this->_modulesList[$module]) ? $this->_modulesList[$module] : null;
    }
    
    /**
     * Load all modules which have main config file
     * 
     * @return MMD_Mmdsys_Model_Platform
     */
    protected function _loadAllModules()
    {
        foreach ($this->_modulesList as $moduleKey => $moduleData) {
            if($moduleData['module_file']) { // only if the config file for this module in /app/etc/modules does exist
                $this->_makeModuleByModuleFile($moduleKey, $moduleData['module_file']);
            }
        }
        return $this;
    }
    
    /**
     * Load certain module by using its main config file 
     * 
     * @param string $moduleKey
     * @param string $moduleFile
     * 
     * @return MMD_Mmdsys_Model_Module
     */
    protected function _makeModuleByModuleFile($moduleKey, $moduleFile)
    {
        $this->tool()->testMsg('Load module: ' . $moduleKey);
        $module = new MMD_Mmdsys_Model_Module();
        $module->loadByModuleFile($moduleFile, $moduleKey);

        return $this->_modules[$moduleKey] = $module;
    }

    /**
     * @param bool $value
     * @return MMD_Mmdsys_Model_Platform
     */
    public function setNeedCorrection($value = true)
    {
        $this->_needCorrection = $value;
        return $this;
    }

    /**
     * @return bool
     */
    public function isNeedCorrection()
    {
        return $this->_needCorrection;
    }
}
