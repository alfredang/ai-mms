<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
abstract class MMD_Mmdsys_Model_Module_Info_Xml_Abstract extends MMD_Mmdsys_Model_Module_Info_Abstract
{
    /**
     * @var SimpleXMLElement 
     */
    protected $_xml;
    
    /**
     * @var string
     */
    protected $_path;
    
    /**
     * @var string
     */
    protected $_pathSuffix;
    
    protected function _init()
    {
        $this->_path = BP . DS . 'app' . DS . 'code' . DS . $this->getCodepool() . DS . join(DS, explode('_', $this->getModule()->getKey())) . DS . $this->_pathSuffix;
        if (file_exists($this->_path)) {
            try {
                $this->_xml = @simplexml_load_file($this->_path);
            } catch (Exception $e) {}
        }
        if ($this->_xml instanceof SimpleXMLElement) {
            $this->_loaded = true;
        }
    }
    
    public function __get($var)
    {
        return $this->isLoaded() ? $this->_xml->{$var} : null;
    }
    
    public function __call($method, $args)
    {
        if ($this->isLoaded()) {
            try {
                return @call_user_func_array(array($this->_xml, $method), $args); 
            } catch (Exception $e) {}
        }
    }
}