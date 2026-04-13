<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 * @author Andrei
 */
class MMD_Mmdsys_Model_Rewriter extends MMD_Mmdsys_Model_Rewriter_Abstract
{
    /**
     * @var array
     */
    protected $_excludedClasses;
    
    /**
     * @return array
     */
    protected function _getExcludedClasses()
    {
        if (is_null($this->_excludedClasses)) {
            $this->_excludedClasses = $this->tool()->db()->getConfigValue('mmdsys_rewriter_exclude_classes', array());
        }
        return $this->_excludedClasses;
    }
    
    public function preRegisterAutoloader()
    {
        $configFile = $this->_rewriteDir . 'config.php';
        /**
        * Will re-generate each time if config does not exist, or cache is disabled
        */
        if (!$this->tool()->isPhpCli()) {
            if (!file_exists($configFile) || !Mage::app()->useCache('mmdsys')) {
                $this->prepare();
            }
        }
    }
    
    public function prepare()
    {
        $merge = new MMD_Mmdsys_Model_Rewriter_Merge();
        $rewriterConfig = new MMD_Mmdsys_Model_Rewriter_Config();
        
        // first clearing current class rewrites
        MMD_Mmdsys_Model_Rewriter_Autoload::instance()->clearConfig();
        $merge->clear();
        
        $conflict = new MMD_Mmdsys_Model_Rewriter_Conflict();
        list($conflicts, $rewritesAbstract) = $conflict->getConflictList();
        
        /**
         * FOR NORMAL REWRITES
         */
        // will combine rewrites by alias groups
        if (!empty($conflicts)) {
            foreach ($conflicts as $groupType => $modules) {
                $groupType = substr($groupType, 0, -1);
                foreach ($modules as $moduleName => $moduleRewrites) {
                    foreach ($moduleRewrites['rewrite'] as $moduleClass => $rewriteClasses) {
                        /*
                         * $rewriteClasses is an array of class names for one rewrite alias
                         * for example:
                         * Array
                         *   (
                         *       [0] => AdjustWare_Deliverydate_Model_Rewrite_AdminhtmlSalesOrderCreate
                         *       [4] => MMD_Checkoutoptions_Model_Rewrite_AdminSalesOrderCreate
                         *       [10] => MMD_Aitorderedit_Model_Rewrite_AdminSalesOrderCreate
                         *   )
                         */
                        // building inheritance tree
                        $alias              = $moduleName . '/' . $moduleClass;
                        $classModel         = new MMD_Mmdsys_Model_Rewriter_Class();
                        $inheritanceModel   = new MMD_Mmdsys_Model_Rewriter_Inheritance();
                        $baseClass          = $classModel->getBaseClass($groupType, $alias);
                        $inheritedClasses   = $inheritanceModel->build($rewriteClasses, $baseClass);
                        
                        // don't create rewrites for excluded Magento base classes
                        if (in_array($baseClass, $this->_getExcludedClasses())) {
                            continue;
                        }
                        
                        $mergedFilename = $merge->merge($inheritedClasses);
                        if ($mergedFilename) {
                            $rewriterConfig->add($mergedFilename, $rewriteClasses);
                        }
                    }
                }
            }
        }
        
        /**
         * FOR ABSTRACT REWRITES (MMD IMPLEMENTATION)
         */
        if (!empty($rewritesAbstract)) {
            foreach ($rewritesAbstract as $groupType => $modules) {
                $groupType = substr($groupType, 0, -1);
                foreach ($modules as $moduleName => $moduleRewrites) {
                    foreach ($moduleRewrites['rewriteabstract'] as $moduleClass => $rewriteClass) {
                        // building inheritance tree
                        $alias              = $moduleName . '/' . $moduleClass;
                        $classModel         = new MMD_Mmdsys_Model_Rewriter_Class();
                        $inheritanceModel   = new MMD_Mmdsys_Model_Rewriter_Inheritance();
                        $baseClass          = $classModel->getBaseClass($groupType, $alias);
                        $inheritedClasses   = $inheritanceModel->buildAbstract($rewriteClass, $baseClass);
                        
                        $mergedFilename = $merge->merge($inheritedClasses, true);
                        if ($mergedFilename) {
                            $rewriterConfig->add($mergedFilename, array($rewriteClass, $baseClass));
                        }
                    }
                }
            }
        }
        
        $rewriterConfig->commit();
        
        MMD_Mmdsys_Model_Rewriter_Autoload::instance()->setupConfig();
    }
}
