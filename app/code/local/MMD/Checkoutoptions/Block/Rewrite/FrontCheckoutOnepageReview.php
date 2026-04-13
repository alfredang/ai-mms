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
class MMD_Checkoutoptions_Block_Rewrite_FrontCheckoutOnepageReview extends Mage_Checkout_Block_Onepage_Review
{
    public function getFieldHtml($aField)
    {
        $sSetName = 'customreview';
        
        return Mage::getModel('checkoutoptions/checkoutoptions')->getAttributeHtml($aField, $sSetName, 'onepage');
    }

    public function getCustomFieldList($iTplPlaceId)
    {
        $iStepId = Mage::helper('checkoutoptions')->getStepId('review');
        
        if (!$iStepId) return false;

        return Mage::getModel('checkoutoptions/checkoutoptions')->getCheckoutAttributeList($iStepId, $iTplPlaceId, 'onepage');
    }

    protected function _beforeToHtml()
    {
        if (version_compare(Mage::getVersion(), '1.5.0.0', 'lt'))
        {
            $this->setTemplate('mmdcommonfiles/design--frontend--base--default--template--checkout--onepage--review.phtml');
        }
        return parent::_beforeToHtml();
    }
}