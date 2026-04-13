<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 * @author Andrei
 */
class MMD_Mmdsys_Model_Rewriter_Autoload
{
    /**
     * @var MMD_Mmdsys_Model_Rewriter_Autoload
     */
    static protected $_instance;
    
    static protected $_registered = false;
    
    /**
     * @var array
     */
    protected $_rewriteConfig = array();
    
    /**
     * @var string
     */
    protected $_rewriteDir = '';
    
    private function __construct()
    {
        $this->_rewriteDir = MMD_Mmdsys_Model_Rewriter_Abstract::getRewritesCacheDir();
        $this->_readConfig();
    }
    
    /**
     * @return string
     */
    public function getRewriteDir()
    {
        return $this->_rewriteDir;
    }
    
    /**
     * Singleton implementation
     * 
     * @return MMD_Mmdsys_Model_Rewriter_Autoload
     */
    static public function instance()
    {
        if (!self::$_instance) {
            self::$_instance = new self();
        }
        return self::$_instance;
    }

    /**
     * @return array
     */
    public function getConfig()
    {
        return $this->_rewriteConfig;
    }

    /**
     * @return array
     */
    public function clearConfig()
    {
        $this->_rewriteConfig = array();
    }
    
    public function setupConfig()
    {
        $this->_readConfig();
    }
    
    static public function register($stopProcessing = false)
    {
        if (!$stopProcessing && !self::$_registered) {
            $rewriter = new MMD_Mmdsys_Model_Rewriter();
            $rewriter->preRegisterAutoloader();
            
            // unregistering all autoloaders to make our performing first
            $autoloaders = spl_autoload_functions();
            if ($autoloaders && is_array($autoloaders) && !empty($autoloaders)) {
                foreach ($autoloaders as $autoloader) {
                    spl_autoload_unregister($autoloader);
                }
            }
    
            // register our autoloader
            spl_autoload_register(array(self::instance(), 'autoload'), false);
            
            // register 1.3.1 and older autoloader
            if (version_compare(Mage::getVersion(),'1.3.1','le')) {
                spl_autoload_register(array(self::instance(), 'performStandardAutoload'), true);
            }
            
            // register back all unregistered autoloaders
            if ($autoloaders && is_array($autoloaders) && !empty($autoloaders)) {
                foreach ($autoloaders as $autoloader) {
                    spl_autoload_register($autoloader, (is_array($autoloader) && $autoloader[0] instanceof Varien_Autoload));
                }
            }
            self::$_registered = true;
        }
    }
    
    /**
     * Compatibility with Magento prior 1.3.2
     *
     *  @param string $class
     *  @return bool
     */
    public function performStandardAutoload($class)
    {
        if (function_exists('__autoload')) {
            return __autoload($class);
        }
        return Varien_Autoload::autoload($class);
    }
    
    /**
     * @param string $class
     * @return bool
     */
    public function autoload($class)
    {
        if (isset($this->_rewriteConfig[$class])) {
            $classFile = $this->_rewriteDir . $this->_rewriteConfig[$class] . '.php';
            try {
                return include $classFile;
            } catch (Exception $e) {
                if (!file_exists($classFile)) {
                    $rewriter = new MMD_Mmdsys_Model_Rewriter();
                    $rewriter->prepare();
                    return $this->autoload($class);
                }
                throw $e;
            }
        }
        return false;
    }
    
    protected function _readConfig()
    {
        /**
         * This config was created when creating rewrite files
         */
        $configFile = $this->_rewriteDir . 'config.php';
        if (file_exists($configFile)) {
            @include($configFile);
        }
        // $rewriteConfig was included from file
        if (isset($rewriteConfig)) {
            $this->_rewriteConfig = $rewriteConfig;
        }
    }
    
    /**
     * @param string $class
     * @return bool
     */
    public function hasClass( $class )
    {
        return isset($this->_rewriteConfig[$class]);
    }
}
