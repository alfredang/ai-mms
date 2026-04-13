<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 * @author Andrei
 */
class MMD_Mmdsys_Model_Rewriter_Class extends MMD_Mmdsys_Model_Rewriter_Abstract
{

    protected $_encoders = array('zend', 'ioncube');
    
    /**
    * Get contents of class file
    * 
    * @param string $class class name
    * @return mixed
    */
    public function getContents($class)
    {
        if ($classPath = $this->getClassPath($class))
        {
            $contents = file_get_contents($classPath);
            $contents = trim($contents);
            
            /* remove open php tag ('<?php' or '<?') */
            $iOpenTagLength = 0;
            if (stripos($contents, '<?php') === 0)
                $iOpenTagLength = 5;
            elseif (strpos($contents, '<?') === 0)
                $iOpenTagLength = 2;
            $contents = substr_replace($contents, '', 0, $iOpenTagLength);
            
            /* remove close php tag '?>' */
            if (substr($contents, -2) == "?>")
                $contents = substr_replace($contents, '', -2);

            return $contents;
        }
        return '';
    }
    
    public function getClassPath( $class )
    {
        $classFile = str_replace(' ', '/', ucwords(str_replace('_', ' ', $class)));
        $classFile.= '.php';
        foreach ($this->_checkClassDir as $classDir)
        {
            $classPath = $classDir . $classFile;
            if (file_exists($classPath))
            {
                return $classPath;
            }
        }
        return null;
    }
    
    protected function _getBaseClass( Varien_Simplexml_Element $config )
    {
        $model = null;
        if ($config->class) 
        {
            $model = (string)$config->class;
        } 
        elseif ($config->model) 
        {
            $model = (string)$config->model;
        } 
        else 
        {
            /**
             * Backwards compatibility for pre-MMDB extensions. MMDB introduced since Magebto 1.6.0.0
             * In MMDB release resource nodes <..._mysql4> were renamed to <..._resource>. So <deprecatedNode> is left
             * to keep name of previously used nodes, that still may be used by non-updated extensions.
             */
             $deprecatedNodes = $config->xpath('../*[deprecatedNode="'.(string)$config->getName().'"]');

             if ($deprecatedNodes && $deprecatedNodes[0]->class)
             {
                $model = (string)$deprecatedNodes[0]->class;
             }
        }
        if (is_null($model))
        {
            return false;
        }
        return $this->_getModelClassName($model,$config);
    }
    
    protected function _getModelClassName( $modelClass , Varien_Simplexml_Element $config )
    {
        $modelClass = trim((string)$modelClass);
        if (strpos($modelClass, '/')===false)
        {
            return $modelClass;
        }
        return $this->_getGroupedClassName($config,'model', $modelClass);
    }
    
    protected function _getGroupedClassName(Varien_Simplexml_Element $config , $groupType, $classId, $groupRootNode=null)
    {
        if (empty($groupRootNode)) 
        {
            $groupRootNode = 'global/'.$groupType.'s';
        }

        $classArr = explode('/', trim((string)$classId));
        $group = $classArr[0];
        $class = !empty($classArr[1]) ? $classArr[1] : null;

        $config = $config->global->{$groupType.'s'}->{$group};

        if (!empty($config)) {
            $className = $this->_getBaseClass($config);
        }
        if (empty($className)) {
            $className = 'mage_'.$group.'_'.$groupType;
        }
        if (!empty($class)) {
            $className .= '_'.$class;
        }
        return uc_words($className);
    }
    
    /**
    * Get base magento class name for alias (with no rewrites)
    * 
    * @param string $groupType
    * @param string $classId
    * @return string
    */
    public function getBaseClass($groupType, $classId)
    {
        return $this->_getGroupedClassName(
            MMD_Mmdsys_Model_Rewriter_MageConfig::get()->getConfig()->getNode(),
            $groupType,$classId
        );
    }

    public function isEncodedClassFile($class)
    {
        $bEncoded = false;
        foreach($this->_encoders as $encoder){
            $methodName = 'check'.ucfirst($encoder).'Encoder';
            if (!method_exists($this, $methodName)) {
                continue;
            }
            if ($classPath = $this->getClassPath($class))
            {
                $contents = file_get_contents($classPath);
                $contents = trim($contents);
                $bEncoded = $bEncoded || $this->$methodName($contents);
            }
        }
        return $bEncoded;
    }
    
    public function checkZendEncoder($fileContent)
    {
        $lines = preg_split("/(\r?\n)/", $fileContent);
        if (preg_match('/@Zend/', trim($lines[0]))) {
            return true;
        }
        return false;
    }
    
    public function checkIoncubeEncoder($fileContent)
    {
        $lines = preg_split("/(\r?\n)/", $fileContent);
        if (preg_match('/^<\?php \/\/([\da-fA-F]+)?/', trim($lines[0]), $matches)) {
            $headerLength = hexdec($matches[1]);
            $fileContent = preg_replace('/\x0D/', '', $fileContent);
            $header = substr($fileContent, 0, $headerLength);
            if (strpos($header, "extension_loaded('ionCube Loader')") !== false) {
                return true;
            }
        }
        return false;
    }
}