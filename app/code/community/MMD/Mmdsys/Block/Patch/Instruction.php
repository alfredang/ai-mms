<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Block_Patch_Instruction extends MMD_Mmdsys_Abstract_Adminhtml_Block
{
    /**
     * @var string
     */
    protected $_currentMod;
    
    protected function _construct()
    {
        $this->setTitle('MMD Manual Patch Instructions');
    }
    
    /**
     * @return string
     */
    public function getInstructionsHtml()
    {
        $html = '';
        $incompatibleList  = Mage::getSingleton('adminhtml/session')->getData('mmdsys_patch_incompatible_files');
        $this->_currentMod = Mage::app()->getRequest()->getParam('mod');
        
        if (!$this->_currentMod || !isset($incompatibleList[$this->_currentMod])) {
            Mage::app()->getResponse()->setRedirect($this->getUrl('mmdsys'));
            return $html;
        }
        foreach ($incompatibleList[$this->_currentMod] as $patchFile) {
            $html .= $this->_getBlockInstruction($patchFile);
        }
        
        return $html;
    }
    
    /**
     * @param array $patchFile
     * @return string
     */
    protected function _getBlockInstruction(array $patchFile)
    {
        $oneBlock = $this->getChild('mmdsys.patch.instruction.one');
        $oneBlock->setSourceFile($patchFile['file']);
        $oneBlock->setPatchFile($patchFile['patchfile']);
        $oneBlock->setExtensionPath($patchFile['mod']);
        $oneBlock->setExtensionName($this->_currentMod);
        return $oneBlock->toHtml();
    }
}