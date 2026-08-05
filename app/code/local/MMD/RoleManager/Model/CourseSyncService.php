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
     * Kept as an independent local constant rather than a cross-module
     * reference — AgentApi/Model/Schedule.php and AgentApi/Model/Template.php
     * each already define their own copy of this same string rather than
     * RoleManager depending on AgentApi for one literal.
     */
    const COURSE_DATE_OPTION_TITLE = 'Course Date';

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

        // Flat-catalog trap, both halves (category-side precedent: see
        // CategorySyncService). _upsertCourse() swaps into admin store scope
        // around $product->save() (see the comment there for why), and while
        // in that scope any product-save-triggered category reindexing would
        // otherwise look up catalog_category_flat_store_0 — which never
        // exists, flat tables are only ever generated per REAL store — and
        // fatal with "table doesn't exist". Disabling flat_catalog_category
        // for the duration sidesteps that. flat_catalog_product is disabled
        // too, defensively — the pre-existing setStoreId(0) comment below
        // documents a related (if not identical) historical flat-resource
        // incident on this exact save path.
        $flatPaths = array('catalog/frontend/flat_catalog_product', 'catalog/frontend/flat_catalog_category');
        $wasFlat = array();
        $touchedFlat = false;
        foreach ($flatPaths as $fp) {
            $wasFlat[$fp] = (string) Mage::getStoreConfig($fp);
            if ($wasFlat[$fp] !== '' && $wasFlat[$fp] !== '0') {
                Mage::getConfig()->saveConfig($fp, '0', 'default', 0);
                $touchedFlat = true;
            }
        }
        if ($touchedFlat) {
            Mage::getConfig()->reinit();
            Mage::app()->reinitStores();
        }

        try {
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
        } finally {
            if ($touchedFlat) {
                foreach ($flatPaths as $fp) {
                    Mage::getConfig()->saveConfig($fp, $wasFlat[$fp], 'default', 0);
                }
                Mage::getConfig()->reinit();
                Mage::app()->reinitStores();
            }
        }

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

        // Same flat-catalog trap as pull() — see the comment there.
        $flatPaths = array('catalog/frontend/flat_catalog_product', 'catalog/frontend/flat_catalog_category');
        $wasFlat = array();
        $touchedFlat = false;
        foreach ($flatPaths as $fp) {
            $wasFlat[$fp] = (string) Mage::getStoreConfig($fp);
            if ($wasFlat[$fp] !== '' && $wasFlat[$fp] !== '0') {
                Mage::getConfig()->saveConfig($fp, '0', 'default', 0);
                $touchedFlat = true;
            }
        }
        if ($touchedFlat) {
            Mage::getConfig()->reinit();
            Mage::app()->reinitStores();
        }
        try {
            $isNew = $this->_upsertCourse($courses[0]);
            if ($isNew) $summary['created']++;
            else        $summary['updated']++;
        } catch (Exception $e) {
            $summary['errors']++;
            $summary['error_msgs'][] = $sku . ': ' . $e->getMessage();
            Mage::log('CourseSyncService: pullOne error sku=' . $sku . ' ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
        } finally {
            if ($touchedFlat) {
                foreach ($flatPaths as $fp) {
                    Mage::getConfig()->saveConfig($fp, $wasFlat[$fp], 'default', 0);
                }
                Mage::getConfig()->reinit();
                Mage::app()->reinitStores();
            }
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
                    $this->_mergeScheduleOptions($localId, $options);
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

    /**
     * Courseware sync (bulk): fill-blanks-only merge of SG's courseware
     * links into every C-prefix course that already exists locally.
     * Deliberate manual retrigger — never runs as part of the regular
     * course pull() (which only ports courseware on first-sync CREATE, see
     * _upsertCourse()). Products absent locally are skipped (run Course
     * Sync first). No product save happens here, so no flat-catalog
     * handling is needed — plain course_courseware row upserts.
     */
    public function pullCourseware($triggeredBy = 'admin')
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
                    $courseware = isset($course['courseware']) && is_array($course['courseware'])
                        ? $course['courseware'] : array();
                    $this->_mergeCourseware($localId, $courseware);
                    $summary['updated']++;
                } catch (Exception $e) {
                    $summary['errors']++;
                    $summary['error_msgs'][] = $sku . ': ' . $e->getMessage();
                    Mage::log('CourseSyncService: courseware error sku=' . $sku . ' ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
                }
            }

            $totalPages = isset($payload['total_pages']) ? (int) $payload['total_pages'] : 1;
            $page++;
        } while ($page <= $totalPages);

        $summary['success'] = $summary['errors'] === 0;
        $this->_writeLog($summary, $triggeredBy . ' (courseware)');
        return $summary;
    }

    /**
     * Courseware sync (single SKU): same fill-blanks merge as
     * pullCourseware(), for exactly one already-imported course — the
     * manual per-course retrigger button on the country-mode Manage
     * Courses page. Errors if the course doesn't exist locally yet.
     */
    public function pullCoursewareOne($sku, $triggeredBy = 'admin')
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

        $localId = (int) Mage::getModel('catalog/product')->getIdBySku($sku);
        if ($localId === 0) {
            throw new Exception($sku . ' has not been synced from SG yet — run Course Sync first.');
        }

        $payload = $this->_fetchPage(1, 1, $sku);
        $courses = isset($payload['courses']) ? (array) $payload['courses'] : array();
        if (empty($courses)) {
            throw new Exception('SG returned no course for ' . $sku);
        }
        $summary['fetched'] = 1;

        try {
            $courseware = isset($courses[0]['courseware']) && is_array($courses[0]['courseware'])
                ? $courses[0]['courseware'] : array();
            $this->_mergeCourseware($localId, $courseware);
            $summary['updated']++;
        } catch (Exception $e) {
            $summary['errors']++;
            $summary['error_msgs'][] = $sku . ': ' . $e->getMessage();
            Mage::log('CourseSyncService: pullCoursewareOne error sku=' . $sku . ' ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
        }

        $summary['success'] = $summary['errors'] === 0;
        $this->_writeLog($summary, $triggeredBy . ' (courseware single: ' . $sku . ')');
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

        // Mage_Catalog_Model_Product::setOrigData() is a stock no-op unless
        // Mage::app()->getStore()->isAdmin() — a storefront-save perf
        // shortcut that assumes orig-data tracking is only ever needed from
        // the admin. Course Sync now also runs from the frontend-area
        // TriggerController (/courses/api_sync_trigger), so without this,
        // _getOrigObject()->getOrigData() comes back null on every UPDATE
        // and Mage_Eav_Model_Entity_Abstract::_collectSaveData()'s foreach
        // over it throws. Swap into admin scope for just the save, restore
        // after — mirrors the setStoreId(0) trick above for the same class
        // of "this must look like an admin operation" requirement.
        $prevStore = Mage::app()->getStore();
        $swappedStore = !$prevStore->isAdmin();
        if ($swappedStore) {
            Mage::app()->setCurrentStore(Mage::app()->getStore(Mage_Core_Model_App::ADMIN_STORE_ID));
        }
        try {
            $product->save();
        } finally {
            if ($swappedStore) {
                Mage::app()->setCurrentStore($prevStore);
            }
        }
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

        // Courseware — CREATE only, same P1 shape as custom options above.
        // Subsequent re-syncs of courseware are a deliberate, separate manual
        // action (pullCourseware() / pullCoursewareOne()), never bundled here.
        if ($isNew && isset($c['courseware']) && is_array($c['courseware'])) {
            $this->_mergeCourseware($savedId, $c['courseware']);
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

    /**
     * Additive-merge replacement for _recreateCustomOptions() used by
     * syncSchedules(). Grouped by option title (e.g. "Course Date"):
     *   - No local option with that title yet -> first-sync full port via
     *     saveOption()/saveOptionValue(), which (unlike _recreateCustomOptions())
     *     correctly writes custom_options_option_view_mode, fixing the
     *     invisible-option bug.
     *   - Local option already exists -> additive merge only. The option row
     *     itself (title/sort_order/view_mode) is never touched; only SG
     *     values not already present locally (case/whitespace-insensitive)
     *     get appended. An existing "Course Date" option additionally has any
     *     value whose parsed end date is before today pruned — unconditionally,
     *     including admin_managed=1 values (confirmed requirement: a stale
     *     date is stale regardless of who added it). Unparseable titles are
     *     left alone.
     */
    private function _mergeScheduleOptions($productId, array $sgOptions)
    {
        /** @var MMD_CustomOptions_Model_Catalog_Product_Option $optionModel */
        $optionModel = Mage::getModel('customoptions/catalog_product_option');

        // Group by title — SG's export should already be one entry per
        // title, but merge defensively rather than assume.
        $byTitle = array();
        foreach ($sgOptions as $opt) {
            $title = trim((string) ($opt['title'] ?? ''));
            if ($title === '') continue;
            if (!isset($byTitle[$title])) {
                $byTitle[$title] = array(
                    'type'       => (string) ($opt['type'] ?? 'drop_down'),
                    'sort_order' => (int) ($opt['sort_order'] ?? 0),
                    'values'     => array(),
                );
            }
            if (!empty($opt['values']) && is_array($opt['values'])) {
                $byTitle[$title]['values'] = array_merge($byTitle[$title]['values'], $opt['values']);
            }
        }

        foreach ($byTitle as $title => $group) {
            $localOptionId = $this->_findLocalOptionIdByTitle($productId, $title);

            if ($localOptionId === 0) {
                // First sync for this option title — full port.
                $localOptionId = (int) $optionModel->saveOption($productId, array(
                    'type'            => $group['type'],
                    'is_require'      => 0,
                    'sort_order'      => $group['sort_order'],
                    'title'           => $title,
                    'view_mode'       => 1,
                    'customer_groups' => '',
                ), 0, 0, $group['type']);

                foreach ($group['values'] as $v) {
                    $vTitle = trim((string) ($v['title'] ?? ''));
                    if ($vTitle === '') continue;
                    $optionModel->saveOptionValue($localOptionId, array(
                        'sku'        => $v['sku'] ?? null,
                        'sort_order' => (int) ($v['sort_order'] ?? 0),
                        'title'      => $vTitle,
                        'price'      => (float) ($v['price'] ?? 0),
                        'price_type' => $v['price_type'] ?? 'fixed',
                    ), array(), array(), 0, 0);
                }
                continue; // first sync — pruning is scoped to existing options only
            }

            // Existing option — additive merge only, option row untouched.
            $existingTitles = $this->_normalizedValueTitles($localOptionId);
            foreach ($group['values'] as $v) {
                $vTitle = trim((string) ($v['title'] ?? ''));
                if ($vTitle === '') continue;
                $norm = $this->_normalizeTitle($vTitle);
                if (isset($existingTitles[$norm])) continue; // already present locally
                $optionModel->saveOptionValue($localOptionId, array(
                    'sku'        => $v['sku'] ?? null,
                    'sort_order' => (int) ($v['sort_order'] ?? 0),
                    'title'      => $vTitle,
                    'price'      => (float) ($v['price'] ?? 0),
                    'price_type' => $v['price_type'] ?? 'fixed',
                ), array(), array(), 0, 0);
                $existingTitles[$norm] = true; // avoid re-adding a dup within this same payload
            }

            if ($this->_normalizeTitle($title) === $this->_normalizeTitle(self::COURSE_DATE_OPTION_TITLE)) {
                $this->_pruneStalePastDates($localOptionId);
            }
        }

        $optionModel->updateProductFlags($productId);
    }

    /** trim + collapse internal whitespace + case-fold, mirrors the existing strcasecmp(trim(...)) pattern in _findOrCreateOption. */
    private function _normalizeTitle($s)
    {
        return strtolower(trim(preg_replace('/\s+/', ' ', (string) $s)));
    }

    /** Find a product's local custom-option id by title (normalized match), or 0. */
    private function _findLocalOptionIdByTitle($productId, $title)
    {
        $read = Mage::getSingleton('core/resource')->getConnection('core_read');
        $tbl  = Mage::getSingleton('core/resource');
        $rows = $read->fetchPairs(
            "SELECT o.option_id, t.title
             FROM " . $tbl->getTableName('catalog_product_option') . " o
             JOIN " . $tbl->getTableName('catalog_product_option_title') . " t
               ON t.option_id = o.option_id AND t.store_id = 0
             WHERE o.product_id = ?",
            array($productId)
        );
        $norm = $this->_normalizeTitle($title);
        foreach ($rows as $optionId => $optTitle) {
            if ($this->_normalizeTitle($optTitle) === $norm) return (int) $optionId;
        }
        return 0;
    }

    /** Normalized set of existing value titles under a given option_id. */
    private function _normalizedValueTitles($optionId)
    {
        $read = Mage::getSingleton('core/resource')->getConnection('core_read');
        $tbl  = Mage::getSingleton('core/resource');
        $rows = $read->fetchCol(
            "SELECT t.title
             FROM " . $tbl->getTableName('catalog_product_option_type_value') . " v
             JOIN " . $tbl->getTableName('catalog_product_option_type_title') . " t
               ON t.option_type_id = v.option_type_id AND t.store_id = 0
             WHERE v.option_id = ?",
            array($optionId)
        );
        $set = array();
        foreach ($rows as $t) {
            $set[$this->_normalizeTitle($t)] = true;
        }
        return $set;
    }

    /**
     * Delete "Course Date" values whose parsed end date is before today.
     * Applies unconditionally, including admin_managed=1 values — confirmed
     * requirement, a deliberate departure from the admin_managed protection
     * AgentApi/Model/Template.php's reconciliation otherwise respects.
     * Unparseable titles are left alone (can't confidently prove they're past).
     */
    private function _pruneStalePastDates($optionId)
    {
        $read  = Mage::getSingleton('core/resource')->getConnection('core_read');
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $tbl   = Mage::getSingleton('core/resource');

        $rows = $read->fetchAll(
            "SELECT v.option_type_id, t.title
             FROM " . $tbl->getTableName('catalog_product_option_type_value') . " v
             JOIN " . $tbl->getTableName('catalog_product_option_type_title') . " t
               ON t.option_type_id = v.option_type_id AND t.store_id = 0
             WHERE v.option_id = ?",
            array($optionId)
        );

        /** @var MMD_RoleManager_Model_CourseRunEnrolmentService $dateParser */
        $dateParser = Mage::getModel('mmd_rolemanager/courseRunEnrolmentService');
        $today = date('Y-m-d');

        foreach ($rows as $row) {
            $parsed = $dateParser->_parseDate($row['title']);
            if ($parsed === null) continue; // can't confidently prove it's past
            $end = $parsed[1];
            if ($end >= $today) continue;

            $otid = (int) $row['option_type_id'];
            foreach (array('catalog_product_option_type_value', 'catalog_product_option_type_title', 'catalog_product_option_type_price') as $t) {
                $write->delete($tbl->getTableName($t), array('option_type_id = ?' => $otid));
            }
        }
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

    /**
     * Fill-blanks-only merge of courseware links into course_courseware.
     * Once the partner has set a field locally (non-empty), SG never
     * overwrites it again — same P1 pattern as price/trainer info. On a
     * brand-new local row (no existing course_courseware yet) every field
     * is blank, so this behaves as a full port.
     */
    private function _mergeCourseware($productId, array $sg)
    {
        $fields = array(
            'lesson_plan_url', 'learner_guide_url', 'learner_slides_url',
            'trainer_slides_url', 'lab_url', 'courseware_link', 'brochure_link',
            'google_meet_url', 'certificate_url',
        );

        $read  = Mage::getSingleton('core/resource')->getConnection('core_read');
        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $tbl   = Mage::getSingleton('core/resource')->getTableName('course_courseware');

        $existing = $read->fetchRow("SELECT * FROM `$tbl` WHERE product_id = ?", array($productId));

        $data = array();
        foreach ($fields as $f) {
            $localVal = $existing ? trim((string) ($existing[$f] ?? '')) : '';
            if ($localVal !== '') continue; // partner already set this — never overwrite (P1)
            $sgVal = isset($sg[$f]) ? trim((string) $sg[$f]) : '';
            if ($sgVal === '') continue; // nothing to fill in from SG either
            $data[$f] = $sgVal;
        }

        if (empty($data)) return;

        if ($existing) {
            $write->update($tbl, $data, array('id = ?' => (int) $existing['id']));
        } else {
            $data['product_id'] = $productId;
            $write->insert($tbl, $data);
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
