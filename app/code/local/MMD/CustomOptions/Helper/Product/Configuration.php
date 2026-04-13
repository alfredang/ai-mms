<?php
/**
 * MMD
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the MMD EULA that is bundled with
 * this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://www.magemobiledesign.com/LICENSE-1.0.html
 *
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade the extension
 * to newer versions in the future. If you wish to customize the extension
 * for your needs please refer to http://www.magemobiledesign.com/ for more information
 *
 * @category   MMD
 * @package    MMD_CustomOptions
 * @copyright  Copyright (c) 2013 MMD (http://www.magemobiledesign.com/)
 * @license    http://www.magemobiledesign.com/LICENSE-1.0.html
 */

/**
 * Advanced Product Options extension
 *
 * @category   MMD
 * @package    MMD_CustomOptions
 * @author     MMD Dev Team
 */
class MMD_CustomOptions_Helper_Product_Configuration extends MMD_CustomOptions_Helper_Product_Configuration_Abstract {
    
    public function getCustomOptions(Mage_Catalog_Model_Product_Configuration_Item_Interface $item) {
        $this->setCustomOptionsDetails($item);
        return parent::getCustomOptions($item);
    }
  
    // $option = $option or $optionValue
    public function getOptionFormatPrice($option, $optionTotalQty = 1, $product, $quote) {
        $helper = Mage::helper('customoptions');
        $store = $product->getStore();        
        
        if ($option->getType()) {
            //field, area, file, date, date_time, time
            list($price, $priceType, $isProductPrice, $taxClassId) = $helper->getOptionPriceAndPriceType($option->getPrice(), $option->getPriceType(), $option->getSku(), $store);
        } else {
            //drop_down, radio, checkbox, multiple
            // apply tier price
            list($price, $priceType, $isProductPrice, $taxClassId) = $helper->getOptionTierPriceAndType($option, $optionTotalQty, $store);
        }        
        $basePrice = Mage::helper('customoptions')->getActualProductPrice($product, $store);

        $price = (($priceType=='percent')?$basePrice * $price / 100 : $price) * $optionTotalQty;


        
        if ($price!=0) {
            // calculate tax            
            if (!$isProductPrice) $taxClassId = $product->getTaxClassId();
            if (Mage::helper('tax')->priceIncludesTax($store)) {
                $priceInclTax = $price;
                $price = $helper->getPriceExcludeTax($price, $quote, $taxClassId);
            } else {    
                $priceInclTax = $price + $helper->getTaxPrice($price, $quote, $taxClassId);
            }
            
            // exclude tax
            if (Mage::helper('tax')->displayCartPriceExclTax($store)) {
                return ' - ' . $helper->currencyByStore($price, $store, true, false);
            }
            
            // exclude and include tax
            if (Mage::helper('tax')->displayCartBothPrices($store)) {                                
                return ' - '  . $helper->currencyByStore($price, $store, true, false) . ' ' . $helper->__('(Incl. Tax %s)', $helper->currencyByStore($priceInclTax, $store, true, false));
            }
            
            // include tax
            if (Mage::helper('tax')->displayCartPriceInclTax($store)) {
                return ' - ' . $helper->currencyByStore($priceInclTax, $store, true, false);
            }
        }
        return '';        
    }
    
    
    public function setCustomOptionsDetails($item) {
        if (!Mage::helper('customoptions')->canShowQtyPerOptionInCart()) return $this;        
        $product = $item->getProduct();
        // if bad magento))
        if (is_null($product->getHasOptions())) $product->load($product->getId());        
        if (!$product->getHasOptions()) return $this;
        $store = $product->getStore();
        
        $optionIds = $item->getOptionByCode('option_ids');
        if ($optionIds) {
            foreach (explode(',', $optionIds->getValue()) as $optionId) {
                $option = $product->getOptionById($optionId);
                if ($option) {
                    $optionQty = null;
                    $qty = $item->getQty();
                    $quoteItemOptionInfoBuyRequest = unserialize($product->getCustomOption('info_buyRequest')->getValue());
                    switch ($option->getType()) {
                        case 'checkbox':
                            if (isset($quoteItemOptionInfoBuyRequest['options'][$optionId])) {                                                                
                                $optionValues = array();
                                foreach ($option->getValues() as $key=>$itemV) {
                                    if (isset($quoteItemOptionInfoBuyRequest['options_'.$optionId.'_'.$itemV->getOptionTypeId().'_qty'])) $optionQty = intval($quoteItemOptionInfoBuyRequest['options_'.$optionId.'_'.$itemV->getOptionTypeId().'_qty']); else $optionQty = 1;
                                    if (!isset($quoteItemOptionInfoBuyRequest['options'][$optionId]) || in_array($itemV->getOptionTypeId(), $quoteItemOptionInfoBuyRequest['options'][$optionId])) {
                                        $optionTotalQty = ($option->getCustomoptionsIsOnetime()?$optionQty:$optionQty*$qty);                                    	
                                        if ($itemV->getOrigTitle()) $itemV->setTitle($itemV->getOrigTitle()); else $itemV->setOrigTitle($itemV->getTitle());
                                    	$itemV->setTitle(($optionTotalQty>1?$optionTotalQty.' x ':'') . $itemV->getTitle() . $this->getOptionFormatPrice($itemV, $optionTotalQty, $product, $item->getQuote()));
                                    }
                                    $optionValues[$key]=$itemV;
                                }
                                $option->setValues($optionValues);
                                break;                                
                            }
                            break;
                        case 'drop_down':
                        case 'swatch':
                        case 'radio':                            
                            if (isset($quoteItemOptionInfoBuyRequest['options_'.$optionId.'_qty'])) $optionQty = intval($quoteItemOptionInfoBuyRequest['options_'.$optionId.'_qty']); else $optionQty = 1;
                        case 'multiple':
                            if (!isset($optionQty)) $optionQty = 1;
                            $optionValues = array();                            
                            $optionTotalQty = ($option->getCustomoptionsIsOnetime()?$optionQty:$optionQty*$qty);
                            foreach ($option->getValues() as $key=>$itemV) {                                
                                if (!isset($quoteItemOptionInfoBuyRequest['options'][$optionId]) || $itemV->getOptionTypeId()==$quoteItemOptionInfoBuyRequest['options'][$optionId]) {
                                    if ($itemV->getOrigTitle()) $itemV->setTitle($itemV->getOrigTitle()); else $itemV->setOrigTitle($itemV->getTitle());
                                    $itemV->setTitle(($optionTotalQty>1?$optionTotalQty.' x ':'') . $itemV->getTitle() . $this->getOptionFormatPrice($itemV, $optionTotalQty, $product, $item->getQuote()));                             
                                }
                                $optionValues[$key]=$itemV;
                            }
                            $option->setValues($optionValues);
                            break;
                        case 'field':
                        case 'area':
                        case 'file':
                        case 'date':
                        case 'date_time':
                        case 'time':
                            $optionTotalQty = ($option->getCustomoptionsIsOnetime()?1:$qty);
                            if ($option->getOrigTitle()) $option->setTitle($option->getOrigTitle()); else $option->setOrigTitle($option->getTitle());                            
                            $option->setTitle(($optionTotalQty>1?$optionTotalQty.' x ':'') . $option->getTitle() . $this->getOptionFormatPrice($option, $optionTotalQty, $product, $item->getQuote()));
                            break;
                    }
                }
            }
        }
    }
    
    
}
