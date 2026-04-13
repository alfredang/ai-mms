<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Model_Mmdsys extends Mage_Eav_Model_Entity_Attribute
implements MMD_Mmdsys_Abstract_Model_Interface
{

    protected $_sModuleRewriteNameOld   = 'MMD_Aitcheckattrib';    
    protected $_sModuleRewriteNameNew   = 'MMD_Checkoutoptions';    
    
    protected $_aModuleClassRewrite     = array();    
    protected $_aModulePriority         = array();    
    protected $_aModuleConfig           = array();    
    protected $_aConfigReplace          = array();    
    protected $_aFileMerge              = array();    
    protected $_aFileWriteContent       = array();    
    protected $_aFilesToUnlink          = array();    
    protected $_aErrorList              = array();
    protected $_patchIncompatibleList   = array();
    protected $_isCorrection            = false;
    
    /**
     * @return MMD_Mmdsys_Abstract_Service
     */
    public function tool()
    {
        return MMD_Mmdsys_Abstract_Service::get();
    }
    
    /**
     * @return MMD_Mmdsys_Abstract_Helper
     */
    protected function _mmdhelper($type = 'Data')
    {
        return $this->tool()->getHelper($type);
    }

    protected function _getModuleOrder()
    {
        if ($this->_aModulePriority)
        {
            arsort($this->_aModulePriority);
            return array_keys($this->_aModulePriority);
        }
        else 
        {
            return false;
        }
    }

    /**
     * @return string
     */
    protected function _getEtcDir()
    {
        return $this->tool()->filesystem()->getEtcDir();
    }

    /**
     * @return string
     */
    protected function _getLocalDir()
    {
        return $this->tool()->filesystem()->getLocalDir();
    }

    /**
     * @return string
     * @todo refactoring: remove?
     */
    protected function _getDiffFilePath($sModuleDir, $sArea, $sFileKey)
    {
        if (!$sModuleDir OR !$sArea OR !$sFileKey)
        {
            return false;
        }
        
        $sDiffFilePath = $sModuleDir . '/data/template/' . $sArea . '/' . $sFileKey . '.diff';
        
        return $sDiffFilePath;
    }

    /**
     * Get location of the module passed
     * 
     * @param string $moduleName
     * @return string|false
     */
    protected function _getModuleDir($moduleName)
    {
        if (!$moduleName)
        {
            return false;
        }
        
        $moduleDir = $this->_getLocalDir() . str_replace('_', '/', $moduleName);
        
        return $moduleDir;
    }

    /**
     * @return array()
     */
    protected function _getModuleHash()
    {
        $result = array();
        foreach ($this->getMMDModuleList() as $module)
        {
            $result[$module->getKey().'.xml'] = $module->getFile();
        }
        return $result;
    }
    
    /**
     * @return array()
     */
    public function getEtcMMDModuleList()
    {
        $result = array();
        foreach ($this->getMMDModuleList() as $module)
        {
            /* @var $module MMD_Mmdsys_Model_Module */
            if ($module->getInstall()->isInstallable())
            {
                $result[] = $module;
            }
        }
        return $result;
    }

    /**
     * @return array()
     */
    public function getMMDModuleList()
    {
        return $this->tool()->platform()->getModules();
    }
    
    /**
     * Get module config file
     *   
     * @param string $moduleDir 
     * @param bool $custom Whether to load main or patches config
     * @return SimpleXMLElement|false
     * 
     * @todo refactoring: split for different configs
     */
    protected function _getModuleConfig($moduleDir, $custom = false)
    {
        if ($moduleDir)
        {
            if ($custom)
            {
                $configFile = $moduleDir . '/etc/custom.data.xml';
            }
            else 
            {
                $configFile = $moduleDir . '/etc/config.xml';
            }
            
            if (file_exists($configFile))
            {
                return simplexml_load_file($configFile);
            }
        }
        return false;
    }

    /**
     * Check if file have writeable permissions and if not add an error
     * 
     * @param string $filePath
     * @return bool
     */
    protected function _checkFileWritePermissions($filePath)
    {
        try
        {
            return $this->tool()->filesystem()->checkWriteable($filePath, true);
        }
        catch(MMD_Mmdsys_Model_Core_Filesystem_Exception $e)
        {
            $this->_addError($e->getMessage(), 'no_access_file');
        }
        return false;
    }
    
    /**
     * @return string
     */
    protected function _getDesignFileDestinationPrefix( $areaName )
    {
        $filePrefix = 'design/' . $areaName . '/base/';
        if (file_exists(Mage::getConfig()->getOptions()->getAppDir().$filePrefix))
        {
            return $filePrefix;
        }
        return 'design/' . $areaName . '/default/';
    }
    
    /**
     * @todo refactoring 
     */
    protected function _clearFileMergeData( $data , $modules , $statuses )
    {
        $disableList = $enableList = array();
        foreach ($statuses as $key => $status)
        {
            if (!$status && isset($data[$key]) && $data[$key])
            {
                $enableList[$key] = $key;
            }
            elseif ($status && (!isset($data[$key]) || !$data[$key]))
            {
                $disableList[$key] = $key;
            }
            elseif (!$status && (!isset($data[$key]) || !$data[$key]))
            {
                $disabledList[$key] = $key;
            }
        }
        foreach ($this->_aFileMerge as $path => $info)
        {
            $has = false;
            foreach (array_keys($info['modules']) as $modulePath)
            {
                $tmp = explode('/',$modulePath);
                $name = array_pop($tmp);
                $vendor = array_pop($tmp);
                $module = $vendor.'_'.$name;
                if (isset($enableList[$module]))
                {
                    $has = true;
                }
                elseif (isset($disableList[$module]))
                {
                    $has = true;
                    unset($this->_aFileMerge[$path]['modules'][$modulePath]);
                }
                elseif (isset($disabledList[$module]))
                {
                    unset($this->_aFileMerge[$path]['modules'][$modulePath]);
                }
            }
            if (!$has || !$this->_aFileMerge[$path]['modules'])
            {
                unset($this->_aFileMerge[$path]);
            }
        }
    }

    /**
     * @todo refactoring 
     */
    protected function _setFileMergeData($oModuleCustomConfig, $sModuleDir)
    {
        if (!$oModuleCustomConfig) return false;
        
        $oConfig     = Mage::getConfig();
        
        $aDestFileHash = array();
        
        if ($oModuleCustomConfig->template AND $oModuleCustomConfig->template->children())
        {
			foreach ($oModuleCustomConfig->template->children() as $sAreaName => $aAreaConfig)
            {
                if ($aAreaConfig AND $aAreaConfig->children())
                {
                    foreach ($aAreaConfig->children() as $sNodeKey => $aFileConfig)
                    {
						if (!$this->validateVersion(Mage::getVersion(), $aFileConfig->attributes()))
						{
							continue;							
						}

						$aFilePathKey = $aFileConfig->attributes()->path;
                        $bOptional = $aFileConfig->attributes()->optional ? (int)$aFileConfig->attributes()->optional : false;						
                        $bOptional = $bOptional ? true : false;						

                        $sTplKey = $aFilePathKey . '.phtml.patch';
                        
                        if (isset($this->_aFileMerge[$sTplKey]['optional']))
                        {
                            if($this->_aFileMerge[$sTplKey]['optional'])
                            {
                                $this->_aFileMerge[$sTplKey]['optional'] = $bOptional;
                            }
                        }
                        else
                        {
                            $this->_aFileMerge[$sTplKey]['optional'] = $bOptional;
                        }
                        
                        $patchFile = $this->tool()->filesystem()->getPatchFilePath($sTplKey, $sModuleDir . '/data/');
                        if ($patchFile->getIsError())
                        {
                            $this->_addError($patchFile->getFilePath(), 'no_module_file');
                        }

                        $sFileDest = $this->_getDesignFileDestinationPrefix($sAreaName).'default/template/mmdcommonfiles/' . $aFilePathKey . '.phtml';
                        
                        $sDestFilePath = MMD_Mmdsys_Model_Mmdpatch::getPatchesCacheDir() . $sFileDest;
                        
                        $aDestFileHash[$sDestFilePath] = 1;
                        
                        if (isset($this->_aFileMerge[$sTplKey]))
                        {
                            $this->_aFileMerge[$sTplKey]['modules'][$sModuleDir] = $sFileDest;
                        }
                        else 
                        {
                            $this->_aFileMerge[$sTplKey] = array(
                                'modules' => array(
                                    $sModuleDir => $sFileDest
                                )
                            );
                        }
                    }
                }
            }			
        }
        
        if ($aDestFileHash)
        {
            foreach ($aDestFileHash as $sFile => $sVal)
            {
                $this->_checkFileWritePermissions($sFile);
            }
        }
        
        return true;
    }

    public function getModulesStatusHash()
    {
        $aModuleList = $this->getEtcMMDModuleList();
        $aModHash = array();
        foreach ($aModuleList as $aMod)
        {
            $aModHash[$aMod['key']] = $aMod['value'];
        }
        return $aModHash;
    }
    
    /**
     * @todo refactoring
     */
    public function saveData($aData, $aModuleHash = array(), $clearCache = true , $hideEvents = false)
    {
        if (!$aData) return false;
        
        if (!$aModuleHash)
        {
            $aModuleHash = $this->_getModuleHash();
        }
        $sModuleEtcDir  = $this->_getEtcDir();
        
        // dispatching pre-disable event
        $aStatusHash = $this->getModulesStatusHash();
        
        if($this->_isCorrection)
        {
            // For correction $aData is an array of modules to be corrected, not a list of all modules with new statuses.
            // To prevent status changes of all other modules we are re-creating $aData from $aStatusHash.
            // Then in $sStatusHash we change current statuses of modules that require correction to an opposite one to simulate
            // normal process of enabling/disabling of modules.
            $newData = array();
            foreach ($aStatusHash as $module => $oldStatus)
            {
                $newData[$module] = $oldStatus;
                $aStatusHash[$module] = isset($aData[$module])?!$oldStatus:$oldStatus;
            }
            $aData = $newData;
        }

		if ($aModuleHash)
        {
            foreach ($aModuleHash as $sFile => $sFullPath)
            {
            	if (!file_exists($sFullPath))
                {
                    continue;
                }
                
            	$oModuleBaseConfigCheck = simplexml_load_file($sFullPath);

            	$this->checkModulesCompatibility($aData, $oModuleBaseConfigCheck, $aModuleHash);
            }
        }

        $eventArg = array(
            'mmdsys' => $this,
            'data' => $aData,
            'module_hash' => $aModuleHash,
            'status_hash' => $aStatusHash
        );
        if (!$hideEvents)
        {
            $this->tool()->event('mmd_module_save_data_before',$eventArg);
        }
        foreach ($aStatusHash as $sModule => $bIsActive)
        {
            if (!isset($aData[$sModule]) or !$aData[$sModule])
            {
                $aEventParams = array(
                    'object'             => $this, // modules will put errors to the current instance
                    'mmdmodulename'    => $sModule,
                );
                if (!$hideEvents)
                {
                    Mage::dispatchEvent('mmd_module_disable_before', $aEventParams);
                }
            }
        }
        // checking if we got any error from events
        $aErrors = $this->_getErrorList();
        if (!empty($aErrors))
        {
            return $aErrors;
        }

        if ($aModuleHash)
        {
            foreach ($aModuleHash as $sFile => $sFullPath)
            {
                if (!file_exists($sFullPath))
                {
                    continue;
                }
                $sModuleName = substr($sFile, 0, strpos($sFile, '.'));
                
                if (!$hideEvents)
                {
                    $this->tool()->event(
                        'mmd_module_modify_before',
                        array('mmdsys' => $this,'key' => $sModuleName)
                    );
                }
                
                $sModuleDir = $this->_getModuleDir($sModuleName);
                
                // get main module config
                
                $oModuleMainConfig = $this->_getModuleConfig($sModuleDir);
                
                // set module status
                if (isset($aData[$sModuleName]) AND $aData[$sModuleName]) // checkbox was checked
                {
                    $sModuleActive = 'true';
                }    
                else            
                {
                    $sModuleActive = 'false';
                }                
                // get base module config
                    
                $oModuleCustomConfig = $this->_getModuleConfig($sModuleDir, true);
                
                $this->_setFileMergeData($oModuleCustomConfig, $sModuleDir);
                
                $oModuleBaseConfig = simplexml_load_file($sFullPath);
                
                $oModuleBaseConfig->modules->$sModuleName->active = $sModuleActive;
                
                if ($iPriority = $oModuleBaseConfig->modules->$sModuleName->priority)
                {
                    $this->_aModulePriority[$sModuleName] = (integer)$iPriority;
                }
                else 
                {
                    $this->_aModulePriority[$sModuleName] = 0;
                }
                
                $sFileContent = $oModuleBaseConfig->asXML();
                
                if ($this->_isCorrection || $this->_checkFileSaveWithContent($sFullPath, $sFileContent))
                {
                    // check if module's status was changed
                    // check if module has license helper
                    // launch module's specific install/uninstall methods from license helper
                    if(array_key_exists($sModuleName, $aData) && array_key_exists($sModuleName, $aStatusHash) && ($aData[$sModuleName] != $aStatusHash[$sModuleName]))
                    {
                        if ($sModuleActive=='false')
                        {
                            $this->tool()->getSetupHelper($sModuleName)->uninstallBefore();
                        }else{
                            $this->tool()->getSetupHelper($sModuleName)->installBefore();
                        }
                    }
                
                    // check if module has resource setup files
                    // also if it has version in `core_resource`
                    // run 'activate' or 'uninstall' scripts
                    if ($oModuleMainConfig AND isset($oModuleMainConfig->global->resources))
                    {
                        $resourceName = '';
                        foreach ($oModuleMainConfig->global->resources->children() as $key => $object)
                        {
                            if ($object->setup)
                            {
                                $resourceName = $key;
                                break;
                            }
                        }
                        
                        if ($resourceName)
                        {
                            // check if module has version in `core_resource`, so it was previously enabled
                            $dbVersion = Mage::getResourceModel('core/resource')->getDBVersion($resourceName);   
                            if ($dbVersion && array_key_exists($sModuleName, $aData) && array_key_exists($sModuleName, $aStatusHash) && ($aData[$sModuleName] != $aStatusHash[$sModuleName])) 
                            {
                                if ($sModuleActive=='false') // module is being disabled
                                {
                                    $mmdsysSetup = new MMD_Mmdsys_Model_Mysql4_Setup('core_setup');
                                    $mmdsysSetup->applyMMDModuleUninstall($sModuleName);
                                }
                                else // module is being enabled
                                {
                                    $mmdsysSetup = new MMD_Mmdsys_Model_Mysql4_Setup('core_setup');
                                    $mmdsysSetup->applyMMDModuleActivate($sModuleName);
                                }
                            }
                        }
                    }
                    
                    // save module status in the database for future correction checks
                    MMD_Mmdsys_Model_Module_Status::updateStatus($sModuleName, ($sModuleActive!='false'));
                }
            }
            
            $this->_clearFileMergeData($aData,$aModuleHash,$aStatusHash);
            
            // checking write permissions to var
            $this->_checkFileWritePermissions(Mage::getBaseDir( $this->tool()->platform()->getVarPath() ));
            
            if (!$this->_aErrorList)
            {
                if ($this->_aFileMerge)
                {
                    $oPatch = new MMD_Mmdsys_Model_Mmdpatch();
                    
                    $oPatch->setPatchFiles($this->_aFileMerge);
                    
                    $aErrorList = $oPatch->applyPatchDryrun();
                    
                    if ($aErrorList)
                    {
                        foreach ($aErrorList as $aError)
                        {
                            $this->_addError($aError['file'], $aError['type']);
                        }
                    }
                    else 
                    {
                        $oPatch->applyPatch();
                    }
                }
                
                if (!$this->_aErrorList)
                {
                    $this->_saveAllFileContent();
                    $this->_deleteFiles();
                }
            }
        }
        
        if ($clearCache)
        {
            $this->tool()->clearCache();
        }
        
        if (!$hideEvents)
        {
            $this->tool()->event('mmd_module_save_data_after',$eventArg);
        }

        return $this->_getErrorList();
    }
    
    protected function _getErrorList()
    {
        if (!$this->_aErrorList) return false;
        
        return array_unique($this->_aErrorList);
    }
    
    protected function _deleteFiles()
    {
        if (!empty($this->_aFilesToUnlink))
        {
            foreach ($this->_aFilesToUnlink as $file)
            {
                @unlink($file);
            }
        }
        return true;
    }
    
    protected function _saveAllFileContent()
    {
        if (!$this->_aFileWriteContent) return false;
        
        foreach ($this->_aFileWriteContent as $sFilePath => $sFileContent)
        {
            $this->tool()->filesystem()->putFile($sFilePath, $sFileContent);
        }
                    
        return true;
    }
    
    protected function _checkFileSaveWithContent($sFilePath, $sFileContent)
    {
        if (!$sFilePath OR !$sFileContent)
        {
            return false;
        }
        
        if (!file_exists($sFilePath))
        {
            $this->_addError($sFilePath, 'no_file');
        }
        else 
        {
            // check for file permissions 
    
            if (!$this->_checkFileWritePermissions($sFilePath))
            {
                $this->_addError($sFilePath, 'no_access_file');
            }
        }
    
        if ($this->_aErrorList)
        {
            return false;
        }
        
        $this->_aFileWriteContent[$sFilePath] = $sFileContent;
        
        return true;
    }
    
    protected function _addError($sFilePath, $sType)
    {
        if (!$sFilePath OR !$sType)
        {
            return false;
        }
        
        switch ($sType)
        {
            case 'no_file':
                $sMessage = 'File does not exist: %s';
            break;   
             
            case 'no_access_file':
                $sMessage = 'File does not have write permissions: %s';
            break;    
            
            case 'no_access_dir':
                $sMessage = 'Folder does not have write permissions: %s';
            break;    
            
            case 'no_module_file':
                $sMessage = 'Module installation file is absent: %s';
            break;    
            
            case 'file_uncompatible':
                $sMessage = 'Magento file is corrupted or changed: %s';
            break; 
            
            case 'modules_compatibility':
                $sMessage = '%s are not compatible and can not be enabled together. Choose one you are going to use and enable it.';
            break;    
        }
        
        $this->_aErrorList[] = $this->_mmdhelper()->__($sMessage, $sFilePath);
        
        return true;
    }
    
    public function addError($error)
    {
        $this->_aErrorList[] = $error;
    }
    
    public function addCustomError($sErrorMessage)
    {
        $this->_aErrorList[] = $this->_mmdhelper()->__($sErrorMessage);
    }
    
    /**
     * @todo refactoring
     */
    public function getAllowInstallErrors()
    {
        $aMMDModuleList = $this->getMMDModuleList();
        
        $aErrorList = array();
       
        if ($aMMDModuleList)
        {
            $sHasRewritePathOld = '';
            $sHasRewritePathNew = '';
            
            foreach ($aMMDModuleList as $aModule)
            {
                if ($aModule['key'] == $this->_sModuleRewriteNameOld)
                {
                    $sHasRewritePathOld = $aModule['file'];
                }
                
                if ($aModule['key'] == $this->_sModuleRewriteNameNew)
                {
                    $sHasRewritePathNew = $aModule['file'];
                }
            }
            
            if ($sHasRewritePathOld) // has old version
            {
                if (!$sHasRewritePathNew) // no new version
                {
                    $sErrorMsg = $this->_mmdhelper()->__('Module can not be installed because you have outdated version of Checkout Fields Manager installed. Please contact MMD for updated version of Checkout Fields Manager to resolve this issue.');
                    
                    $aErrorList[] = $sErrorMsg;
                    return $aErrorList;
                }
                
                if (is_writable($sHasRewritePathOld))
                {
                    $aPostData = array($aModule['key'] => 1);
                    
                    $aModuleHashStrict = array($this->_sModuleRewriteNameNew . '.php' => $sHasRewritePathNew);
                    
                    $aErrorList = $this->saveData($aPostData, $aModuleHashStrict);
                    
                    if (!$aErrorList)
                    {
                        unlink($sHasRewritePathOld); // kill old version config file
                    }
                    
                    return $aErrorList;
                }
                else 
                {
                    $sErrorMsg = $this->_mmdhelper()->__('File does not have write permissions: %s', $sHasRewritePathOld);
                    $aErrorList[] = $sErrorMsg;
                    return $aErrorList;
                }
            }
        }
        
        return false;
    }
	
	/**
	 * Checks Magento version against rules
	 *
	 * @param mixed $mageVersion
	 * @param SimpleXMLElement $object
	 * @return boolean
	 */
	public function validateVersion($mageVersion, SimpleXMLElement $object)
	{
		return $this->_validate($mageVersion, array(
			'include' => $object->includeVer,
			'exclude' => $object->excludeVer,
			'values' => $object->version,
			'operator' => $object->operator,
		));
	}

	/**
	 * Checks values against rules
	 *
	 * Following operators are supported:
	 * lt lower than
	 * le lower or equal
	 * eq equal
	 * gt greater than
	 * ge greater or qeual
	 * ne not equal
	 *
	 * @param mixed $valueToCheckAgainst
	 * @param array $rules
	 * @return boolean
	 */
	protected function _validate($valueToCheckAgainst, $rules)
	{
		$keys = array('include', 'exclude', 'values', 'operator');

		foreach ($keys as $key)
		{
			$rules[$key] = isset($rules[$key]) ? $rules[$key] : null;
		}


		$globalValid = true;

		foreach ($keys as $key)
		{
			if ('operator' == $key)
			{
				continue;
			}

			$values = null;
			switch($key)
			{
				case 'include':
					$operator =  'eq';
					$values = $rules[$key];
					break;
				case 'exclude':
					$operator =  'ne';
					$values = $rules[$key];
					break;
				case 'values':
					$operator = $rules['operator'];
					$values = $rules['values'];
					break;
			}

			$valid = true;

			if ($values && $operator)
			{
				$values = preg_split('/-/', $values);

				if (isset($values[0]) && (0 < strlen($values[0])))
				{
					$valid = true;

					foreach ($values as $value)
					{
						//var_dump($valueToCheckAgainst, $value, $operator);
						$result = version_compare($valueToCheckAgainst, $value, $operator);

						if ('eq' == $operator)
						{
							if ($result)
							{
								return true;
							}
						}
						else
						{
							$valid &= $result;
						}
					}
				}
			}

			$globalValid &= (bool) $valid;
		}

		return (bool) $globalValid;
	}
	
    public function checkModulesCompatibility($aData, $oConfig, $aModuleHash)
    {
		foreach ($aData as $sModuleKey=>$bStatus)
		{
			if (is_object($oConfig->modules->$sModuleKey))
			{
				$oIncompatible = $oConfig->modules->$sModuleKey->incompatible;
				
				foreach ($aData as $sIncompatibleModuleKey=>$bIncompatibleStatus)
				{
					if (isset($oIncompatible->$sIncompatibleModuleKey) && $sIncompatibleModuleKey != $sModuleKey && $bIncompatibleStatus == 1 && $bStatus == 1)
					{
						$this->_addError($this->getModuleName($sModuleKey, true).' and '.$this->getModuleName($sIncompatibleModuleKey, true), 'modules_compatibility');
					}
				}
			}
		}
    }
    
    /**
     * Get module's name by key and prefix 
     * 
     * @param string $key Module key
     * @param bool $usePrefix Module prefix
     * @return string
     */
    public function getModuleName($key, $usePrefix = false)
    {
    	$prefix = 'MMD';
    	$moduleHash = $this->_getModuleHash();
    	$moduleBaseConfig = simplexml_load_file($moduleHash[$key.'.xml']);
    	$moduleName = ($usePrefix ? $prefix . ' ' : '') .  $moduleBaseConfig->modules->$key->self_name;
    	return $moduleName;
    }
    
    public function correction()
    {
        // checks whether upgrade from 2.15.5 to 2.15.6 is in progress
        if(Mage::registry('mmdsys_correction_setup')) {
            return;
        }
        
        $this->_isCorrection = true;
        $aData = array();
        foreach($this->getMMDModuleList() as $module)
        {
            if($module->isNeedCorrection())
            {
                $aData[$module->getKey()] = $module->getValue();
            }
        }
        $this->saveData($aData, array(), true);
        $this->_isCorrection = false;
    }
}