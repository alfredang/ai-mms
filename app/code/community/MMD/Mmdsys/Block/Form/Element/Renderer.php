<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Block_Form_Element_Renderer extends Mage_Adminhtml_Block_Widget_Form_Renderer_Fieldset_Element
{
    protected function _construct()
    {
        $this->setTemplate('mmdcore/fieldset/element.phtml');
    }
    
    /**
     * @return MMD_Mmdsys_Model_Module
     */
    public function getModule()
    {
        return $this->getElement()->getModule();
    }
}