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
class MMD_CustomOptions_Model_Catalog_Product_Type_Downloadable_Price extends Mage_Downloadable_Model_Product_Price {

    /**
     * Apply options price
     *
     * @param Mage_Catalog_Model_Product $product
     * @param int $qty
     * @param double $finalPrice
     * @return double
     */         
    
    // 100% copy from  ../Price.php
    protected function _applyOptionsPrice($product, $qty, $finalPrice) {

        if ($optionIds = $product->getCustomOption('option_ids')) {
            $basePrice = $finalPrice;
            $finalPrice = 0;
            foreach (explode(',', $optionIds->getValue()) as $optionId) {
                if ($option = $product->getOptionById($optionId)) {
                    $optionQty = null;
                    $quoteItemOptionInfoBuyRequest = unserialize($product->getCustomOption('info_buyRequest')->getValue());
                    switch ($option->getType()) {
                        case 'checkbox':
                            if (isset($quoteItemOptionInfoBuyRequest['options'][$optionId])) {                                                                
                                $optionValues = array();
                                $optionQtyArr = array();
                                foreach ($option->getValues() as $key=>$itemV) {                                    
                                    if (isset($quoteItemOptionInfoBuyRequest['options_'.$optionId.'_'.$itemV->getOptionTypeId().'_qty'])) $optionQty = intval($quoteItemOptionInfoBuyRequest['options_'.$optionId.'_'.$itemV->getOptionTypeId().'_qty']); else $optionQty = 1;
                                    $optionQtyArr[$itemV->getOptionTypeId()] = $optionQty;
                                }
                                $optionQty = $optionQtyArr;
                                break;                                
                            }
                            break;
                        case 'drop_down':
                        case 'radio':
                        case 'swatch':    
                            if (isset($quoteItemOptionInfoBuyRequest['options_'.$optionId.'_qty'])) $optionQty = intval($quoteItemOptionInfoBuyRequest['options_'.$optionId.'_qty']); else $optionQty = 1;
                        case 'multiple':
                            if (!isset($optionQty)) $optionQty = 1;
                            break;
                        case 'field':
                        case 'area':
                        case 'file':
                        case 'date':
                        case 'date_time':
                        case 'time':
                            break;
                    }

                    switch ($option->getType()) {
                        case 'field':
                        case 'area':
                        case 'file':
                        case 'date':
                        case 'date_time':
                        case 'time':
                            list($price, $priceType) = Mage::helper('customoptions')->getOptionPriceAndPriceType($option->getPrice(), $option->getPriceType(), $option->getSku(), $product->getStore());
                            $finalPrice += $this->_getCustomOptionsChargableOptionPrice($price, $priceType == 'percent', $basePrice, $qty, $option->getCustomoptionsIsOnetime());
                            break;                        
                        default: //multiple
                            $optionQty = 1;
                        case 'drop_down':
                        case 'radio':
                        case 'checkbox':
                        case 'swatch':    
                            $quoteItemOption = $product->getCustomOption('option_' . $option->getId());
                            $group = $option->groupFactory($option->getType())->setOption($option)->setQuoteItemOption($quoteItemOption);
                            $finalPrice += $group->getOptionPrice($quoteItemOption->getValue(), $basePrice, $qty, $optionQty, $product->getStore());
                    }
                }
            }
            $product->setBaseCustomoptionsPrice($finalPrice); // for additional info
            if (!Mage::helper('customoptions')->getProductAbsolutePrice($product) || $finalPrice==0) $finalPrice += $basePrice;
        }        
        return $finalPrice;
    }

    protected function _getCustomOptionsChargableOptionPrice($price, $isPercent, $basePrice, $qty = 1, $customoptionsIsOnetime = 0) {
        $sub = 1;
        if ($customoptionsIsOnetime) {
            $sub = $qty;
        }
        if ($isPercent) {
            return ($basePrice * $price / 100) / $sub;
        } else {
            return $price / $sub;
        }
    }

}