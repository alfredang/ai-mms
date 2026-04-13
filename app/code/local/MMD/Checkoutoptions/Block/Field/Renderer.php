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
class MMD_Checkoutoptions_Block_Field_Renderer  extends Mage_Core_Block_Abstract
{
        protected $_renderer;
        protected $_type;
        protected $_params=array();
        
        public function setType($type) {
            $this->_type = $type;
            return $this;
        }
        
        public function setParams(array $params)
        {
            $this->_params = $params;
            return $this;
        }
        
        protected function _getRendererByType()
        {
            $type = strtolower($this->_type);
            return 'checkoutoptions/field_renderer_'.$type;
        }
        
        public function _getRenderer()
        {
            if(!$this->_renderer)
            {
                $this->_renderer = $this->getLayout()->createBlock($this->_getRendererByType())->setParams($this->_params);
            }
            return $this->_renderer;
        }
        
        public function render()
        {
            return $this->_getRenderer()->render();
        }
        
}

?>