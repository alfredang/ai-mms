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
 
class MMD_Checkoutoptions_Block_Widget_Grid_Column_Filter_Multiselect extends Mage_Adminhtml_Block_Widget_Grid_Column_Filter_Abstract
{
    protected function _getOptions()
    {
        $colOptions = $this->getColumn()->getOptions();
        if ( !empty($colOptions) && is_array($colOptions) ) {
            $options = array(array('value' => null, 'label' => Mage::helper('adminhtml')->__('-- None --')));
            foreach ($colOptions as $value => $label) {
                $options[] = array('value' => $value, 'label' => $label);
            }
            return $options;
        }
        return array();
    }

    public function getHtml()
    {
         $select = Mage::getModel('core/layout')->createBlock('core/html_select')
                    ->setName($this->_getHtmlName() . '[]')
                    ->setId($this->_getHtmlId())
                    //->setTitle($sLabel)
                    ->setClass('no-changes')
                    ->setValue($this->getValue())
                    ->setExtraParams('multiple="multiple"')
                    ->setOptions($this->_getOptions());
                    $sHidden = '<input type="hidden" name="'.$this->_getHtmlName().'"  value="" />';
                    
                    $sHtml = $sHidden . $select->getHtml();
                    return $sHtml;
    }

    public function getCondition()
    {
        if (is_null($this->getValue())) {
            return null;
        }
        $options = $this->getColumn()->getOptions();
        if ( !empty($options) && is_array($options) ) {
            if(is_array($this->getValue()))
            {
                $res = array();
                foreach($this->getValue() as $val)
                {
                    if(isset($options[$val]))
                    {
                        $res[] = array('finset' => $val);
                    }    
                }
                return($res);
            }
            else
            {
                $value = $this->getValue();
            }
            return array('finset' => $value);
        }
        else
        {
            return array();
        }
    }

}