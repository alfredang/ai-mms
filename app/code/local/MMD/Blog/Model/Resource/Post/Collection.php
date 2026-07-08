<?php
class MMD_Blog_Model_Resource_Post_Collection extends Mage_Core_Model_Resource_Db_Collection_Abstract
{
    protected function _construct()
    {
        $this->_init('mmd_blog/post');
    }

    /** Published posts, newest first — the storefront-facing view. */
    public function addPublishedFilter()
    {
        // Qualified with main_table — the tag join also carries a `status` column.
        $this->addFieldToFilter('main_table.status', MMD_Blog_Model_Post::STATUS_PUBLISHED)
             ->setOrder('published_at', 'DESC')
             ->setOrder('post_id', 'DESC');
        return $this;
    }

    /** Restrict to posts carrying a given Magento tag name. */
    public function addTagFilter($tagName)
    {
        $resource = Mage::getSingleton('core/resource');
        $this->getSelect()
            ->join(
                array('bpt' => $resource->getTableName('mmd_blog_post_tag')),
                'bpt.post_id = main_table.post_id',
                array()
            )
            ->join(
                array('t' => $resource->getTableName('tag/tag')),
                't.tag_id = bpt.tag_id',
                array()
            )
            ->where('t.name = ?', $tagName);
        return $this;
    }
}
