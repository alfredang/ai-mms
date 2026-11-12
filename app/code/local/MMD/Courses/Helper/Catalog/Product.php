<?php

/**
 * Keeps a TMS-hidden WSQ course reachable at its direct URL.
 *
 * /courses/api_availability hides a non-active TGS- course from listings by setting
 * visibility = "Not Visible Individually" (migration 1922). Stock canShow() then
 * 404s the product page, so old links, search engines and the renewal notice in
 * catalog/product/view.phtml all hit "Not found" (GSC 404 bucket, 2026-11-12).
 * An enabled TGS- course with a non-active availability row is still shown;
 * registration stays closed through MMD_Courses_Model_Observer.
 */
class MMD_Courses_Helper_Catalog_Product extends Mage_Catalog_Helper_Product
{
    public function canShow($product, $where = 'catalog')
    {
        if (parent::canShow($product, $where)) {
            return true;
        }
        if (is_int($product)) {
            $product = Mage::getModel('catalog/product')->load($product);
        }
        if (!$product->getId()
            || !$product->isVisibleInCatalog()
            || stripos((string) $product->getSku(), 'TGS-') !== 0
        ) {
            return false;
        }

        $availability = Mage::helper('courses')->getCourseAvailability($product);
        return $availability && $availability['availability_status'] !== 'active';
    }
}
