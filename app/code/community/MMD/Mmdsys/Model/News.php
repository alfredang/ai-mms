<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc. 
 */
class MMD_Mmdsys_Model_News extends MMD_Mmdsys_Abstract_Model
{
    protected function _construct()
    {
        $this->_init('mmdsys/news');
    }
    
    /**
     * @return bool
     */
    public function isOld()
    {
        return strtotime($this->getDateAdded()) < time()-86400;
    }
}