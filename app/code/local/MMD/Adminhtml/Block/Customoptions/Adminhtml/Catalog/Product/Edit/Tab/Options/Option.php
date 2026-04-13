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

class MMD_Adminhtml_Block_Customoptions_Adminhtml_Catalog_Product_Edit_Tab_Options_Option extends MMD_Adminhtml_Block_Customoptions_Adminhtml_Catalog_Product_Edit_Tab_Options_Option_Abstract {

    public function __construct() {
        parent::__construct();
        if (!Mage::helper('customoptions')->isEnabled()) return $this;
        $this->setTemplate('customoptions/catalog-product-edit-options-option.phtml');
    }
    
    public function getViewIGI($IGI) {        
        return (($IGI<65536)?$IGI:floor($IGI/65535).'x'.$IGI%65535);
    }

    public function getOptionValues() {                
        
        $optionsCollection = $this->getProduct()->getOptions();        
        // if option enabled = no && hasOptions = 0
        if (!$optionsCollection) $optionsCollection = $this->getProduct()->getProductOptionsCollection();
        
        
        if (!$this->_values) {
            $values = array();            
            $scope = (int) Mage::app()->getStore()->getConfig(Mage_Core_Model_Store::XML_PATH_PRICE_SCOPE);
            $helper = Mage::helper('customoptions');
            
            foreach ($optionsCollection as $option) {

                /* @var $option Mage_Catalog_Model_Product_Option */

                $this->setItemCount($option->getOptionId());                
                $value = array();

                $value['id'] = $option->getOptionId();
                $value['template_title'] = ($option->getGroupTitle())?$helper->__('Options Template:').' '.$option->getGroupTitle():'';
                $value['item_count'] = $this->getItemCount();
                $value['option_id'] = $option->getOptionId();
                $value['title'] = $this->htmlEscape($option->getTitle());
                $value['type'] = $option->getType();
                $value['is_require'] = $option->getIsRequire(true);
                $value['view_mode'] = $option->getViewMode();
                $value['is_dependent'] = $option->getIsDependent();
                $value['div_class'] = $option->getDivClass();
                $value['sku_policy'] = $option->getSkuPolicy();
                
                $value['customoptions_is_onetime'] = $option->getCustomoptionsIsOnetime();
                $value['qnty_input'] = ($option->getQntyInput()?'checked':'');
                $value['qnty_input_disabled'] = (($option->getType()=='multiple')?'disabled':'');
                
                
                $value['image_mode'] = $option->getImageMode();
                $value['image_mode_disabled'] = (($option->getGroupByType()!=Mage_Catalog_Model_Product_Option::OPTION_GROUP_SELECT)?'disabled':'');
                $value['exclude_first_image'] = ($option->getExcludeFirstImage()?'checked':'');
                
                
                $value['sort_order'] = $option->getSortOrder();
                $value['image_button_label'] = ($option->getImagePath()?$helper->__('Change Image'):$helper->__('Add Image'));
                
                $value['description'] = $this->htmlEscape($option->getDescription());
                if ($helper->isCustomerGroupsEnabled() && $option->getCustomerGroups() != null) {
                    $value['customer_groups'] = $option->getCustomerGroups();
                }
                
                $value['in_group_id'] = $option->getInGroupId();
                $value['in_group_id_view'] = $this->getViewIGI($option->getInGroupId());
                
                

                if ($this->getProduct()->getStoreId() != '0') {
                    $value['checkboxScopeTitle'] = $this->getCheckboxScopeHtml($option->getOptionId(), 'title', is_null($option->getStoreTitle()));
                    $value['scopeTitleDisabled'] = is_null($option->getStoreTitle()) ? 'disabled' : null;
                    
                    $value['checkboxScopeViewMode'] = $this->getCheckboxScopeHtml($option->getOptionId(), 'view_mode', is_null($option->getStoreViewMode()));
                    $value['scopeViewModeDisabled'] = is_null($option->getStoreViewMode()) ? 'disabled' : null;
                    
                    $value['checkboxScopeDescription'] = $this->getCheckboxScopeHtml($option->getOptionId(), 'description', is_null($option->getStoreDescription()));
                    $value['scopeDescriptionDisabled'] = is_null($option->getStoreDescription()) ? 'disabled' : null;
                }

                $connection = Mage::getSingleton('core/resource')->getConnection('core_write');
                $tablePrefix = (string) Mage::getConfig()->getTablePrefix();

                $select = $connection->select()->from($tablePrefix . 'custom_options_relation')->where('option_id = ' . $option->getOptionId());
                $relation = $connection->fetchRow($select);

                if ($option->getGroupByType()==Mage_Catalog_Model_Product_Option::OPTION_GROUP_SELECT) {
                    $i = 0;
                    $itemCount = 0;
                    foreach ($option->getValues() as $_value) {
                        /* @var $_value Mage_Catalog_Model_Product_Option_Value */
                        
                        $dependentIds = array();
                        $dependentIdsTmp = explode(',', $_value->getDependentIds());                        
                        foreach ($dependentIdsTmp as $d_id) {
                            $dependentIds[] = $this->getViewIGI($d_id);
                        }
                        
                        list($price, $priceType, $isProductPrice, $taxClassId, $oldPrice) = $helper->getOptionPriceAndPriceType($_value->getPrice(), $_value->getPriceType(), $_value->getSku(), $this->getProduct()->getStore());
                        if ($isProductPrice && $helper->isSkuPriceLinkingEnabled()) {
                            $priceDisabled = true;
                            if ($helper->isSpecialPriceEnabled()) {
                                if ($oldPrice) {
                                    $_value->setSpecialPrice($price);
                                    $price = $oldPrice;
                                } else {
                                    $_value->setSpecialPrice('');
                                }
                            }
                        } else {
                            $priceDisabled = false;
                        }
                        
                        $value['optionValues'][$i] = array(
                            'item_count' => max($itemCount, $_value->getOptionTypeId()),
                            'option_id' => $_value->getOptionId(),
                            'option_type_id' => $_value->getOptionTypeId(),
                            'title' => $this->htmlEscape($_value->getTitle()),
							'reg_course' => $this->htmlEscape($_value->getReg_course()) ,
							'reg_from' => $this->htmlEscape($_value->getReg_from()),
							'reg_to' => $this->htmlEscape($_value->getReg_to()),
                            'price' => $this->getPriceValue($price, $priceType),
                            'price_type' => $priceType,
                            'special_price' => $_value->getSpecialPrice()?$this->getPriceValue($_value->getSpecialPrice(), $priceType):'',
                            'special_comment' => $_value->getSpecialComment(),
                            'price_disabled' => $priceDisabled,
                            'customoptions_qty' => $helper->getCustomoptionsQty($_value->getCustomoptionsQty(), $_value->getSku()),
                            'customoptions_qty_disabled' => $helper->getProductIdBySku($_value->getSku())?'disabled="disabled"':'',
                            'sku' => $this->htmlEscape($_value->getSku()),
                            'sku_class' => $_value->getSku() && $helper->getProductIdBySku($_value->getSku())==0?'red':'',
                            'image_button_label' => $helper->__('Add Image'),
                            'sort_order' => $_value->getSortOrder(),
                            'checked' => $_value->getDefault() != 0 ? 'checked' : '',
                            'default_type' => (($option->getType()=='checkbox' || $option->getType()=='multiple') ? 'checkbox' : 'radio'),
                            'in_group_id' => $_value->getInGroupId(),
                            'in_group_id_view' => $this->getViewIGI($_value->getInGroupId()),
                            'dependent_ids' => implode(',', $dependentIds),
                            'weight' => $_value->getWeight()
                        );
                        
                        // getImages
                        $images = $_value->getImages();
                        if ($images) {
                            foreach($images as $image) {
                                if ($image['source']==1) { // file
                                    $imgArr = $helper->getImgHtml($image['image_file'], $option->getId(), $_value->getOptionTypeId(), true);
                                    if ($imgArr) {
                                        $imgArr['option_type_image_id'] = $image['option_type_image_id'];
                                        $imgArr['source'] = $image['source'];
                                        $value['optionValues'][$i]['images'][] = $imgArr;
                                    }
                                } else if ($image['source']==2) { // color
                                    $colorArr = $image;
                                    $colorArr['id'] = $option->getId();
                                    $colorArr['select_id'] = $_value->getOptionTypeId();                                    
                                    $value['optionValues'][$i]['images'][] = $colorArr;
                                }
                            }
                        } else {
                            $value['optionValues'][$i]['image_tr_style'] = 'display:none';
                        }
                                                
                        //getOptionValueTierPrices                        
                        $tierPrices = $_value->getTiers();
                        if ($tierPrices) {
                            foreach ($tierPrices as $qty=>$tierPrice) {                                
                                $tierPrices[$qty]['price'] = $this->getPriceValue($tierPrice['price'], $tierPrice['price_type']);
                            }                            
                            $value['optionValues'][$i]['tiers'] = $tierPrices;   
                        } else {
                            $value['optionValues'][$i]['tier_price_tr_style'] = 'display:none';
                        }

                        if ($this->getProduct()->getStoreId() != '0') {
                            $value['optionValues'][$i]['checkboxScopeTitle'] = $this->getCheckboxScopeHtml($_value->getOptionId(), 'title', is_null($_value->getStoreTitle()), $_value->getOptionTypeId());
                            $value['optionValues'][$i]['scopeTitleDisabled'] = is_null($_value->getStoreTitle()) ? 'disabled' : null;
                            
                            if ($scope==Mage_Core_Model_Store::PRICE_SCOPE_WEBSITE) {
                                if (!$priceDisabled) $value['optionValues'][$i]['checkboxScopePrice'] = $this->getCheckboxScopeHtml($_value->getOptionId(), 'price', is_null($_value->getStorePrice()), $_value->getOptionTypeId());
                                $value['optionValues'][$i]['scopePriceDisabled'] = is_null($_value->getStorePrice()) ? 'disabled' : null;
                            }
                        }
                        $i++;
                    }
                } else {
                    list($price, $priceType, $isProductPrice, $taxClassId, $oldPrice) = $helper->getOptionPriceAndPriceType($option->getPrice(), $option->getPriceType(), $option->getSku(), $this->getProduct()->getStore());
                    if ($isProductPrice && $helper->isSkuPriceLinkingEnabled()) {
                        $priceDisabled = true;
                        if ($helper->isSpecialPriceEnabled()) {
                            if ($oldPrice) {
                                $_value->setSpecialPrice($price);
                                $price = $oldPrice;
                            } else {
                                $_value->setSpecialPrice('');
                            }
                        }
                    } else {
                        $priceDisabled = false;
                    }
                    
                    $value['price'] = $this->getPriceValue($price, $priceType);
                    $value['price_type'] = $priceType;
                    $value['price_disabled'] = $priceDisabled;
                    $value['sku'] = $this->htmlEscape($option->getSku());
                    $value['max_characters'] = $option->getMaxCharacters();
                    $value['default_text'] = $this->htmlEscape($option->getDefaultText());
                    $value['file_extension'] = $option->getFileExtension();
                    $value['image_size_x'] = $option->getImageSizeX();
                    $value['image_size_y'] = $option->getImageSizeY();
                    
                    $imgHtml = $helper->getImgHtml($option->getImagePath(), $option->getId());
                    if ($imgHtml) $value['image'] = $imgHtml;
                                        
                    if ($this->getProduct()->getStoreId()!='0' && $scope == Mage_Core_Model_Store::PRICE_SCOPE_WEBSITE) {                        
                        if (!$priceDisabled) $value['checkboxScopePrice'] = $this->getCheckboxScopeHtml($option->getOptionId(), 'price', is_null($option->getStorePrice()));
                        $value['scopePriceDisabled'] = is_null($option->getStorePrice()) ? 'disabled' : null;
                        $value['checkboxScopeDefaultText'] = $this->getCheckboxScopeHtml($option->getOptionId(), 'default_text', is_null($option->getStoreDefaultText()));
                        $value['scopeDefaultTextDisabled'] = is_null($option->getStoreDefaultText()) ? 'disabled' : null;
                    }
                }
                $values[] = new Varien_Object($value);
            }
            $this->_values = $values;
        }
        return $this->_values;
    }

    public function getOneTimeSelectHtml() {        
        $select = $this->getLayout()->createBlock('adminhtml/html_select')
                ->setData(array(
                    'id' => $this->getFieldId() . '_{{id}}_customoptions_is_onetime',
                    'class' => 'select'
                ))
                ->setName($this->getFieldName() . '[{{id}}][customoptions_is_onetime]')
                ->setOptions(Mage::getSingleton('adminhtml/system_config_source_yesno')->toOptionArray());        
        $select->setOptions(array_reverse($select->getOptions()));
        return $select->getHtml();
    }

    public function getCustomerGroupsMultiselectHtml() {
        $collection = Mage::getModel('customer/group')->getCollection();
        $customerGroups = array();

        foreach ($collection as $item) {
            $customerGroups[$item->getId()]['value'] = $item->getId();
            $customerGroups[$item->getId()]['label'] = $item->getCustomerGroupCode();
        }

        $select = $this->getLayout()->createBlock('adminhtml/html_select')
                ->setData(array(
                    'id' => $this->getFieldId() . '_{{id}}_customer_groups',
                    'class' => 'select multiselect',
                ))
                ->setExtraParams('multiple="multiple" size="5"')
                ->setName($this->getFieldName() . '[{{id}}][customer_groups][]')
                ->setOptions($customerGroups);

        return $select->getHtml();
    }
    
    public function getViewModeSelectHtml() {        
        $select = $this->getLayout()->createBlock('adminhtml/html_select')
                ->setData(array(
                    'id' => $this->getFieldId() . '_{{id}}_view_mode',
                    'class' => 'select'
                ))
                ->setName($this->getFieldName() . '[{{id}}][view_mode]')
                ->setOptions(Mage::getSingleton('customoptions/system_config_source_view_mode')->toOptionArray());        
        $select->setOptions($select->getOptions());
        return $select->getHtml();
    }
    
    public function getDependentSelectHtml() {        
        $select = $this->getLayout()->createBlock('adminhtml/html_select')
                ->setData(array(
                    'id' => $this->getFieldId() . '_{{id}}_is_dependent',
                    'class' => 'select'
                ))
                ->setName($this->getFieldName() . '[{{id}}][is_dependent]')
                ->setOptions(Mage::getSingleton('adminhtml/system_config_source_yesno')->toOptionArray());        
        $select->setOptions(array_reverse($select->getOptions()));
        return $select->getHtml();
    }
    
    public function getSkuPolicySelectHtml() {
        $select = $this->getLayout()->createBlock('adminhtml/html_select')
                ->setData(array(
                    'id' => $this->getFieldId() . '_{{id}}_sku_policy',
                    'class' => 'select'
                ))
                ->setName($this->getFieldName() . '[{{id}}][sku_policy]')
                ->setOptions(Mage::getSingleton('customoptions/system_config_source_sku_policy')->toOptionArray(true));        
        $select->setOptions($select->getOptions());
        return $select->getHtml();
    }
    
    public function getImageModeSelectHtml() {
        $select = $this->getLayout()->createBlock('adminhtml/html_select')
                ->setData(array(
                    'id' => $this->getFieldId() . '_{{id}}_image_mode',
                    'class' => 'select',
                    'extra_params' => '{{image_mode_disabled}} style="margin-bottom:6px;"'
                ))
                ->setName($this->getFieldName() . '[{{id}}][image_mode]')
                ->setOptions(Mage::getSingleton('customoptions/system_config_source_image_mode')->toOptionArray());        
        $select->setOptions($select->getOptions());
        return $select->getHtml();
    }
    
}