<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Block_Edit extends Mage_Adminhtml_Block_Widget
{
    /**
     * @var bool
     */
    protected $_allowInstall = true;
    
    /**
     * @var array
     */
    protected $_errorList = array();
    
    public function _construct()
    {
        $mmdsysModel = new MMD_Mmdsys_Model_Mmdsys(); 
        if ($this->_errorList = $mmdsysModel->getAllowInstallErrors()) {
            $this->_allowInstall = false;
        }
        
        $this->setTitle('MMD Modules Manager v%s');
    }
    
    /**
     * Get current module version
     * 
     * @return string
     */
    public function getVersion()
    {
        return MMD_Mmdsys_Model_Platform::getInstance()->getVersion();
    }
    
    /**
     * Get new permissions link param
     * 
     * @return string
     */
    public function getPermLink()
    {
        $mode = $this->tool()->filesystem()->getPermissionsMode();
        
        if ($mode === MMD_Mmdsys_Model_Core_Filesystem::MODE_ALL) {
            return MMD_Mmdsys_Model_Core_Filesystem::MODE_NORMAL;
        } else {
            return MMD_Mmdsys_Model_Core_Filesystem::MODE_ALL;
        }
    }

    /**
     * Get new permissions link description
     * 
     * @return string
     */
    public function getPermLinkTitle()
    {
        $mode = $this->tool()->filesystem()->getPermissionsMode();

        if ($mode === MMD_Mmdsys_Model_Core_Filesystem::MODE_ALL) {
            return 'Grant restricted write permissions';
        } else {
            return 'Grant full write permissions';
        }
    }

    protected function _prepareLayout()
    {
        if ($this->_allowInstall) {
            $this->setChild('save_button',
                $this->getLayout()->createBlock('adminhtml/widget_button')
                    ->setData(array(
                        'label'     => Mage::helper('mmdsys')->__('Save modules settings'),
                        'onclick'   => 'configForm.submit()',
                        'class' => 'save',
                    ))
            );
            
            $this->setChild('form',
                $this->getLayout()->createBlock('mmdsys/form')
                    ->initForm()
            );
        }
        return parent::_prepareLayout();
    }

    /**
     * @return string
     */
    public function getSaveButtonHtml()
    {
        return $this->getChildHtml('save_button');
    }

    /**
     * @return string
     */
    public function getSaveUrl()
    {
        return $this->getUrl('*/*/save', array('_current'=>true));
    }

    /**
     * @return string
     */
    public function getInstallText()
    {
        if ($this->_allowInstall) {
            $installText = '';
            $closedFolders = $this->tool()->filesystem()->checkMainPermissions();
            if (!empty($closedFolders)) {
                $installText = '<ul class="messages"><li class="notice-msg"><ul><li>'.
                Mage::helper('mmdsys')->__('Before any action with MMD Modules, please ensure the folders below (including their files and subfolders) have writable permissions for the web server user (for example, apache):').
                '<br /><b>'.
                join('<br />', $closedFolders).
                '</b></li></ul></li></ul>';
            }
        } else {
            $installText = '<ul class="messages"><li class="error-msg"><ul><li>';
            
            foreach ($this->_errorList as $errorMsg) {
                $installText .= $errorMsg . '<br />';
            }
            $installText .= '</li></ul></li></ul>';
        }
        
        return $installText;
    }
    
    /**
     * @return MMD_Mmdsys_Abstract_Service
     */
    public function tool()
    {
        return MMD_Mmdsys_Abstract_Service::get($this);
    }
}