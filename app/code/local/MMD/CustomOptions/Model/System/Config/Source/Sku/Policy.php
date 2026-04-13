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

class MMD_Customoptions_Model_System_Config_Source_Sku_Policy {
    public function toOptionArray($isAll = false) {
        $helper = Mage::helper('customoptions');
        $options = array(            
            array('value' => 1, 'label'=>$helper->__('Standard')),
            array('value' => 2, 'label'=>$helper->__('Independent')),
            array('value' => 3, 'label'=>$helper->__('Grouped')),
            array('value' => 4, 'label'=>$helper->__('Replacement')),
        );        
        if ($isAll) array_unshift($options, array('value' => 0, 'label'=>$helper->__('Default')));
        return $options;
    }

}