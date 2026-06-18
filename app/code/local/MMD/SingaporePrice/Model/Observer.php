<?php
/**
 * MMD_SingaporePrice_Model_Observer
 *
 * On product save, if `enable_sg_funding` is set, makes sure the
 * standard Magento custom option "Funding Eligibility (Subject to
 * Verification)" exists on the product with the five canonical
 * radio values. The percentages themselves live in Company Settings
 * (mmd_company/sg_funding/*) and are read by the storefront JS and
 * the price model — so per-product editing is no longer needed and
 * the third-party "option templates" feature can be retired.
 *
 * Behaviour:
 *   - enable_sg_funding=1 + funding option missing → create it (5 values)
 *   - enable_sg_funding=1 + funding option present → no-op (idempotent)
 *   - enable_sg_funding=0 → no-op (does NOT delete; admin can prune)
 */
class MMD_SingaporePrice_Model_Observer
{
    /** Title of the canonical funding option created on products. */
    const OPTION_TITLE = 'Funding Eligibility (Subject to Verification)';

    /** Canonical value labels — match the keys in helper::getFundingDiscountMap(). */
    protected $_values = array(
        'Singaporean above 40 yrs old',
        'Singaporean below 40 yrs old',
        'Singapore PR',
        'non Singaporean',
        'SME (Singaporean/PR Direct Hire)',
    );

    /** catalog_product_save_after observer entry point. */
    public function onProductSaveAfter($observer)
    {
        try {
            /** @var Mage_Catalog_Model_Product $product */
            $product = $observer->getProduct();
            if (!$product || !$product->getId()) return;

            // Use the raw attribute value rather than getEnableSgFunding()
            // because not every load path hydrates EAV magic getters.
            $enabled = (int) $product->getData('enable_sg_funding');
            if ($enabled !== 1) return;

            if ($this->_hasFundingOption($product)) return;

            $this->_createFundingOption($product);
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }

    /** True when the product already carries any option titled like funding. */
    protected function _hasFundingOption(Mage_Catalog_Model_Product $product)
    {
        foreach ($product->getOptions() as $option) {
            $title = trim((string) $option->getTitle());
            if (strcasecmp($title, self::OPTION_TITLE) === 0) {
                return true;
            }
        }
        // Re-load options from DB in case the in-memory model is stale.
        $coll = Mage::getModel('catalog/product_option')->getCollection()
            ->addProductToFilter($product->getId())
            ->addTitleToResult($product->getStoreId());
        foreach ($coll as $option) {
            $title = trim((string) $option->getTitle());
            if (strcasecmp($title, self::OPTION_TITLE) === 0) {
                return true;
            }
        }
        return false;
    }

    /** Create the radio option with the 5 canonical values. */
    protected function _createFundingOption(Mage_Catalog_Model_Product $product)
    {
        $optionData = array(
            'title'      => self::OPTION_TITLE,
            'type'       => 'radio',
            'is_require' => 0,
            'sort_order' => 100,
            'values'     => array(),
        );
        $sortOrder = 1;
        foreach ($this->_values as $label) {
            $optionData['values'][] = array(
                'title'      => $label,
                'price'      => 0,
                'price_type' => 'fixed',
                'sku'        => '',
                'sort_order' => $sortOrder++,
            );
        }

        $option = Mage::getModel('catalog/product_option')
            ->setProductId($product->getId())
            ->setStoreId($product->getStoreId())
            ->addData($optionData);
        $option->save();
    }

    /**
     * sales_quote_collect_totals_after observer.
     *
     * SG GST rule: tax is frozen at gst_rate × catalog list price, NOT
     * computed on the discounted line subtotal. By the time this event
     * fires, Magento's standard tax engine has already written
     * tax_amount = discounted_subtotal × rate onto each item + the
     * address. We rewrite those values to the catalog-price-based amount.
     *
     * Active only when isActive(storeId) is true (SG storeId 1).
     * Other stores: no-op.
     */
    public function freezeSgGstOnCatalogPrice($observer)
    {
        try {
            /** @var Mage_Sales_Model_Quote $quote */
            $quote = $observer->getQuote();
            if (!$quote) return;

            $helper = Mage::helper('mmd_singaporeprice');
            if (!$helper->isActive($quote->getStoreId())) return;

            $rate = $helper->getGstRate();
            if ($rate <= 0) return;

            foreach ($quote->getAllAddresses() as $address) {
                $totalNewTax = 0.0;

                foreach ($address->getAllItems() as $item) {
                    if ($item->getParentItemId()) continue; // child of configurable/bundle
                    $product = $item->getProduct();
                    if (!$product) continue;

                    // Catalog list price = stable x for GST math.
                    $catalogPrice = $helper->getCatalogPrice($product);
                    if ($catalogPrice <= 0) continue;

                    $qty = (float) ($item->getTotalQty() ?: $item->getQty());
                    if ($qty <= 0) $qty = 1;

                    $itemTax = $catalogPrice * $rate * $qty;
                    $rowTotal = (float) $item->getRowTotal();

                    $item->setTaxAmount($itemTax)
                         ->setBaseTaxAmount($itemTax)
                         ->setRowTotalInclTax($rowTotal + $itemTax)
                         ->setBaseRowTotalInclTax($rowTotal + $itemTax)
                         ->setTaxPercent($rate * 100)
                         ->setPriceInclTax($catalogPrice * $rate + (float) $item->getPrice())
                         ->setBasePriceInclTax($catalogPrice * $rate + (float) $item->getBasePrice());

                    $totalNewTax += $itemTax;
                }

                $oldTax = (float) $address->getTaxAmount();
                $delta  = $totalNewTax - $oldTax;

                $address->setTaxAmount($totalNewTax)
                        ->setBaseTaxAmount($totalNewTax)
                        ->setGrandTotal((float) $address->getGrandTotal() + $delta)
                        ->setBaseGrandTotal((float) $address->getBaseGrandTotal() + $delta);
            }

            // Roll address totals up to the quote.
            $grand = 0.0;
            $baseGrand = 0.0;
            $taxSum = 0.0;
            foreach ($quote->getAllAddresses() as $address) {
                $grand     += (float) $address->getGrandTotal();
                $baseGrand += (float) $address->getBaseGrandTotal();
                $taxSum    += (float) $address->getTaxAmount();
            }
            $quote->setGrandTotal($grand)
                  ->setBaseGrandTotal($baseGrand);
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }
}
