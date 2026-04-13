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
class MMD_Checkoutoptions_Block_Field_Renderer_Radio extends MMD_Checkoutoptions_Block_Field_Renderer_Abstract 
{
    public function render() 
    {
            $selectHtml = '<ul id="options-'.$this->sFieldId.'-list" class="options-list">';
            $require = ($this->aField['is_required']) ? ' validate-one-required-by-name' : '';
            
                    $type = 'radio';
                    $class = 'radio';
                    if (!$this->aField['is_required']) {
                        $selectHtml .= '<li><input type="radio" id="'.$this->sFieldId.'" class="'.$class.' product-custom-option" name="'.$this->sFieldName.'" value="" checked="checked" /><span class="label"><label for="options_'.$this->sFieldId.'"'.(($this->sPageType=='register')?' style="font-weight:normal;"':"").'>' . Mage::helper('catalog')->__('None') . '</label></span></li>';
                    }
                    
            $count = 0;
            
            if ($this->aOptionHash)
            {
                foreach ($this->aOptionHash as $iKey => $sValue) 
                {
                    $count++;
                    
                    $sChecked = '';
                    
                    if ($iKey == $this->sFieldValue)
                    {
                        $sChecked = 'checked';
                    }
                    
                    $selectHtml .= '<li>' .
                                   '<input type="'.$type.'" class="'.$class.' '.$require.' product-custom-option" name="'.$this->sFieldName.''.'" id="'.$this->sFieldId.'_'.$count.'" value="'.$iKey.'" '.$sChecked.' />' .
                                   '<span class="label"><label for="'.$this->sFieldId.'_'.$count.'"'.(($this->sPageType=='register')?' style="font-weight:normal;"':"").'>'.$sValue.'</label></span>';
                                   
                    $selectHtml .= '</li>';
                }
            }
            $selectHtml .= '</ul>';
                
                $sHidden = '<input type="hidden" name="'.$this->sFieldName.'"  value="" />';                
            
                return $sHidden . $selectHtml;
    }
}

?>