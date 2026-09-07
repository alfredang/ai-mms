<?php
/**
 * Appends published blog posts to the generated sitemap.xml.
 *
 * Stock Mage_Sitemap_Model_Sitemap only knows categories, products and CMS
 * pages, so /blog/<url_key> posts were never listed — live, indexable pages
 * invisible to Google. Hooks the core `sitemap_urlset_generating_before`
 * event (fired just before </urlset>) rather than rewriting the sitemap
 * model, so stock generation is untouched.
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
}
