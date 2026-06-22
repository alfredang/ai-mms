<?php
class MMD_Reindex_Block_Adminhtml_Reindexlog extends Mage_Adminhtml_Block_Widget_Grid_Container
{
    public function __construct()
    {
        $this->_controller = 'adminhtml_reindexlog';
        $this->_blockGroup = 'mmd_reindex';
        $this->_headerText = Mage::helper('mmd_reindex')->__('Reindex Logs');
        parent::__construct();
        $this->_removeButton('add');
    }
}
