<?php
/**
 * Leads admin container — standard Grid_Container so the grid is
 * wrapped by sidebar-nav-v2.js::wrapAdminGridInCard() the same way
 * All Reviews / URL Rewrite / Funding Tags / every other admin
 * grid is. Previously this rendered via a custom phtml template,
 * which produced a visually-similar-but-not-identical chrome —
 * one code path is easier to keep canonical.
 */
class MMD_Leads_Block_Adminhtml_Leads extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_leads';
        $this->_blockGroup = 'mmd_leads';
        $this->_headerText = Mage::helper('mmd_leads')->__('General Enquiry');
        parent::__construct();
        // No "Add Lead" button — leads come from the storefront only.
        $this->_removeButton('add');
    }
}
