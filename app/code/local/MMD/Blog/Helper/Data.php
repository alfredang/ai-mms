<?php
/**
 * Blog helper — slugs, tag sync (reuses the core Magento `tag` table via the
 * mmd_blog_post_tag link table), URLs and content filtering.
 */
class MMD_Blog_Helper_Data extends Mage_Core_Helper_Abstract
{
    /** Storefront URL of a post: <base>/blog/<url_key> */
    public function getPostUrl($post)
    {
        return Mage::getUrl('', array('_direct' => 'blog/' . $post->getUrlKey()));
    }

    public function getListUrl()
    {
        return Mage::getUrl('', array('_direct' => 'blog'));
    }

    public function getTagUrl($tagName)
    {
        return Mage::getUrl('', array('_direct' => 'blog/tag/' . urlencode($tagName)));
    }

    /** "Mastering Claude Code!" -> "mastering-claude-code" */
    public function slugify($text)
    {
        $slug = strtolower(trim((string) $text));
        $slug = preg_replace('/[^a-z0-9]+/', '-', $slug);
        return trim($slug, '-');
    }

    /** Append -2, -3, ... until the url_key is free (excluding the post itself). */
    public function ensureUniqueUrlKey($urlKey, $excludePostId = null)
    {
        $read      = Mage::getSingleton('core/resource')->getConnection('core_read');
        $table     = Mage::getSingleton('core/resource')->getTableName('mmd_blog/post');
        $candidate = $urlKey !== '' ? $urlKey : 'post';
        $n         = 2;
        while (true) {
            $select = $read->select()->from($table, 'post_id')->where('url_key = ?', $candidate);
            if ($excludePostId) {
                $select->where('post_id <> ?', (int) $excludePostId);
            }
            if (!$read->fetchOne($select)) {
                return $candidate;
            }
            $candidate = $urlKey . '-' . $n++;
            if ($n > 50) {
                Mage::throwException('Cannot find a unique blog URL key for: ' . $urlKey);
            }
        }
    }

    /**
     * Replace a post's tags with the given names. Tag rows are reused from /
     * created in the core `tag` table (status 1 = approved) so blog tags and
     * product tags share one vocabulary.
     *
     * @param int      $postId
     * @param string[] $tagNames
     */
    public function syncTags($postId, array $tagNames)
    {
        $resource = Mage::getSingleton('core/resource');
        $write    = $resource->getConnection('core_write');
        $tagTable = $resource->getTableName('tag/tag');
        $linkTable = $resource->getTableName('mmd_blog_post_tag');

        $tagIds = array();
        foreach ($tagNames as $name) {
            $name = trim($name);
            if ($name === '') {
                continue;
            }
            $tagId = $write->fetchOne(
                $write->select()->from($tagTable, 'tag_id')->where('name = ?', $name)
            );
            if (!$tagId) {
                $write->insert($tagTable, array('name' => $name, 'status' => 1));
                $tagId = $write->lastInsertId($tagTable);
            }
            $tagIds[(int) $tagId] = true;
        }

        $write->delete($linkTable, array('post_id = ?' => (int) $postId));
        foreach (array_keys($tagIds) as $tagId) {
            $write->insert($linkTable, array('post_id' => (int) $postId, 'tag_id' => $tagId));
        }
    }

    /** @return string[] tag names for a post */
    public function getPostTags($postId)
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        return $read->fetchCol(
            $read->select()
                ->from(array('bpt' => $resource->getTableName('mmd_blog_post_tag')), array())
                ->join(array('t' => $resource->getTableName('tag/tag')), 't.tag_id = bpt.tag_id', array('name'))
                ->where('bpt.post_id = ?', (int) $postId)
                ->order('t.name')
        );
    }

    /** @return string[] distinct tag names across published posts (for the list-page filter strip) */
    public function getPublishedTagNames()
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        return $read->fetchCol(
            $read->select()
                ->distinct()
                ->from(array('t' => $resource->getTableName('tag/tag')), array('name'))
                ->join(array('bpt' => $resource->getTableName('mmd_blog_post_tag')), 'bpt.tag_id = t.tag_id', array())
                ->join(array('p' => $resource->getTableName('mmd_blog/post')), 'p.post_id = bpt.post_id', array())
                ->where('p.status = ?', MMD_Blog_Model_Post::STATUS_PUBLISHED)
                ->order('t.name')
        );
    }

    /** Run post HTML through the CMS directive filter ({{store}}, {{media}}, ...). */
    public function filterContent($html)
    {
        return Mage::helper('cms')->getBlockTemplateProcessor()->filter((string) $html);
    }

    /**
     * Load the products behind a post's related_skus (comma-separated) that
     * are visible + have a URL — these power the sign-up CTA cards.
     *
     * @return Mage_Catalog_Model_Product[]
     */
    public function getRelatedCourses($post, $limit = 4)
    {
        $out  = array();
        $skus = array_filter(array_map('trim', explode(',', (string) $post->getRelatedSkus())));
        foreach ($skus as $sku) {
            if (count($out) >= $limit) {
                break;
            }
            $product = Mage::getModel('catalog/product');
            $id      = $product->getIdBySku($sku);
            if (!$id) {
                continue;
            }
            $product->setStoreId(Mage::app()->getStore()->getId())->load($id);
            if ($product->getId() && $product->getStatus() == Mage_Catalog_Model_Product_Status::STATUS_ENABLED) {
                $out[] = $product;
            }
        }
        return $out;
    }

    /**
     * Register a thumbs-up. One like per visitor (keyed by IP+UA hash) — a
     * repeat click is a no-op that just returns the current count. The seeded
     * baseline (10..300, migration 309) is preserved: a genuine new like adds 1
     * on top of it.
     *
     * @return array{likes:int,liked:bool}
     */
    public function likePost($postId)
    {
        $postId    = (int) $postId;
        $resource  = Mage::getSingleton('core/resource');
        $write      = $resource->getConnection('core_write');
        $voteTable  = $resource->getTableName('mmd_blog_post_vote');
        $postTable  = $resource->getTableName('mmd_blog/post');

        $hash = sha1($postId . '|' . Mage::helper('core/http')->getRemoteAddr() . '|'
            . Mage::helper('core/http')->getHttpUserAgent());

        // INSERT IGNORE returns affected rows = 1 for a new like, 0 for a repeat.
        $stmt   = $write->query(
            "INSERT IGNORE INTO {$voteTable} (post_id, voter_hash, rating, created_at)
             VALUES (:post_id, :hash, 1, NOW())",
            array('post_id' => $postId, 'hash' => $hash)
        );
        $isNew = ((int) $stmt->rowCount()) > 0;
        if ($isNew) {
            $write->query(
                "UPDATE {$postTable} SET likes = likes + 1 WHERE post_id = :post_id",
                array('post_id' => $postId)
            );
        }

        $likes = (int) $write->fetchOne(
            $write->select()->from($postTable, 'likes')->where('post_id = ?', $postId)
        );
        return array('likes' => $likes, 'liked' => $isNew);
    }
}
