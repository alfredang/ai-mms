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
class MMD_Checkoutoptions_Block_Rewrite_FrontSalesOrderEmailItems extends Mage_Sales_Block_Order_Email_Items
{
    protected static $_excludeArray = array('paypal','epay','paypaluk');
    
    public function _toHtml()
    {
        $sContent = '';
        
        $aCustomAtrrList = $this->getOrderCustomData();
        if ($aCustomAtrrList)
        {
            $sContent .= '<TABLE cellSpacing=0 cellPadding=0 width="100%" border=0>
              <THEAD>
              <TR>
                <TH 
                style="'.Mage::getStoreConfig('checkoutoptions/email_settings/checkoutoptions_email_TheadTrThStyle', $this->getStoreId()).'" 
                align=left width="100%" bgColor=#EAEAEA>' . Mage::getStoreConfig('checkoutoptions/email_settings/checkoutoptions_email_label', $this->getStoreId()) . '</TH></TR></THEAD>
              <TBODY>
              <TR>
                <TD 
                style="'.Mage::getStoreConfig('checkoutoptions/email_settings/checkoutoptions_email_TbodyTrTdStyle', $this->getStoreId()).'" 
                vAlign=top>';
            
            foreach ($aCustomAtrrList as $aItem)
            {
                if($aItem['value'])
                    $sContent .= '<b>' . $aItem['label'] . ':</b> ' . Mage::helper('core')->escapeHtml($aItem['value']) . '<br>';
            }
            
            $sContent .= '</TD></TR></TBODY></TABLE><BR />';
            
        }
        
        $sContent .= parent::_toHtml();
        
        return $sContent;
    }

    public function getOrderCustomData()
    {
        $oFront = Mage::app()->getFrontController();
        $request = $oFront->getRequest();
        
        $oCheckoutoptions  = Mage::getModel('checkoutoptions/checkoutoptions');
        
        $iOrderId = 0;
        if (in_array($request->getModuleName(), self::$_excludeArray) && $this->getOrder())
        {
            $iOrderId = $this->getOrder()->getId();
        }
        if (!$iOrderId)
        {
            $iOrderId = $request->getParam('order_id');
        }
        
        if ($iOrderId) // sent order from admin area 
        {
            $oOrder = Mage::getModel('sales/order')->load($iOrderId);
            
            $iStoreId = $oOrder->getStoreId();
            
            $aCustomAtrrList = $oCheckoutoptions->getEmailOrderCustomData($iOrderId, $iStoreId);
        }
        
        if(empty($aCustomAtrrList)) 
        {
            $oOrder = $this->getOrder();
            
            if (!$oOrder) return false;
            
            $iStoreId = $oOrder->getStoreId();
            $sPathInfo = $request->getPathInfo();
            if (isset($_SESSION['mmd_checkout_used']['adminorderfields']))
            {
                $sPageType = 'adminorderfields';
            }
            elseif ($sPathInfo AND strpos($sPathInfo, '/multishipping/'))
            {
                $sPageType = 'multishipping';
            }
            else 
            {
                $sPageType = 'onepage';
            }
            $aCustomAtrrList = $oCheckoutoptions->getSessionCustomData($sPageType, $iStoreId, true);
        }
        return $aCustomAtrrList;
    }
}