<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Model_Mysql4_News_Collection extends MMD_Mmdsys_Abstract_Mysql4_Collection
{
    protected function _construct()
    {
        $this->_init('mmdsys/news');
    }
    
    /**
     * @param string $type [news|important]
     * 
     * @return MMD_Mmdsys_Model_Mysql4_News_Collection
     */
    public function addTypeFilter( $type )
    {
        return $this->addFieldToFilter('type', array('=' => $type));
    }
}