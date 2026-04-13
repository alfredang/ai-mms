<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Model_Observer extends MMD_Mmdsys_Abstract_Model
{
    /**
     * @var bool
     */
    protected $_correctionDone = false;
    
    /**
     * Corrects modules' status and launches install/uninstall scripts if some module was enabled/disabled through xml.
     */
    public function correction()
    {
        if (!$this->_correctionDone) {
            $this->tool()->platform()->getModules(); // load modules
            if ($this->tool()->platform()->isNeedCorrection()) {
                $mmdsysModel = new MMD_Mmdsys_Model_Mmdsys(); 
                $mmdsysModel->correction(); 
            }
            $this->_correctionDone = true;
        }
    }
    
    public function errorRender()
    {
        $this->tool()->platform()->renderAdminError(true);
    }
    
    /**
     * Replacement for an old abstract rewrite necessary for some extensions.
     * Compatible with Magento CE 1.4.1+
     * 
     * @param Varien_Object $observer
     */
    public function compatibility($observer)
    {
        if (version_compare(Mage::getVersion(), '1.4.1.0', 'ge')) {
            Mage::dispatchEvent('mmdsys_block_abstract_to_html_after', $observer->getData());
        }
    }

    /**
     * Update news from www.mmd.com
     */
    public function updateNews()
    {
        $news = new MMD_Mmdsys_Model_News_Recent();
        $news->loadData();
        
        $important = new MMD_Mmdsys_Model_News_Important();
        $important->loadData();
    }
}