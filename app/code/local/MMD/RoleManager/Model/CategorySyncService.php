<?php
/**
 * Country-side category sync: mirrors the SG course category tree onto this
 * franchisee instance. Companion to CourseSyncService (same config, same
 * X-API-Key, same log table).
 *
 * What it does per run:
 *   1. GETs SG's /courses/api_sync_export/categories endpoint — every SG
 *      category whose subtree holds a C-prefix course, parents-first, keyed
 *      by url_key path (no numeric IDs cross install).
 *   2. Walks each path, find-or-creates the category under the local default
 *      root (parent 2). A category created THIS run gets the full field port
 *      (name / is_active / include_in_menu / is_anchor / position /
 *      description / meta fields) at admin scope. A category that already
 *      existed — whether shared with SG or partner-only — is never touched
 *      again: partner-side customisation (a translated name, local SEO copy,
 *      a category the partner intentionally disabled) survives every
 *      subsequent run. Mirrors the same additive-only discipline as
 *      CourseSyncService's P1 fields / the schedule-sync merge.
 *   3. Never deletes or disables local categories absent from SG — extras
 *      (partner-specific branches) are left untouched.
 *   4. Reindexes catalog_url + category flat and flushes cache.
 *   5. Writes a row to mmd_course_sync_log.
 *
 * One-way SG -> country: only READS from SG's export endpoint, writes only
 * to the local DB.
 *
 * Flat-catalog trap: when catalog/frontend/flat_catalog_category = 1 the
 * category model binds the read-only flat resource and saves fail
 * (see memory feedback_category_model_save_under_flat) — so all model saves
 * run with flat temporarily disabled, restored in finally.
 */
class MMD_RoleManager_Model_CategorySyncService
{
    const LOG_FILE  = 'category-sync.log';
    const LOG_TABLE = 'mmd_course_sync_log';

    /** Category fields synced from SG (attribute code => category model key). */
    private static $_syncedAttrs = array(
        'name', 'is_active', 'include_in_menu', 'is_anchor',
        'description', 'meta_title', 'meta_description', 'meta_keywords',
    );

    public function getEndpointUrl()
    {
        $base = rtrim(trim((string) Mage::getStoreConfig(MMD_RoleManager_Model_CourseSyncService::URL_CONFIG_PATH)), '/');
        if ($base === '') return '';
        // The stored value may be a bare base URL or the full course-export
        // endpoint — normalise to the categories action either way.
        $base = preg_replace('#/courses/api_sync_export.*$#', '', $base);
        return $base . '/courses/api_sync_export/categories';
    }

    public function getApiKey()
    {
        return trim((string) Mage::getStoreConfig(MMD_RoleManager_Model_CourseSyncService::KEY_CONFIG_PATH));
    }

    public function isConfigured()
    {
        return $this->getEndpointUrl() !== '' && $this->getApiKey() !== '';
    }

    /**
     * Full pull: fetch the SG tree and upsert every category. Returns summary.
     */
    public function pull($triggeredBy = 'admin')
    {
        if (!$this->isConfigured()) {
            throw new Exception('SG sync URL / API key not configured (mmd/course_sync/sg_url + api_key).');
        }

        $summary = array(
            'fetched' => 0, 'created' => 0, 'updated' => 0,
            'disabled' => 0, 'skipped' => 0, 'errors' => 0,
            'error_msgs' => array(), 'success' => true,
        );

        $payload    = $this->_fetch();
        $categories = isset($payload['categories']) ? (array) $payload['categories'] : array();
        $summary['fetched'] = count($categories);

        // Disable category flat around the model saves (read-only flat
        // resource breaks creates/saves), restore whatever was set after.
        $flatPath = 'catalog/frontend/flat_catalog_category';
        $wasFlat  = (string) Mage::getStoreConfig($flatPath);
        $touched  = ($wasFlat !== '' && $wasFlat !== '0');
        if ($touched) {
            Mage::getConfig()->saveConfig($flatPath, '0', 'default', 0);
            Mage::getConfig()->reinit();
            Mage::app()->reinitStores();
        }

        try {
            // SG exports parents-first, so a plain walk creates in order.
            $pathIds = array(); // "uk/uk" => local entity_id (per-run cache)
            foreach ($categories as $c) {
                $path = trim((string) ($c['path'] ?? ''), '/');
                if ($path === '') { $summary['skipped']++; continue; }
                try {
                    $this->_upsertCategory($path, $c, $pathIds, $summary);
                } catch (Exception $e) {
                    $summary['errors']++;
                    $summary['error_msgs'][] = $path . ': ' . $e->getMessage();
                    Mage::log('CategorySyncService: error path=' . $path . ' ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
                }
            }
        } catch (Exception $e) {
            $summary['errors']++;
            $summary['error_msgs'][] = $e->getMessage();
        } finally {
            if ($touched) {
                Mage::getConfig()->saveConfig($flatPath, $wasFlat, 'default', 0);
                Mage::getConfig()->reinit();
                Mage::app()->reinitStores();
            }
        }

        try {
            $this->_reindex();
        } catch (Exception $e) {
            Mage::log('CategorySyncService: reindex error ' . $e->getMessage(), Zend_Log::WARN, self::LOG_FILE);
        }

        $summary['success'] = $summary['errors'] === 0;
        $this->_writeLog($summary, $triggeredBy);
        return $summary;
    }

    /**
     * Find-or-create the category at $path. Only a category created THIS
     * call gets SG's fields ported onto it — an already-existing one (leaf
     * or ancestor) is left completely untouched. $pathIds caches resolved
     * local IDs per url_key path for the run.
     */
    private function _upsertCategory($path, array $c, array &$pathIds, array &$summary)
    {
        $segments = array_filter(explode('/', $path));
        $parentId = 2; // default root
        $walked   = array();
        $catId    = null;
        $isNew    = false;

        foreach ($segments as $urlKey) {
            $walked[] = $urlKey;
            $walkPath = implode('/', $walked);
            if (isset($pathIds[$walkPath])) {
                $catId = $pathIds[$walkPath];
                $isNew = false;
            } else {
                $catId = $this->_findByUrlKey($urlKey, $parentId);
                if ($catId === 0) {
                    // Ancestors are exported before children, so a miss can
                    // only be the leaf itself (or a gap SG couldn't address).
                    $parent = Mage::getModel('catalog/category')->setStoreId(0)->load($parentId);
                    $cat    = Mage::getModel('catalog/category');
                    $cat->setStoreId(0)
                        ->setPath($parent->getPath())
                        ->setParentId($parentId)
                        ->setName(ucwords(str_replace('-', ' ', $urlKey)))
                        ->setUrlKey($urlKey)
                        ->setIsActive(1)
                        ->setIsAnchor(1)
                        ->setIncludeInMenu(1);
                    $cat->save();
                    $catId = (int) $cat->getId();
                    $isNew = true;
                } else {
                    $isNew = false;
                }
                $pathIds[$walkPath] = $catId;
            }
            $parentId = $catId;
        }

        if (!$catId) {
            $summary['skipped']++;
            return;
        }

        if (!$isNew) {
            // Already existed before this run — never touched again, so
            // partner-side edits to a shared category survive every
            // subsequent sync (same discipline as the schedule-sync merge).
            $summary['skipped']++;
            return;
        }

        // First sync for this category — full port of SG's exported fields.
        $cat = Mage::getModel('catalog/category')->setStoreId(0)->load($catId);
        foreach (self::$_syncedAttrs as $code) {
            if (!array_key_exists($code, $c) || $c[$code] === null) continue;
            $cat->setData($code, is_int($c[$code]) ? $c[$code] : (string) $c[$code]);
        }
        if (isset($c['position'])) {
            $cat->setPosition((int) $c['position']);
        }
        $cat->save();
        $summary['created']++;
    }

    /** Resolve a url_key under a parent to a local category ID (0 = none). */
    private function _findByUrlKey($urlKey, $parentId)
    {
        $read     = Mage::getSingleton('core/resource')->getConnection('core_read');
        $ukAttrId = (int) $read->fetchOne(
            "SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key' LIMIT 1"
        );
        return (int) $read->fetchOne(
            "SELECT e.entity_id FROM catalog_category_entity e
             JOIN catalog_category_entity_varchar v
               ON v.entity_id = e.entity_id AND v.attribute_id = ? AND v.store_id = 0 AND v.value = ?
             WHERE e.parent_id = ? LIMIT 1",
            array($ukAttrId, $urlKey, $parentId)
        );
    }

    /** GET the SG categories export. */
    private function _fetch()
    {
        $ch = curl_init($this->getEndpointUrl());
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_MAXREDIRS      => 5,
            CURLOPT_TIMEOUT        => 120,
            CURLOPT_CONNECTTIMEOUT => 15,
            CURLOPT_USERAGENT      => 'Mozilla/5.0 (compatible; MMD-CategorySync/1.0)',
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
            throw new Exception('SG category export failed: ' . $msg);
        }
        return $rsp;
    }

    /** Reindex URL rewrites + category flat so the storefront menu updates. */
    private function _reindex()
    {
        foreach (array('catalog_url', 'catalog_category_flat') as $code) {
            try {
                $indexer = Mage::getModel('index/process')->load($code, 'indexer_code');
                if ($indexer && $indexer->getId()) {
                    $indexer->reindexAll();
                }
            } catch (Exception $e) {
                Mage::log('CategorySyncService: reindex ' . $code . ' failed: ' . $e->getMessage(), Zend_Log::WARN, self::LOG_FILE);
            }
        }
        try {
            Mage::app()->getCacheInstance()->flush();
        } catch (Exception $e) {
            Mage::log('CategorySyncService: cache flush failed: ' . $e->getMessage(), Zend_Log::WARN, self::LOG_FILE);
        }
    }

    /** Write a run summary to mmd_course_sync_log (shared with course sync). */
    private function _writeLog(array $s, $triggeredBy)
    {
        try {
            $write  = Mage::getSingleton('core/resource')->getConnection('core_write');
            $logTbl = Mage::getSingleton('core/resource')->getTableName(self::LOG_TABLE);
            $status = $s['errors'] === 0 ? 'success' : ($s['created'] + $s['updated'] > 0 ? 'partial' : 'error');
            $msg    = empty($s['error_msgs']) ? null : implode('; ', array_slice($s['error_msgs'], 0, 5));
            $write->insert($logTbl, array(
                'triggered_by' => (string) $triggeredBy . ' (categories)',
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
            Mage::log('CategorySyncService: failed to write log: ' . $e->getMessage(), Zend_Log::WARN, self::LOG_FILE);
        }
    }
}
