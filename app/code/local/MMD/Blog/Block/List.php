<?php
/**
 * Blog listing block — published posts, optional tag filter (tagAction sets
 * TagName), optional free-text search via ?q= (blog posts only), simple
 * page/limit pagination via ?p=N.
 */
class MMD_Blog_Block_List extends Mage_Core_Block_Template
{
    private const PER_PAGE = 12;

    /** How many numbered page buttons the pager shows around the current page. */
    private const WINDOW = 5;

    /** Base published collection with the active tag/search filters applied. */
    private function _filteredCollection()
    {
        $collection = Mage::getModel('mmd_blog/post')->getCollection()->addPublishedFilter();
        if ($this->getTagName()) {
            $collection->addTagFilter($this->getTagName());
        }
        if ($this->getSearchQuery() !== '') {
            $collection->addSearchFilter($this->getSearchQuery());
        }
        return $collection;
    }

    /** @return MMD_Blog_Model_Resource_Post_Collection */
    public function getPosts()
    {
        return $this->_filteredCollection()
            ->setPageSize(self::PER_PAGE)
            ->setCurPage($this->getCurrentPage());
    }

    /** The ?q= blog search term (trimmed; '' when not searching). */
    public function getSearchQuery()
    {
        return trim((string) $this->getRequest()->getParam('q', ''));
    }

    /** Total matches for the current filters — for the "N results" line. */
    public function getResultCount()
    {
        return (int) $this->_filteredCollection()->getSize();
    }

    /** Total published posts, ignoring tag/search filters — for the header count. */
    public function getTotalPublishedCount()
    {
        return (int) Mage::getModel('mmd_blog/post')->getCollection()
            ->addPublishedFilter()
            ->getSize();
    }

    public function getCurrentPage()
    {
        return max(1, (int) $this->getRequest()->getParam('p', 1));
    }

    /** getCurrentPage() clamped into 1..getLastPage() — for the pager UI. */
    public function getDisplayPage()
    {
        return min($this->getCurrentPage(), $this->getLastPage());
    }

    public function getLastPage()
    {
        return max(1, (int) ceil($this->_filteredCollection()->getSize() / self::PER_PAGE));
    }

    /**
     * Page numbers to render around the current page, as a sliding window of
     * at most WINDOW entries. The template adds First/Last itself, so this
     * never has to list every page — at 500+ posts the old "1..N" loop drew
     * 40+ buttons and grew without bound.
     *
     * @return int[] ascending page numbers, always including the current page
     */
    public function getPageWindow()
    {
        $last = $this->getLastPage();
        $cur  = min($this->getCurrentPage(), $last);
        $half = (int) floor(self::WINDOW / 2);

        $start = max(1, $cur - $half);
        $end   = min($last, $start + self::WINDOW - 1);
        $start = max(1, $end - self::WINDOW + 1);

        return range($start, $end);
    }

    public function getPageUrl($page)
    {
        $base = $this->getTagName()
            ? Mage::helper('mmd_blog')->getTagUrl($this->getTagName())
            : Mage::helper('mmd_blog')->getListUrl();
        $params = array();
        if ($this->getSearchQuery() !== '') {
            $params['q'] = $this->getSearchQuery();
        }
        if ($page > 1) {
            $params['p'] = (int) $page;
        }
        return $params ? $base . '?' . http_build_query($params) : $base;
    }

    /** Latest N published posts — for the homepage "From our blog" strip. */
    public function getRecentPosts($limit = 4)
    {
        return Mage::getModel('mmd_blog/post')->getCollection()
            ->addPublishedFilter()
            ->setPageSize((int) $limit)
            ->setCurPage(1);
    }

    public function helper($name = 'mmd_blog')
    {
        return Mage::helper($name);
    }
}
