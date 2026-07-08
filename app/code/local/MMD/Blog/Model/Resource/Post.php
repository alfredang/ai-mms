<?php
class MMD_Blog_Model_Resource_Post extends Mage_Core_Model_Resource_Db_Abstract
{
    protected function _construct()
    {
        $this->_init('mmd_blog/post', 'post_id');
    }
}
