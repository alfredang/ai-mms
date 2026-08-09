<?php
/**
 * Featured-review data access.
 *
 * Featured reviews are ordinary approved product reviews carrying
 * `review.is_featured = 1` (migration 897). Nothing here writes — the admin
 * grid massaction and the edit form own the flag.
 */
class MMD_Reviews_Helper_Data extends Mage_Core_Helper_Abstract
{
    /** Homepage strip size. */
    const HOME_LIMIT = 4;

    /**
     * Featured approved reviews for the current store, newest first.
     *
     * Returns plain rows (not a review collection) because the storefront only
     * needs nickname/title/detail/product + the average score — loading the
     * full EAV product collection per review would cost 4 extra queries a card.
     *
     * @param int  $limit  0 = no limit
     * @param bool $random shuffle in SQL (homepage strip) vs newest-first
     * @return array<int,array<string,mixed>>
     */
    public function getFeaturedReviews($limit = 0, $random = false)
    {
        $storeId = (int) Mage::app()->getStore()->getId();
        $read    = Mage::getSingleton('core/resource')->getConnection('core_read');
        $res     = Mage::getSingleton('core/resource');

        $select = $read->select()
            ->from(array('r' => $res->getTableName('review/review')), array(
                'review_id', 'entity_pk_value', 'created_at',
            ))
            ->join(
                array('d' => $res->getTableName('review/review_detail')),
                'd.review_id = r.review_id',
                array('title', 'detail', 'nickname')
            )
            // review_store scopes a review to the store views it shows on.
            ->join(
                array('s' => $res->getTableName('review/review_store')),
                's.review_id = r.review_id AND s.store_id = ' . $storeId,
                array()
            )
            ->where('r.is_featured = ?', 1)
            ->where('r.status_id = ?', Mage_Review_Model_Review::STATUS_APPROVED);

        if ($random) {
            $select->order(new Zend_Db_Expr('RAND()'));
        } else {
            $select->order('r.created_at DESC');
        }
        if ($limit > 0) {
            $select->limit($limit);
        }

        $rows = $read->fetchAll($select);
        if (!$rows) {
            return array();
        }

        $this->_attachProducts($rows);
        $this->_attachScores($rows);
        return $rows;
    }

    /**
     * Convenience wrapper for the homepage strip.
     * @return array<int,array<string,mixed>>
     */
    public function getHomepageReviews()
    {
        return $this->getFeaturedReviews(self::HOME_LIMIT, true);
    }

    /**
     * Add course name + url to each row in one collection load.
     *
     * @param array<int,array<string,mixed>> $rows passed by reference
     */
    protected function _attachProducts(array &$rows)
    {
        $ids = array();
        foreach ($rows as $row) {
            $ids[] = (int) $row['entity_pk_value'];
        }

        $products = Mage::getResourceModel('catalog/product_collection')
            ->addAttributeToSelect(array('name', 'url_key'))
            ->addAttributeToFilter('entity_id', array('in' => array_unique($ids)))
            ->addUrlRewrite();

        $byId = array();
        foreach ($products as $product) {
            $byId[(int) $product->getId()] = array(
                'course_name' => $product->getName(),
                'course_url'  => $product->getProductUrl(),
            );
        }

        foreach ($rows as &$row) {
            $pid = (int) $row['entity_pk_value'];
            $row['course_name'] = isset($byId[$pid]) ? $byId[$pid]['course_name'] : null;
            $row['course_url']  = isset($byId[$pid]) ? $byId[$pid]['course_url'] : null;
        }
        unset($row);
    }

    /**
     * Add the average star score (1–5, rounded to 1dp) per review.
     *
     * Reviews carry one vote per rating question; the storefront shows a
     * single star row, so average the questions.
     *
     * @param array<int,array<string,mixed>> $rows passed by reference
     */
    protected function _attachScores(array &$rows)
    {
        $ids = array();
        foreach ($rows as $row) {
            $ids[] = (int) $row['review_id'];
        }

        $read = Mage::getSingleton('core/resource')->getConnection('core_read');
        $res  = Mage::getSingleton('core/resource');
        $avg  = $read->fetchPairs(
            $read->select()
                ->from(
                    $res->getTableName('rating/rating_option_vote'),
                    array('review_id', new Zend_Db_Expr('AVG(value)'))
                )
                ->where('review_id IN (?)', $ids)
                ->group('review_id')
        );

        foreach ($rows as &$row) {
            $rid = (int) $row['review_id'];
            // No votes (e.g. an imported testimonial) reads as a full 5 — a
            // featured review is hand-picked, so it is never a low score.
            $row['score'] = isset($avg[$rid]) ? round((float) $avg[$rid], 1) : 5.0;
        }
        unset($row);
    }

    /**
     * Initials for the avatar circle, e.g. "Wai Mun Chia" -> "WC".
     *
     * @param string $name
     * @return string
     */
    public function getInitials($name)
    {
        $parts = preg_split('/\s+/', trim((string) $name), -1, PREG_SPLIT_NO_EMPTY);
        if (!$parts) {
            return '?';
        }
        $first = mb_substr($parts[0], 0, 1, 'UTF-8');
        $last  = count($parts) > 1 ? mb_substr($parts[count($parts) - 1], 0, 1, 'UTF-8') : '';
        return mb_strtoupper($first . $last, 'UTF-8');
    }

    /**
     * Deterministic avatar colour index (0–5) so a learner keeps the same
     * colour across page loads even though the homepage order is random.
     *
     * @param string $name
     * @return int
     */
    public function getAvatarIndex($name)
    {
        return (int) (crc32((string) $name) % 6);
    }

    /**
     * @return string
     */
    public function getTestimonialsUrl()
    {
        return Mage::getUrl('testimonials');
    }
}
