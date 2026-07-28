<?php
/**
 * Public read-only API: course details by SKU.
 *
 * GET /courses/api_courses?sku=<sku>
 *   Header:  X-API-Key: <shared secret>
 *   Returns: full details for one SG course — overview, suitability,
 *            prerequisites, duration, level, assessment, certification,
 *            fee/funding, venue/mode, course code, course page URL,
 *            registration URL. Used by the WhatsApp bot to answer
 *            "tell me about course X" style questions.
 *
 * Auth: X-API-Key header compared against
 *       courses/general/wsq_schedule_api_key. Mismatch → 401.
 *       Blank stored key disables the endpoint (503).
 *
 * Scope: SG store (store_id=1) — bot is SG-only.
 *
 * Pragmatism note: courses in this catalog have inconsistent attribute
 * coverage (some have a structured `duration` attribute, others bury
 * the same info in description text). This controller returns whatever
 * is available and uses the long `description` as a fallback so the bot
 * never sees a hard NULL on the overview field.
 */
class MMD_Courses_Api_CoursesController extends Mage_Core_Controller_Front_Action
{
    const SG_STORE_ID         = 1;
    const CONFIG_PATH_API_KEY = 'courses/general/wsq_schedule_api_key';

    public function indexAction()
    {
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        if ($expected === '') {
            return $this->_json(503, $this->_errEnvelope('api_disabled', 'API key not configured.'));
        }
        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, $this->_errEnvelope('unauthorized', 'Invalid or missing X-API-Key.'));
        }

        $sku = trim((string) $this->getRequest()->getParam('sku', ''));
        if ($sku === '') {
            return $this->_json(400, $this->_errEnvelope('missing_sku',
                'Pass ?sku=<course_code> (e.g. ?sku=C814 or ?sku=TGS-2024010234).'));
        }

        // Resolve the SKU directly (getIdBySku bypasses the flat catalog, which
        // omits disabled products) so we can tell a genuinely-missing course apart
        // from a disabled one and return an accurate, distinct signal for each.
        $id = Mage::getModel('catalog/product')->getIdBySku($sku);
        if (!$id) {
            return $this->_json(404, $this->_errEnvelope('not_found',
                'No course with sku=' . $sku . ' exists in the SG catalog.'));
        }

        try {
            // Load against the SG store view so storefront-scoped attributes
            // (description, name, url_key) resolve correctly.
            $product = Mage::getModel('catalog/product')->setStoreId(self::SG_STORE_ID)->load($id);
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, $this->_errEnvelope('internal_error', $e->getMessage()));
        }

        // Never surface a disabled/deactivated course. Distinct error code
        // (course_unavailable, not not_found) so the bot can exclude it from
        // recommendations and answers without parsing the message text.
        if ((int) $product->getStatus() === Mage_Catalog_Model_Product_Status::STATUS_DISABLED) {
            return $this->_json(404, $this->_errEnvelope('course_unavailable',
                'Course ' . $sku . ' is not currently available.'));
        }

        try {
            $data = $this->_buildCourseData($product);
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, $this->_errEnvelope('internal_error', $e->getMessage()));
        }

        return $this->_json(200, $this->_okEnvelope(
            $data['course_page_url'] ?: 'https://www.tertiarycourses.com.sg/',
            'high',
            $data
        ));
    }

    private function _buildCourseData($product)
    {
        $url = $this->_productUrl($product);

        $overview = $this->_stripTags((string) $product->getShortDescription(), 800);
        if ($overview === '') {
            $overview = $this->_stripTags((string) $product->getDescription(), 800);
        }

        return array(
            'sku'              => (string) $product->getSku(),
            'course_code'      => (string) $product->getSku(),
            'name'             => (string) $product->getName(),
            'overview'         => $overview,
            'description_full' => $this->_stripTags((string) $product->getDescription(), 4000),
            'suitability'      => $this->_stripTags($this->_attr($product, 'who_should_attend', ''), 1000),
            'prerequisites'    => $this->_stripTags($this->_attr($product, 'prerequisites', $this->_attr($product, 'prerequisite', '')), 1500),
            'duration'         => $this->_stripTags($this->_attr($product, 'duration', $this->_attr($product, 'course_duration', '')), 200),
            'level'            => $this->_stripTags($this->_attr($product, 'level', ''), 200),
            'assessment'       => $this->_stripTags($this->_attr($product, 'assessment', ''), 800),
            'certification'    => $this->_stripTags($this->_attr($product, 'certification', 'Tertiary Infotech Certificate of Completion'), 400),
            'fee'              => array(
                'list_price'   => $this->_formatPrice($product->getPrice()),
                'list_price_raw' => (float) $product->getPrice(),
                'currency'     => 'SGD',
                'note'         => 'Subsidised rates may apply for funded courses — see funding_badges for eligible schemes.',
            ),
            'venue'            => 'Tertiary Infotech HQ — see course_page_url for the latest venue map.',
            'mode'             => $this->_attr($product, 'training_mode', 'Classroom and/or Live Online'),
            'funding_badges'   => $this->_badges($product),
            'image_url'        => $this->_productImageUrl($product),
            'course_page_url'  => $url,
            'registration_url' => $url . '#schedule',
        );
    }

    private function _attr($product, $code, $default = '')
    {
        $val = $product->getData($code);
        if ($val === null || $val === '') {
            return $default;
        }
        // EAV may return an option ID for select attributes — try to resolve
        // to its label so the bot doesn't see "42" as the level.
        try {
            $attr = $product->getResource()->getAttribute($code);
            if ($attr && $attr->usesSource()) {
                $label = $attr->getSource()->getOptionText($val);
                if ($label !== false && $label !== null && $label !== '') {
                    return is_array($label) ? implode(', ', $label) : (string) $label;
                }
            }
        } catch (Exception $e) {
            // fall through — return raw value
        }
        return is_scalar($val) ? (string) $val : (is_array($val) ? implode(', ', $val) : $default);
    }

    private function _badges($product)
    {
        try {
            return Mage::helper('mmd_courseimage')->getProductBadges($product);
        } catch (Exception $e) {
            return array();
        }
    }

    private function _productUrl($product)
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

    private function _productImageUrl($product)
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

    private function _formatPrice($v)
    {
        $v = (float) $v;
        return $v > 0 ? 'S$' . number_format($v, 2) : 'Contact for price';
    }

    private function _stripTags($s, $maxLen = 800)
    {
        $s = trim(strip_tags($s));
        $s = preg_replace('/\s+/u', ' ', $s);
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
            ->setHeader('Cache-Control', 'public, max-age=300', true)
            ->setBody(json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        return $this;
    }
}
