<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Model_Module_Info_Package extends MMD_Mmdsys_Model_Module_Info_Xml_Abstract
{
    /**
     * @var string
     */
    protected $_pathSuffix = MMD_Mmdsys_Model_Module::PACKAGE_FILE;
    
    /**
     * @return string
     */
    public function getVersion()
    {
        return (string)$this->version;
    }
    
    /**
     * @return string
     */
    public function getPlatform()
    {
        return strtolower((string)$this->platform);
    }
    
    /**
     * @return string
     */
    public function getSerial()
    {
        return (string)$this->license;
    }
    
    /**
     * @return string
     */
    public function getLabel()
    {
        return (string)$this->product;
    }
    
    /**
     * @return int
     */
    public function getProductId()
    {
        return (int)$this->product_id;
    }
}