<?php
/**
 * MMD_SingaporePrice_Helper_Data
 *
 * Encapsulates the SG product-page pricing formula:
 *
 *     fee_displayed = x * (1 - y/100)
 *     gst           = 0.09 * x          (frozen on catalog price)
 *     total         = fee_displayed + gst
 *
 * x = catalog list price; y = funding-discount percent from Company
     * Settings (mmd_company/sg_funding/*). Singapore-only (storeId 1);
     * other stores are not the concern of this module.
 */
class MMD_SingaporePrice_Helper_Data extends Mage_Core_Helper_Abstract
{
    /** Stores this module applies to (id values). */
    const STORE_SG       = 1;

    /** GST rate. Loaded from mmd_company/gst/rate with a 9% fallback. */
    public function getGstRate()
    {
        $raw = (string) Mage::getStoreConfig('mmd_company/gst/rate');
        if ($raw === '') {
            return 0.09;
        }
        $clean = (float) str_replace(array('%', ' '), '', $raw);
        return $clean > 1 ? $clean / 100 : $clean;
    }

    /** Does this store render the SG price box? */
    public function isActive($storeId = null)
    {
        if ($storeId === null) {
            $storeId = (int) Mage::app()->getStore()->getId();
        }
        return ($storeId == self::STORE_SG);
    }

    /**
     * Funding-discount lookup keyed by lowercased option label.
     * Labels come straight from the storefront radio values for the
     * "Funding Eligibility" custom-option group; admins manage the
     * percentages from Dashboard → Company Setting → SG Funding
     * Discounts.
     */
    public function getFundingDiscountMap()
    {
        return array(
            'singaporean above 40 yrs old'     => (float) Mage::getStoreConfig('mmd_company/sg_funding/above_40'),
            'singaporean below 40 yrs old'     => (float) Mage::getStoreConfig('mmd_company/sg_funding/below_40'),
            'singapore pr'                     => (float) Mage::getStoreConfig('mmd_company/sg_funding/pr'),
            'non singaporean'                  => (float) Mage::getStoreConfig('mmd_company/sg_funding/non_sg'),
            'sme (singaporean/pr direct hire)' => (float) Mage::getStoreConfig('mmd_company/sg_funding/sme'),
        );
    }

    /**
     * Catalog list price for the product. Uses getPrice() rather than
     * getFinalPrice() because MMD_CustomOptions resets the latter to 0
     * server-side; getPrice() is the stable x in the formula.
     */
    public function getCatalogPrice(Mage_Catalog_Model_Product $product)
    {
        $p = (float) $product->getPrice();
        if ($p > 0) {
            return $p;
        }
        // Fallback for products whose `price` attribute is missing —
        // pull from the price index where final_price was repaired by
        // migration 076/077.
        return (float) $product->getFinalPrice();
    }

    /** y = 0 by default; positive y = a discount the storefront should subtract. */
    public function computeFee($catalogPrice, $discountPercent)
    {
        $x = (float) $catalogPrice;
        $y = max(0.0, min(100.0, (float) $discountPercent));
        return $x * (1 - ($y / 100));
    }

    /** GST is always frozen at rate × catalog price, regardless of discount. */
    public function computeGst($catalogPrice)
    {
        return (float) $catalogPrice * $this->getGstRate();
    }

    /** fee_displayed + frozen_gst. */
    public function computeTotal($catalogPrice, $discountPercent)
    {
        return $this->computeFee($catalogPrice, $discountPercent)
             + $this->computeGst($catalogPrice);
    }
}
