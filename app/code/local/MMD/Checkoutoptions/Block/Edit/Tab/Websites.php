<?php
/**
 * Checkout Fields Manager
 *
 * @category:    MMD
 * @package:     MMD_Checkoutoptions
 * @version      2.9.2
 * @license:     
 * @copyright:   Copyright (c) 2013 MMD, Inc. (http://www.mmd.com)
 */
class MMD_Checkoutoptions_Block_Edit_Tab_Websites extends Mage_Adminhtml_Block_Widget
{
    protected $_bIsGlobal = false;
    
    public function __construct()
    {
        parent::__construct();
        $this->setTemplate('checkoutoptions/websites.phtml');
    }
    
    public function getStores()
    {
        $stores = $this->getData('stores');
        if (is_null($stores)) {
            $stores = Mage::getModel('core/store')
                ->getResourceCollection()
                ->setLoadDefault(true)
                ->load();
            $this->setData('stores', $stores);
        }
        return $stores;
    }

    public function getWebsites()
    {
        $websites = $this->getData('websites');
        
        if (is_null($websites)) {
            foreach (Mage::getConfig()->getNode('websites')->children() as $code=>$config) {
                $id = (string)$config->system->website->id;
                $name = (string)$config->system->website->name;
                if ($id!=0) {
                    $websites[$id] = $name;
                }
            }
            $this->setData('websites', $websites);
        }
        return $websites;
    }

    public function getIsGlobal()
    {
        if (!$this->_bIsGlobal)
        {
            $model = Mage::registry('checkoutoptions_data');
            
            if ($model->getId())
            {
                $this->_bIsGlobal   = $model->getData('is_visible_in_advanced_search');
            }
            else 
            {
                $this->_bIsGlobal   = 1;
            }
        }
        
        return $this->_bIsGlobal;
    }
    
    public function getFullDataList()
    {
        $aDataList = array();
        
        $aWebsiteHash = $this->getWebsites();
        
        $model = Mage::registry('checkoutoptions_data');
        
        if ($model->getId())
        {
            $sSavedStoreData    = $model->getData('note');
            $sSavedSitesData    = $model->getData('apply_to');
        }
        else 
        {
            $sSavedStoreData    = '';
            $sSavedSitesData    = '';
        }
        
        $this->_bIsGlobal = $this->getIsGlobal();
        
        if ($sSavedStoreData)
        {
            $sSavedStoreHash = explode(',', $sSavedStoreData);
        }
        else 
        {
            $sSavedStoreHash = array();
        }
        
        if ($sSavedSitesData)
        {
            $sSavedSitesHash = explode(',', $sSavedSitesData);
        }
        else 
        {
            $sSavedSitesHash = array();
        }
        
        foreach ($aWebsiteHash as $iKey => $sVal)
        {
            if ($this->_bIsGlobal OR in_array($iKey, $sSavedSitesHash))
            {
                $sValue = 1;
            }
            else 
            {
                $sValue = '';
            }
            
            $aDataList[$iKey] = array('label' => $sVal, 'value' => $sValue, 'stores' => array());
        }
        
        $aStores = $this->getStores();
        
        foreach ($this->getStores() as $store) 
        {
            $aStoreData = $store->getData();
            
            if ($aStoreData['store_id'] != 0)
            {
                if ($this->_bIsGlobal OR in_array($aStoreData['store_id'], $sSavedStoreHash))
                {
                    $sValue = 1;
                }
                else 
                {
                    $sValue = '';
                }
                
                $aDataList[$aStoreData['website_id']]['stores'][$aStoreData['store_id']] = array
                (
                    'label' => $store->getName(), 
                    'value' => $sValue,
                );
            }
        }
        
        return $aDataList;
    }
}