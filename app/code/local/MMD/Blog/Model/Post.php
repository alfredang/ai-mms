<?php
/**
 * Blog post entity. Table: mmd_blog_post (migrations/303-blog-feature.sql).
 *
 * status: 0 = draft, 1 = published.
 * Rating aggregates (rating_sum / rating_count) are denormalised onto the row
 * and recomputed from mmd_blog_post_vote on every vote.
 */
class MMD_Blog_Model_Post extends Mage_Core_Model_Abstract
{
    public const STATUS_DRAFT     = 0;
    public const STATUS_PUBLISHED = 1;

    protected function _construct()
    {
        $this->_init('mmd_blog/post');
    }

    public function loadByUrlKey($urlKey)
    {
        $this->load($urlKey, 'url_key');
        return $this;
    }

    public function isPublished()
    {
        return (int) $this->getStatus() === self::STATUS_PUBLISHED;
    }

    /** @return float 0.0 when unrated */
    public function getAvgRating()
    {
        $count = (int) $this->getRatingCount();
        if ($count < 1) {
            return 0.0;
        }
        return round(((int) $this->getRatingSum()) / $count, 1);
    }

    protected function _beforeSave()
    {
        $now = Varien_Date::now();
        if (!$this->getId() && !$this->getCreatedAt()) {
            $this->setCreatedAt($now);
        }
        $this->setUpdatedAt($now);
        return parent::_beforeSave();
    }
}
