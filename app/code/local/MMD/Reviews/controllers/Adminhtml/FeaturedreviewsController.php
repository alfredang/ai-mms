<?php
/**
 * Admin "Featured Reviews" page — the curated list behind the storefront
 * testimonials (homepage strip + /testimonials).
 *
 * A focused view over `review.is_featured = 1`, so staff can see exactly what
 * the public sees without filtering the 22k-row All Reviews grid every time.
 * Un-featuring happens here; featuring still happens on All Reviews (that's
 * where you find a review worth promoting).
 *
 * Routed as adminhtml/featuredreviews/index. Kept separate from
 * FeaturedController (the mass-action endpoint) so the grid page and the
 * write endpoints stay independently ACL-able.
 */
class MMD_Reviews_Adminhtml_FeaturedreviewsController extends Mage_Adminhtml_Controller_Action
{
    public function indexAction()
    {
        $this->loadLayout();
        $this->_setActiveMenu('catalog');
        $this->_title($this->__('Featured Reviews'));

        $block = $this->getLayout()->createBlock('core/template')
            ->setTemplate('mmd/reviews/featured-grid.phtml');
        $this->getLayout()->getBlock('content')->append($block);

        $this->renderLayout();
    }

    /**
     * Remove a single review from the featured set (row action on this page).
     * Featuring is done from All Reviews; this page only demotes.
     */
    public function unfeatureAction()
    {
        $id      = (int) $this->getRequest()->getParam('id');
        $session = Mage::getSingleton('adminhtml/session');

        if ($id <= 0) {
            $session->addError($this->__('No review specified.'));
            $this->_redirect('*/*/index');
            return;
        }

        try {
            $write = Mage::getSingleton('core/resource')->getConnection('core_write');
            $write->update(
                Mage::getSingleton('core/resource')->getTableName('review/review'),
                array('is_featured' => 0),
                $write->quoteInto('review_id = ?', $id)
            );
            $session->addSuccess($this->__('Review removed from featured.'));
        } catch (Exception $e) {
            $session->addError($e->getMessage());
        }

        $this->_redirect('*/*/index');
    }

    /**
     * ACL: same resource the stock Reviews grid uses, so whoever can moderate
     * reviews can curate the featured set.
     */
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('catalog/reviews_ratings');
    }
}
