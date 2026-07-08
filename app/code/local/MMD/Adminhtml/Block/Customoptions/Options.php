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
class MMD_Adminhtml_Block_Customoptions_Options extends MMD_Adminhtml_Block_Customoptions_Abstract {

    protected function _prepareLayout() {
        $this->setChild('add_new_button', $this->getLayout()->createBlock('adminhtml/widget_button')
                        ->setData(array(
                            'label' => Mage::helper('customoptions')->__('Add Class Schedule'),
                            'onclick' => "setLocation('" . $this->getUrl('*/*/new', array('store' => $this->getStoreId())) . "')",
                            'class' => 'add'
                        ))
        );

        $helper = Mage::helper('customoptions');

        $cleanUrl = $this->getUrl('*/*/cleanTemplatesPastDates');
        $cleanConfirm = $helper->__(
            'Step 1 of 2: remove past Course Date entries from every template (not products yet). Continue?'
        );
        $this->setChild('clean_templates_button', $this->getLayout()->createBlock('adminhtml/widget_button')
                        ->setData(array(
                            'label'   => $helper->__('1. Clean Templates'),
                            'onclick' => "if (confirm('" . addslashes($cleanConfirm) . "')) { setLocation('" . $cleanUrl . "'); }",
                            'class'   => 'delete',
                        ))
        );

        $applyUrl = $this->getUrl('*/*/applyTemplatesToProducts');
        $applyConfirm = $helper->__(
            'Step 2 of 2: delete past Course Date rows from every product, reindex prices, and flush caches. This cannot be undone. Continue?'
        );
        $this->setChild('apply_to_products_button', $this->getLayout()->createBlock('adminhtml/widget_button')
                        ->setData(array(
                            'label'   => $helper->__('2. Apply to Products'),
                            'onclick' => "if (confirm('" . addslashes($applyConfirm) . "')) { setLocation('" . $applyUrl . "'); }",
                            'class'   => 'delete',
                        ))
        );

        $this->setChild('bulk_generate_button', $this->getLayout()->createBlock('adminhtml/widget_button')
                        ->setData(array(
                            'label'   => Mage::helper('customoptions')->__('Bulk Generate Schedules'),
                            'onclick' => "mmdBulkGenToggle(); return false;",
                            'class'   => '',
                        ))
        );

        $this->setChild('grid', $this->getLayout()->createBlock('mmd/customoptions_options_grid', 'customoptions.grid'));

        return parent::_prepareLayout();
    }

    public function getAddNewButtonHtml() {
        return $this->getChildHtml('add_new_button');
    }

    public function getCleanTemplatesButtonHtml() {
        return $this->getChildHtml('clean_templates_button');
    }

    public function getApplyToProductsButtonHtml() {
        return $this->getChildHtml('apply_to_products_button');
    }

    public function getBulkGenerateButtonHtml() {
        return $this->getChildHtml('bulk_generate_button');
    }

    public function getGridHtml() {
        return $this->getChildHtml('grid');
    }

}