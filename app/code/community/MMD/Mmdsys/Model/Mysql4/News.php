<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Model_Mysql4_News extends MMD_Mmdsys_Abstract_Mysql4
{
    protected function _construct()
    {
        $this->_init('mmdsys/news','entity_id');
    }
    
    /**
     * @return MMD_Mmdsys_Model_Notification_News
     */
    public function getLatest( $type )
    {
        return $this->_getNewsCollection()
            ->addTypeFilter($type)
            ->addOrder('date_added')
            ->getLastItem();
    }
    
    /**
     * @param MMD_Mmdsys_Model_Mysql4_News
     */
    public function clear( $type )
    {
        $this->_getWriteAdapter()->query("DELETE FROM `{$this->getMainTable()}` WHERE `type` = ?",array($type));
        return $this;
    }
    
    /**
     * @return MMD_Mmdsys_Model_Mysql4_News_Collection
     */
    protected function _getNewsCollection()
    {
        return Mage::getResourceModel('mmdsys/news_collection');
    }
}