<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 * @author Andrei
 */
class MMD_Mmdsys_Model_Rewriter_Inheritance extends MMD_Mmdsys_Model_Rewriter_Abstract
{
    
    public function loadOrderConfig()
    {
        return $this->tool()->db()->getConfigValue('mmdsys_rewriter_classorder', array());
    }
    
    /**
    * Creates inheritance array
    * 
    * @param array $rewriteClasses
    * @param array $baseClass
    */
    public function build($rewriteClasses, $baseClass, $useOrdering = true)
    {
        $inheritedClasses = array();
        $orderedInheritance = array();
        krsort($rewriteClasses);
        $rewriteClasses = array_values($rewriteClasses);
        
        $i = 0;
        while ($i < count($rewriteClasses))
        {
            $inheritedClasses[$rewriteClasses[$i]] = isset($rewriteClasses[++$i]) ? $rewriteClasses[$i] : $baseClass;
        }
        // reversing to make it read classed in order of existence
        $inheritedClasses = array_reverse($inheritedClasses, true);

        // sorting in desired order
        $order = $this->loadOrderConfig();
        if (!$order)
        {
            $order = array();
        }
        if (!isset($order[$baseClass]) || !$this->_mmdhelper('Rewriter')->validateSavedClassConfig($order[$baseClass], $rewriteClasses))
        {
            $config = MMD_Mmdsys_Model_Rewriter_MageConfig::get()->getConfig();
            $tmp = array();
            foreach ($rewriteClasses as $class)
            {
                list($vendor,$name) = explode('_',$class,3);
                $priority = (string)$config->getNode('modules/'.$vendor.'_'.$name.'/priority');
                $priority = $priority ? $priority : 1;
                while (isset($tmp[$priority]))
                {
                    ++$priority;
                }
                $tmp[$priority] = $class;
            }
            krsort($tmp);
            $i = 0;
            $order[$baseClass] = array();
            foreach ($tmp as $class)
            {
                $order[$baseClass][$class] = ++$i;
            }
        }
        
        /* Check encoded files */
        $encoded = array();
        if (isset($order[$baseClass])) {
            $classes = array_flip($order[$baseClass]);
            ksort($classes);
            $classes = array_values($classes);
            $classModel = new MMD_Mmdsys_Model_Rewriter_Class();
            foreach ($classes as $k => $class) {
                if ($classModel->isEncodedClassFile($class)) {
                    $encoded[] = $class;
                    unset($classes[$k]);
                }
            }
            $classes = array_merge($classes, $encoded);
            $i = 0;
            $order[$baseClass] = array();
            foreach ($classes as $class)
            {
                $order[$baseClass][$class] = ++$i;
            }
        }
        if ($useOrdering && isset($order[$baseClass]))
        {
            $orderedClasses = array_flip($order[$baseClass]);
            ksort($orderedClasses);
            $orderedClasses = array_values($orderedClasses);
            
            $i             = 0;
            $replaceClass = array();
            while ($i < count($orderedClasses))
            {
                $contentsFromClass = $orderedClasses[$i];
                if (0 == $i && $orderedClasses[$i] != $rewriteClasses[$i])
                {
                    $parentClass = $rewriteClasses[$i];
                    $replaceClass[$rewriteClasses[$i]] = $orderedClasses[$i];
                } 
                else 
                {
                    $parentClass = $orderedClasses[$i];
                    if (isset($replaceClass[$parentClass]))
                    {
                        $parentClass = $replaceClass[$parentClass];
                    }
                }
                if (isset($orderedClasses[$i+1]))
                {
                    $childClass = $orderedClasses[$i+1];
                    if (isset($replaceClass[$childClass]))
                    {
                        $childClass = $replaceClass[$childClass];
                    }
                } else 
                {
                    $childClass = $baseClass;
                }
                $orderedInheritance[] = array(
                    'contents'  => $contentsFromClass,
                    'parent'    => $parentClass,
                    'child'     => $childClass,
                    'encoded'   => in_array($contentsFromClass, $encoded),
                );
                $i++;
            }
            if ($orderedInheritance)
            {
                krsort($orderedInheritance);
                $inheritedClasses = $orderedInheritance;
            }
        }
        return $inheritedClasses;
    }
    
    public function buildAbstract($rewriteClass, $baseClass)
    {
        $inheritedClasses = array();
        $inheritedClasses[] = array(
            'contents'  => $baseClass,
            'parent'    => $rewriteClass,
            'child'     => '', // empty to keep current
        );
        $inheritedClasses[] = array(
            'contents'  => $rewriteClass,
            'parent'    => $baseClass,
            'child'     => $rewriteClass,
        );
        return $inheritedClasses;
    }
}