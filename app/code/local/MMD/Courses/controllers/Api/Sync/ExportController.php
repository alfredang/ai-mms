<?php
/**
 * SG-side course sync export endpoint.
 *
 * GET /courses/api_sync_export?page=1&page_size=50
 * GET /courses/api_sync_export?sku=C123          (single-course export)
 *   Header: X-API-Key: <mmd/course_sync/api_key>
 *
 * Returns paginated C-prefix courses (SKU LIKE 'C%') with all fields needed
 * by a country import service. TGS-prefix courses are excluded — they belong
 * to the WSQ/SkillsFuture system and are never synced to country instances.
 * With ?sku= the same envelope carries exactly that one course (404 when the
 * SKU is unknown; 400 when it isn't C-prefix) — powers the partner-side
 * individual course sync.
 *
 * Auth: same X-API-Key pattern as MMD_Courses_Api_CoursesController.
 * Mode guard: returns 403 in MMS_MODE=country (export is SG-only).
 * Read-only: never mutates any table.
 *
 * Response envelope:
 *   { success: true, page: 1, page_size: 50, total: 498,
 *     total_pages: 10, courses: [ {...}, ... ] }
 *
 * Per-course shape:
 *   sku, type_id, attribute_set (name), status, visibility,
 *   attributes: { attribute_code -> value (labels for select/multiselect) },
 *   categories: [ "url_key/path", ... ],
 *   custom_options: [ { title, type, sort_order, values: [{title,price,...}] } ],
 *   badges: [ "SkillsFuture Credit", ... ],
 *   course_image_url: "<SG R2 or local URL — importer fetches bytes from here>",
 *   updated_at: "2026-06-01 10:00:00"
 *
 * Cross-install ID safety: NO numeric IDs are exported (entity_id,
 * attribute_id, option_id, category_id). Everything maps by stable string
 * keys so the importer can safely upsert into a different DB.
 */
class MMD_Courses_Api_Sync_ExportController extends Mage_Core_Controller_Front_Action
{
    const CONFIG_API_KEY   = 'mmd/course_sync/api_key';
    const DEFAULT_PAGE_SZ  = 50;
    const MAX_PAGE_SZ      = 100;
    const ADMIN_STORE_ID   = 0;

    /** Attribute codes exported for every C-course (content-bearing, no trainer/contact noise). */
    const EXPORT_ATTRS = array(
        // Standard
        'name', 'description', 'short_description', 'url_key', 'price', 'special_price',
        'meta_title', 'meta_description', 'meta_keyword',
        // Course content
        'duration', 'level', 'software', 'sessions', 'whoshouldattend', 'prerequisite',
        'trainerprofile', 'additional_note', 'venue',
        'course_image_url', 'course_brochure_html', 'course_lo_html',
        'course_wsq_funding_raw_html', 'course_skills_framework_html',
        'enable_sg_funding', 'agegroup', 'assessment_duration', 'assessment_methods',
        'participants', 'min_participants', 'cancellation',
    );

    public function indexAction()
    {
        // Mode guard: this endpoint is SG-only
        if (strtolower((string) getenv('MMS_MODE')) === 'country') {
            return $this->_json(403, array('success' => false, 'error' => 'Export endpoint not available in country mode.'));
        }

        // Auth
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_API_KEY));
        if ($expected === '') {
            return $this->_json(503, array('success' => false, 'error' => 'API key not configured (mmd/course_sync/api_key).'));
        }
        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, array('success' => false, 'error' => 'Invalid or missing X-API-Key.'));
        }

        $page   = max(1, (int) $this->getRequest()->getParam('page', 1));
        $pgSize = min(self::MAX_PAGE_SZ, max(1, (int) $this->getRequest()->getParam('page_size', self::DEFAULT_PAGE_SZ)));

        // Country instances pass their own base currency so the exported
        // price/special_price/fixed-option prices arrive already converted
        // — the importer's PRICE RULE (P1) writes them verbatim on create,
        // so an unconverted SGD number would otherwise be mislabelled as
        // the country's own currency.
        $rate = $this->_getConversionRate((string) $this->getRequest()->getParam('currency', ''));

        // Single-course mode (?sku=C123) — same envelope, exactly one course.
        $singleSku = trim((string) $this->getRequest()->getParam('sku', ''));
        if ($singleSku !== '') {
            if (strtoupper(substr($singleSku, 0, 1)) !== 'C') {
                return $this->_json(400, array('success' => false, 'error' => 'Only C-prefix courses are exportable.'));
            }
            try {
                $read = Mage::getSingleton('core/resource')->getConnection('core_read');
                $exists = (int) $read->fetchOne(
                    "SELECT entity_id FROM catalog_product_entity WHERE sku = ?",
                    array($singleSku)
                );
                if (!$exists) {
                    return $this->_json(404, array('success' => false, 'error' => 'SKU not found: ' . $singleSku));
                }
                $course = $this->_buildCourse(
                    $singleSku,
                    $read,
                    $this->_buildAttrLabelCache($read),
                    $this->_buildAttrMetaCache($read),
                    $rate
                );
                return $this->_json(200, array(
                    'success' => true, 'page' => 1, 'page_size' => 1,
                    'total' => 1, 'total_pages' => 1,
                    'courses' => array($course),
                ));
            } catch (Exception $e) {
                Mage::logException($e);
                return $this->_json(500, array('success' => false, 'error' => $e->getMessage()));
            }
        }

        try {
            $resource = Mage::getSingleton('core/resource');
            $read     = $resource->getConnection('core_read');

            // Total C-course count (exclude TGS- which also starts with C if someone mislabels, but TGS- starts with T so this is clean)
            $total = (int) $read->fetchOne(
                "SELECT COUNT(*) FROM catalog_product_entity WHERE sku LIKE 'C%'"
            );
            $totalPages = max(1, (int) ceil($total / $pgSize));
            $offset     = ($page - 1) * $pgSize;

            $skus = $read->fetchCol(
                "SELECT sku FROM catalog_product_entity WHERE sku LIKE 'C%' ORDER BY sku LIMIT $pgSize OFFSET $offset"
            );

            // Build option-label cache for this batch of products
            $attrLabelCache = $this->_buildAttrLabelCache($read);
            $attrMetaCache  = $this->_buildAttrMetaCache($read);

            $courses = array();
            foreach ($skus as $sku) {
                try {
                    $courses[] = $this->_buildCourse($sku, $read, $attrLabelCache, $attrMetaCache, $rate);
                } catch (Exception $e) {
                    Mage::log('SyncExport: skip sku=' . $sku . ' err=' . $e->getMessage(), Zend_Log::WARN, 'course-sync.log');
                }
            }

            $this->_json(200, array(
                'success'     => true,
                'page'        => $page,
                'page_size'   => $pgSize,
                'total'       => $total,
                'total_pages' => $totalPages,
                'courses'     => $courses,
            ));
        } catch (Exception $e) {
            Mage::logException($e);
            $this->_json(500, array('success' => false, 'error' => $e->getMessage()));
        }
    }

    /**
     * GET /courses/api_sync_export/categories
     *   Header: X-API-Key: <mmd/course_sync/api_key>
     *
     * Category-tree export for the partner Category Sync. Exports every
     * category whose subtree contains at least one C-prefix product (plus the
     * structural ancestors of those categories) — WSQ-only branches never
     * leave SG, matching the C-prefix catalog-parity rule. Ordered
     * parents-first so the importer can create as it walks. Same
     * cross-install ID safety as the course export: categories are addressed
     * by url_key path only, never by entity_id.
     *
     * Envelope: { success: true, total: N, categories: [
     *   { path: "parent-uk/child-uk", name, is_active, include_in_menu,
     *     is_anchor, position, description, meta_title, meta_description,
     *     meta_keywords } ] }
     */
    public function categoriesAction()
    {
        // Mode guard: this endpoint is SG-only
        if (strtolower((string) getenv('MMS_MODE')) === 'country') {
            return $this->_json(403, array('success' => false, 'error' => 'Export endpoint not available in country mode.'));
        }

        // Auth — same contract as indexAction
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_API_KEY));
        if ($expected === '') {
            return $this->_json(503, array('success' => false, 'error' => 'API key not configured (mmd/course_sync/api_key).'));
        }
        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, array('success' => false, 'error' => 'Invalid or missing X-API-Key.'));
        }

        try {
            $read = Mage::getSingleton('core/resource')->getConnection('core_read');

            // Categories directly holding a C-prefix product
            $cCatIds = $read->fetchCol(
                "SELECT DISTINCT ccp.category_id
                 FROM catalog_category_product ccp
                 JOIN catalog_product_entity p ON p.entity_id = ccp.product_id
                 WHERE p.sku LIKE 'C%'"
            );

            // All categories under the default root, parents-first
            $allCats = $read->fetchAll(
                "SELECT entity_id, parent_id, path, position
                 FROM catalog_category_entity
                 WHERE path LIKE '1/2/%'
                 ORDER BY LENGTH(path) - LENGTH(REPLACE(path, '/', '')), position, entity_id"
            );

            // Include each C-bearing category and every ancestor on its path
            $include = array();
            $byId = array();
            foreach ($allCats as $row) {
                $byId[(int) $row['entity_id']] = $row;
            }
            foreach ($cCatIds as $catId) {
                if (!isset($byId[(int) $catId])) continue;
                foreach (explode('/', $byId[(int) $catId]['path']) as $seg) {
                    if ((int) $seg > 2) $include[(int) $seg] = true;
                }
            }

            // Attribute values at store 0 for the included set
            $attrCodes = array(
                'url_key' => 'varchar', 'name' => 'varchar', 'is_active' => 'int',
                'include_in_menu' => 'int', 'is_anchor' => 'int',
                'description' => 'text', 'meta_title' => 'varchar',
                'meta_description' => 'text', 'meta_keywords' => 'text',
            );
            $values = array(); // [entity_id][code] => value
            if (!empty($include)) {
                $idList = implode(',', array_map('intval', array_keys($include)));
                foreach ($attrCodes as $code => $backend) {
                    $rows = $read->fetchAll(
                        "SELECT v.entity_id, v.value
                         FROM catalog_category_entity_{$backend} v
                         JOIN eav_attribute a ON a.attribute_id = v.attribute_id
                         WHERE a.entity_type_id = 3 AND a.attribute_code = ?
                           AND v.store_id = 0 AND v.entity_id IN ($idList)",
                        array($code)
                    );
                    foreach ($rows as $r) {
                        $values[(int) $r['entity_id']][$code] = $r['value'];
                    }
                }
            }

            $categories = array();
            foreach ($allCats as $row) {
                $id = (int) $row['entity_id'];
                if (!isset($include[$id])) continue;

                // url_key path from root — skip categories we can't address
                $keys = array();
                foreach (explode('/', $row['path']) as $seg) {
                    if ((int) $seg <= 2) continue;
                    $uk = isset($values[(int) $seg]['url_key']) ? trim((string) $values[(int) $seg]['url_key']) : '';
                    if ($uk === '') { $keys = array(); break; }
                    $keys[] = $uk;
                }
                if (empty($keys)) continue;

                $v = isset($values[$id]) ? $values[$id] : array();
                $categories[] = array(
                    'path'             => implode('/', $keys),
                    'name'             => isset($v['name']) ? (string) $v['name'] : '',
                    'is_active'        => isset($v['is_active']) ? (int) $v['is_active'] : 1,
                    'include_in_menu'  => isset($v['include_in_menu']) ? (int) $v['include_in_menu'] : 1,
                    'is_anchor'        => isset($v['is_anchor']) ? (int) $v['is_anchor'] : 1,
                    'position'         => (int) $row['position'],
                    'description'      => isset($v['description']) ? (string) $v['description'] : null,
                    'meta_title'       => isset($v['meta_title']) ? (string) $v['meta_title'] : null,
                    'meta_description' => isset($v['meta_description']) ? (string) $v['meta_description'] : null,
                    'meta_keywords'    => isset($v['meta_keywords']) ? (string) $v['meta_keywords'] : null,
                );
            }

            $this->_json(200, array(
                'success'    => true,
                'total'      => count($categories),
                'categories' => $categories,
            ));
        } catch (Exception $e) {
            Mage::logException($e);
            $this->_json(500, array('success' => false, 'error' => $e->getMessage()));
        }
    }

    private function _buildCourse($sku, $read, array $labelCache, array $attrMeta, $rate = null)
    {
        $tbl = Mage::getSingleton('core/resource');

        // Resolve entity_id via raw query to avoid loadByAttribute triggering
        // addAttributeToSelect('*') on the flat resource (which lacks loadAllAttributes()).
        $entityId = (int) $read->fetchOne(
            "SELECT entity_id FROM catalog_product_entity WHERE sku = ?",
            array($sku)
        );
        if (!$entityId) {
            throw new Exception('Product not found for sku=' . $sku);
        }
        $product = Mage::getModel('catalog/product')
            ->setStoreId(self::ADMIN_STORE_ID)
            ->load($entityId);

        $pid = (int) $product->getId();

        // Attribute set name (stable key)
        $attrSetName = (string) $read->fetchOne(
            "SELECT attribute_set_name FROM eav_attribute_set WHERE attribute_set_id = ?",
            array((int) $product->getAttributeSetId())
        );

        // Attributes — resolve select/multiselect to labels
        $attrs = array();
        foreach (self::EXPORT_ATTRS as $code) {
            $val = $product->getData($code);
            if ($val === null || $val === false || $val === '') {
                $attrs[$code] = null;
                continue;
            }
            $input = isset($attrMeta[$code]) ? $attrMeta[$code]['input'] : '';
            if ($input === 'select') {
                $attrs[$code] = isset($labelCache[$code][(int)$val]) ? $labelCache[$code][(int)$val] : null;
            } elseif ($input === 'boolean') {
                $attrs[$code] = (bool)(int)$val;
            } elseif ($input === 'multiselect') {
                $ids = array_filter(array_map('intval', explode(',', (string)$val)));
                $labels = array();
                foreach ($ids as $id) {
                    if (isset($labelCache[$code][$id])) {
                        $labels[] = $labelCache[$code][$id];
                    }
                }
                $attrs[$code] = $labels ?: null;
            } else {
                $attrs[$code] = $val;
            }
        }
        if ($rate) {
            foreach (array('price', 'special_price') as $code) {
                if ($attrs[$code] !== null) {
                    $attrs[$code] = round((float) $attrs[$code] * $rate, 2);
                }
            }
        }

        // Categories — export as url_key paths (no numeric IDs)
        $categories = $this->_getCategoryPaths($pid, $read);

        // Custom options (Course Date / Course Time) by title, no option IDs
        $customOptions = $this->_getCustomOptions($pid, $read, $rate);

        // Badge tags (canonical MMD_CourseImage vocabulary)
        $badges = $this->_getBadges($pid, $read);

        return array(
            'sku'           => $sku,
            'type_id'       => $product->getTypeId(),
            'attribute_set' => $attrSetName,
            'status'        => (int) $product->getStatus(),
            'visibility'    => (int) $product->getVisibility(),
            'attributes'    => $attrs,
            'categories'    => $categories,
            'custom_options'=> $customOptions,
            'badges'        => $badges,
            'updated_at'    => $product->getUpdatedAt(),
        );
    }

    /** Build [ attribute_code => [ option_id => label ] ] for select/multiselect attrs */
    private function _buildAttrLabelCache($read)
    {
        $codes = implode("','", array_map('addslashes', self::EXPORT_ATTRS));
        $rows  = $read->fetchAll("
            SELECT ea.attribute_code, eaov.option_id, eaovv.value AS label
            FROM eav_attribute ea
            JOIN eav_attribute_option eaov ON eaov.attribute_id = ea.attribute_id
            JOIN eav_attribute_option_value eaovv ON eaovv.option_id = eaov.option_id AND eaovv.store_id = 0
            WHERE ea.entity_type_id = 4
              AND ea.frontend_input IN ('select','multiselect')
              AND ea.attribute_code IN ('" . $codes . "')
        ");
        $cache = array();
        foreach ($rows as $r) {
            $cache[$r['attribute_code']][(int)$r['option_id']] = $r['label'];
        }
        return $cache;
    }

    /** Build [ attribute_code => [ 'input' => '...' ] ] */
    private function _buildAttrMetaCache($read)
    {
        $codes = implode("','", array_map('addslashes', self::EXPORT_ATTRS));
        $rows  = $read->fetchAll("
            SELECT attribute_code, frontend_input
            FROM eav_attribute
            WHERE entity_type_id = 4
              AND attribute_code IN ('" . $codes . "')
        ");
        $meta = array();
        foreach ($rows as $r) {
            $meta[$r['attribute_code']] = array('input' => $r['frontend_input']);
        }
        return $meta;
    }

    /** Returns [ "parent-url-key/child-url-key", ... ] — no IDs */
    private function _getCategoryPaths($productId, $read)
    {
        $tbl = Mage::getSingleton('core/resource');
        $catProdTbl    = $tbl->getTableName('catalog_category_product');
        $catEntityTbl  = $tbl->getTableName('catalog_category_entity');
        $catVarcharTbl = $tbl->getTableName('catalog_category_entity_varchar');

        // Get all category IDs for this product
        $catIds = $read->fetchCol(
            "SELECT category_id FROM `$catProdTbl` WHERE product_id = ?",
            array($productId)
        );
        if (empty($catIds)) return array();

        $paths = array();
        foreach ($catIds as $catId) {
            // Get the path string (e.g. "1/2/5/12") and resolve each non-root segment to its url_key
            $path = (string) $read->fetchOne(
                "SELECT path FROM `$catEntityTbl` WHERE entity_id = ?",
                array((int)$catId)
            );
            $segments = array_filter(explode('/', $path), function($s) { return (int)$s > 2; });
            if (empty($segments)) continue;

            $ukAttrId = (int) $read->fetchOne(
                "SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key' LIMIT 1"
            );
            $keys = array();
            foreach ($segments as $seg) {
                $uk = (string) $read->fetchOne(
                    "SELECT value FROM `$catVarcharTbl` WHERE entity_id = ? AND attribute_id = ? AND store_id = 0",
                    array((int)$seg, $ukAttrId)
                );
                if ($uk !== '') $keys[] = $uk;
            }
            if (!empty($keys)) {
                $paths[] = implode('/', $keys);
            }
        }
        return array_values(array_unique($paths));
    }

    /** Returns custom options by title (no option_id). */
    private function _getCustomOptions($productId, $read, $rate = null)
    {
        $tbl   = Mage::getSingleton('core/resource');
        $optTbl    = $tbl->getTableName('catalog_product_option');
        $optTitTbl = $tbl->getTableName('catalog_product_option_title');
        $optTypTbl = $tbl->getTableName('catalog_product_option_type_value');
        $optTTitTbl= $tbl->getTableName('catalog_product_option_type_title');
        $optTPricTbl=$tbl->getTableName('catalog_product_option_type_price');

        $options = $read->fetchAll(
            "SELECT o.option_id, o.type, o.sort_order, ot.title
             FROM `$optTbl` o
             JOIN `$optTitTbl` ot ON ot.option_id = o.option_id AND ot.store_id = 0
             WHERE o.product_id = ?
             ORDER BY o.sort_order",
            array($productId)
        );

        $result = array();
        foreach ($options as $opt) {
            $values = $read->fetchAll(
                "SELECT ott.title, otp.price, otp.price_type, otv.sort_order, otv.sku
                 FROM `$optTypTbl` otv
                 JOIN `$optTTitTbl` ott ON ott.option_type_id = otv.option_type_id AND ott.store_id = 0
                 LEFT JOIN `$optTPricTbl` otp ON otp.option_type_id = otv.option_type_id AND otp.store_id = 0
                 WHERE otv.option_id = ?
                 ORDER BY otv.sort_order",
                array((int)$opt['option_id'])
            );
            $valList = array();
            foreach ($values as $v) {
                $price = $v['price'];
                // Only "fixed" option prices are a currency amount — "percent"
                // values are a percentage of the (already-converted) base
                // price and must not be converted again.
                if ($rate && $v['price_type'] === 'fixed' && $price !== null) {
                    $price = round((float) $price * $rate, 2);
                }
                $valList[] = array(
                    'title'      => $v['title'],
                    'price'      => $price,
                    'price_type' => $v['price_type'],
                    'sort_order' => (int)$v['sort_order'],
                    'sku'        => $v['sku'],
                );
            }
            $result[] = array(
                'title'      => $opt['title'],
                'type'       => $opt['type'],
                'sort_order' => (int)$opt['sort_order'],
                'values'     => $valList,
            );
        }
        return $result;
    }

    /** Returns badge names from the catalog_product_tag / tag join for this product. */
    private function _getBadges($productId, $read)
    {
        $tbl = Mage::getSingleton('core/resource');
        $tagRelTbl = $tbl->getTableName('catalog_product_tag');
        $tagTbl    = $tbl->getTableName('tag');

        try {
            $tags = $read->fetchCol(
                "SELECT t.name FROM `$tagTbl` t
                 JOIN `$tagRelTbl` pt ON pt.tag_id = t.tag_id
                 WHERE pt.product_id = ? AND t.status = 1",
                array($productId)
            );
        } catch (Exception $e) {
            return array(); // tag tables may not exist on all installs
        }

        $canonical = array(
            'WSQ', 'SkillsFuture Credit', 'PSEA', 'UTAP', 'IBF',
            'HRDF', 'SFEC', 'Absentee Payroll', 'MCES',
        );
        return array_values(array_intersect($tags, $canonical));
    }

    /**
     * Resolve the SG-base-currency -> requested-currency rate.
     * Returns null when no conversion is needed/possible (blank/SGD-equal
     * request, or no rate row) — callers then export the raw SGD number,
     * same as before this existed.
     */
    private function _getConversionRate($requestedCurrency)
    {
        $target = strtoupper(trim((string) $requestedCurrency));
        if ($target === '') {
            return null;
        }
        $base = (string) Mage::app()->getBaseCurrencyCode();
        if ($target === $base) {
            return null;
        }
        $rate = Mage::getModel('directory/currency')->load($base)->getRate($target);
        if (!$rate) {
            Mage::log('SyncExport: no currency rate ' . $base . '->' . $target, Zend_Log::WARN, 'course-sync.log');
            return null;
        }
        return (float) $rate;
    }

    private function _json($code, array $data)
    {
        $this->getResponse()
            ->setHttpResponseCode($code)
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($data));
    }
}
