<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Model_Module_Info_Factory
{
    /**
     * @var array
     */
    protected static $_sources = array(
        'Package', // package info file
        'Config',  // main config.xml file 
        'Fallback' // this model should be used if no other sources of info have been found
    );
    
    /**
     * @param MMD_Mmdsys_Model_Module $module Module entity
     * @param string $source Source type
     * @param string $codepool Module codepool. Default: local
     * 
     * @return MMD_Mmdsys_Model_Module_Info_Abstract
     * @throws MMD_Mmdsys_Model_Module_Info_Exception
     */
    public static function getModuleInfoFromSource(MMD_Mmdsys_Model_Module $module, $source, $codepool = MMD_Mmdsys_Model_Module::DEFAULT_CODEPOOL)
    {
        if (!in_array($source, self::$_sources)) {
            throw new MMD_Mmdsys_Model_Module_Info_Exception ('Incorrect module info source type. Module: ' . $moduleKey . '. Source: ' . $source);
        }
        $class = 'MMD_Mmdsys_Model_Module_Info_'.$source;
        return new $class($module, $codepool);
    }
    
    /**
     * Get module info from the first available source
     * 
     * @param MMD_Mmdsys_Model_Module $module Module entity
     * @param string $codepool Module codepool. Default: local
     * 
     * @return MMD_Mmdsys_Model_Module_Info_Abstract
     * @throws MMD_Mmdsys_Model_Module_Info_Exception
     */
    public static function getModuleInfo(MMD_Mmdsys_Model_Module $module, $codepool = MMD_Mmdsys_Model_Module::DEFAULT_CODEPOOL)
    {
        foreach (self::$_sources as $source) {
            $info = self::getModuleInfoFromSource($module, $source, $codepool);
            if ($info->isLoaded()) {
                return $info;
            }
        }
        throw new MMD_Mmdsys_Model_Module_Info_Exception ('No module info sources available. Module: ' . $moduleKey);
    }
}