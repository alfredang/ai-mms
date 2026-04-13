<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
class MMD_Mmdsys_Helper_Data extends MMD_Mmdsys_Abstract_Helper
{
    protected $_hasStagingModule = null;
    protected $_mysqlTimeoutWarningValue = 120;
    protected $_testConnectionResult = null;

    public function getErrorText($code)
    {
        $args = func_get_args();
        try
        {
            $args[0] = Mage::getStoreConfig('mmdsys/errors/'.$code.'/text');
        }
        catch (Mage_Core_Model_Store_Exception $exc)
        {
            $args[0] = $code;
        }
        return call_user_func_array(array($this,'__'),$args);
    }

    public function getErrorCode($code)
    {
        return Mage::getStoreConfig('mmdsys/errors/'.$code.'/code');
    }

    public function getModuleLicenseUpgradeLink( MMD_Mmdsys_Model_Module $module , $onlyUrl = true )
    {
        if ($license = $module->getLicense())
        {
            $licenseId = $license->getLicenseId();
        }
        else
        {
            return '';
        }
        $url = $module->getStoreUrl().'mmdcprod/license/upgrade/license_id/'.$licenseId;
        if ($onlyUrl)
        {
            return $url;
        }
        return '<a target="_blank" href="'.$url.'">'.$this->__('Buy license upgrade').'</a>';
    }

    public function getModuleSupportLink( MMD_Mmdsys_Model_Module $module , $onlyUrl = true )
    {
        $url = $this->tool()->getMMDUrl() . 'contacts.html?';
        if ($serial = $module->getInfo()->getSerial()) {
            $url .= $serial . '&';
        }
        if ($moduleId = $module->getInfo()->getProductId()) {
            $url .= $moduleId . '&';
        }
        $url .= 'support';
        
        if ($onlyUrl)
        {
            return $url;
        }
        return '<a target="_blank" href="'.$url.'">'.$this->__('Create support ticket').'</a>';
    }

    public function hasStagingModule()
    {
        if($this->_hasStagingModule === null) {
            $val = Mage::getConfig()->getNode('modules/Enterprise_Staging/active');
            $this->_hasStagingModule = ((string)$val == 'true');
        }
        return $this->_hasStagingModule;
    }

    public function isMysqlTimeoutValueLow()
    {
        $timeout = $this->tool()->getWaitTimeout();
        if($timeout < $this->_mysqlTimeoutWarningValue)
        {
            return true;
        }
        return false;
    }

    public function getMysqlTimeoutValue()
    {
        return $this->tool()->getWaitTimeout();
    }

    public function isTestConnectPassed()
    {
        if(is_null($this->_testConnectionResult)) {
            if( $this->isMysqlTimeoutValueLow() ) {
                //allow connection only when sql timeout set to big value, because it may affect even test connection
                $this->_testConnectionResult = true;
                return $this->_testConnectionResult;
            }
            $service = $this->tool()->platform()->getService();
            $this->_testConnectionResult = true;
            try
            {
                $this->_testConnectionResult = $service->testConnection();
            }
            catch (Exception $exc)
            {
                if($exc->getCode() >= 400  && $exc->getCode() < 500)
                {
                    //$this->_testConnectionResult = 'Error code '.$exc->getCode().': '.$exc->getMessage();
                    return 'INSTALL_TEST_CONNECTION_FAILED';
                }
                if($exc->getCode() >= 500 && $exc->getCode() < 600)
                {
                    //$this->_testConnectionResult = 'Error code '.$exc->getCode().': '.$exc->getMessage();
                    return 'INSTALL_TEST_SERVER_ERROR';
                }
            }

        }

        return $this->_testConnectionResult;
    }
}