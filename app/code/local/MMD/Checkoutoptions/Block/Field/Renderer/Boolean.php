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
class MMD_Checkoutoptions_Block_Field_Renderer_Boolean extends MMD_Checkoutoptions_Block_Field_Renderer_Abstract 
{
    public function render() 
    {
                $select = Mage::getModel('core/layout')->createBlock('core/html_select')
                    ->setName($this->sFieldName)
                    ->setId($this->sFieldId)
                    ->setTitle($this->sLabel) 
                    ->setClass('validate-select')
                    ->setValue($this->sFieldValue)
                    ->setOptions(Mage::getModel('adminhtml/system_config_source_yesno')-> toOptionArray());
                    return $select->getHtml();
    }
}

?>