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

class MMD_Adminhtml_Block_Customoptions_Options_Edit_Tabs extends Mage_Adminhtml_Block_Widget_Tabs {

    public function __construct() {
        parent::__construct();
        $this->setId('customoptions_tabs');
        $this->setDestElementId('edit_form');
        $this->setTitle($this->_getHelper()->__('Options Information'));
    }

    protected function _beforeToHtml() {
        $helper = $this->_getHelper();
        $this->addTab('options_tab', array(
            'label' => $helper->__('Template Options'),
            'title' => $helper->__('Template Options'),
            'content' => $this->getLayout()->createBlock('mmd/customoptions_options_edit_tab_options', 'admin.product.options')->toHtml(),
            'active' => true,
        ));

        $this->addTab('product_tab', array(
            'label' => $helper->__('Products'),
            'title' => $helper->__('Products'),
            'content' => $this->getLayout()->createBlock('mmd/customoptions_options_edit_tab_product')->toHtml(),
        ));

        return parent::_beforeToHtml();
    }

    private function _getHelper() {
        return Mage::helper('customoptions');
    }

}