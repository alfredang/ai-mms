<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 * @author Andrei
 */
class MMD_Mmdsys_Model_Rewriter_Conflict extends MMD_Mmdsys_Model_Rewriter_Abstract
{
    protected $_allClasses = array();
    protected $_classRewritesToRecover = array();

    /**
     * Retrive possible conflicts list
     *
     * @return array
     */
    public function getConflictList()
    {
        $moduleFiles = glob($this->_etcDir . 'modules' . DIRECTORY_SEPARATOR . '*.xml');

        if (!$moduleFiles) {
            return false;
        }
        
        // load file contents
        $unsortedConfig = new Varien_Simplexml_Config();
        $unsortedConfig->loadString('<config/>');
        $fileConfig = new Varien_Simplexml_Config();

        foreach($moduleFiles as $filePath) {
            $fileConfig->loadFile($filePath);
            $unsortedConfig->extend($fileConfig);
        }

        // create sorted config [only active modules]
        $sortedConfig = new Varien_Simplexml_Config();
        $sortedConfig->loadString('<config><modules/></config>');

        foreach ($unsortedConfig->getNode('modules')->children() as $moduleName => $moduleNode) {
            if('true' === (string)$moduleNode->active) {
                $sortedConfig->getNode('modules')->appendChild($moduleNode);
            }
        }

        $fileConfig = new Varien_Simplexml_Config();

        $_finalResult = array();
        $_finalResultAbstract = array();

        foreach($sortedConfig->getNode('modules')->children() as $moduleName => $moduleNode) {
            $codePool = (string)$moduleNode->codePool;
            $configPath = $this->_codeDir . $codePool . DIRECTORY_SEPARATOR . uc_words($moduleName, DS) . DIRECTORY_SEPARATOR . 'etc' . DS . 'config.xml';

            $fileConfig->loadFile($configPath);

            $rewriteBlocks = array('blocks', 'models', 'helpers');

            foreach($rewriteBlocks as $param) {
                if(!isset($_finalResult[$param])) {
                    $_finalResult[$param] = array();
                }

                if($rewrites = $fileConfig->getXpath('global/' . $param . '/*/rewrite')) {
                    foreach ($rewrites as $rewrite) {
                        $parentElement = $rewrite->xpath('../..');
                        foreach($parentElement[0] as $moduleKey => $moduleItems) {
                            $moduleItemsArray['rewrite'] = array();
                            foreach ($moduleItems->rewrite as $rewriteLine)
                            {
                                foreach ($rewriteLine as $key => $value)
                                {
                                    $moduleItemsArray['rewrite'][$key] = (string)$value;
                                }
                                #echo "<pre>".print_r($moduleItemsArray['rewrite'],1)."</pre>";
                            }
                            if($moduleItems->rewrite) {
                                $_finalResult[$param] = array_merge_recursive($_finalResult[$param], array($moduleKey => $moduleItemsArray));
                            }
                        }
                    }
                }
                
                if($rewrites = $fileConfig->getXpath('global/' . $param . '/*/rewriteabstract')) {
                    foreach ($rewrites as $rewrite) {
                        $parentElement = $rewrite->xpath('../..');
                        foreach($parentElement[0] as $moduleKey => $moduleItems) {
                            if($moduleItems->rewriteabstract) {
                                $list = array();
                                foreach ($moduleItems->rewriteabstract->children() as $key => $value)
                                {
                                    $list[$key] = (string)$value;
                                }
                                #echo "<pre>--".print_r($list,1)."</pre>";
                                #echo "<pre>++".print_r($moduleItems->asArray(),1)."</pre>";
                                $_finalResultAbstract[$param][$moduleKey] = array('rewriteabstract' => $list);
                            }
                        }
                    }
                }
            }
        }

        $_finalResult = $this->_fillAllClassesToRewrite($_finalResult);
        $_finalResult = $this->_clearEmptyRows($_finalResult);
        $_finalResult = $this->_recoverDeletedClassRewrites($_finalResult);

        $_finalResultAbstract = $this->_workWithAbstractResult($_finalResultAbstract);

        // filter mmd modules
        foreach ($_finalResult as $type => $data)
        {
            foreach ($data as $module => $data)
            {
                foreach ($data['rewrite'] as $model => $classes)
                {
                    $remove = true;
                    foreach ($classes as $class)
                    {
                        if (strstr($class,'MMD') || strstr($class,'AdjustWare'))
                        {
                            $remove = false;
                            break;
                        }
                    }
                    if ($remove)
                    {
                        unset ($_finalResult[$type][$module]['rewrite'][$model]);
                    }
                }
                if (!$_finalResult[$type][$module]['rewrite'])
                {
                    unset($_finalResult[$type][$module]);
                }
            }
        }           
       
        return array($_finalResult, $_finalResultAbstract);
    }

    /**
     * Get Magento real class names
     *
     * @param string $key, e.g. catalog_resource
     * @param string $key1, e.g. product_option
     * @param string $groupType, e.g. models, blocks, helpers
     * @return string class name
     */
    protected function _getBaseClass($key, $key1, $groupType)
    {
        $alias              = $key . '/' . $key1;
        $groupType = substr($groupType, 0, -1);
        $classModel = new MMD_Mmdsys_Model_Rewriter_Class();
        $baseClass = $classModel->getBaseClass($groupType, $alias);

        return $baseClass;
    }

    /**
     * Stores all rewrite classes for future work
     *
     * @param array $_finalResult
     * @return array
     */
    protected function _fillAllClassesToRewrite($_finalResult)
    {
        foreach(array_keys($_finalResult) as $groupType) {
            foreach(array_keys($_finalResult[$groupType]) as $key) {
                // remove some repeating elements after merging all parents 
                foreach($_finalResult[$groupType][$key]['rewrite'] as $key1 => $value) {
                    if(is_array($value)) {
                        $_finalResult[$groupType][$key]['rewrite'][$key1] = array_unique($value);
                    }

                    $baseClass = $this->_getBaseClass($key, $key1, $groupType);
                    if(isset($this->_allClasses[$baseClass])){
                        $this->_allClasses[$baseClass] += 1;
                    }
                    else{
                        $this->_allClasses[$baseClass] = 1;
                    }
                }
            }
        }

        return $_finalResult;
    }

    /**
     * Clears rewrites without conflicts from rewrites array
     *
     * @param array $_finalResult
     * @return array
     */
    protected function _clearEmptyRows($_finalResult)
    {
        foreach(array_keys($_finalResult) as $groupType) {
            foreach(array_keys($_finalResult[$groupType]) as $key) {
                foreach($_finalResult[$groupType][$key]['rewrite'] as $key1 => $value) {
                    // if rewrites count < 2 - no conflicts - remove
                    if( 
                        (gettype($_finalResult[$groupType][$key]['rewrite'][$key1]) == 'array' && count($_finalResult[$groupType][$key]['rewrite'][$key1]) < 2) 
                        ||
                        gettype($_finalResult[$groupType][$key]['rewrite'][$key1]) == 'string'
                    ){
                        if(gettype($_finalResult[$groupType][$key]['rewrite'][$key1]) == 'array')
                        {
                            $baseClass = $this->_getBaseClass($key, $key1, $groupType);
                            if(isset($this->_allClasses[$baseClass]) && $this->_allClasses[$baseClass] > 1)
                            {
                                $dataToRecover = array('base_class' => $baseClass,
                                //'group_type' => $groupType,
                                //'key' => $key,
                                'key1' => $_finalResult[$groupType][$key]['rewrite'][$key1]);
                                $this->_classRewritesToRecover[] = $dataToRecover;        
                            }
                        }

                        unset($_finalResult[$groupType][$key]['rewrite'][$key1]);
                    }
                    elseif(gettype($_finalResult[$groupType][$key]['rewrite'][$key1]) == 'array')
                    {
                        $baseClass = $this->_getBaseClass($key, $key1, $groupType);
                        if(isset($this->_allClasses[$baseClass]) && $this->_allClasses[$baseClass] > 1)
                        {
                                $dataToRecover = array('base_class' => $baseClass,
                                //'group_type' => $groupType,
                                //'key' => $key,
                                'key1' => $_finalResult[$groupType][$key]['rewrite'][$key1]);
                                $this->_classRewritesToRecover[] = $dataToRecover; 
                        }
                    }
                } 
               
                // clear empty elements
                if(count($_finalResult[$groupType][$key]['rewrite']) < 1) {
                    unset($_finalResult[$groupType][$key]);
                }
            }

            // clear empty elements
            if(count($_finalResult[$groupType]) < 1) {
                unset($_finalResult[$groupType]);
            }
        }

        return $_finalResult;
    }

    /**
     * Restores incorrectly deleted class rewrites
     *
     * @param array $_finalResult
     * @return array
     */
    protected function _recoverDeletedClassRewrites($_finalResult)
    {
        foreach(array_keys($_finalResult) as $groupType)
        {
            foreach(array_keys($_finalResult[$groupType]) as $key)
            {
                foreach($_finalResult[$groupType][$key]['rewrite'] as $key1 => $value)
                {
                    if(gettype($_finalResult[$groupType][$key]['rewrite'][$key1]) == 'array')
                    {
                        $baseClass = $this->_getBaseClass($key, $key1, $groupType);
            
                        foreach($this->_classRewritesToRecover as $classRewriteToRecover)
                        {
                            if($classRewriteToRecover['base_class'] == $baseClass)
                            {
                                foreach($classRewriteToRecover['key1'] as $newKey1)
                                {
                                    if(!in_array($newKey1, $_finalResult[$groupType][$key]['rewrite'][$key1]))
                                        $_finalResult[$groupType][$key]['rewrite'][$key1][] = $newKey1;                                
                                }
                            }
                        }                        
                    }
                }
            }
        }

        return $_finalResult;
    }

    /**
     * Clears rewrites without conflicts from rewrites array
     *
     * @param array $_finalResult
     * @return array
     */
    protected function _workWithAbstractResult($_finalResultAbstract)
    {
        foreach(array_keys($_finalResultAbstract) as $groupType) {
            foreach(array_keys($_finalResultAbstract[$groupType]) as $key) {
                // remove some repeating elements after merging all parents 
                foreach($_finalResultAbstract[$groupType][$key]['rewriteabstract'] as $key1 => $value) {
                    if(is_array($value)) {
                        $_finalResultAbstract[$groupType][$key]['rewriteabstract'][$key1] = array_unique($value);
                    }
                } 
                
                // clear empty elements
                if(count($_finalResultAbstract[$groupType][$key]['rewriteabstract']) < 1) {
                    unset($_finalResultAbstract[$groupType][$key]);
                }
            }
            
            // clear empty elements
            if(count($_finalResultAbstract[$groupType]) < 1) {
                unset($_finalResultAbstract[$groupType]);
            }
        }

        return $_finalResultAbstract;
    }
}