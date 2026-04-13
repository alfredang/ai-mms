<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Model_Core_Compiler_Process extends Mage_Compiler_Model_Process
{
    /**
     * @var MMD_Mmdsys_Model_Core_Compiler_Rules
     */
    protected $_rulesProcessor;
    
    /**
     * @return MMD_Mmdsys_Model_Core_Compiler_Rules
     */
    protected function _getRulesProcessor()
    {
        if(is_null($this->_rulesProcessor))
        {
            $this->_rulesProcessor = Mage::getModel('mmdsys/core_compiler_rules')
                ->setCompileConfig($this->getCompileConfig())
                ->setIncludeDir($this->_includeDir)
                ->init();
        }
        return $this->_rulesProcessor;
    }

    /**
     * @return Mage_Compiler_Model_Process
     */
    protected function _collectFiles()
    {
        parent::_collectFiles();
        
        $this->_getRulesProcessor()->applyExcludeFilesRule()->applyReplaceRule();

        return $this;
    }
    
    /**
     * @return array
     */
    public function getCompileClassList()
    {
        $this->_getRulesProcessor()->applyRenameScopeRule()->applyRemoveScopeRule();
        
        $arrFiles = parent::getCompileClassList();
        $arrFiles = $this->_getRulesProcessor()->applyExcludeClassesRule($arrFiles);

        return $arrFiles;
    }
    
    protected function _copy($source, $target, $firstIteration = true)
    {
        if(substr($source, strlen($source)-9, 9)=='.data.php')
        {
            return $this;
        }
        return parent::_copy($source, $target, $firstIteration);
    }
}