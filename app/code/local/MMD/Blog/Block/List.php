<?php
/**
 * Blog listing block — published posts, optional tag filter (tagAction sets
 * TagName), simple page/limit pagination via ?p=N.
 */
class MMD_Blog_Block_List extends Mage_Core_Block_Template
{
    private const PER_PAGE = 12;

    /** @return MMD_Blog_Model_Resource_Post_Collection */
    public function getPosts()
    {
        $collection = Mage::getModel('mmd_blog/post')->getCollection()->addPublishedFilter();
        if ($this->getTagName()) {
            $collection->addTagFilter($this->getTagName());
        }
        $collection->setPageSize(self::PER_PAGE)->setCurPage($this->getCurrentPage());
        return $collection;
    }

    public function getCurrentPage()
    {
        return max(1, (int) $this->getRequest()->getParam('p', 1));
    }

    public function getLastPage()
    {
        $collection = Mage::getModel('mmd_blog/post')->getCollection()->addPublishedFilter();
        if ($this->getTagName()) {
            $collection->addTagFilter($this->getTagName());
        }
        return max(1, (int) ceil($collection->getSize() / self::PER_PAGE));
    }

    public function getPageUrl($page)
    {
        $base = $this->getTagName()
            ? Mage::helper('mmd_blog')->getTagUrl($this->getTagName())
            : Mage::helper('mmd_blog')->getListUrl();
        return $page > 1 ? $base . '?p=' . (int) $page : $base;
    }

    public function helper($name = 'mmd_blog')
    {
        return Mage::helper($name);
    }
}
