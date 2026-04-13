<?php
/**
 * @copyright  Copyright (c) 2009 MMD, Inc.
 */
class MMD_Mmdsys_Model_Mysql4_Module_Status extends MMD_Mmdsys_Abstract_Mysql4
{
    protected function _construct()
    {
        $this->_init('mmdsys/status', 'id');
    }
}