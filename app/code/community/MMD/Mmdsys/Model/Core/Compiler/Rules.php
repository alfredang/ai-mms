<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Model_Core_Compiler_Rules
{
    /**
     * @var Mage_Core_Model_Config_Base
     */
    protected $_compileConfig;
    
    /**
     * @var string
     */
    protected $_includeDir;
    
    /**
     * @return Mage_Core_Model_Config_Base
     */
    public function getCompileConfig()
    {
        return $this->_compileConfig;
    }
    
    /**
     * @param Mage_Core_Model_Config_Base $config
     * @return MMD_Mmdsys_Model_Core_Compiler_Rules
     */
    public function setCompileConfig($config)
    {
        $this->_compileConfig = $config;
        return $this;
    }
    
    /**
     * @return string
     */
    public function getIncludeDir()
    {
        return $this->_includeDir;
    }
    
    /**
     * @param string $path
     * @return MMD_Mmdsys_Model_Core_Compiler_Rules
     */
    public function setIncludeDir($path)
    {
        $this->_includeDir = $path;
        return $this;
    }
    
    /**
     * @return MMD_Mmdsys_Model_Core_Compiler_Rules
     */
    public function init()
    {
        $this->_applyModulesRules();
        return $this; 
    }

    /**
     * Apply specific modules rules to the main config
     */
    protected function _applyModulesRules()
    {
        foreach ($this->getCompileConfig()->getNode('modules_rules')->children() as $module => $rules) {
            if (MMD_Mmdsys_Abstract_Service::get()->isModuleActive($module)) {
                foreach ($rules as $rule) {
                    $this->getCompileConfig()->getNode()->extendChild($rule);
                }
            }
        }
        unset($this->getCompileConfig()->getNode()->modules_rules);
    }
    
    /**
     * Removes some collected files
     * 
     * @return MMD_Mmdsys_Model_Core_Compiler_Rules
     */
    public function applyExcludeFilesRule()
    {
        foreach (array_keys($this->getCompileConfig()->getNode('exclude_files')->asArray()) as $exclusion) {
            $target = $this->getIncludeDir() . DS . $exclusion . '.php';
            if(@file_exists($target)) {
                MMD_Mmdsys_Abstract_Service::get()->filesystem()->rmFile($target);
            }
        }
        return $this;
    }
    
    /**
     * Replaces some collected classes with abstract rewrites
     * 
     * @return MMD_Mmdsys_Model_Core_Compiler_Rules
     */
    public function applyReplaceRule()
    {
        foreach (array_keys($this->getCompileConfig()->getNode('replace')->asArray()) as $replace) {
            $source = MMD_Mmdsys_Model_Rewriter_Abstract::getRewritesCacheDir().$replace.'.php';
            $target = $this->getIncludeDir().DS.$replace.'.php';
            if(@file_exists($source) && @file_exists($target)) {
                copy($source, $target);
            }
        }
        return $this;
    }
    
    /**
     * Removes some classes from collection
     * 
     * @param array $arrFiles Array with the data changes should be applied to.
     * @return array
     */
    public function applyExcludeClassesRule($arrFiles)
    {
        foreach ($this->getCompileConfig()->getNode('exclude_classes')->children() as $scope => $classes) {
            $excludes = array_keys($classes->asArray());
            foreach ($excludes as $exclude) {
                if (false !== $index = array_search($exclude, $arrFiles[$scope])) {
                    unset($arrFiles[$scope][$index]);
                }
            }
        }
        return $arrFiles;
    }
    
    /**
     * Removes compile scope from config
     * 
     * @return MMD_Mmdsys_Model_Core_Compiler_Rules
     */
    public function applyRemoveScopeRule()
    {
        $scopesToRemove = $this->getCompileConfig()->getNode('remove_scope')->asArray();
        if (!empty($scopesToRemove) && is_array($scopesToRemove)) {
            foreach (array_keys($scopesToRemove) as $scope) {
                $this->_removeScope($scope);
            }
        }
        return $this;
    }
    
    protected function _removeScope($scope)
    {
        unset($this->getCompileConfig()->getNode('includes')->$scope);
        unset($this->getCompileConfig()->getNode('exclude_classes')->$scope);
    }
    
    /**
     * Rename scope
     * 
     * @return MMD_Mmdsys_Model_Core_Compiler_Rules 
     */
    public function applyRenameScopeRule()
    {
        $scopesToRename = $this->getCompileConfig()->getNode('rename_scope')->asArray();
        if (!empty($scopesToRename) && is_array($scopesToRename)) {
            foreach ($scopesToRename as $scopeFrom => $scopeTo) {
                $this->_copyElement('includes', $scopeFrom, $scopeTo)
                     ->_copyElement('exclude_classes', $scopeFrom, $scopeTo);
                
                // remove original scope 
                $this->_removeScope($scopeFrom);
            }
        }
        return $this;
    }
    
    /**
     * Duplicate an existing config element
     * 
     * @param string $area Area to work with
     * @param string $oldName Old node name
     * @param string $newName New node name
     * 
     * @return MMD_Mmdsys_Model_Core_Compiler_Rules
     */
    protected function _copyElement($area, $oldName, $newName)
    {
        $parent = $this->getCompileConfig()->getNode($area);
        $newElement = clone $parent->$oldName;
        $elementClass = get_class($newElement);
        $newElement = new $elementClass(str_replace($oldName, $newName, $newElement->asXml()));
        $parent->extendChild($newElement);
        return $this;
    }
}