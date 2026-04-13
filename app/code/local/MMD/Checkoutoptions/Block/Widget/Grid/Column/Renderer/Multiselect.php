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
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */

class MMD_Checkoutoptions_Block_Widget_Grid_Column_Renderer_Multiselect extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract
{
    public function render(Varien_Object $row)
    {
        $options = $this->getColumn()->getOptions();
        $showMissingOptionValues = (bool)$this->getColumn()->getShowMissingOptionValues();
        if (!empty($options) && is_array($options)) {
            $value = $row->getData($this->getColumn()->getIndex());
            if(count($itemsArr = explode(',', $value))>0)
            {
                $res = array();
                foreach ($itemsArr as $item) {
                    if (isset($options[$item])) {
                        $res[] = $options[$item];
                    }
                    elseif($showMissingOptionValues) {
                        $res[] = $item;
                    }
                }
                return implode(', ', $res);
            }
            else return $value;
        }
    }
}