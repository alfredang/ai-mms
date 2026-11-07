<?php
/**
 * Appends published blog posts to the generated sitemap.xml.
 *
 * Stock Mage_Sitemap_Model_Sitemap only knows categories, products and CMS
 * pages, so /blog/<url_key> posts were never listed — live, indexable pages
 * invisible to Google. Hooks the core `sitemap_urlset_generating_before`
 * event (fired just before </urlset>) rather than rewriting the sitemap
 * model, so stock generation is untouched. Also filters empty course listings
 * out of the category section via `sitemap_categories_generating_before`.
 */
class MMD_Blog_Model_Observer_Sitemap
{
    /** Posts a crawler should see: published, and past their publish date. */
    protected function _publishedPosts()
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');

        $select = $read->select()
            ->from(
                $resource->getTableName('mmd_blog/post'),
                array('url_key', 'published_at', 'updated_at')
            )
            ->where('status = ?', MMD_Blog_Model_Post::STATUS_PUBLISHED)
            ->where('url_key IS NOT NULL AND url_key <> ""')
            ->where('published_at IS NOT NULL')
            ->where('published_at <= ?', Mage::getSingleton('core/date')->date('Y-m-d'))
            ->order('published_at DESC');

        return $read->fetchAll($select);
    }

    public function addPosts(Varien_Event_Observer $observer)
    {
        $io      = $observer->getEvent()->getFile();
        $baseUrl = rtrim($observer->getEvent()->getBaseUrl(), '/');

        foreach ($this->_publishedPosts() as $post) {
            // lastmod: prefer the real edit time, fall back to the publish date.
            $lastmod = $post['updated_at']
                ? substr($post['updated_at'], 0, 10)
                : $post['published_at'];

            $io->streamWrite(
                '<url>'
                . '<loc>' . htmlspecialchars($baseUrl . '/blog/' . $post['url_key']) . '</loc>'
                . '<lastmod>' . $lastmod . '</lastmod>'
                . '<changefreq>weekly</changefreq>'
                . '<priority>0.5</priority>'
                . '</url>'
            );
        }
    }

    /**
     * Drops course listing pages with no visible courses from the sitemap; the
     * pages stay live. Off unless this site's DB sets
     * sitemap/category/exclude_empty = 1. PAGE-mode categories render CMS
     * content rather than a course list, so they are kept.
     */
    public function removeEmptyCategories(Varien_Event_Observer $observer)
    {
        $storeId = (int) $observer->getEvent()->getStoreId();
        if (!Mage::getStoreConfigFlag('sitemap/category/exclude_empty', $storeId)) {
            return;
        }

        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');

        $withCourses = $read->fetchCol(
            $read->select()->distinct()
                ->from($resource->getTableName('catalog/category_product_index'), array('category_id'))
                ->where('store_id = ?', $storeId)
                ->where('visibility IN (?)', Mage::getSingleton('catalog/product_visibility')->getVisibleInCatalogIds())
        );
        // No rows at all means the index is mid-rebuild, not that every page is empty.
        if (!$withCourses) {
            return;
        }

        $displayMode = Mage::getSingleton('eav/config')->getAttribute('catalog_category', 'display_mode');
        $pageMode    = $read->fetchCol(
            $read->select()
                ->from($displayMode->getBackendTable(), array('entity_id'))
                ->where('attribute_id = ?', $displayMode->getId())
                ->where('store_id IN (?)', array(0, $storeId))
                ->where('value = ?', Mage_Catalog_Model_Category::DM_PAGE)
        );

        $categories = $observer->getEvent()->getCollection();
        $categories->setItems(array_intersect_key(
            $categories->getItems(),
            array_flip(array_merge($withCourses, $pageMode))
        ));
    }
}
