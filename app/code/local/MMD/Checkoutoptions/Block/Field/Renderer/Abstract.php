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
class MMD_Checkoutoptions_Block_Field_Renderer_Abstract  extends Mage_Core_Block_Abstract
{
    public function setParams(array $data) {
        foreach($data as $key => $value)
        {
            $this->$key=$value;
        }
        return $this;
    }
    
    public function render()
    {
        return '';
    }
}

?>