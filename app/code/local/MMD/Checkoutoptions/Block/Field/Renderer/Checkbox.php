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
class MMD_Checkoutoptions_Block_Field_Renderer_Checkbox extends MMD_Checkoutoptions_Block_Field_Renderer_Abstract 
{
    public function render() 
    {
            $selectHtml = '<ul id="options-'.$this->sFieldId.'-list" class="options-list">';
            $require = ($this->aField['is_required']) ? ' validate-one-required-by-name' : '';
            $arraySign = '';
                    $type = 'checkbox';
                    $class = 'checkbox';
                    $arraySign = '[]';
                    
            $count = 0;
            
            if ($this->aOptionHash)
            {
                foreach ($this->aOptionHash as $iKey => $sValue) 
                {
                    $count++;
                    
                    $selectHtml .= '<li>' .
                                   '<input type="'.$type.'" class="'.$class.' '.$require.' product-custom-option" name="'.$this->sFieldName.''.$arraySign.'" id="'.$this->sFieldId.'_'.$count.'" value="'.$iKey.'" '.$this->_printIfChecked($iKey).' />' .
                                   '<span class="label"><label for="'.$this->sFieldId.'_'.$count.'"'.(($this->sPageType=='register')?' style="font-weight:normal;"':"").'>'.$sValue.'</label></span>';
                    $selectHtml .= '</li>';
                }
            }
            $selectHtml .= '</ul>';
                
                $sHidden = '<input type="hidden" name="'.$this->sFieldName.'"  value="" />';                
            
                return $sHidden . $selectHtml;
    }
    
    
    
    private function _printIfChecked($key) 
    {
        if ($this->sFieldValue AND in_array($key, $this->sFieldValue))
        {
            return 'checked';
        }
        return '';
    }
}

?>