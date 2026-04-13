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
class MMD_Checkoutoptions_Block_Orderedit_Edit_Form extends Mage_Adminhtml_Block_Widget_Form
{

    public function __construct()
    {
        parent::__construct();
        $this->setId('mmdoptionstemplate_template_form');
        $this->setTitle(Mage::helper('salesrule')->__('Template Information'));
    }
    
    protected function _prepareForm()
    {
        $form = new Varien_Data_Form(array('id' => 'edit_form', 'action' => $this->getData('action'), 'method' => 'post'));
        $form->setUseContainer(true);
        $this->setForm($form);
        return parent::_prepareForm();
    }

    public function getCustomEditHtml()
    {
        $oFront = Mage::app()->getFrontController();
        
        $iOrderId = $oFront->getRequest()->getParam('order_id');
        
        $model = Mage::getModel('sales/order');
        
        $model->load($iOrderId);
        
        if (!$model->getData()) return '';

        $iStoreId = $model->getStoreId();

        $oCheckoutoptions  = Mage::getModel('checkoutoptions/checkoutoptions');

        $aCustomAtrrList = $oCheckoutoptions->getOrderCustomEditList($iOrderId, $iStoreId);
                
        $sHtml = '';
        
        $sHtml .= $this->getLayout()->createBlock('checkoutoptions/orderedit_edit_order')->toHtml();

        // to get rid of billing and shipping
        
        $aParts = explode('<div class="clear"></div>', $sHtml);
        
        $sHtml = $aParts[0] . '<div class="clear"></div>';

        $sHtml .= '<div class="entry-edit"><div class="entry-edit-head"><h4 class="icon-head head-account">' . Mage::helper('sales')->__('Edit Order Custom Data') . '</h4></div><div class="fieldset"><div class="hor-scroll">';
        
        if ($aCustomAtrrList)
        {
            $sHtml .= '<ul id="custom_order_data" >';
            
            foreach ($aCustomAtrrList as $sField)
            {
//                $sHtml .= '<li><div class="input-box">' . $sField . '</div></li>';
                $sHtml .= '' . $sField . '';
            }
            
            $sHtml .= '</ul>';
        }
        else 
        {
            $sHtml .= '' . Mage::helper('salesrule')->__('<b>No custom data</b>') . '';
        }
        
        $sHtml .= '</div></div></div>';
        
        return $sHtml;
    }
    
    
    protected function _toHtml()
    {
        $sHtml = parent::_toHtml();

        $sContent = $this->getCustomEditHtml();
        
        $sHtml = str_replace('</form>', $sContent . '</form>', $sHtml);
        
        return $sHtml;
    }


}