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
class MMD_Checkoutoptions_Block_Field_Renderer_Textarea extends MMD_Checkoutoptions_Block_Field_Renderer_Abstract 
{
    public function render() 
    {           $aParams=$this->getData('a_params');
                return '<textarea id="'.(isset($aParams['id'])?$aParams['id'].' ':'').'" class="'.(isset($aParams['class'])?$aParams['class'].' ':'').'input-text" style="height:50px;" name="'.$this->sFieldName.'">'.$this->sFieldValue.'</textarea>';
    }
}

?>