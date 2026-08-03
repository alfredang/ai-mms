<?php
/**
 * Country-side course sync: pulls C-prefix course definitions from SG.
 *
 * Mirrors MMD_RoleManager_Model_TrainerImportService in structure.
 *
 * What it does per run:
 *   1. Paginates through SG's /courses/api_sync_export endpoint.
 *   2. For each C-prefix product: find-or-create by SKU, upsert all
 *      attributes (labels→local option IDs), categories (url_key→local ID),
 *      custom options (idempotent recreation), image (fetch→local media/).
 *   3. PARTNER-OWNED FIELDS (P1): the country owns its course fee and trainer
 *      info after first import. On UPDATE these are never overwritten:
 *        - price / special_price attributes
 *        - trainerprofile attribute (trainer info)
 *        - ALL custom options (Course Date schedule, per-option fees, trainer
 *          options) — recreated on CREATE only; updates leave them untouched.
 *      Everything is one-way SG -> country: this service only READS from SG's
 *      export endpoint and never writes back.
 *   4. Disables (status=2) any local C-prefix products absent from the export
 *      (retirement policy — never hard-deletes). Bulk pull only — pullOne()
 *      never disables anything.
 *   5. Reindexes catalog_url + flat catalog/category.
 *   6. Writes a row to mmd_course_sync_log.
 *
 * Cross-install ID safety: NEVER uses numeric IDs from the export payload.
 * Maps attribute_set by name, options by label, categories by url_key/name.
 */
class MMD_RoleManager_Model_CourseSyncService
{
    const LOG_FILE         = 'course-sync.log';
    const URL_CONFIG_PATH  = 'mmd/course_sync/sg_url';
    const KEY_CONFIG_PATH  = 'mmd/course_sync/api_key';
    const LOG_TABLE        = 'mmd_course_sync_log';

    /**
     * Attributes the country owns after first import — never overwritten on
     * UPDATE (P1): course fee + trainer info stay local.
     */
    private static $_partnerOwnedAttrs = array('price', 'special_price', 'trainerprofile');

    public function getSgUrl()
    {
        $base = rtrim(trim((string) Mage::getStoreConfig(self::URL_CONFIG_PATH)), '/');
        // Accept either a bare base URL or the full endpoint URL.
        // Append the path if the stored value doesn't already end with it.
        if ($base !== '' && strpos($base, '/courses/api_sync_export') === false) {
            $base .= '/courses/api_sync_export';
        }
        return $base;
    }
    public function getApiKey()
    {
        return trim((string) Mage::getStoreConfig(self::KEY_CONFIG_PATH));
    }
    public function isConfigured()
    {
        return $this->getSgUrl() !== '' && $this->getApiKey() !== '';
    }

    /**
     * Full pull: paginate SG export and import all courses. Returns summary array.
     */
    public function pull($triggeredBy = 'cron')
    {
        if (!$this->isConfigured()) {
            throw new Exception('SG sync URL / API key not configured (mmd/course_sync/sg_url + api_key).');
        }

        $summary = array(
            'fetched' => 0, 'created' => 0, 'updated' => 0,
            'disabled' => 0, 'skipped' => 0, 'errors' => 0,
            'error_msgs' => array(), 'success' => true,
        );

        $page = 1;
        $seenSkus = array();

        do {
            $payload = $this->_fetchPage($page, 50);
            $courses  = isset($payload['courses']) ? (array)$payload['courses'] : array();
            $summary['fetched'] += count($courses);

            foreach ($courses as $course) {
                $sku = isset($course['sku']) ? (string)$course['sku'] : '';
                if ($sku === '' || strtoupper(substr($sku, 0, 1)) !== 'C') {
                    $summary['skipped']++;
                    continue; // safety invariant: only C-prefix
                }
                if (isset($course['status']) && (int)$course['status'] === 2) {
                    $summary['skipped']++;
                    continue;
                }
                $seenSkus[$sku] = true;
                $lastErr = null;
                for ($attempt = 0; $attempt < 3; $attempt++) {
                    try {
                        $isNew = $this->_upsertCourse($course);
                        if ($isNew) $summary['created']++;
                        else        $summary['updated']++;
                        $lastErr = null;
                        break;
                    } catch (Exception $e) {
                        $lastErr = $e;
                        // Retry on InnoDB deadlock (1213), back off slightly
                        if ($attempt < 2 && strpos($e->getMessage(), '1213') !== false) {
                            usleep(300000 * ($attempt + 1));
                            continue;
                        }
                        break;
                    }
                }
                if ($lastErr !== null) {
                    $summary['errors']++;
                    $summary['error_msgs'][] = $sku . ': ' . $lastErr->getMessage();
                    Mage::log('CourseSyncService: error sku=' . $sku . ' ' . $lastErr->getMessage(), Zend_Log::ERR, self::LOG_FILE);
                }
            }

            $totalPages = isset($payload['total_pages']) ? (int)$payload['total_pages'] : 1;
            $page++;
        } while ($page <= $totalPages);

        // Disable local C-products absent from the export (retirement)
        $summary['disabled'] = $this->_disableRetiredCourses($seenSkus);

        // Reindex
        try {
            $this->_reindex();
        } catch (Exception $e) {
            Mage::log('CourseSyncService: reindex error ' . $e->getMessage(), Zend_Log::WARN, self::LOG_FILE);
        }

        $summary['success'] = $summary['errors'] === 0;
        $this->_writeLog($summary, $triggeredBy);
        return $summary;
    }

    /**
     * Individual course sync: pull exactly ONE C-prefix course from SG and
     * upsert it. Same P1 partner-owned preservation as the bulk pull; never
     * disables/retires anything else. Returns summary array.
     */
    public function pullOne($sku, $triggeredBy = 'admin')
    {
        if (!$this->isConfigured()) {
            throw new Exception('SG sync URL / API key not configured (mmd/course_sync/sg_url + api_key).');
        }
        $sku = trim((string) $sku);
        if ($sku === '' || strtoupper(substr($sku, 0, 1)) !== 'C') {
            throw new Exception('Only C-prefix (non-WSQ) course codes can be synced.');
        }

        $summary = array(
            'fetched' => 0, 'created' => 0, 'updated' => 0,
            'disabled' => 0, 'skipped' => 0, 'errors' => 0,
            'error_msgs' => array(), 'success' => true,
        );

        $payload = $this->_fetchPage(1, 1, $sku);
        $courses = isset($payload['courses']) ? (array) $payload['courses'] : array();
        if (empty($courses)) {
            throw new Exception('SG returned no course for ' . $sku);
        }
        $summary['fetched'] = 1;

        try {
            $isNew = $this->_upsertCourse($courses[0]);
            if ($isNew) $summary['created']++;
            else        $summary['updated']++;
        } catch (Exception $e) {
            $summary['errors']++;
            $summary['error_msgs'][] = $sku . ': ' . $e->getMessage();
            Mage::log('CourseSyncService: pullOne error sku=' . $sku . ' ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
        }

        try {
            $this->_reindex();
        } catch (Exception $e) {
            Mage::log('CourseSyncService: reindex error ' . $e->getMessage(), Zend_Log::WARN, self::LOG_FILE);
        }

        $summary['success'] = $summary['errors'] === 0;
        $this->_writeLog($summary, $triggeredBy . ' (single: ' . $sku . ')');
        return $summary;
    }

    /**
     * Schedule sync: replace the local Course Date / Course Time custom
     * options with SG's for every C-prefix course that already exists
     * locally. This deliberately overrides the P1 custom-option ownership —
     * it only ever runs from an explicit trigger (SG Franchise Management
     * page or a partner admin), never from cron. Products absent locally are
     * skipped (run a course sync first to create them). Returns summary.
     */
    public function syncSchedules($triggeredBy = 'admin')
    {
        if (!$this->isConfigured()) {
            throw new Exception('SG sync URL / API key not configured (mmd/course_sync/sg_url + api_key).');
        }

        $summary = array(
            'fetched' => 0, 'created' => 0, 'updated' => 0,
            'disabled' => 0, 'skipped' => 0, 'errors' => 0,
            'error_msgs' => array(), 'success' => true,
        );

        $page = 1;
        do {
            $payload = $this->_fetchPage($page, 50);
            $courses = isset($payload['courses']) ? (array) $payload['courses'] : array();
            $summary['fetched'] += count($courses);

            foreach ($courses as $course) {
                $sku = isset($course['sku']) ? (string) $course['sku'] : '';
                if ($sku === '' || strtoupper(substr($sku, 0, 1)) !== 'C') {
                    $summary['skipped']++;
                    continue;
                }
                $localId = (int) Mage::getModel('catalog/product')->getIdBySku($sku);
                if ($localId === 0) {
                    $summary['skipped']++; // not imported yet — course sync first
                    continue;
                }
                try {
                    $options = isset($course['custom_options']) && is_array($course['custom_options'])
                        ? $course['custom_options'] : array();
                    $this->_recreateCustomOptions($localId, $options);
                    $summary['updated']++;
                } catch (Exception $e) {
                    $summary['errors']++;
                    $summary['error_msgs'][] = $sku . ': ' . $e->getMessage();
                    Mage::log('CourseSyncService: schedule error sku=' . $sku . ' ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
                }
            }

            $totalPages = isset($payload['total_pages']) ? (int) $payload['total_pages'] : 1;
            $page++;
        } while ($page <= $totalPages);

        $summary['success'] = $summary['errors'] === 0;
        $this->_writeLog($summary, $triggeredBy . ' (schedules)');
        return $summary;
    }

    /** GET one page (or one SKU) from the SG export endpoint. */
    private function _fetchPage($page, $pageSize, $sku = null)
    {
        // Tell SG which currency to convert price/special_price/custom-option
        // fixed prices into before exporting, so this country's courses are
        // created with a price already denominated in its own currency
        // instead of a raw SGD number mislabelled as the local unit.
        $currency = (string) Mage::app()->getBaseCurrencyCode();
        $url = $this->getSgUrl() . '?page=' . $page . '&page_size=' . $pageSize
            . '&currency=' . rawurlencode($currency)
            . ($sku !== null ? '&sku=' . rawurlencode($sku) : '');
        $ch  = curl_init($url);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_MAXREDIRS      => 5,
            CURLOPT_TIMEOUT        => 120,
            CURLOPT_CONNECTTIMEOUT => 15,
            CURLOPT_USERAGENT      => 'Mozilla/5.0 (compatible; MMD-CourseSync/1.0)',
            CURLOPT_HTTPHEADER     => array(
                'X-API-Key: ' . $this->getApiKey(),
                'Accept: application/json',
            ),
        ));
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);

        if ($raw === false || $raw === '') {
            throw new Exception('SG unreachable: ' . ($err ?: 'no response'));
        }
        $rsp = json_decode($raw, true);
        if ($code >= 400 || !is_array($rsp) || empty($rsp['success'])) {
            $msg = is_array($rsp) && isset($rsp['error']) ? $rsp['error'] : ('HTTP ' . $code);
            throw new Exception('SG export failed: ' . $msg);
        }
        return $rsp;
    }

    /**
     * Upsert one course. Returns true if created, false if updated.
     */
    private function _upsertCourse(array $c)
    {
        $sku = (string)$c['sku'];

        // Find existing product by SKU
        $existingId = (int) Mage::getModel('catalog/product')->getIdBySku($sku);
        $isNew      = $existingId === 0;

        /** @var Mage_Catalog_Model_Product $product */
        // setStoreId(0) BEFORE load: forces the EAV resource. Without it, a
        // CLI/cron context (default store) loads via the read-only FLAT
        // resource and ->save() fatals in _collectSaveData — so every cron
        // UPDATE of an existing course silently errored under flat catalog.
        $product = Mage::getModel('catalog/product')->setStoreId(0);
        if (!$isNew) {
            $product->load($existingId);
        }

        // Attribute set — map by name to local ID
        $attrSetId = $this->_resolveAttributeSetId(
            isset($c['attribute_set']) ? (string)$c['attribute_set'] : 'Default'
        );

        $product->setTypeId(isset($c['type_id']) ? (string)$c['type_id'] : 'simple');
        $product->setAttributeSetId($attrSetId);
        $product->setSku($sku);
        $product->setStatus(isset($c['status']) ? (int)$c['status'] : 1);
        $product->setVisibility(isset($c['visibility']) ? (int)$c['visibility'] : 4);

        // Attributes — resolve labels back to local option IDs
        $attrs = isset($c['attributes']) && is_array($c['attributes']) ? $c['attributes'] : array();
        foreach ($attrs as $code => $value) {
            if ($value === null) continue;
            if (in_array($code, self::$_partnerOwnedAttrs, true)) {
                if ($isNew) $product->setData($code, $value); // P1: partner-owned after first import
                continue;
            }
            $localValue = $this->_resolveAttrValue($code, $value);
            if ($localValue !== null) {
                $product->setData($code, $localValue);
            }
        }

        // Assign to all websites in this instance (country DBs may use a different website_id than 1)
        $allWebsiteIds = array_keys(Mage::app()->getWebsites());
        $product->setWebsiteIds($allWebsiteIds ?: array(1));
        $product->setStoreId(0); // save at admin scope

        if ($isNew) {
            $product->setStockData(array(
                'use_config_manage_stock' => 0,
                'manage_stock'            => 0,
                'is_in_stock'             => 1,
                'qty'                     => 9999,
            ));
        }

        $product->save();
        $savedId = (int) $product->getId();

        // Categories — assign by url_key/name (find-or-create)
        if (!empty($c['categories']) && is_array($c['categories'])) {
            $this->_assignCategories($savedId, $c['categories']);
        }

        // Custom options — CREATE only (P1). The country owns its class
        // schedule, per-option fees, and trainer options after first import;
        // recreating them on update would clobber all three with SG's data.
        if ($isNew && isset($c['custom_options']) && is_array($c['custom_options']) && !empty($c['custom_options'])) {
            $this->_recreateCustomOptions($savedId, $c['custom_options']);
        }

        // Badge tags — sync canonical tags
        if (isset($c['badges']) && is_array($c['badges'])) {
            $this->_syncBadges($savedId, $c['badges']);
        }

        // Image — download from SG and store locally
        $imageUrl = isset($attrs['course_image_url']) ? (string)$attrs['course_image_url'] : '';
        if ($imageUrl !== '' && substr($imageUrl, 0, 4) === 'http') {
            try {
                $this->_fetchAndStoreImage($savedId, $sku, $imageUrl, $product);
            } catch (Exception $e) {
                Mage::log('CourseSyncService: image error sku=' . $sku . ' ' . $e->getMessage(), Zend_Log::WARN, self::LOG_FILE);
            }
        }

        return $isNew;
    }

    /** Resolve attribute_set name → local attribute_set_id */
    private function _resolveAttributeSetId($name)
    {
        $read = Mage::getSingleton('core/resource')->getConnection('core_read');
        $id   = (int) $read->fetchOne(
            "SELECT attribute_set_id FROM eav_attribute_set WHERE entity_type_id = 4 AND attribute_set_name = ? LIMIT 1",
            array($name)
        );
        if ($id === 0) {
            // Fall back to the default attribute set for catalog_product
            $id = (int) $read->fetchOne(
                "SELECT default_attribute_set_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product'"
            );
        }
        return $id;
    }

    /** Resolve an exported attribute value (label or label[]) to the local option ID(s) */
    private function _resolveAttrValue($code, $value)
    {
        $attr = Mage::getSingleton('eav/config')->getAttribute('catalog_product', $code);
        if (!$attr || !$attr->getId()) return $value; // unknown attribute — pass through

        $input = $attr->getFrontendInput();

        if ($input === 'select') {
            if (!is_string($value) && !is_numeric($value)) return null;
            $optId = $this->_findOrCreateOption($attr, (string)$value);
            return $optId > 0 ? $optId : null;
        }

        if ($input === 'multiselect') {
            if (!is_array($value)) return null;
            $ids = array();
            foreach ($value as $label) {
                $optId = $this->_findOrCreateOption($attr, (string)$label);
                if ($optId > 0) $ids[] = $optId;
            }
            return empty($ids) ? null : implode(',', $ids);
        }

        if ($input === 'boolean') {
            return $value ? 1 : 0;
        }

        return $value; // text/textarea/price/etc — pass through
    }

    /** Find existing option by label or create it. Returns option_id. */
    private function _findOrCreateOption($attr, $label)
    {
        $label = trim($label);
        if ($label === '') return 0;

        // Check existing options
        foreach ($attr->getSource()->getAllOptions(false) as $opt) {
            if (strcasecmp(trim((string)$opt['label']), $label) === 0) {
                return (int)$opt['value'];
            }
        }

        // Create new option
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $attrId = (int)$attr->getId();

        $write->insert($write->getTableName('eav_attribute_option'), array('attribute_id' => $attrId, 'sort_order' => 0));
        $optId = (int) $write->lastInsertId();
        $write->insert($write->getTableName('eav_attribute_option_value'), array(
            'option_id' => $optId, 'store_id' => 0, 'value' => $label,
        ));

        // Reload the attribute source so subsequent lookups see the new option
        $attr->setData('_cache_instance_options_array', null);
        $attr->getSource()->setAttribute($attr);

        return $optId;
    }

    /** Assign categories by url_key path. Creates missing categories on the fly. */
    private function _assignCategories($productId, array $paths)
    {
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $tbl   = Mage::getSingleton('core/resource');

        $catIds = array();
        foreach ($paths as $path) {
            $parts    = array_filter(explode('/', $path));
            $parentId = 2; // Magento default root
            $leafId   = null;
            foreach ($parts as $urlKey) {
                $leafId   = $this->_findOrCreateCategory($urlKey, $parentId);
                $parentId = $leafId;
            }
            if ($leafId) $catIds[] = $leafId;
        }
        $catIds = array_unique($catIds);

        $cpTbl = $tbl->getTableName('catalog_category_product');
        $write->delete($cpTbl, array('product_id = ?' => $productId));
        foreach ($catIds as $catId) {
            $write->insertIgnore($cpTbl, array('category_id' => $catId, 'product_id' => $productId, 'position' => 0));
        }
    }

    /** Find or create a category by url_key under a given parent. Cached per sync run. */
    private function _findOrCreateCategory($urlKey, $parentId)
    {
        static $cache = array();
        $key = $parentId . '/' . $urlKey;
        if (isset($cache[$key])) return $cache[$key];

        $read     = Mage::getSingleton('core/resource')->getConnection('core_read');
        $ukAttrId = (int) $read->fetchOne(
            "SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key' LIMIT 1"
        );

        $catId = (int) $read->fetchOne(
            "SELECT e.entity_id FROM catalog_category_entity e
             JOIN catalog_category_entity_varchar v
               ON v.entity_id = e.entity_id AND v.attribute_id = ? AND v.store_id = 0 AND v.value = ?
             WHERE e.parent_id = ? LIMIT 1",
            array($ukAttrId, $urlKey, $parentId)
        );

        if ($catId === 0) {
            // Must load the parent so Magento can calculate path/level correctly on save.
            $parent = Mage::getModel('catalog/category')->load($parentId);
            $name   = ucwords(str_replace('-', ' ', $urlKey));
            $cat    = Mage::getModel('catalog/category');
            $cat->setPath($parent->getPath())
                ->setParentId($parentId)
                ->setName($name)
                ->setUrlKey($urlKey)
                ->setIsActive(1)
                ->setIsAnchor(1)
                ->setIncludeInMenu(1)
                ->setStoreId(0);
            $cat->save();
            $catId = (int) $cat->getId();
        }

        $cache[$key] = $catId;
        return $catId;
    }

    /** Delete existing custom options for a product and recreate from export data. */
    private function _recreateCustomOptions($productId, array $options)
    {
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $tbl   = Mage::getSingleton('core/resource');

        // Delete all existing options for this product
        $write->delete($tbl->getTableName('catalog_product_option'), array('product_id = ?' => $productId));

        foreach ($options as $opt) {
            $title      = (string)($opt['title'] ?? '');
            $type       = (string)($opt['type'] ?? 'drop_down');
            $sortOrder  = (int)($opt['sort_order'] ?? 0);
            if ($title === '') continue;

            $write->insert($tbl->getTableName('catalog_product_option'), array(
                'product_id' => $productId,
                'type'       => $type,
                'is_require' => 0,
                'sort_order' => $sortOrder,
            ));
            $optId = (int) $write->lastInsertId();

            $write->insert($tbl->getTableName('catalog_product_option_title'), array(
                'option_id' => $optId, 'store_id' => 0, 'title' => $title,
            ));

            if (!empty($opt['values']) && is_array($opt['values'])) {
                foreach ($opt['values'] as $v) {
                    $vTitle = (string)($v['title'] ?? '');
                    if ($vTitle === '') continue;
                    $write->insert($tbl->getTableName('catalog_product_option_type_value'), array(
                        'option_id'  => $optId,
                        'sort_order' => (int)($v['sort_order'] ?? 0),
                        'sku'        => $v['sku'] ?? null,
                    ));
                    $typeId = (int) $write->lastInsertId();
                    $write->insert($tbl->getTableName('catalog_product_option_type_title'), array(
                        'option_type_id' => $typeId, 'store_id' => 0, 'title' => $vTitle,
                    ));
                    $write->insert($tbl->getTableName('catalog_product_option_type_price'), array(
                        'option_type_id' => $typeId,
                        'store_id'       => 0,
                        'price'          => (float)($v['price'] ?? 0),
                        'price_type'     => $v['price_type'] ?? 'fixed',
                    ));
                }
            }
        }

        // Mark the product as having custom options (0 when SG has none —
        // the schedule sync mirrors an empty schedule by clearing local options)
        $write->update(
            $tbl->getTableName('catalog_product_entity'),
            array('has_options' => empty($options) ? 0 : 1, 'required_options' => 0),
            array('entity_id = ?' => $productId)
        );
    }

    /** Sync badge tags for a product — add missing, leave extras. */
    private function _syncBadges($productId, array $badges)
    {
        if (empty($badges)) return;
        $read  = Mage::getSingleton('core/resource')->getConnection('core_read');
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $tbl   = Mage::getSingleton('core/resource');
        $tagTbl    = $tbl->getTableName('tag');
        $tagRelTbl = $tbl->getTableName('catalog_product_tag');

        foreach ($badges as $name) {
            $name = trim((string)$name);
            if ($name === '') continue;
            $tagId = (int) $read->fetchOne("SELECT tag_id FROM `$tagTbl` WHERE name = ? LIMIT 1", array($name));
            if ($tagId === 0) {
                $write->insert($tagTbl, array('name' => $name, 'status' => 1));
                $tagId = (int) $write->lastInsertId();
            }
            // insertIgnore keeps it idempotent
            try {
                $write->insertIgnore($tagRelTbl, array(
                    'tag_id'     => $tagId,
                    'product_id' => $productId,
                    'store_id'   => 1,
                ));
            } catch (Exception $e) {
                // tag relation may not exist in all DB versions — non-fatal
            }
        }
    }

    /** Download the course image and set course_image_url to the local URL. */
    private function _fetchAndStoreImage($productId, $sku, $imageUrl, $product)
    {
        /** @var MMD_CourseImage_Helper_LocalDisk $disk */
        $disk = Mage::helper('mmd_courseimage/localDisk');

        $ext = pathinfo(parse_url($imageUrl, PHP_URL_PATH), PATHINFO_EXTENSION) ?: 'jpg';
        $key = strtolower($sku) . '.' . $ext;

        $result = $disk->fetchAndStore($imageUrl, $key);
        $localUrl = $result['url'];

        // Update course_image_url to the instance-local URL
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $tbl   = Mage::getSingleton('core/resource');

        // Get the attribute_id for course_image_url
        $attrId = (int) $write->fetchOne(
            "SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url' LIMIT 1"
        );
        if ($attrId === 0) return;

        $varcharTbl = $tbl->getTableName('catalog_product_entity_varchar');
        $existing = $write->fetchOne(
            "SELECT value_id FROM `$varcharTbl` WHERE entity_id = ? AND attribute_id = ? AND store_id = 0",
            array($productId, $attrId)
        );
        if ($existing) {
            $write->update($varcharTbl, array('value' => $localUrl),
                array('entity_id = ?' => $productId, 'attribute_id = ?' => $attrId, 'store_id = ?' => 0));
        } else {
            $write->insert($varcharTbl, array(
                'entity_id' => $productId, 'attribute_id' => $attrId, 'store_id' => 0, 'value' => $localUrl,
            ));
        }
    }

    /** Disable (status=2) any local C-products not seen in this export run. */
    private function _disableRetiredCourses(array $seenSkus)
    {
        if (empty($seenSkus)) return 0;

        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $write    = $resource->getConnection('core_write');
        $tbl      = $resource;

        $localCSkus = $read->fetchCol(
            "SELECT sku FROM catalog_product_entity WHERE sku LIKE 'C%'"
        );
        $toDisable = array_diff($localCSkus, array_keys($seenSkus));
        if (empty($toDisable)) return 0;

        $statusAttrId = (int) $read->fetchOne(
            "SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status' LIMIT 1"
        );
        $count = 0;
        foreach ($toDisable as $sku) {
            $pid = (int) $read->fetchOne(
                "SELECT entity_id FROM catalog_product_entity WHERE sku = ? LIMIT 1", array($sku)
            );
            if ($pid === 0) continue;
            $intTbl = $tbl->getTableName('catalog_product_entity_int');
            $write->update($intTbl,
                array('value' => 2), // 2 = Disabled
                array('entity_id = ?' => $pid, 'attribute_id = ?' => $statusAttrId, 'store_id = ?' => 0)
            );
            $count++;
        }
        return $count;
    }

    /** Run catalog_url and flat catalog indexers. */
    private function _reindex()
    {
        $indexerCodes = array('catalog_url', 'catalog_product_flat', 'catalog_category_flat', 'catalogsearch_fulltext');
        foreach ($indexerCodes as $code) {
            try {
                $indexer = Mage::getModel('index/process')->load($code, 'indexer_code');
                if ($indexer && $indexer->getId()) {
                    $indexer->reindexAll();
                }
            } catch (Exception $e) {
                Mage::log('CourseSyncService: reindex ' . $code . ' failed: ' . $e->getMessage(), Zend_Log::WARN, self::LOG_FILE);
            }
        }
    }

    /** Write a run summary to mmd_course_sync_log. */
    private function _writeLog(array $s, $triggeredBy)
    {
        try {
            $write = Mage::getSingleton('core/resource')->getConnection('core_write');
            $logTbl = Mage::getSingleton('core/resource')->getTableName(self::LOG_TABLE);
            $status = $s['errors'] === 0 ? 'success' : ($s['created'] + $s['updated'] > 0 ? 'partial' : 'error');
            $msg = empty($s['error_msgs']) ? null : implode('; ', array_slice($s['error_msgs'], 0, 5));
            $write->insert($logTbl, array(
                'triggered_by' => (string)$triggeredBy,
                'fetched'      => $s['fetched'],
                'created'      => $s['created'],
                'updated'      => $s['updated'],
                'disabled'     => $s['disabled'],
                'skipped'      => $s['skipped'],
                'errors'       => $s['errors'],
                'status'       => $status,
                'message'      => $msg,
            ));
        } catch (Exception $e) {
            Mage::log('CourseSyncService: failed to write log: ' . $e->getMessage(), Zend_Log::WARN, self::LOG_FILE);
        }
    }

    /** Return the most recent log row, or null. */
    public function getLastLog()
    {
        try {
            $read   = Mage::getSingleton('core/resource')->getConnection('core_read');
            $logTbl = Mage::getSingleton('core/resource')->getTableName(self::LOG_TABLE);
            return $read->fetchRow("SELECT * FROM `$logTbl` ORDER BY log_id DESC LIMIT 1");
        } catch (Exception $e) {
            return null;
        }
    }
}
