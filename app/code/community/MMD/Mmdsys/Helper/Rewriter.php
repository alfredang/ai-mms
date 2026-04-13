<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Helper_Rewriter extends MMD_Mmdsys_Helper_Data
{
    public function getOrderConfig()
    {
        $order = unserialize( (string) Mage::getConfig()->getNode('default/mmdsys_rewriter_classorder') );
        if (!$order) {
            $order = array();
        }
        return $order;
    }
    
    public function saveOrderConfig($order)
    {
        Mage::getConfig()->saveConfig('mmdsys_rewriter_classorder', serialize($order));
        Mage::app()->cleanCache();
    }
    
    public function mergeOrderConfig($order)
    {
        $currentOrder = unserialize( (string) Mage::getConfig()->getNode('default/mmdsys_rewriter_classorder') );
        if (!$currentOrder)
        {
            $newOrder = $order;
        } else
        {
            $newOrder = array_merge($currentOrder, $order);
        }
        $this->saveOrderConfig($newOrder);
    }
    
    public function removeOrderConfig()
    {
        Mage::getConfig()->deleteConfig('mmdsys_rewriter_classorder');
        Mage::app()->cleanCache();
    }
    
    public function saveExcludeClassesConfig($classes)
    {
        $classes = array_map('trim', preg_split("/[\n,]+/", $classes));
        Mage::getConfig()->saveConfig('mmdsys_rewriter_exclude_classes', serialize($classes));
        Mage::app()->cleanCache();
    }
    
    public function getExcludeClassesConfig()
    {
        $configValue = (string) Mage::getConfig()->getNode('default/mmdsys_rewriter_exclude_classes');
        $configValue = $this->tool()->unserialize($configValue);
        if (!$configValue) {
            $configValue = array();
        }
        return $configValue;
    }
    
    public function validateSavedClassConfig($savedClassConfig, $rewriteClasses)
    {
        if(!is_array($savedClassConfig) || !is_array($rewriteClasses))
        {
            return false;
        }
        
        $savedClasses = array_keys($savedClassConfig);
        
        if(count($rewriteClasses)!=count($savedClasses))
        {
                return false;
        }
        
        $diff1 = array_diff($rewriteClasses, $savedClasses);
        $diff2 = array_diff($savedClasses, $rewriteClasses);
        
        if(!empty($diff1) || !empty($diff2))
        {
                return false;
        }
        
        
        return true;        
    }
    
}
