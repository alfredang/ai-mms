<?php
class MMD_MagentoCaptcha_Block_MagentoCaptcha extends Mage_Core_Block_Template
{
	public function _prepareLayout()
    {
		return parent::_prepareLayout();
    }
    
     public function getMagentoCaptcha()     
     { 
        if (!$this->hasData('magentocaptcha')) {
            $this->setData('magentocaptcha', Mage::registry('magentocaptcha'));
        }
        return $this->getData('magentocaptcha');
        
    }
}