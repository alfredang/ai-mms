<?php
/**
 * Render-time SEO <title> composer.
 *
 * Guarantees:
 *   1. Every storefront page <title> ends with the site's brand postfix,
 *      "| Tertiary Courses <Country>", read from general/store_information/name
 *      (SG = Singapore, MY = Malaysia, GH = Ghana — each partner DB carries its
 *      own brand, so one shared code path yields the right postfix per site).
 *   2. Course product pages carry the correct funding PREFIX:
 *        - Malaysia site  -> fixed templates instead, see _malaysiaTitle()
 *        - Singapore site -> IBF-badged course       -> "IBF funded"
 *                            (IBF wins over WSQ — every IBF course is also TGS-)
 *        - Singapore site -> WSQ course (SKU TGS-)   -> "WSQ funded"
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
            // Malaysia: fixed per-page-type templates (SEO audit, Batch 2).
            $myTitle = $this->_malaysiaTitle();
            if ($myTitle !== null) {
                return htmlspecialchars($myTitle, ENT_QUOTES, 'UTF-8');
            }
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
     * Malaysia site titles, built from the product / category NAME (stored meta_titles on MY
     * were copied from SG and carry SG branding):
     *   Course:   "<Course> Training Malaysia | HRD Corp Claimable"
     *   Category: "<Topic> Training Courses Malaysia | Tertiary Courses"
     * Other pages keep their own title; one already ending "| Tertiary Courses" (homepage) gets
     * no second brand. null = not the Malaysia site, use the standard composer.
     *
     * @return string|null
     */
    protected function _malaysiaTitle()
    {
        if (Mage::app()->getStore()->getCode() !== 'malaysia') {
            return null;
        }
        $product = Mage::registry('current_product');
        if ($product && $product->getId()) {
            $name = trim((string) $product->getName());
            return (preg_match('/\bTraining$/i', $name) ? $name : $name . ' Training') . ' Malaysia | HRD Corp Claimable';
        }
        $category = Mage::registry('current_category');
        if ($category && $category->getId()) {
            $topic = preg_replace('/\s+(?:Training\s+)?(?:Courses?|Training)$/i', '', trim((string) $category->getName()));
            return $topic . ' Training Courses Malaysia | Tertiary Courses';
        }
        $title = trim(html_entity_decode(parent::getTitle(), ENT_QUOTES, 'UTF-8'));
        return preg_match('/\|\s*Tertiary Courses$/i', $title) ? $title : null;
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
        return $prefix . ' ' . ltrim($title);
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

        // Singapore: IBF wins over WSQ (every IBF course is also a TGS- WSQ SKU).
        if (stripos($brand, 'Singapore') !== false) {
            $badges = Mage::helper('mmd_courseimage')->getProductBadges($product);
            if (in_array('IBF', $badges, true)) {
                return 'IBF funded';
            }
            if (stripos((string) $product->getSku(), 'TGS-') === 0) {
                return 'WSQ funded';
            }
        }

        return '';
    }
}
