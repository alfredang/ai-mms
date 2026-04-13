<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 * @author Andrei
 */
class MMD_Mmdsys_Model_Rewriter_Merge extends MMD_Mmdsys_Model_Rewriter_Abstract
{
    
    protected $_latestMergedFiles = array();
    
    /**
    * Clearing current rewrites
    */
    public function clear()
    {
        $filesystem = $this->tool()->filesystem();
        $filesystem->rmFile($this->_rewriteDir . 'config.php');
    }
    
    public function getLatestMergedFiles()
    {
        return $this->_latestMergedFiles;
    }
    
    /**
    * Merging one group of classed (for one alias)
    * 
    * @param array $classes
    * @return boolean
    */
    public function merge($classes, $isAbstract = false)
    {
        $this->_latestMergedFiles = array();
        if (!is_array($classes) || empty($classes))
        {
            return false;
        }

        if($isAbstract)
        {
            $filename = $classes[count($classes)-1]['parent'];
        }
        else
        {
            $filename = $classes[count($classes)-1]['child'];
        }
        $filepath = $this->_rewriteDir . $filename . '.php';
        
        $fileContent = '';
        $fileContent .= '<?php' . "\r\n";
        $fileContent .= '/* DO NOT MODIFY THIS FILE! THIS IS TEMPORARY FILE AND WILL BE RE-GENERATED AS SOON AS CACHE CLEARED. */' . "\r\n";
        $rewriteClass = new MMD_Mmdsys_Model_Rewriter_Class();
        $bOmitRewriteChain = false;
        $iEncodedCount = 0;
        
        //set count of encoded classes
        foreach ($classes as $parent => $class)
        {
            if (isset($class['encoded']) && $class['encoded']) {
                $iEncodedCount++;
            }
        }
        
        foreach ($classes as $parent => $class)
        {
            if ($bOmitRewriteChain) {
                continue;
            }
            $bEncodedCurrent = false;
            /**
            * Different strategy for normal and abstract rewrites
            */
            if (is_array($class))
            {
                // for abstract rewrites
                $contentFrom = $class['contents'];
                $parent      = $class['parent'];
                $child       = $class['child'];
                $bEncodedCurrent = isset($class['encoded']) && $class['encoded'] ? true : false;
                if ($bEncodedCurrent) {
                    $iEncodedCount--;
                }
            }
            else 
            {
                // parent is parent
                $contentFrom = $parent;
                $child       = $class;
            }
            
            /**
            * The last $child is always magento base class
            */
            $contents = $rewriteClass->getContents($contentFrom);
            $this->_latestMergedFiles[$contentFrom] = $rewriteClass->getClassPath($contentFrom);
            if ($child) // if child is empty - need to keep current child
            {
                $contents = preg_replace('/' . $contentFrom . '(\s+)(extends)?(\s+)?([^\s{]+)?/', "$parent $2 $child", $contents, 1);
            } 
            else 
            {
                $contents = preg_replace('/' . $contentFrom . '(\s+)(extends)?(\s+)?([^\s{]+)?/', "$parent $2 $4", $contents, 1);
            }
            if ($bEncodedCurrent) {
                if ($contentFrom != $parent) {
                    $bOmitRewriteChain = true;
                    continue;
                }
                else {
                    $contents = ($iEncodedCount > 0 ? '//':'') .'require_once("'.$rewriteClass->getClassPath($parent).'");';
                }
            }
            $fileContent .= $contents;
            $fileContent .= "\r\n\r\n";
        }
        if ($bOmitRewriteChain) {
            return false;
        }
        
        $this->tool()->filesystem()->putFile($filepath, $fileContent);
        
        return $filename;
    }
}