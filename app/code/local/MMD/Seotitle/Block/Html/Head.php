<?php
/**
 * Render-time SEO <title> composer.
 *
 * Guarantees:
 *   1. Every storefront page <title> ends with the site's brand postfix,
 *      "| Tertiary Courses <Country>", read from general/store_information/name
 *      (SG = Singapore, MY = Malaysia, GH = Ghana — each partner DB carries its
 *      own brand, so one shared code path yields the right postfix per site).
 *   2. Course product pages carry the correct funding PREFIX (always first word "Funded",
 *      then the "up to 70%" subsidy cap so it survives SERP truncation):
 *        - Malaysia site  -> every course            -> "HRD Corp Claimable"
 *        - Singapore site -> IBF-badged course       -> "Funded up to 70% IBF"
 *                            (IBF wins over WSQ — every IBF course is also TGS-)
 *        - Singapore site -> CASL-badged course      -> "Funded up to 70% CASL"
 *        - Singapore site -> other TGS- course       -> "Funded up to 70% WSQ"
 *        - Ghana / SG non-WSQ                         -> no prefix
 *   Course AND category pages on every site therefore read
 *   "[prefix] <stored meta_title> | Tertiary Courses <Country>"; meta_title is stored BARE.
 *
 * Applied at render time (NOT baked into meta_title) so the transform is
 * idempotent — titles that already end with the brand, or already start with
 * the funding prefix, are left untouched (no double suffix on the ~865 SG
 * products whose meta_title already carries it). Only the <title> / og:title
 * are affected; product name, H1 and JSON-LD (which echo getName()) are never
 * touched — see memory feedback_product_name_is_sacred.
 *
 * Admin pages defer to stock behaviour.
 */
class MMD_Seotitle_Block_Html_Head extends Mage_Page_Block_Html_Head
{
    /**
     * @return string HTML-encoded title, as the parent contract requires.
     */
    public function getTitle()
    {
        $title = parent::getTitle();

        // Storefront only — never rewrite admin page titles.
        if (Mage::app()->getStore()->isAdmin()) {
            return $title;
        }

        try {
            // Transform in the decoded space, then re-encode like the parent.
            $decoded = trim(html_entity_decode($title, ENT_QUOTES, 'UTF-8'));
            $decoded = $this->_applyFundingPrefix($decoded);
            $decoded = $this->_applyBrandSuffix($decoded);
            return htmlspecialchars($decoded, ENT_QUOTES, 'UTF-8');
        } catch (Exception $e) {
            Mage::logException($e);
            return $title;
        }
    }

    /**
     * Append "| <brand>" unless the title already ends with the brand.
     */
    protected function _applyBrandSuffix($title)
    {
        $brand = trim((string) Mage::getStoreConfig('general/store_information/name'));
        if ($brand === '') {
            return $title;
        }
        // Idempotent: already ends with the brand (any trailing whitespace).
        if (preg_match('/' . preg_quote($brand, '/') . '\s*$/ui', $title)) {
            return $title;
        }
        // Drop a stale baked brand ("| Tertiary Courses", "| Tertiary Courses Singapore" on a
        // partner page) so only this site's own postfix remains.
        $title = preg_replace('/\s*[|\x{2013}\-]\s*Tertiary Courses(?:\s+[A-Za-z]+)?\s*$/ui', '', $title);
        // Drop any trailing separator/whitespace (incl. NBSP / U+202F from MS
        // paste — see memory feedback_short_description_unicode_whitespace)
        // before appending our own.
        $title = preg_replace('/[\s\x{00a0}\x{202f}|\x{2013}\-]+$/u', '', $title);
        return $title . ' | ' . $brand;
    }

    /**
     * Prepend the funding prefix on course product pages, idempotently.
     */
    protected function _applyFundingPrefix($title)
    {
        $prefix = $this->_fundingPrefix();
        if ($prefix === '') {
            return $title;
        }
        if (stripos($title, $prefix) === 0) {
            return $title;
        }
        // Drop a scheme word baked into the stored meta_title ("WSQ ...", "IBF-STS ...",
        // "WSQ funded ...", "Funded up to 70% WSQ ...") so the prefix never double-prints.
        $title = preg_replace('/^(?:funded\s+)?(?:up\s+to\s+70%\s+)?(?:WSQ|CASL|IBF(?:-STS)?)(?:\s+funded)?(?:\s*[-:]\s*|\s+)/i', '', ltrim($title));
        return $prefix . ' ' . $title;
    }

    /**
     * Funding prefix for the current course product page, keyed off this
     * site's brand + the product's WSQ/IBF signals. '' when not a course
     * product page or no funding applies for this site.
     *
     * @return string
     */
    protected function _fundingPrefix()
    {
        $product = Mage::registry('current_product');
        if (!$product || !$product->getId()) {
            return '';
        }

        $brand = (string) Mage::getStoreConfig('general/store_information/name');

        // Malaysia: every course is HRD Corp claimable.
        if (stripos($brand, 'Malaysia') !== false) {
            return 'HRD Corp Claimable';
        }

        // Singapore: funded titles always START with "Funded". IBF wins over WSQ (every IBF
        // course is also a TGS- WSQ SKU); CASL courses are TGS- but not WSQ-badged.
        if (stripos($brand, 'Singapore') !== false) {
            $badges = Mage::helper('mmd_courseimage')->getProductBadges($product);
            if (in_array('IBF', $badges, true)) {
                return 'Funded up to 70% IBF';
            }
            if (in_array('CASL', $badges, true)) {
                return 'Funded up to 70% CASL';
            }
            if (stripos((string) $product->getSku(), 'TGS-') === 0) {
                return 'Funded up to 70% WSQ';
            }
        }

        return '';
    }
}
