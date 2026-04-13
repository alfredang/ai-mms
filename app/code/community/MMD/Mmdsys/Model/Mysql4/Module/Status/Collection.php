<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
class MMD_Mmdsys_Model_Mysql4_Module_Status_Collection extends MMD_Mmdsys_Abstract_Mysql4_Collection
{
    protected function _construct()
    {
        $this->_init('mmdsys/module_status');
    }
    
    public function clearTable()
    {
        $this->load();
        $keys = array();
        foreach ($this->getItems() as $item) {
            if (!in_array($item->getModule(), $keys)) {
                $keys[] = $item->getModule();
             } else {
                $item->delete();
            }
        }
    }
}