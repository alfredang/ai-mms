<?php
/**
 * Storefront /testimonials — every featured review.
 */
class MMD_Reviews_IndexController extends Mage_Core_Controller_Front_Action
{
    public function indexAction()
    {
        $this->loadLayout();

        if ($head = $this->getLayout()->getBlock('head')) {
            $head->setTitle($this->__('Learner Testimonials'));
            $head->setDescription($this->__(
                'What our learners say about training with Tertiary Infotech Academy.'
            ));
        }

        $this->renderLayout();
    }
}
