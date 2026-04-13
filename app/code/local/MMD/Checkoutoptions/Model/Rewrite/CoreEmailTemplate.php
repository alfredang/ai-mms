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
class MMD_Checkoutoptions_Model_Rewrite_CoreEmailTemplate extends Mage_Core_Model_Email_Template
{
    /**
     * Send transactional email to recipient
     *
     * @param   int $templateId
     * @param   string|array $sender sneder informatio, can be declared as part of config path
     * @param   string $email recipient email
     * @param   string $name recipient name
     * @param   array $vars varianles which can be used in template
     * @param   int|null $storeId
     * @return  Mage_Core_Model_Email_Template
     */
    public function sendTransactional($templateId, $sender, $email, $name, $vars=array(), $storeId=null)
    {	
        if(isset($vars['order']))
        {
            $aCustomAtrrList = $this->_getCustomAttributesList($vars);
            
            $cfm = new Varien_Object;
            foreach($aCustomAtrrList as $attr)
            {   
                if(!isset($attr['attribute_code']) && isset($attr['code']))
                {
                    $attr['attribute_code'] = $attr['code'];
                }
                
                $cfm->setData($attr['attribute_code'], $attr['value']);
                if($attr['value'] && isset($attr['frontend_label']))
                {
                    $cfm->setData($attr['attribute_code'].'_label', $attr['frontend_label']);
                }
            }

            $vars['cfm'] = $cfm;

        }

        parent::sendTransactional($templateId, $sender, $email, $name, $vars, $storeId);
    }
    
    protected function _getCustomAttributesList($vars)
	{
		$aCustomAtrrList = array(); 
		
		$request = Mage::app()->getFrontController()->getRequest();
		$oCheckoutoptions  = Mage::getModel('checkoutoptions/checkoutoptions');
		
		$iOrderId = 0;
		
		if ($vars['order'] instanceof Varien_Object)
		{
			$iOrderId = $vars['order']->getId();
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
			$oOrder = $vars['order'];
			
			if (!$oOrder)
			{
				return false;
			}
			
			$iStoreId = $oOrder->getStoreId();
			$sPathInfo = $request->getPathInfo();
			
			$aCustomAtrrList = array();
			
			$aSessionAttrList = $this->_getSessionAttributeList($sPathInfo);
			
			if( !empty($aSessionAttrList) )
			{
				$oAttribute  = Mage::getModel('eav/entity_attribute');
				foreach($aSessionAttrList as $attributeId => $sValue)
				{
					$oAttribute->load($attributeId);
					$data = $oAttribute->getData();                    
					
					switch ($data['frontend_input'])
					{
						case 'text':
						case 'date': // to check?
						case 'textarea':
                        case 'static':
							$sValue = $sValue;
						break;
							
						case 'boolean':
							
							if ($sValue == 1)
							{
								$sValue = Mage::helper('catalog')->__('Yes');
							}
							elseif ($sValue) 
							{
								$sValue = '';
							}
							else 
							{
								$sValue = Mage::helper('catalog')->__('No');
							}
							
						break;
							
						case 'select':
						case 'radio':
							
							$aValueList = $oCheckoutoptions->getAttributeOptionValues($attributeId, $iStoreId, $sValue);
							if ($aValueList)
							{
								$sValue = $aValueList[0];
							}
						break;    
						
						case 'multiselect':
							if(version_compare(Mage::getVersion(), '1.6.0.0', '>='))
							{
								if(is_array($sValue))
								{
									$tempArray = array();
									foreach ($sValue as $val)
									{
										$explodedArr = explode(',', $val);
										
										foreach($explodedArr as $expVal)
										{
											array_push($tempArray, $expVal);
										}
									}
								$aValueList = $oCheckoutoptions->getAttributeOptionValues($attributeId, $iStoreId, $tempArray);
								}
								else
								{
									$aValueList = $oCheckoutoptions->getAttributeOptionValues($attributeId, $iStoreId, explode(',', $sValue));
								}
							}
							else
								$aValueList = $oCheckoutoptions->getAttributeOptionValues($attributeId, $iStoreId, $sValue);
							if ($aValueList)
							{
								$sValue = implode(', ', $aValueList);
							}
						break;
						
						case 'checkbox':
								$aValueList = $oCheckoutoptions->getAttributeOptionValues($attributeId, $iStoreId, $sValue);
							if ($aValueList)
							{
								$sValue = implode(', ', $aValueList);
							}
						break;                            
					}
					
					$data['value'] = $sValue;
					$aCustomAtrrList[] = $data;
				}
			}
		}
		return $aCustomAtrrList;
    }
	
	protected function _getSessionAttributeList($sPathInfo)
	{
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
        
	    $aSessionAttrList = ( isset($_SESSION['mmd_checkout_used'][$sPageType]) && is_array($_SESSION['mmd_checkout_used'][$sPageType]) ) ?  $_SESSION['mmd_checkout_used'][$sPageType] : array();
		
	    return $aSessionAttrList;
	}

}