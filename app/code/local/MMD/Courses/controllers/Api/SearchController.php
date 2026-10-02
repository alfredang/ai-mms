<?php
/**
 * Public read-only API: course search by keyword.
 *
 * GET /courses/api_search?q=<keyword>&limit=<n>
 *   Header:  X-API-Key: <shared secret>
 *   Returns: JSON list of SG storefront courses matching the keyword in
 *            name OR sku. Used by the WhatsApp customer-reply bot to
 *            answer "do you have a Python course?" style questions.
 *
 * Auth: X-API-Key header compared against System Config
 *       courses/general/wsq_schedule_api_key (admin scope). Mismatch → 401.
 *       Blank stored key disables the endpoint (503).
 *
 * Scope: SG store (store_id=1). Bot is SG-only per Alisha's spec.
 *
 * Envelope: every response wraps the data in { source_url, last_updated,
 *           confidence, data } so the bot can decide whether to surface
 *           the answer or escalate to a human.
 */
class MMD_Courses_Api_SearchController extends Mage_Core_Controller_Front_Action
{
    const SG_STORE_ID         = 1;
    const CONFIG_PATH_API_KEY = 'courses/general/wsq_schedule_api_key';
    const DEFAULT_LIMIT       = 10;
    const MAX_LIMIT           = 50;

    public function indexAction()
    {
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        if ($expected === '') {
            return $this->_json(503, $this->_errEnvelope('api_disabled', 'API key not configured on server.'));
        }
        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, $this->_errEnvelope('unauthorized', 'Invalid or missing X-API-Key header.'));
        }

        $q     = trim((string) $this->getRequest()->getParam('q', ''));
        $limit = (int) $this->getRequest()->getParam('limit', self::DEFAULT_LIMIT);
        if ($limit < 1)              { $limit = self::DEFAULT_LIMIT; }
        if ($limit > self::MAX_LIMIT){ $limit = self::MAX_LIMIT; }

        if ($q === '') {
            return $this->_json(400, $this->_errEnvelope('missing_query',
                'Pass ?q=<keyword> with at least 1 character.'));
        }

        try {
            $results = $this->_searchCourses($q, $limit);
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, $this->_errEnvelope('internal_error', $e->getMessage()));
        }

        $confidence = count($results) === 0 ? 'low' : 'high';
        return $this->_json(200, $this->_okEnvelope(
            'https://www.tertiarycourses.com.sg/catalogsearch/result/?q=' . rawurlencode($q),
            $confidence,
            array(
                'query'   => $q,
                'limit'   => $limit,
                'count'   => count($results),
                'results' => $results,
            )
        ));
    }

    /**
     * Search SG enabled, visible products by name OR sku LIKE %q%.
     * Returns lightweight cards (sku, name, url, image, price, funding badges)
     * suitable for the bot to list to the customer.
     */
    private function _searchCourses($q, $limit)
    {
        $badgeHelper = $this->_safeBadgeHelper();

        $collection = Mage::getModel('catalog/product')->getCollection()
            ->setStoreId(self::SG_STORE_ID)
            ->addStoreFilter(self::SG_STORE_ID)
            ->addAttributeToSelect(array('name', 'sku', 'price', 'small_image', 'course_image_url', 'url_key', 'short_description'))
            ->addAttributeToFilter('status', Mage_Catalog_Model_Product_Status::STATUS_ENABLED)
            ->addAttributeToFilter('visibility', array('neq' => Mage_Catalog_Model_Product_Visibility::VISIBILITY_NOT_VISIBLE))
            ->addAttributeToFilter(array(
                array('attribute' => 'name', 'like' => '%' . $q . '%'),
                array('attribute' => 'sku',  'like' => '%' . $q . '%'),
            ))
            ->setPageSize($limit)
            ->setCurPage(1);

        $out = array();
        foreach ($collection as $product) {
            $product->setStoreId(self::SG_STORE_ID);
            $out[] = array(
                'sku'              => (string) $product->getSku(),
                'name'             => (string) $product->getName(),
                'url'              => $this->_productUrl($product),
                'image_url'        => $this->_productImageUrl($product),
                'price'            => $this->_formatPrice($product->getPrice()),
                'short_description'=> $this->_stripTags((string) $product->getShortDescription(), 200),
                'funding_badges'   => $badgeHelper ? $badgeHelper->getProductBadges($product) : array(),
            );
        }
        return $out;
    }

    private function _safeBadgeHelper()
    {
        try {
            return Mage::helper('mmd_courseimage');
        } catch (Exception $e) {
            return null;
        }
    }

    private function _productUrl($product)
    {
        try {
            return (string) $product->getProductUrl(false);
        } catch (Exception $e) {
            $urlKey = $product->getUrlKey();
            return $urlKey
                ? 'https://www.tertiarycourses.com.sg/' . $urlKey . '.html'
                : '';
        }
    }

    private function _productImageUrl($product)
    {
        // Course covers are the storefront's authoritative product images.
        $cover = trim((string) $product->getData('course_image_url'));
        if ($cover !== '' && preg_match('#^https?://#i', $cover)) {
            return $cover;
        }
        $img = (string) $product->getSmallImage();
        if ($img === '' || $img === 'no_selection') {
            return '';
        }
        try {
            return (string) Mage::helper('catalog/image')->init($product, 'small_image')->resize(400);
        } catch (Exception $e) {
            return '';
        }
    }

    private function _formatPrice($v)
    {
        $v = (float) $v;
        return $v > 0 ? 'S$' . number_format($v, 2) : 'Contact for price';
    }

    private function _stripTags($s, $maxLen = 200)
    {
        $s = trim(strip_tags($s));
        if (strlen($s) > $maxLen) {
            $s = substr($s, 0, $maxLen - 1) . '…';
        }
        return $s;
    }

    private function _okEnvelope($sourceUrl, $confidence, $data)
    {
        return array(
            'source_url'   => $sourceUrl,
            'last_updated' => gmdate('c'),
            'confidence'   => $confidence,
            'data'         => $data,
        );
    }

    private function _errEnvelope($code, $message)
    {
        return array(
            'source_url'   => null,
            'last_updated' => gmdate('c'),
            'confidence'   => 'error',
            'error'        => $code,
            'message'      => $message,
        );
    }

    private function _json($status, array $body)
    {
        $this->getResponse()
            ->setHttpResponseCode($status)
            ->setHeader('Content-Type', 'application/json; charset=utf-8', true)
            ->setHeader('Cache-Control', 'public, max-age=120', true)
            ->setBody(json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        return $this;
    }
}
