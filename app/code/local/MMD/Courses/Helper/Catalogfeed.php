<?php
/**
 * Shared catalog-feed logic for the read-only course list APIs.
 *
 * Two thin controllers sit on top of this helper and deliberately stay separate,
 * so WSQ and non-WSQ are never mixed in one response:
 *
 *   GET /courses/api_wsq     → MMD_Courses_Api_WsqController     (TGS- SKUs)
 *   GET /courses/api_nonwsq  → MMD_Courses_Api_NonwsqController  (C- SKUs)
 *
 * Both share the auth, row builder and JSON envelope defined here, so the two
 * feeds can never drift in shape.
 *
 * Auth: X-API-Key compared against courses/general/wsq_schedule_api_key — the
 * same shared external key the other read endpoints already use.
 *
 * Scope: SG store (store_id = 1).
 */
class MMD_Courses_Helper_Catalogfeed extends Mage_Core_Helper_Abstract
{
    const SG_STORE_ID         = 1;
    const CONFIG_PATH_API_KEY = 'courses/general/wsq_schedule_api_key';
    /** WSQ course codes are TGS-prefixed; non-WSQ course codes are C-prefixed. */
    const WSQ_SKU_PREFIX    = 'TGS-';
    const NONWSQ_SKU_REGEX  = '/^C/i';

    /**
     * Verify the caller's API key.
     *
     * @return array|null  null when authorised, else array($httpStatus, $errorBody)
     */
    public function authError($providedKey)
    {
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        if ($expected === '') {
            return array(503, $this->errEnvelope('api_disabled', 'API key not configured.'));
        }
        if (!hash_equals($expected, (string) $providedKey)) {
            return array(401, $this->errEnvelope('unauthorized', 'Invalid or missing X-API-Key.'));
        }
        return null;
    }

    public function isWsqSku($sku)
    {
        return stripos((string) $sku, self::WSQ_SKU_PREFIX) === 0;
    }

    public function isNonWsqSku($sku)
    {
        return (bool) preg_match(self::NONWSQ_SKU_REGEX, (string) $sku);
    }

    /**
     * Does this SKU belong in the requested track?
     * Anything that is neither TGS- nor C- (staging junk, test rows) is in
     * NEITHER feed — matching on the explicit prefix keeps stray SKUs out.
     */
    public function skuInTrack($sku, $wsq)
    {
        return $wsq ? $this->isWsqSku($sku) : $this->isNonWsqSku($sku);
    }

    /**
     * Build the catalog feed for one funding track.
     *
     * @param bool $wsq   true → TGS- (WSQ) courses; false → C- (non-WSQ) courses
     * @param bool $full  true → the rich per-course payload; false → compact rows
     * @return array      the response body
     *
     * Products are loaded one at a time rather than as a hydrated collection:
     * storefront-scoped attributes (description, url_key, price) only resolve on a
     * store-loaded model, and hydrating ~560 of them at once would blow PHP's
     * memory limit. Each model is discarded as soon as its row is built.
     */
    public function buildFeed($wsq, $full = false)
    {
        $ids = Mage::getModel('catalog/product')->getCollection()
            ->setStoreId(self::SG_STORE_ID)
            ->addStoreFilter(self::SG_STORE_ID)
            ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED)
            ->addAttributeToFilter('visibility', array(
                'neq' => Mage_Catalog_Model_Product_Visibility::VISIBILITY_NOT_VISIBLE,
            ))
            ->getAllIds();

        $rows = array();
        foreach ($ids as $id) {
            try {
                $product = Mage::getModel('catalog/product')
                    ->setStoreId(self::SG_STORE_ID)->load($id);
                if (!$product->getId()) {
                    continue;
                }

                // The whole point of the split: each feed carries one track only.
                if (!$this->skuInTrack($product->getSku(), $wsq)) {
                    continue;
                }

                $rows[] = $full
                    ? $this->buildFullRow($product)
                    : $this->buildSummaryRow($product);

                unset($product);
            } catch (Exception $e) {
                // A single malformed product must never sink the whole feed.
                Mage::logException($e);
            }
        }

        usort($rows, array($this, 'compareBySku'));

        // Names and other raw attributes bypass stripText(), so scrub the whole
        // payload once more — a single bad byte would otherwise empty the response.
        $rows = $this->sanitizeUtf8($rows);

        return array(
            'source_url'   => 'https://www.tertiarycourses.com.sg/',
            'last_updated' => gmdate('c'),
            'confidence'   => 'high',
            'store'        => 'singapore',
            'track'        => $wsq ? 'wsq' : 'non-wsq',
            'count'        => count($rows),
            'data'         => $rows,
        );
    }

    /** Compact catalog row — enough to render a course list. */
    public function buildSummaryRow($product)
    {
        $url      = $this->productUrl($product);
        $overview = $this->stripText((string) $product->getShortDescription(), 400);
        if ($overview === '') {
            $overview = $this->stripText((string) $product->getDescription(), 400);
        }

        return array(
            'sku'              => (string) $product->getSku(),
            'course_code'      => (string) $product->getSku(),
            'name'             => (string) $product->getName(),
            'is_wsq'           => $this->isWsqSku($product->getSku()),
            'overview'         => $overview,
            'duration'         => $this->stripText($this->attr($product, 'duration', $this->attr($product, 'course_duration', '')), 200),
            'level'            => $this->stripText($this->attr($product, 'level', ''), 200),
            'mode'             => $this->attr($product, 'training_mode', 'Classroom and/or Live Online'),
            'fee'              => array(
                'list_price'     => $this->formatPrice($product->getPrice()),
                'list_price_raw' => (float) $product->getPrice(),
                'currency'       => 'SGD',
            ),
            'funding_badges'   => $this->badges($product),
            'categories'       => $this->categoryNames($product),
            'image_url'        => $this->productImageUrl($product),
            'course_page_url'  => $url,
            'registration_url' => $url . '#schedule',
        );
    }

    /** Rich row — mirrors the single-SKU payload of /courses/api_courses. */
    public function buildFullRow($product)
    {
        $row = $this->buildSummaryRow($product);
        $row['overview']         = $this->stripText((string) $product->getShortDescription(), 800);
        if ($row['overview'] === '') {
            $row['overview']     = $this->stripText((string) $product->getDescription(), 800);
        }
        $row['description_full'] = $this->stripText((string) $product->getDescription(), 4000);
        $row['suitability']      = $this->stripText($this->attr($product, 'who_should_attend', ''), 1000);
        $row['prerequisites']    = $this->stripText($this->attr($product, 'prerequisites', $this->attr($product, 'prerequisite', '')), 1500);
        $row['assessment']       = $this->stripText($this->attr($product, 'assessment', ''), 800);
        $row['certification']    = $this->stripText($this->attr($product, 'certification', 'Tertiary Infotech Certificate of Completion'), 400);
        $row['venue']            = 'Tertiary Infotech HQ — see course_page_url for the latest venue map.';
        $row['fee']['note']      = 'Subsidised rates may apply for funded courses — see funding_badges for eligible schemes.';
        return $row;
    }

    /** Category names the product belongs to, for grouping in the consumer UI. */
    public function categoryNames($product)
    {
        $names = array();
        try {
            foreach ($product->getCategoryIds() as $catId) {
                $name = (string) Mage::getModel('catalog/category')
                    ->setStoreId(self::SG_STORE_ID)->load($catId)->getName();
                if ($name !== '' && !in_array($name, $names, true)) {
                    $names[] = $name;
                }
            }
        } catch (Exception $e) {
            // Categories are a nicety — never fail a row over them.
        }
        return $names;
    }

    public function attr($product, $code, $default = '')
    {
        $val = $product->getData($code);
        if ($val === null || $val === '') {
            return $default;
        }
        // EAV may hand back an option ID for select attributes — resolve the label.
        try {
            $attr = $product->getResource()->getAttribute($code);
            if ($attr && $attr->usesSource()) {
                $label = $attr->getSource()->getOptionText($val);
                if ($label !== false && $label !== null && $label !== '') {
                    return is_array($label) ? implode(', ', $label) : (string) $label;
                }
            }
        } catch (Exception $e) {
            // fall through — return the raw value
        }
        return is_scalar($val) ? (string) $val : (is_array($val) ? implode(', ', $val) : $default);
    }

    public function badges($product)
    {
        try {
            return Mage::helper('mmd_courseimage')->getProductBadges($product);
        } catch (Exception $e) {
            return array();
        }
    }

    public function productUrl($product)
    {
        try {
            $url = (string) $product->getProductUrl(false);
            if ($url !== '') {
                return $url;
            }
        } catch (Exception $e) {
            // fall through
        }
        $urlKey = $product->getUrlKey();
        return $urlKey
            ? 'https://www.tertiarycourses.com.sg/' . $urlKey . '.html'
            : 'https://www.tertiarycourses.com.sg/';
    }

    public function productImageUrl($product)
    {
        $img = (string) $product->getSmallImage();
        if ($img === '' || $img === 'no_selection') {
            return '';
        }
        try {
            return (string) Mage::helper('catalog/image')->init($product, 'small_image')->resize(600);
        } catch (Exception $e) {
            return '';
        }
    }

    public function formatPrice($v)
    {
        $v = (float) $v;
        return $v > 0 ? 'S$' . number_format($v, 2) : 'Contact for price';
    }

    /**
     * Plain-text a description and cap its length.
     *
     * Some catalog rows contain byte sequences that are not valid UTF-8 (legacy
     * copy-paste from Word, mostly). One such row is enough to make json_encode()
     * return false for the WHOLE feed and emit an empty body, so every string is
     * scrubbed here rather than trusted. Truncation is multibyte-aware for the
     * same reason: cutting mid-character would itself create invalid UTF-8.
     */
    public function stripText($s, $maxLen = 800)
    {
        $s = (string) $s;

        // Drop invalid byte sequences (substituting, so valid text is preserved).
        if (!mb_check_encoding($s, 'UTF-8')) {
            $prev = ini_set('mbstring.substitute_character', 'none');
            $s = mb_convert_encoding($s, 'UTF-8', 'UTF-8');
            if ($prev !== false) {
                ini_set('mbstring.substitute_character', $prev);
            }
        }

        $s = trim(strip_tags($s));
        $s = preg_replace('/\s+/u', ' ', $s);
        if ($s === null) {
            return '';
        }
        if (mb_strlen($s, 'UTF-8') > $maxLen) {
            $s = mb_substr($s, 0, $maxLen - 1, 'UTF-8') . '…';
        }
        return $s;
    }

    /** Recursively scrub any remaining invalid UTF-8 so json_encode cannot fail. */
    public function sanitizeUtf8($value)
    {
        if (is_string($value)) {
            if (mb_check_encoding($value, 'UTF-8')) {
                return $value;
            }
            $prev = ini_set('mbstring.substitute_character', 'none');
            $clean = mb_convert_encoding($value, 'UTF-8', 'UTF-8');
            if ($prev !== false) {
                ini_set('mbstring.substitute_character', $prev);
            }
            return $clean;
        }
        if (is_array($value)) {
            foreach ($value as $k => $v) {
                $value[$k] = $this->sanitizeUtf8($v);
            }
        }
        return $value;
    }

    public function compareBySku($a, $b)
    {
        return strcmp((string) $a['sku'], (string) $b['sku']);
    }

    public function okEnvelope($sourceUrl, $confidence, $data)
    {
        return array(
            'source_url'   => $sourceUrl,
            'last_updated' => gmdate('c'),
            'confidence'   => $confidence,
            'data'         => $data,
        );
    }

    public function errEnvelope($code, $message)
    {
        return array(
            'source_url'   => null,
            'last_updated' => gmdate('c'),
            'confidence'   => 'error',
            'error'        => $code,
            'message'      => $message,
        );
    }
}
