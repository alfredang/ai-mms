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
 * @copyright  Copyright (c) 2012 MMD (http://www.magemobiledesign.com/)
 * @license    http://www.magemobiledesign.com/LICENSE-1.0.html
 */

/**
 * Advanced Product Options extension
 *
 * @category   MMD
 * @package    MMD_CustomOptions
 * @author     MMD Dev Team
 */

class MMD_Adminhtml_Block_Customoptions_Adminhtml_Catalog_Product_Edit_Tab_Options_Type_Select extends Mage_Adminhtml_Block_Catalog_Product_Edit_Tab_Options_Type_Select 
{

    public function __construct() {
        parent::__construct();
        if (!Mage::helper('customoptions')->isEnabled()) return $this;
        $this->setTemplate('customoptions/catalog-product-edit-options-type-select.phtml');
    }

    protected function _prepareLayout() {
        $this->setChild('add_select_row_button', $this->getLayout()->createBlock('adminhtml/widget_button')
                    ->setData(array(
                        'label' => Mage::helper('catalog')->__('Add New Row'),
                        'class' => 'add add-select-row',
                        'id' => 'add_select_row_button_{{option_id}}',
                    )));

        $this->setChild('delete_select_row_button', $this->getLayout()->createBlock('adminhtml/widget_button')
                    ->setData(array(
                        'label' => Mage::helper('catalog')->__('Delete Row'),
                        'class' => 'delete delete-select-row icon-btn'                            
                    )));

        $this->setChild('add_image_button', $this->getLayout()->createBlock('adminhtml/widget_button')
                    ->setData(array(
                        'label' => '{{image_button_label}}',
                        'class' => 'add',                            
                        //'id' => 'new-option-file-{{option_id}}-{{select_id}}',
                        'onclick' => 'selectOptionType.addFileRow({{option_id}}, {{select_id}})'                            
                    )));
        
        $this->setChild('add_tier_price_row_button', $this->getLayout()->createBlock('adminhtml/widget_button')
                    ->setData(array(
                        'class' => 'add',
                        'label' => '',                            
                        'title' => Mage::helper('customoptions')->__('Add Tier Price'),
                        'id' => 'product_option_{{id}}_select_{{select_id}}_price_new',
                        'style' => 'width:23px;',
                        'onclick' => 'selectOptionType.addTierPriceRow({{option_id}}, {{select_id}}, -1, \'\',\'\',\'fixed\')'
                    )));
        
        $this->setChild('option_tier_price_type', $this->getLayout()->createBlock('adminhtml/html_select')->setData(array('class' => 'select product-option-price-type')));
        return parent::_prepareLayout();
    }

    public function getAddButtonHtml() {
        return $this->getChildHtml('add_select_row_button');
    }

    public function getDeleteButtonHtml() {
        return $this->getChildHtml('delete_select_row_button');
    }

    public function getAddImageButtonHtml() {
        return $this->getChildHtml('add_image_button');
    }

    public function getAddTierPriceButtonHtml() {
        return $this->getChildHtml('add_tier_price_row_button');
    }            
    
    public function getPriceTypeSelectHtml() {
        $this->getChild('option_price_type')
                ->setData('id', 'product_option_{{id}}_select_{{select_id}}_price_type')
                ->setName('product[options][{{id}}][values][{{select_id}}][price_type]');
        return $this->getChildHtml('option_price_type');
    }
    
    public function getTierPriceTypeSelectHtml() {
        $this->getChild('option_tier_price_type')
                ->setId('product_option_{{id}}_select_{{select_id}}_price_{{tier_price_id}}_price_type')
                ->setName('product[options][{{id}}][values][{{select_id}}][tiers][{{tier_price_id}}][price_type]')
                ->setOptions(Mage::getSingleton('adminhtml/system_config_source_product_options_price')->toOptionArray());
        return $this->getChildHtml('option_tier_price_type');
    }

}
