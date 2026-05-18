<?php
/**
 * MMD_SingaporePrice_Model_Catalog_Product_Type_Price
 *
 * Persists the SG funding-discount math from quote → checkout → order.
 *
 * Why a class rewrite rather than an observer:
 *
 *   The standard final-price chain is
 *
 *       $finalPrice = parent::getFinalPrice($qty, $product);
 *       // dispatches catalog_product_get_final_price (observer slot)
 *       $finalPrice = $this->_applyOptionsPrice(...);
 *       $product->setFinalPrice($finalPrice);
 *
 *   The observer slot fires BEFORE _applyOptionsPrice, and the parent
 *   class's _applyOptionsPrice (the MMD_CustomOptions implementation)
 *   resets finalPrice to 0 and then re-adds basePrice when none of
 *   the selected options carry a $-price. That overwrites anything an
 *   observer would have set. So the only safe injection point is
 *   after _applyOptionsPrice returns — which means a class rewrite.
 *
 * Extension chain (least to most specific):
 *
 *   Mage_Catalog_Model_Product_Type_Price
 *     ↑ extends
 *   MMD_CustomOptions_Model_Catalog_Product_Type_Price   ← option-price math
 *     ↑ extends
 *   MMD_SingaporePrice_Model_Catalog_Product_Type_Price  ← this class
 *
 *   When MMD_CustomOptions is eventually retired:
 *     1. Change `extends MMD_CustomOptions_Model_…_Price` to
 *        `extends Mage_Catalog_Model_Product_Type_Price`.
 *     2. Remove the <depends>Mage_Catalog</depends> note in this
 *        module's module xml (no longer relevant).
 *     3. Delete the customoptions <rewrite> entry from its config.xml
 *        (already gone with the module).
 *   No other changes needed in this file.
 */
class MMD_SingaporePrice_Model_Catalog_Product_Type_Price
    extends MMD_CustomOptions_Model_Catalog_Product_Type_Price
{
    /**
     * Defensive guard against the recurring "$0 in cart, $350 on page"
     * bug. A special_price of exactly 0 is never meaningful for a paid
     * course (see migrations 076 / 077). When products are re-saved or
     * re-imported the bad special_price=0 EAV row comes back: Magento's
     * final-price math then collapses the cart line to $0, while the
     * product page + GST still show the real fee (getCatalogPrice reads
     * the untouched `price` attribute, not special_price). The one-shot
     * cleanup migrations don't catch rows created after they ran, so
     * neutralise a zero special_price here — every final-price
     * computation flows through this model, so the cart can never be
     * zeroed by it again. Genuinely-free courses use a regular price of
     * 0 (not special_price=0) and are unaffected.
     *
     * @param Mage_Catalog_Model_Product $product
     * @param float                       $qty
     * @return float
     */
    public function getFinalPrice($qty, $product)
    {
        $sp = $product->getSpecialPrice();
        if ($sp !== null && $sp !== false && $sp !== '' && (float) $sp == 0.0) {
            $product->setSpecialPrice(false);
        }
        return parent::getFinalPrice($qty, $product);
    }

    /**
     * After the parent has resolved the option-loaded final price,
     * apply the SG funding-discount percent if the buyer selected a
     * Funding-Eligibility radio whose label maps to a configured
     * percent in mmd_company/sg_funding/*.
     *
     * @param Mage_Catalog_Model_Product $product
     * @param float                       $qty
     * @param float                       $finalPrice
     * @return float
     */
    protected function _applyOptionsPrice($product, $qty, $finalPrice)
    {
        $finalPrice = parent::_applyOptionsPrice($product, $qty, $finalPrice);

        /** @var MMD_SingaporePrice_Helper_Data $helper */
        $helper = Mage::helper('mmd_singaporeprice');
        if (!$helper->isActive($product->getStoreId())) {
            return $finalPrice;
        }

        $percent = $this->_fundingDiscountPercent($product, $helper);
        if ($percent <= 0) {
            // No funding discount → the SG course fee is simply the
            // catalog price plus any priced option add-ons (e.g. the
            // +$130 starter kit). Floor to that. This is mechanism-
            // independent: whatever zeroed the parent's final price
            // (a recurring special_price=0 row, a stale/collapsed
            // catalog_product_index_price.final_price, a 100%-off
            // catalog price rule, a final_price data override, …) can
            // no longer make the cart $0 while the product page + frozen
            // GST still show the real fee via getCatalogPrice(). SG
            // courses never use special_price / catalog-rule discounts —
            // the ONLY legitimate discount is the funding option handled
            // in the percent>0 branch below (076/077 policy). So
            // flooring here cannot mask an intended discount.
            $catalogPrice = $helper->getCatalogPrice($product);
            if ($catalogPrice > 0) {
                $optionAddOns = (float) $product->getBaseCustomoptionsPrice();
                $expected     = $catalogPrice + $optionAddOns;
                if ($expected > $finalPrice) {
                    return $expected;
                }
            }
            return $finalPrice;
        }

        // The "course fee" before tax = catalog list × (1 − y/100).
        // Tax (GST) is applied separately by Magento's tax engine on
        // the catalog list price (see Mage_Tax + SG GST override in
        // app/code/local/MMD/Branchscope), so we only need to return
        // the discounted fee here, not the GST-inclusive total.
        $catalogPrice = $helper->getCatalogPrice($product);
        $discounted   = $helper->computeFee($catalogPrice, $percent);

        return max(0, $discounted);
    }

    /**
     * Inspect every selected custom option on the buy request. For
     * each one, look up the chosen value's title and check whether
     * it maps to a configured SG funding row. Return the highest
     * matching percent — only one funding option should ever be
     * selected per product, but max() defends against duplicate
     * configurations.
     *
     * @param Mage_Catalog_Model_Product             $product
     * @param MMD_SingaporePrice_Helper_Data         $helper
     * @return float 0–100
     */
    protected function _fundingDiscountPercent($product, $helper)
    {
        $optionIdsOpt = $product->getCustomOption('option_ids');
        if (!$optionIdsOpt) {
            return 0.0;
        }

        $map = $helper->getFundingDiscountMap();
        if (empty($map)) {
            return 0.0;
        }

        $best = 0.0;
        foreach (explode(',', (string) $optionIdsOpt->getValue()) as $optionId) {
            $optionId = (int) $optionId;
            if (!$optionId) {
                continue;
            }
            $option = $product->getOptionById($optionId);
            if (!$option) {
                continue;
            }
            $selectedOpt = $product->getCustomOption('option_' . $optionId);
            if (!$selectedOpt) {
                continue;
            }
            $selectedValueId = (string) $selectedOpt->getValue();
            if ($selectedValueId === '') {
                continue;
            }

            foreach ($option->getValues() as $value) {
                if ((string) $value->getOptionTypeId() !== $selectedValueId) {
                    continue;
                }
                $key = strtolower(trim(preg_replace('/\s+/', ' ', (string) $value->getTitle())));
                if (isset($map[$key]) && (float) $map[$key] > $best) {
                    $best = (float) $map[$key];
                }
            }
        }

        return $best;
    }
}
