<?php

/**
 * Magento
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the Open Software License (OSL 3.0)
 * that is bundled with this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://opensource.org/licenses/osl-3.0.php
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@magentocommerce.com so we can send you a copy immediately.
 *
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade Magento to newer
 * versions in the future. If you wish to customize Magento for your
 * needs please refer to http://www.magentocommerce.com for more information.
 *
 * @category    Mage
 * @package     Mage_Adminhtml
 * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
 * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
 */

/**
 * customers defined options
 *
 * @category   Mage
 * @package    Mage_Adminhtml
 * @author     Magento Core Team <core@magentocommerce.com>
 */
class MMD_Adminhtml_Block_Customoptions_Adminhtml_Catalog_Product_Edit_Tab_Options_Type_Date extends Mage_Adminhtml_Block_Catalog_Product_Edit_Tab_Options_Type_Date {

    public function __construct() {
        parent::__construct();
        if (!Mage::helper('customoptions')->isEnabled()) return $this;
        $this->setTemplate('customoptions/catalog-product-edit-options-type-date.phtml');
    }

    protected function _prepareLayout() {
        $this->setChild('add_select_row_button',
                        $this->getLayout()->createBlock('adminhtml/widget_button')
                        ->setData(array(
                            'label' => Mage::helper('catalog')->__('Add New Row'),
                            'class' => 'add add-select-row',
                            'id' => 'add_select_row_button_{{option_id}}',
                        ))
        );

        $this->setChild('delete_select_row_button',
                        $this->getLayout()->createBlock('adminhtml/widget_button')
                        ->setData(array(
                            'label' => Mage::helper('catalog')->__('Delete Row'),
                            'class' => 'delete delete-select-row icon-btn',
                        ))
        );

        $this->setChild('add_image_button',
                        $this->getLayout()->createBlock('adminhtml/widget_button')
                        ->setData(array(
                            'label' => Mage::helper('customoptions')->__('Add Image'),
                            'class' => 'add disabled',
                            'id' => 'new-option-file-{{option_id}}',
                            'onclick' => ' productOptionTypeDate.createFileField(this.id)',
                            'disabled' => true
                        )));

        return parent::_prepareLayout();
    }

    public function getAddImageButtonHtml() {
        return $this->getChildHtml('add_image_button');
    }

}