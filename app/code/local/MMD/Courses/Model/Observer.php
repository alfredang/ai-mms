<?php

class MMD_Courses_Model_Observer
{
    /** Prevent direct add-to-cart even when a customer kept an old course URL. */
    public function catalogProductIsSalableAfter(Varien_Event_Observer $observer)
    {
        $product = $observer->getEvent()->getProduct();
        if (!$product || stripos((string) $product->getSku(), 'TGS-') !== 0) {
            return $this;
        }

        if (!Mage::helper('courses')->isRegistrationOpen($product)) {
            $salable = $observer->getEvent()->getSalable();
            if ($salable) {
                $salable->setIsSalable(false);
            }
        }
        return $this;
    }
}
