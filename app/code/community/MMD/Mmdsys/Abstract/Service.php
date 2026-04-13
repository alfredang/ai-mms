<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
final class MMD_Mmdsys_Abstract_Service
{
    /**
     * @var MMD_Mmdsys_Abstract_Service
     */
    static private $_instance;
    
    /**
     * @var MMD_Mmdsys_Abstract_Model
     */
    protected $_currentObject;
    
    /**
     * @var string
     */
    protected $_realBaseUrl;
    
    /**
     * @var MMD_Mmdsys_Abstract_Version
     */
    protected $_versionComparer;
    
    /**
     * @var string
     */
    protected $_mmdUrl = '';
    
    /**
     * @var array
     */
    protected $_singletones = array();

    /**
     * @return MMD_Mmdsys_Abstract_Service
     */
    static public function get($object = null)
    {
        if (!self::$_instance) {
            self::$_instance = new self;
        }
        return self::$_instance->setCurrentObject($object);
    }
    
    /**
     * @return MMD_Mmdsys_Abstract_Version
     */
    public function getVersionComparer()
    {
        if (!$this->_versionComparer) {
            $this->_versionComparer = new MMD_Mmdsys_Abstract_Version();
        }
        return $this->_versionComparer;
    }
    
    /**
     * @return MMD_Mmdsys_Model_Platform
     */
    public function platform()
    {
        return MMD_Mmdsys_Model_Platform::getInstance();
    }
    
    /**
     * @param $object
     * @return MMD_Mmdsys_Abstract_Service
     */
    public function setCurrentObject($object)
    {
        if ($object instanceof MMD_Mmdsys_Abstract_Model) {
            $this->_currentObject = $object;
        } else {
            $this->_currentObject = null;
        }
        return $this;
    }
    
    /**
     * @param mixed $object
     * @param string $var
     * 
     * @return string
     */
    public function toPhpArray($object = null, $var = 'info')
    {
        $result = array();
        if (is_array($object)) {
            $data = $object;
        } else {
            $object = $object ? $object : $this->_currentObject;
            $data = $object->getData();
        }
        
        foreach ($data as $key => $value) {
            if (is_scalar($value)) {
                $result[] = "\t'" . $key . "' => '" . addcslashes($value, "'") . "'";
            }
        }
        
        $res = join(",\n", $result);
        if (!is_null($var)) {
            $res = '$' . $var . " = array(\n" . $res . "\n);\n";
        }
        return $res;
    }
    
    public function testMsg($msg, $trace = false)
    {
        #Mage::log($msg, false, 'mmdsys.log', true);
    }
    
    /**
     * @param string $name Module name
     * @return bool
     */
    public function isModuleActive($name)
    {
        $val = Mage::getConfig()->getNode('modules/' . $name . '/active');
        return 'true' == (string)$val;
    }
    
    /**
     * @param string $class
     * 
     * @return mixed
     */
    protected function _getSingleton($class)
    {
        if(!isset($this->_singletones[$class]) || !$this->_singletones[$class]) {
            $this->_singletones[$class] = new $class();
        }
        return $this->_singletones[$class];
    }
    
    /**
     * @return MMD_Mmdsys_Model_Core_Filesystem
     */
    public function filesystem()
    {
        return $this->_getSingleton('MMD_Mmdsys_Model_Core_Filesystem');
    }
    
    /**
     * @return MMD_Mmdsys_Model_Core_Database
     */
    public function db()
    {
        return $this->_getSingleton('MMD_Mmdsys_Model_Core_Database');
    }
    
    /**
     * @return MMD_Mmdsys_Model_Core_Cache
     */
    public function getCache()
    {
        return $this->_getSingleton('MMD_Mmdsys_Model_Core_Cache');
    }

    /**
     * Flush cache storage, re-init magento config, apply updates
     * 
     * @return MMD_Mmdsys_Abstract_Service
     */
    public function clearCache()
    {
        $this->getCache()->flush();
        return $this;
    }
    
    /**
     * @param $name
     * @param $data
     * @return MMD_Mmdsys_Abstract_Service
     */
    public function event($name, $data = array())
    {
        Mage::app()->loadAreaPart(Mage_Core_Model_App_Area::AREA_GLOBAL, Mage_Core_Model_App_Area::PART_EVENTS);
        Mage::dispatchEvent($name, $data);
        return $this;
    }
    
    /**
     * @return Zend_Db_Adapter_Abstract
     */
    protected function _getReadConnection()
    {
        $resource = Mage::getSingleton('core/resource');
        return $resource->getConnection('core_read');
    }
    
    /**
     * @return Zend_Db_Adapter_Abstract
     */
    public function getReadConnection()
    {
        return $this->_getReadConnection();
    }
    
    /**
     * @return Zend_Db_Adapter_Abstract
     */
    protected function _getWriteConnection()
    {
        $resource = Mage::getSingleton('core/resource');
        return $resource->getConnection('core_write');
    }
    
    /**
     * @return Zend_Db_Adapter_Abstract
     */
    public function getWriteConnection()
    {
        return $this->_getWriteConnection();
    }
    
    protected function _getUrlFromSource()
    {
        $conn = $this->_getReadConnection();
        $table = Mage::getModel('core/config_data')->getResource()->getMainTable();
        $select = $conn->select()
                    ->from($table, array('value'))
                    ->where('path = ?', 'web/unsecure/base_url')
                    ->where('scope_id = ?', 0)
                    ->where('scope = ?', 'default');
        return $conn->fetchOne($select);
    }
    
    public function getRealBaseUrl($clearDomain = true)
    {
        if (!$this->_realBaseUrl) {
            $this->_realBaseUrl = $this->_getUrlFromSource();
        }
        return $clearDomain ? $this->cleanDomain($this->_realBaseUrl) : $this->_realBaseUrl;
    }

    public function isMagentoVersion($sourceVersion, $mageVersion = null)
    {
        $mageVersion = $mageVersion ? $mageVersion : Mage::getVersion();
        return $this->getVersionComparer()->isMagentoVersion($sourceVersion, $mageVersion);
    }
    
    public function getApiUrl()
    {
        if ($this->platform()->hasData('_api_url')) {
            return $this->platform()->getData('_api_url');
        }
        $url = 'https://www.mmd.com/api/xmlrpc/';
        if (false === strpos($url, 'MMD_SERVICE_URL')) {
            return $url;
        }
    }
    
    public function getMMDUrl()
    {
        if (!$this->_mmdUrl) {
            $this->_mmdUrl = 'https://www.mmd.com/en/'; // default value
            $url = 'https://www.mmd.com/en/';
            if (false === strpos($url, 'MMD_STORE_URL')) {
                $this->_mmdUrl = $url;
            }
        }
        return $this->_mmdUrl;
    }
    
    /**
     * @return MMD_Mmdsys_Abstract_Helper
     */
    public function getHelper($type = 'Data', $module = 'MMD_Mmdsys')
    {
        $class = $module . '_Helper_' . $type;  
        return $this->_getSingleton($class);
    }
    
    /**
     * @return MMD_Mmdsys_Helper_License
     */
    public function getSetupHelper($module)
    {
    	if ($module && is_string($module) && file_exists($this->filesystem()->getLocalDir().str_replace('_', DS, $module) . DS . 'Helper' . DS . 'License.php')) {
        	$key = $module;
        } else {
            $key = 'MMD_Mmdsys';
        }

        return $this->getHelper('License', $key);
    }
    
    /**
     * Check whether PHP works in cli mode
     * 
     * @return bool
     */
    public function isPhpCli()
    {
        return (bool)('cli' == @php_sapi_name());
    }
    
    /**
     * Safely unserializes a string IF it contains a serialized data 
     * 
     * @param string $string
     * @return mixed
     */
    public function unserialize($string)
    {
        // before trying to unserialize we are replacing error_handler with another one to catch E_NOTICE run-time error
        $this->setTemporaryErrorException();
        $tmpValue = $string;
        try {
            $result = unserialize($string);
        }
        catch (ErrorException $e) {
            //restore old data value
            $result = $tmpValue;
        }
        $this->restorePreviousErrorHandler();
        return $result;
    }
    
    /**
     * @see MMD_Mmdsys_Abstract_Service::unserialize
     */
    public function setTemporaryErrorException()
    {
        $a = set_error_handler(function ($a, $b, $c, $d) { throw new ErrorException($b, 0, $a, $c, $d); }, E_ALL);
    }
    
    /**
     * @see MMD_Mmdsys_Abstract_Service::unserialize
     */
    public function restorePreviousErrorHandler()
    {
        restore_error_handler();
    }
}