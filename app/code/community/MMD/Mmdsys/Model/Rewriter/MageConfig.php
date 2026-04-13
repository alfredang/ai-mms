<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
class MMD_Mmdsys_Model_Rewriter_MageConfig
{
    
    static private $_instance;
    
    /**
    * 
    * @return MMD_Mmdsys_Model_Rewriter_MageConfig
    */
    static public function get()
    {
        if (!self::$_instance)
        {
            self::$_instance = new self;
        }
        return self::$_instance;
    }
    
    /**
    * 
    * @var Varien_Simplexml_Config
    */
    protected $_config;
    
    private function __construct()
    {
        $moduleFiles = glob(BP.'/app/etc/modules/*.xml');
        $unsortedConfig = new Varien_Simplexml_Config();
        $unsortedConfig->loadString('<config/>');
        $fileConfig = new Varien_Simplexml_Config();

        foreach($moduleFiles as $filePath) {
            $fileConfig->loadFile($filePath);
            $unsortedConfig->extend($fileConfig);
        }

        // create sorted config [only active modules]
        #$sortedConfig = new Varien_Simplexml_Config();
        #$sortedConfig->loadString('<config><modules/></config>');

        $fileConfig = new Varien_Simplexml_Config();
        foreach ($unsortedConfig->getNode('modules')->children() as $moduleName => $moduleNode) {
            if('true' === (string)$moduleNode->active) {
                $codePool = (string)$moduleNode->codePool;
                $configPath = BP.'/app/code/'.$codePool.'/'.uc_words($moduleName,'/').'/etc/config.xml';
                $fileConfig->loadFile($configPath);
                $unsortedConfig->extend($fileConfig);
            }
        }
        $this->_config = $unsortedConfig;
    }
    
    
    /**
    * 
    * @return Varien_Simplexml_Config
    */
    public function getConfig()
    {
        return $this->_config;
    }
    
}