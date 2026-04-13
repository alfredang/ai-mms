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
class MMD_Checkoutoptions_Block_Rewrite_FrontCheckoutOnepageReviewInfo extends Mage_Checkout_Block_Onepage_Review_Info
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
        if (version_compare(Mage::getVersion(), '1.5.0.0', 'ge'))
        {
            $this->setTemplate('mmdcommonfiles/design--frontend--base--default--template--checkout--onepage--review--info.phtml');
        }
        return parent::_beforeToHtml();
    }

    protected function _toHtml()
    {
        $html = parent::_toHtml();

        if ('' != $html)
        {
            if (Mage::getConfig()->getNode('modules/Ebizmarts_SagePaySuite/active'))
            {
                $html .= '
<script type="text/javascript">
//<![CDATA[
SageServer = new EbizmartsSagePaySuite.Checkout
(
    {
        \'checkout\':  checkout,
        \'review\':    review,
        \'payment\':   payment,
        \'billing\':   billing,
        \'accordion\': accordion
    }
);
//]]>
</script>
';
            }
        }

        return $html;
    }
}