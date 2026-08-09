<?php
/**
 * Bulk featured/unfeatured toggling from the All Reviews grid massaction.
 *
 * Editing 22k reviews one at a time is not a workflow, so the grid gets
 * "Mark as Featured" / "Remove from Featured" mass actions pointing here.
 */
class MMD_Reviews_Adminhtml_FeaturedController extends Mage_Adminhtml_Controller_Action
{
    /**
     * @return bool
     */
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('catalog/reviews_ratings');
    }

    public function massFeaturedAction()
    {
        $this->_setFeatured(1);
    }

    public function massUnfeaturedAction()
    {
        $this->_setFeatured(0);
    }

    /**
     * @param int $flag
     */
    protected function _setFeatured($flag)
    {
        $reviewIds = $this->getRequest()->getParam('reviews');
        $session   = Mage::getSingleton('adminhtml/session');

        if (!is_array($reviewIds) || !$reviewIds) {
            $session->addError($this->__('Please select one or more reviews.'));
            $this->_redirectBack();
            return;
        }

        $reviewIds = array_filter(array_map('intval', $reviewIds));
        if (!$reviewIds) {
            $session->addError($this->__('Please select one or more reviews.'));
            $this->_redirectBack();
            return;
        }

        try {
            $write = Mage::getSingleton('core/resource')->getConnection('core_write');
            $table = Mage::getSingleton('core/resource')->getTableName('review/review');
            $count = $write->update(
                $table,
                array('is_featured' => (int) $flag),
                $write->quoteInto('review_id IN (?)', $reviewIds)
            );

            $session->addSuccess($flag
                ? $this->__('%d review(s) marked as featured.', $count)
                : $this->__('%d review(s) removed from featured.', $count));

            if ($flag) {
                // Featured only surfaces on the storefront once approved —
                // say so rather than letting the admin wonder why nothing
                // appeared on the homepage.
                $pending = (int) $write->fetchOne(
                    $write->select()->from($table, 'COUNT(*)')
                        ->where('review_id IN (?)', $reviewIds)
                        ->where('status_id <> ?', Mage_Review_Model_Review::STATUS_APPROVED)
                );
                if ($pending > 0) {
                    $session->addNotice($this->__(
                        '%d of them are not approved yet and will stay hidden on the storefront until they are.',
                        $pending
                    ));
                }
            }
        } catch (Exception $e) {
            $session->addError($e->getMessage());
        }

        $this->_redirectBack();
    }

    protected function _redirectBack()
    {
        $this->_redirect('adminhtml/catalog_product_review/index');
    }
}
