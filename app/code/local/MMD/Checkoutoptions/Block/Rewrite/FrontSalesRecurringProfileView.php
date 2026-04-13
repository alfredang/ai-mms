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
class MMD_Checkoutoptions_Block_Rewrite_FrontSalesRecurringProfileView  extends Mage_Sales_Block_Recurring_Profile_View
{
	public function getRecurringProfileCustomData()
    {
	    
        $iStoreId = $this->geRecurringProfile()->getStoreId();

        $oFront = Mage::app()->getFrontController();
	
        $iRecProfileId = $oFront->getRequest()->getParam('profile');
        
        $oCheckoutoptions  = Mage::getModel('checkoutoptions/checkoutoptions');

        $aCustomAtrrList = $oCheckoutoptions->getRecurringProfileCustomData($iRecProfileId, $iStoreId, false, true);

        $this->_shouldRenderInfo = true;
		foreach ($aCustomAtrrList as $aItem)
        {
            if($aItem['value'])
		    {
		        $this->_addInfo(array(
                    'label' => $aItem['label'],
                    'value' => $aItem['value'],
                ));
			}
		}
		
		$viewLabel = Mage::getStoreConfig('checkoutoptions/common_settings/checkoutoptions_additionalblock_label', $this->getStoreId());
		$this->setViewLabel($viewLabel);
    }
	
	public function geRecurringProfile()
    {
        return Mage::registry('current_recurring_profile');
    }
}
?>