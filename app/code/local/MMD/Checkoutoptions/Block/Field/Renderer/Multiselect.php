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
/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of Date
 *
 * @author kirichenko
 */
class MMD_Checkoutoptions_Block_Field_Renderer_Multiselect extends MMD_Checkoutoptions_Block_Field_Renderer_Abstract 
{
    public function render() 
    {
                $select = Mage::getModel('core/layout')->createBlock('core/html_select')
                    ->setName($this->sFieldName . '[]')
                    ->setId($this->sFieldId)
                    ->setTitle($this->sLabel)
                    ->setClass($this->sFieldClass)
                    ->setValue($this->sFieldValue)
                    ->setExtraParams('multiple')
                    ->setOptions($this->aOptionHash);
                
                    $sHidden = '<input type="hidden" name="'.$this->sFieldName.'"  value="" />';
                    
                    return $sHidden . $select->getHtml();
    }
}

?>