<?php
/**
 * Persists the `is_featured` flag posted by the admin review edit form.
 *
 * Mage_Review_Model_Resource_Review only writes the columns it knows about,
 * so the flag would silently vanish on save. Rather than rewrite the stock
 * review resource (which every review save in the app goes through), write
 * the single column here on `review_save_after`.
 */
class MMD_Reviews_Model_Observer
{
    /**
     * @param Varien_Event_Observer $observer
     * @return $this
     */
    public function saveFeaturedFlag(Varien_Event_Observer $observer)
    {
        /** @var Mage_Review_Model_Review $review */
        $review = $observer->getEvent()->getObject();
        if (!$review instanceof Mage_Review_Model_Review || !$review->getId()) {
            return $this;
        }

        // Only act when the form actually carried the field — a storefront
        // review submit or a programmatic save must not clear the flag.
        if (!$review->hasData('is_featured')) {
            return $this;
        }

        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $write->update(
            Mage::getSingleton('core/resource')->getTableName('review/review'),
            array('is_featured' => $review->getData('is_featured') ? 1 : 0),
            $write->quoteInto('review_id = ?', (int) $review->getId())
        );

        return $this;
    }
}
