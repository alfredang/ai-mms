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

class MMD_CustomOptions_Block_Catalog_Product_View_Options_Type_Select extends Mage_Catalog_Block_Product_View_Options_Type_Select {

    static $isFirstOption = true;

    public function getValuesHtml() {
        $_option = $this->getOption();        
		$current_product = Mage::registry('current_product');
        $helper = Mage::helper('customoptions');
        $displayQty = $helper->canDisplayQtyForOptions();
        $hideOutOfStockOptions = $helper->canHideOutOfStockOptions();
        $enabledInventory = $helper->isInventoryEnabled();
        $enabledDependent = $helper->isDependentEnabled();
        $enabledTierPrice = $helper->isTierPriceEnabled();
        $enabledSpecialPrice = $helper->isSpecialPriceEnabled();
        
        if ((version_compare(Mage::getVersion(), '1.5.0', '>=') && version_compare(Mage::getVersion(), '1.9.0', '<')) || version_compare(Mage::getVersion(), '1.10.0', '>=')) {
            $configValue = $this->getProduct()->getPreconfiguredValues()->getData('options/' . $_option->getId());                                                    
        } else {
            $configValue= false;
        }
        
        $buyRequest = false;
        $quoteItemId = 0;
        if ($helper->isQntyInputEnabled() && Mage::app()->getRequest()->getControllerName()!='product') {
            $quoteItemId = (int) $this->getRequest()->getParam('id');
            if ($quoteItemId) {                
                if (Mage::app()->getStore()->isAdmin()) {
                    $item = Mage::getSingleton('adminhtml/session_quote')->getQuote()->getItemById($quoteItemId);
                } else {
                    $item = Mage::getSingleton('checkout/cart')->getQuote()->getItemById($quoteItemId);           
                }
                if ($item) {
                    $buyRequest = $item->getBuyRequest();
                    if ($_option->getType() != Mage_Catalog_Model_Product_Option::OPTION_TYPE_CHECKBOX) {
                        $optionQty = $buyRequest->getData('options_' . $_option->getId() . '_qty');
                        $_option->setOptionQty($optionQty);
                    }
                }
            }
        }
        
        $tiersJs = '';
        if ($_option->getType()==Mage_Catalog_Model_Product_Option::OPTION_TYPE_DROP_DOWN || $_option->getType()==Mage_Catalog_Model_Product_Option::OPTION_TYPE_MULTIPLE || $_option->getType()==MMD_CustomOptions_Model_Catalog_Product_Option::OPTION_TYPE_SWATCH) {            
            
            $require = '';
            if ($_option->getIsRequire(true)) {                
                if ($enabledDependent && $_option->getIsDependent()) $require = ' required-dependent'; else $require = ' required-entry';
            }
            
            $extraParams = ($enabledDependent && $_option->getIsDependent()?' disabled="disabled"':'');
            $select = $this->getLayout()->createBlock('core/html_select')
                    ->setData(array(
                        'id' => 'select_' . $_option->getId(),
                        'class' => $require . ' product-custom-option' . ($_option->getType()==MMD_CustomOptions_Model_Catalog_Product_Option::OPTION_TYPE_SWATCH ? ' swatch' : '')
                    ));
            if ($_option->getType()==Mage_Catalog_Model_Product_Option::OPTION_TYPE_DROP_DOWN || $_option->getType()==MMD_CustomOptions_Model_Catalog_Product_Option::OPTION_TYPE_SWATCH) {
                $select->setName('options[' . $_option->getid() . ']')
                        ->addOption('', $this->__('-- Please Select --'));
            } else {
                $select->setName('options[' . $_option->getid() . '][]');
                $select->setClass('multiselect' . $require . ' product-custom-option');
            }
            
            $imagesHtml = '';
            $setProdutQtyJs = '';
            
            $dependentJs = '';
            $defaultFlag = false;
            
            $itemValueCount = count($_option->getValues());
            
            if ($enabledDependent && $_option->getType()==Mage_Catalog_Model_Product_Option::OPTION_TYPE_MULTIPLE) $dependentJs .= 'dependentDefault["select_' . $_option->getId().'"] = [];';
            
            foreach ($_option->getValues() as $_value) {                
                $qty = '';
                $customoptionsQty = $helper->getCustomoptionsQty($_value->getCustomoptionsQty(), $_value->getSku(), $_option->getId(), $_value->getId(), $quoteItemId);
                if ($enabledInventory && $hideOutOfStockOptions && ($customoptionsQty===0 || $_value->getIsOutOfStock())) continue;
                
                
				$courseRegDate =  $_value->getreg_course();
				
				 $today = strtotime(date('m/d/y'));
				/*$from =  strtotime($current_product->getNews_from_date()); 
				 $to =  strtotime($current_product->getNews_to_date());
				
				 if($today >= $from && $today <= $to)
				 {
					 $statusopt ="Open";
				 }
				 elseif($today>=$from && $current_product->getNews_to_date()=="")
				 {
					  $statusopt ="Open"; 
				 }
				 elseif($today > $to)
				 {
					  $statusopt ="Close"; 
				 }
				 else { $statusopt ="Open"; }*/
						
                $selectOptions = array();
                if ($enabledInventory && $customoptionsQty===0) {
                    $selectOptions['disabled'] = 'disabled'; 
                }
				/* elseif($statusopt=="Close")*/
				elseif($today>=strtotime($courseRegDate) &&  $_value->getreg_course()!="")
				 {
					 $selectOptions['disabled'] = 'disabled'; 
				 }
				
				/*
				elseif(strtotime('now') <= strtotime($_value->getreg_from()) || strtotime('now') >= strtotime($_value->getreg_to())){
					$selectOptions['disabled'] = 'disabled';
				}*/
								
                if ($_value->getDefault() == 1 && !isset($selectOptions['disabled']) && !$configValue) {
                    if (!$enabledDependent || !$_option->getIsDependent()) $selectOptions['selected'] = 'selected';
                    if ($enabledDependent) {
                        if ($_option->getType()==Mage_Catalog_Model_Product_Option::OPTION_TYPE_DROP_DOWN || $_option->getType()==MMD_CustomOptions_Model_Catalog_Product_Option::OPTION_TYPE_SWATCH) {
                            $dependentJs .= 'dependentDefault["select_' . $_option->getId().'"] = '.$_value->getOptionTypeId().';';
                        } else {
                            $dependentJs .= 'dependentDefault["select_' . $_option->getId().'"]['.$_value->getOptionTypeId().'] = 1;';
                        }
                    }    
                    $defaultFlag = true;
                }

                if ($enabledInventory) {
                    if ($displayQty && substr($customoptionsQty, 0, 1)!='x' && $customoptionsQty!=='') {
                        $qty = ' (' . ($customoptionsQty > 0 ? $customoptionsQty : $helper->__('Out of stock')) . ')';
                    }                
                    if (substr($customoptionsQty, 0, 1)=='x') {
                        if (!$setProdutQtyJs) {
                            $setProdutQtyJs = 'optionSetQtyProductData['.$_option->getId().'] = [];';
                        } 
                        $setProdutQtyJs .= 'optionSetQtyProductData['.$_option->getId().']['.$_value->getOptionTypeId().']='.intval(substr($customoptionsQty, 1)).';';
                    }
                }
                
                if (!Mage::app()->getStore()->isAdmin() && $_value->getIsMsrp()) {
                    $priceStr = '';
                } else {
                    $priceStr = $helper->getFormatedOptionPrice(
                            $this->getProduct(),
                            $this->_formatPrice(array(
                                'is_percent' => ($_value->getPriceType() == 'percent') ? true : false,
                                'pricing_value' => $_value->getPrice(true)
                                    ), false)
                        );

                    // Special Price
                    if ($enabledSpecialPrice && $_value->getSpecialPrice()>0) {
                        $priceStr = '(' . $priceStr . ') ' . $helper->getFormatedOptionPrice(
                            $this->getProduct(),
                            $this->_formatPrice(array(
                                'is_percent' => ($_value->getPriceType() == 'percent') ? true : false,
                                'pricing_value' => $_value->getSpecialPrice()
                                    ), false)
                        ) . ' '. $_value->getSpecialComment();
                    }
                }
                
                // swatch
                if ($_option->getType()==MMD_CustomOptions_Model_Catalog_Product_Option::OPTION_TYPE_SWATCH) {
                    $images = $_value->getImages();
                    if (count($images)>0) {
                        if ($customoptionsQty===0) {
                            $onClick = 'return false;';
                            $className = 'swatch swatch-disabled';
                        } else {
                            $onClick = 'optionSwatch.select('. $_option->getId() .', '.$_value->getOptionTypeId().'); return false;';
                            $className = 'swatch';
                        }
                        
                        $image = $images[0];
                        if ($image['source']==1) { // file
                            $arr = $helper->getImgHtml($image['image_file'], false, false, true);
                            if (isset($arr['big_img_url'])) {
                                $imagesHtml .= '<li id="swatch_'. $_value->getOptionTypeId() .'" class="'. $className .'">'.
                                        '<a href="'.$arr['big_img_url'].'" onclick="'. $onClick .'">'.
                                            '<img src="'.$arr['url'].'" title="'.$this->htmlEscape($_value->getTitle()).'" class="swatch small-image-preview v-middle" />'.
                                        '</a>'.
                                    '</li>';
                            }
                        } else if ($image['source']==2) { // color
                            $imagesHtml .= '<li id="swatch_'. $_value->getOptionTypeId() .'" class="'. $className .'">'.
                                        '<a href="#" onclick="'. $onClick .'">'.
                                            '<div class="swatch container-swatch-color small-image-preview v-middle"" title="'.$this->htmlEscape($_value->getTitle()).'">'.
                                                '<div class="swatch-color" style="background:'. $image['image_file'] .';">&nbsp;</div>'.
                                            '</div>'.
                                        '</a>'.
                                    '</li>';
                        }
                    }
                } else {
                    if (!$imagesHtml && $_value->getImages() && ($_option->getImageMode()==1 || ($_option->getImageMode()>1 && $_option->getExcludeFirstImage()))) {
                        $imagesHtml = '<div id="customoptions_images_'. $_option->getId() .'" class="customoptions-images-div" style="display:none"></div>';
                    }
                }
                
                if ($enabledDependent) {
                    if ($_value->getDependentIds()) {                    
                        $dependentJs .= 'dependentData['.$_value->getOptionTypeId().'] = ['.$_value->getDependentIds().']; ';
                    }                
                    if ($_value->getInGroupId()) {
                        $dependentJs .= 'inGroupIdData['.$_value->getInGroupId().'] = {"disabled":'.($_option->getIsDependent()?'true':'false').', "select_'. $_option->getId() .'":'.$_value->getOptionTypeId().'}; ';
                    }
                } 
                if ($enabledTierPrice) $tiersJs .= $this->getTiersJs($_option, $_value);
                $select->addOption($_value->getOptionTypeId(), $_value->getTitle() . ' ' . $priceStr . $qty, $selectOptions);
            }
            if ($_option->getType() == Mage_Catalog_Model_Product_Option::OPTION_TYPE_MULTIPLE) {
                $extraParams .= ' multiple="multiple"';
            } elseif ($_option->getType()==MMD_CustomOptions_Model_Catalog_Product_Option::OPTION_TYPE_SWATCH) {
                $extraParams .= ' style="visibility:hidden; float:left; height:1px;"';
            }
                        
            if ($setProdutQtyJs) $setProdutQtyFunc = 'optionSetQtyProduct.setQty();'; else $setProdutQtyFunc = '';
            if ($imagesHtml) $showImgFunc = 'optionImages.showImage(this);'; else $showImgFunc = '';
            
            if ($_option->getType()==MMD_CustomOptions_Model_Catalog_Product_Option::OPTION_TYPE_SWATCH) $showImgFunc .= ' optionSwatch.change(this)';
            
            $select->setExtraParams('onchange="'.(($enabledDependent)?'dependentOptions.select(this);':'')                
                .((Mage::app()->getStore()->isAdmin())?'':'opConfig.reloadPrice();')
                .$setProdutQtyFunc
                .$showImgFunc.'"'.$extraParams);
            
            if ($configValue) {
                $select->setValue($configValue);
                if ($enabledDependent) $dependentJs .= 'dependentDefault["select_' . $_option->getId().'"] = '.$configValue.';';
            }
            
            if ((count($select->getOptions())>1 && ($_option->getType()==Mage_Catalog_Model_Product_Option::OPTION_TYPE_DROP_DOWN || $_option->getType()==MMD_CustomOptions_Model_Catalog_Product_Option::OPTION_TYPE_SWATCH)) || (count($select->getOptions())>0 && $_option->getType()==Mage_Catalog_Model_Product_Option::OPTION_TYPE_MULTIPLE)) {
                $outHTML = $select->getHtml();
                
                if ($_option->getType()==MMD_CustomOptions_Model_Catalog_Product_Option::OPTION_TYPE_SWATCH) {
                    $outHTML = '<ul id="ul_swatch_'. $_option->getId() .'">' . $imagesHtml . '</ul>' . $outHTML;
                } else {
                    if ($imagesHtml) {
                        if ($helper->isImagesAboveOptions()) $outHTML = $imagesHtml.$outHTML; else $outHTML .= $imagesHtml;
                    }
                }
                
                
                if ($defaultFlag) $outHTML.='<script type="text/javascript">'.$showImgFunc.'</script>';
                if ($dependentJs) $outHTML.='<script type="text/javascript">'.$dependentJs.'</script>';
                if ($tiersJs) $outHTML.='<script type="text/javascript">'.$tiersJs.'</script>';
                if ($setProdutQtyJs) {$outHTML.='<script type="text/javascript">'.$setProdutQtyJs.'optionSetQtyProduct.hideQty();</script>'; $_option->setOptionSetQtyProduct(1);}                
                
                return $outHTML;
            }
            
        } elseif ($_option->getType()==Mage_Catalog_Model_Product_Option::OPTION_TYPE_RADIO || $_option->getType()==Mage_Catalog_Model_Product_Option::OPTION_TYPE_CHECKBOX) {
            $selectHtml = '';
            $dependentJs = '';
            $setProdutQtyJs = '';            
                        
            $require = '';
            if ($_option->getIsRequire(true)) {                
                if ($enabledDependent && $_option->getIsDependent()) $require = ' required-dependent'; else $require = ' validate-one-required-by-name';
            }
            
            $arraySign = '';
            switch ($_option->getType()) {
                case Mage_Catalog_Model_Product_Option::OPTION_TYPE_RADIO:
                    $type = 'radio';
                    $class = 'radio';
                    break;
                case Mage_Catalog_Model_Product_Option::OPTION_TYPE_CHECKBOX:
                    $type = 'checkbox';
                    $class = 'checkbox';
                    $arraySign = '[]';
                    break;
            }
            $count = 1;
            foreach ($_option->getValues() as $_value) {
                $count++;
                
                if (!Mage::app()->getStore()->isAdmin() && $_value->getIsMsrp()) {
                    $priceStr = '';
                } else {
                    $priceStr = $helper->getFormatedOptionPrice(
                            $this->getProduct(),
                            $this->_formatPrice(array(
                                'is_percent' => ($_value->getPriceType() == 'percent') ? true : false,
                                'pricing_value' => $_value->getPrice(true)
                            ))
                        );

                    // Special Price
                    if ($enabledSpecialPrice && $_value->getSpecialPrice()>0) {
                        $priceStr = '<s>' . $priceStr . '</s> <span class="special-price">' . $helper->getFormatedOptionPrice(
                            $this->getProduct(),
                            $this->_formatPrice(array(
                                'is_percent' => ($_value->getPriceType() == 'percent') ? true : false,
                                'pricing_value' => $_value->getSpecialPrice()
                                    ), false)
                        ) . ' ' . $_value->getSpecialComment() . '</span>';

                    }
                }
                
                $qty = '';
                $customoptionsQty = $helper->getCustomoptionsQty($_value->getCustomoptionsQty(), $_value->getSku(), $_option->getId(), $_value->getId(), $quoteItemId);
                
                if ($enabledInventory && $hideOutOfStockOptions && ($customoptionsQty===0 || $_value->getIsOutOfStock())) continue;
                
                $inventory = ($enabledInventory && $customoptionsQty===0) ? false : true;
                $disabled = (!$inventory) || ($enabledDependent && $_option->getIsDependent()) ? 'disabled="disabled"' : '';
                if ($enabledInventory) {
                    if ($displayQty && substr($customoptionsQty, 0, 1)!='x' && $customoptionsQty!=='') {
                        $qty = ' (' . ($customoptionsQty > 0 ? $customoptionsQty : $helper->__('Out of stock')) . ')';
                    }

                    if (substr($customoptionsQty, 0, 1)=='x') {
                        if (!$setProdutQtyJs) {
                            $setProdutQtyJs = 'optionSetQtyProductData['.$_option->getId().'] = [];';
                        } 
                        $setProdutQtyJs .= 'optionSetQtyProductData['.$_option->getId().']['.$_value->getOptionTypeId().']='.intval(substr($customoptionsQty, 1)).';';                        
                    }
                }    
                
                                
                if ($disabled && $enabledDependent && $helper->hideDependentOption() && $_option->getIsDependent()) $selectHtml .= '<li style="display: none;">'; else $selectHtml .= '<li>';
                
                $imagesHtml = '';
                $images = $_value->getImages();
                if ($images) {
                    if ($_option->getImageMode()==1) {
                        foreach($images as $image) {
                            if ($image['source']==1) { // file
                                $imagesHtml .= $helper->getImgHtml($image['image_file']);
                            } else if ($image['source']==2) { // color
                                $imagesHtml .= $this->getColorHtml($image['image_file']);
                            }
                        }
                    } elseif ($_option->getExcludeFirstImage()) {
                        $image = $images[0];
                        if ($image['source']==1) { // file
                            $imagesHtml = $helper->getImgHtml($image['image_file']);
                        } else if ($image['source']==2) { // color
                            $imagesHtml = $this->getColorHtml($image['image_file']);
                        }
                    }
                }
                                
                if ($configValue) {                    
                    $htmlValue = $_value->getOptionTypeId();
                    if ($arraySign) {
                        $checked = (is_array($configValue) && in_array($htmlValue, $configValue)) ? 'checked' : '';
                    } else {
                        $checked = ($configValue == $htmlValue ? 'checked' : '');
                    }
                } else {
                    $checked = ($_value->getDefault()==1 && !$disabled) ? 'checked' : '';
                }                
                
                if ($enabledDependent) {
                    if ($_value->getDependentIds()) {                    
                        $dependentJs .= 'dependentData['.$_value->getOptionTypeId().'] = ['.$_value->getDependentIds().']; ';
                    }                
                    if ($_value->getInGroupId() ) {
                        $dependentJs .= 'inGroupIdData['.$_value->getInGroupId().'] = {"disabled":'.($_option->getIsDependent()?'true':'false').', "out_of_stock":'.(($enabledInventory && $customoptionsQty===0)?'true':'false').', "options_'.$_option->getId().'_'.$count.'":1}; ';
                    }
                    if ($checked || (!$configValue && $_value->getDefault()==1 && $inventory)) $dependentJs .= 'dependentDefault["options_' . $_option->getId() . '_' . $count . '"] = 1;';
                }

                if ($setProdutQtyJs) $setProdutQtyFunc = 'optionSetQtyProduct.setQty();'; else $setProdutQtyFunc = '';
                if ($checked) $setProdutQtyJs .= $setProdutQtyFunc;                
                
                if ($images && $_option->getImageMode()>1) $showImgFunc = 'optionImages.showImage(this);'; else $showImgFunc = '';
                
                $onclick = (($enabledDependent)?'dependentOptions.select(this);':'') . ((Mage::app()->getStore()->isAdmin())?'':'opConfig.reloadPrice();') . $setProdutQtyFunc . $showImgFunc;
  
                
                if ($helper->isQntyInputEnabled() && $_option->getQntyInput() && $_option->getType()==Mage_Catalog_Model_Product_Option::OPTION_TYPE_CHECKBOX) {                    
                    if ($buyRequest) $optionValueQty = $buyRequest->getData('options_'.$_option->getId().'_'.$_value->getOptionTypeId().'_qty'); else $optionValueQty = 0;
                    if (!$optionValueQty && $checked) $optionValueQty = 1;
                    $selectHtml .=
                        '<input ' . $disabled . ' ' . $checked . '  data-type="'.$_value->getPriceType().'" type="' . $type . '" class="' . $class . ' ' . $require . ' product-custom-option" onclick="optionSetQtyProduct.checkboxQty(this); '.$onclick.'" name="options[' . $_option->getId() . ']' . $arraySign . '" id="options_' . $_option->getId() . '_' . $count . '" value="' . $_value->getOptionTypeId() . '" />'
                        . $imagesHtml .
                        '<span class="label">
                            <label for="options_' . $_option->getId() . '_' . $count . '">' . $_value->getTitle() . ' ' . $priceStr . $qty . '</label>
                            &nbsp;&nbsp;&nbsp;
                            <label><b>'.$helper->getDefaultOptionQtyLabel().'</b> <input type="text" class="input-text qty'. ($checked?' validate-greater-than-zero':'') .'" value="'.$optionValueQty.'" maxlength="12" id="options_'.$_option->getId().'_'.$_value->getOptionTypeId().'_qty" name="options_'.$_option->getId().'_'.$_value->getOptionTypeId().'_qty" onchange="'.((Mage::app()->getStore()->isAdmin())?'':'opConfig.reloadPrice();'.$setProdutQtyFunc).'" onKeyPress="if(event.keyCode==13){'.((Mage::app()->getStore()->isAdmin())?'':'opConfig.reloadPrice();'.$setProdutQtyFunc).'}" '.($checked?$disabled:'disabled').'></label>
                         </span>';
                } else {
                    $selectHtml .=
                        '<input ' . $disabled . ' ' . $checked . ' data-type="'.$_value->getPriceType().'" type="' . $type . '" class="' . $class . ' ' . $require . ' product-custom-option" onclick="'.$onclick.'" name="options[' . $_option->getId() . ']' . $arraySign . '" id="options_' . $_option->getId() . '_' . $count . '" value="' . $_value->getOptionTypeId() . '" />'
                        . $imagesHtml .
                        '<span class="label"><label for="options_' . $_option->getId() . '_' . $count . '">' . $_value->getTitle() . ' ' . $priceStr . $qty . '</label></span>';
                }
                                                
                if ($_option->getIsRequire(true)) {
                    $selectHtml .= '<script type="text/javascript">' .
                            '$(\'options_' . $_option->getId() . '_' . $count . '\').advaiceContainer = \'options-' . $_option->getId() . '-container\';' .
                            '$(\'options_' . $_option->getId() . '_' . $count . '\').callbackFunction = \'validateOptionsCallback\';' .
                            '</script>';
                }
                $selectHtml .= '</li>';                                                
                if ($enabledTierPrice) $tiersJs .= $this->getTiersJs($_option, $_value);
            }
            
            if ($selectHtml) $selectHtml = '<ul id="options-' . $_option->getId() . '-list" class="options-list">'.$selectHtml.'</ul>';
            self::$isFirstOption = false;
            if ($dependentJs) $selectHtml.='<script type="text/javascript">'.$dependentJs.'</script>';
            if ($tiersJs) $selectHtml.='<script type="text/javascript">'.$tiersJs.'</script>';
            if ($setProdutQtyJs) {$selectHtml.='<script type="text/javascript">'.$setProdutQtyJs.'optionSetQtyProduct.hideQty();</script>'; $_option->setOptionSetQtyProduct(1);}
            
            return $selectHtml;
        }
    }
    
    public function getTiersJs($_option, $_value) {
        $tiers = $_value->getTiers();                
        $tiersJs = '';
        if ($tiers && count($tiers)>0) {
            $basePrice = $_option->getProduct()->getFinalPrice();
            $tiersJsArr = array();
            foreach ($tiers as $qty=>$value) {               
                if ($value['price_type']== 'percent') {                            
                    $price = $basePrice*($value['price']/100);                            
                } else {
                    $price = $value['price'];
                }
                $price = number_format($price, 2, null, '');

                $tiersJsArr[] = $qty.':"'.$price.'"';
            }
            $tiersJs .= 'optionTierPricesData["'.$_option->getId().'_'.$_value->getId().'"] = {'.implode(',', $tiersJsArr).'};';
        }
        return $tiersJs;
    }
    
    public function getColorHtml($color) {
        return '<div class="container-swatch-color small-image-preview v-middle">'.
                    '<div class="swatch-color" style="background:'. $color .';">&nbsp;</div>'.
                '</div>';
    }

}