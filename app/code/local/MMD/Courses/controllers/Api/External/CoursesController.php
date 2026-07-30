<?php
/**
 * Public read-only API: local course catalog feed for external automations
 * (e.g. the country instance's own n8n email-reply workflows).
 *
 * GET /courses/api_external_courses
 *   Header: X-API-Key: <mmd/external_api/api_key>
 *
 * Query params (all optional):
 *   page         0-based page index (default 0)
 *   limit        page size (default 500, max 1000)
 *   course_code  exact SKU match
 *   search       LIKE match on name or SKU
 *   fields       comma-separated subset of the output field allow-list below
 *                (omit for the full row)
 *
 * Mirrors the shape of lms-tms's GET /api/external/courses so existing n8n
 * "Map Course Fields" nodes need minimal changes when repointed at a country
 * instance instead of lms-tms: { success, pagination, data: [...] }.
 *
 * Scope: THIS instance's own catalog only (C-prefix courses synced in via
 * MMD_RoleManager_Model_CourseSyncService — see mmd/course_sync/*). No call
 * to any other system happens on the request path; this is intentionally
 * decoupled from SG at runtime. Price/trainer info reflect this country's
 * own partner-owned values (see CourseSyncService P1 rule), already in the
 * store's own base currency — no conversion needed here.
 *
 * Only status=Enabled products are returned — a disabled course's product
 * page 404s, so serving it here would hand callers (e.g. n8n auto-reply) a
 * broken course_link.
 *
 * Auth: X-API-Key header compared against mmd/external_api/api_key
 * (own config path — distinct from mmd/course_sync/api_key, which
 * authenticates the opposite direction: this instance calling out to SG).
 * Blank stored key disables the endpoint (503).
 */
class MMD_Courses_Api_External_CoursesController extends Mage_Core_Controller_Front_Action
{
    const CONFIG_PATH_API_KEY = 'mmd/external_api/api_key';
    const DEFAULT_LIMIT       = 500;
    const MAX_LIMIT           = 1000;
    const STORE_ID            = 0; // admin/default scope — same as CourseSyncService writes

    /** Canonical funding/eligibility badge vocabulary (shared with ExportController). */
    const CANONICAL_BADGES = array(
        'WSQ', 'SkillsFuture Credit', 'PSEA', 'UTAP', 'IBF',
        'HRDF', 'SFEC', 'Absentee Payroll', 'MCES',
    );

    /** Output field name -> product attribute code (or synthetic). */
    private static $_fieldMap = array(
        'course_id'     => null, // synthetic: entity_id
        'title'         => 'name',
        'course_code'   => null, // synthetic: sku
        'description'   => 'description',
        'short_description' => 'short_description',
        'course_outline'    => 'sessions',
        'prerequisites' => 'prerequisite',
        'suitability'   => 'whoshouldattend',
        'duration'      => 'duration',
        'level'         => 'level',
        'venue'         => 'venue',
        'trainer_info'  => 'trainerprofile',
        'course_fee'    => 'price',
        'special_price' => 'special_price',
        'course_link'   => null, // synthetic: product URL
        'brochure_link' => 'course_brochure_html',
        'image_url'     => null, // synthetic: small_image resize
        'badges'        => null, // synthetic: tag lookup
        'currency'      => null, // synthetic: store base currency
    );

    public function indexAction()
    {
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        if ($expected === '') {
            return $this->_json(503, array('success' => false, 'error' => 'API key not configured (mmd/external_api/api_key).'));
        }
        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, array('success' => false, 'error' => 'Invalid or missing X-API-Key.'));
        }

        try {
            $page  = max(0, (int) $this->getRequest()->getParam('page', 0));
            $limit = min(self::MAX_LIMIT, max(1, (int) $this->getRequest()->getParam('limit', self::DEFAULT_LIMIT)));
            $offset = $page * $limit;

            $courseCode = trim((string) $this->getRequest()->getParam('course_code', ''));
            $search     = trim((string) $this->getRequest()->getParam('search', ''));

            $requestedFields = trim((string) $this->getRequest()->getParam('fields', ''));
            $picked = array();
            if ($requestedFields !== '') {
                foreach (explode(',', $requestedFields) as $f) {
                    $f = trim($f);
                    if ($f !== '' && array_key_exists($f, self::$_fieldMap)) {
                        $picked[] = $f;
                    }
                }
            }
            $outputFields = !empty($picked) ? $picked : array_keys(self::$_fieldMap);

            $read = Mage::getSingleton('core/resource')->getConnection('core_read');

            // Only ever serve enabled products — a disabled course still has a
            // catalog row (and a SKU matching 'C%'), but its product page 404s,
            // so course_link in the auto-reply would point at a broken page.
            $statusAttrId = (int) $read->fetchOne(
                "SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status' LIMIT 1"
            );
            $enabledClause = "entity_id IN (
                SELECT entity_id FROM catalog_product_entity_int
                WHERE attribute_id = ? AND store_id = 0 AND value = ?
            )";
            $enabledParams = array($statusAttrId, Mage_Catalog_Model_Product_Status::STATUS_ENABLED);

            $where  = "sku LIKE 'C%' AND $enabledClause";
            $params = $enabledParams;
            if ($courseCode !== '') {
                $where .= ' AND sku = ?';
                $params[] = $courseCode;
            } elseif ($search !== '') {
                // name lives in EAV varchar table; resolve via a join for the
                // search case, exact-code case stays a cheap indexed lookup.
                $nameAttrId = (int) $read->fetchOne(
                    "SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name' LIMIT 1"
                );
                $entityTypeVarchar = $this->_productVarcharTable();
                $where = "(sku LIKE 'C%') AND ($enabledClause) AND (sku LIKE ? OR entity_id IN (
                    SELECT entity_id FROM `$entityTypeVarchar`
                    WHERE attribute_id = ? AND store_id = 0 AND value LIKE ?
                ))";
                $params = array_merge($enabledParams, array('%' . $search . '%', $nameAttrId, '%' . $search . '%'));
            }

            $total = (int) $read->fetchOne("SELECT COUNT(*) FROM catalog_product_entity WHERE $where", $params);

            $skus = $read->fetchCol(
                "SELECT sku FROM catalog_product_entity WHERE $where ORDER BY sku ASC LIMIT $limit OFFSET $offset",
                $params
            );

            $currency = $this->_storefrontCurrency();
            $data = array();
            foreach ($skus as $sku) {
                try {
                    $data[] = $this->_buildRow($sku, $outputFields, $currency);
                } catch (Exception $e) {
                    Mage::log('ExternalCourses: skip sku=' . $sku . ' err=' . $e->getMessage(), Zend_Log::WARN, 'external-courses-api.log');
                }
            }

            return $this->_json(200, array(
                'success'    => true,
                'pagination' => array('page' => $page, 'limit' => $limit, 'total' => $total, 'returned' => count($data)),
                'data'       => $data,
            ));
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, array('success' => false, 'error' => $e->getMessage()));
        }
    }

    private function _buildRow($sku, array $outputFields, $currency)
    {
        // loadByAttribute() triggers addAttributeToSelect('*') -> loadAllAttributes(),
        // unsupported on the flat product resource this app runs under (same gotcha
        // documented in CourseSyncService::_upsertCourse). Resolve entity_id via raw
        // SQL first, matching ExportController's pattern.
        $read = Mage::getSingleton('core/resource')->getConnection('core_read');
        $entityId = (int) $read->fetchOne(
            "SELECT entity_id FROM catalog_product_entity WHERE sku = ?",
            array($sku)
        );
        if (!$entityId) {
            throw new Exception('Product not found for sku=' . $sku);
        }
        $product = Mage::getModel('catalog/product')->setStoreId(self::STORE_ID)->load($entityId);

        $row = array();
        foreach ($outputFields as $field) {
            switch ($field) {
                case 'course_id':
                    $row[$field] = (int) $product->getId();
                    break;
                case 'course_code':
                    $row[$field] = $sku;
                    break;
                case 'course_link':
                    $row[$field] = $this->_productUrl($product);
                    break;
                case 'image_url':
                    $row[$field] = $this->_productImageUrl($product);
                    break;
                case 'badges':
                    $row[$field] = $this->_badges($product);
                    break;
                case 'currency':
                    $row[$field] = $currency;
                    break;
                case 'course_fee':
                case 'special_price':
                    $val = $product->getData(self::$_fieldMap[$field]);
                    $row[$field] = $val !== null && $val !== '' ? (float) $val : null;
                    break;
                default:
                    $attrCode = self::$_fieldMap[$field];
                    $row[$field] = $attrCode ? $this->_stripTags((string) $product->getData($attrCode)) : null;
            }
        }
        return $row;
    }

    private function _productVarcharTable()
    {
        return Mage::getSingleton('core/resource')->getTableName('catalog_product_entity_varchar');
    }

    /**
     * Mage::app()->getBaseCurrencyCode() resolves at the admin/default scope (store_id=0),
     * which does not reflect a country instance's own currency override (e.g. currency
     * config is set at the country's website/store scope, not admin default — verified on
     * MY: admin default = SGD leftover, malaysia website/store = MYR). Every country
     * instance is guaranteed exactly one non-admin website by the store-topology invariant
     * enforced elsewhere in this app, so find that website's default store and read its
     * currency instead of assuming admin default is authoritative.
     */
    /** The country's own (non-admin) storefront — guaranteed to be exactly one by the
     *  store-topology invariant enforced elsewhere in this app. Shared by both the
     *  currency and URL lookups below, since both suffer the same admin-scope-fallback
     *  problem when resolved from store_id=0. */
    private function _storefrontStore()
    {
        try {
            foreach (Mage::app()->getWebsites() as $website) {
                if ((int) $website->getId() === 0) {
                    continue; // skip admin
                }
                $store = $website->getDefaultStore();
                if ($store) {
                    return $store;
                }
            }
        } catch (Exception $e) {
            // fall through to null below
        }
        return null;
    }

    private function _storefrontCurrency()
    {
        $store = $this->_storefrontStore();
        if ($store) {
            return (string) $store->getBaseCurrencyCode();
        }
        return (string) Mage::app()->getBaseCurrencyCode();
    }

    private function _productUrl($product)
    {
        try {
            $store = $this->_storefrontStore();
            if ($store) {
                // Mage_Catalog_Model_Product_Url::_getRequestPath() looks up the URL
                // rewrite using $product->getStoreId() directly — it ignores the
                // '_store' param entirely. Since products are loaded at admin scope
                // (STORE_ID = 0) for consistent attribute reads, the rewrite lookup
                // was always searching store 0 (no rewrites live there) and silently
                // falling back to the raw catalog/product/view/id/... URL, even when
                // a proper rewrite exists at the real storefront's store id. Flip the
                // product's store_id just for this lookup so it finds it.
                $originalStoreId = $product->getStoreId();
                $product->setStoreId($store->getId());
                $url = (string) $product->getUrlInStore(array('_store' => $store->getId()));
                $product->setStoreId($originalStoreId);
            } else {
                $url = (string) $product->getProductUrl(false);
            }
            if ($url !== '') {
                return $url;
            }
        } catch (Exception $e) {
            // fall through
        }
        return '';
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

    private function _badges($product)
    {
        $read = Mage::getSingleton('core/resource')->getConnection('core_read');
        $tbl  = Mage::getSingleton('core/resource');
        $tagRelTbl = $tbl->getTableName('catalog_product_tag');
        $tagTbl    = $tbl->getTableName('tag');
        try {
            $tags = $read->fetchCol(
                "SELECT t.name FROM `$tagTbl` t
                 JOIN `$tagRelTbl` pt ON pt.tag_id = t.tag_id
                 WHERE pt.product_id = ? AND t.status = 1",
                array((int) $product->getId())
            );
        } catch (Exception $e) {
            return array();
        }
        return array_values(array_intersect($tags, self::CANONICAL_BADGES));
    }

    private function _stripTags($s, $maxLen = 4000)
    {
        $s = trim(strip_tags($s));
        $s = preg_replace('/\s+/u', ' ', $s);
        if ($s !== null && strlen($s) > $maxLen) {
            $s = substr($s, 0, $maxLen - 1) . '…';
        }
        return $s;
    }

    private function _json($status, array $body)
    {
        $this->getResponse()
            ->setHttpResponseCode($status)
            ->setHeader('Content-Type', 'application/json; charset=utf-8', true)
            ->setBody(json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        return $this;
    }
}
