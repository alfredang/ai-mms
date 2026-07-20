<?php
/**
 * Blog post entity. Table: mmd_blog_post (migrations/303-blog-feature.sql).
 *
 * status: 0 = draft, 1 = published, 2 = pending review (emailed to the managers),
 * 3 = scheduled (approved — publishes at scheduled_publish_at, Mon/Thu 09:00),
 * 4 = changes requested (manager feedback recorded, regeneration pending).
 * Review/scheduling columns come from migrations/450-blog-review-pipeline.sql.
 * Rating aggregates (rating_sum / rating_count) are denormalised onto the row
 * and recomputed from mmd_blog_post_vote on every vote.
 */
class MMD_Blog_Model_Post extends Mage_Core_Model_Abstract
{
    public const STATUS_DRAFT             = 0;
    public const STATUS_PUBLISHED         = 1;
    public const STATUS_PENDING_REVIEW    = 2;
    public const STATUS_SCHEDULED         = 3;
    public const STATUS_CHANGES_REQUESTED = 4;

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

    /** Thumbs-up count shown on the card and post page. */
    public function getLikeCount()
    {
        return (int) $this->getLikes();
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
