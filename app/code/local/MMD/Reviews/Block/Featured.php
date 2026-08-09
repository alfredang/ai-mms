<?php
/**
 * Featured-review block — backs both the homepage strip (random 4) and the
 * /testimonials listing (all featured, newest first).
 *
 * Which mode is used is set from layout XML via `mode` (`home` | `all`).
 */
class MMD_Reviews_Block_Featured extends Mage_Core_Block_Template
{
    /** @var array<int,array<string,mixed>>|null */
    protected $_reviews;

    /**
     * @return array<int,array<string,mixed>>
     */
    public function getReviews()
    {
        if ($this->_reviews === null) {
            $helper = $this->helper('mmd_reviews');
            $this->_reviews = $this->getMode() === 'all'
                ? $helper->getFeaturedReviews()
                : $helper->getHomepageReviews();
        }
        return $this->_reviews;
    }

    /**
     * The homepage strip is random per request, so it must never be held in
     * the block cache — otherwise every visitor sees the same four.
     *
     * @return string|null
     */
    public function getCacheKey()
    {
        return null;
    }

    /**
     * @return int|bool
     */
    public function getCacheLifetime()
    {
        return null;
    }
}
