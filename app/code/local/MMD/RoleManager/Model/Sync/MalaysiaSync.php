<?php
/**
 * Malaysia-aware SG -> Malaysia sync (group decision 6B). Used instead of the plain
 * CourseSyncService / CategorySyncService pull when this site is the Malaysia partner
 * (store 'malaysia', MMS_MODE=country). Singapore and Ghana keep the existing sync.
 *
 * Two steps, so nothing changes without review:
 *   plan*()   — dry run: reads SG's export, works out every change and stores it (with the
 *               exact before values) in mmd_my_sync_run / mmd_my_sync_change. Writes nothing
 *               else. The stored rows ARE the dry-run report.
 *   apply()   — applies exactly the planned values of one recent planned run. A change whose
 *               field was edited on Malaysia since the dry run is skipped as a conflict.
 *   rollback()— restores every before value of an applied run, deletes drafts / categories /
 *               redirects it created.
 *
 * Rules (see MMD_RoleManager_Model_Sync_MyLocaliser for the wording rules):
 *   - copied from SG: title, overview / outline / outcomes / prerequisites / audience, note,
 *     duration, sessions, level; all text localised. Shared categories are ADDED only — a course is
 *     never taken out of a Malaysia category. Cover images are not copied (Malaysia keeps its own;
 *     new drafts start with SG's cover). Both group decisions of 14 Oct.
 *   - generated for Malaysia: meta title (= title), meta description (<= 160), keywords
 *     without SG terms, URL key without singapore / wsq / skillsfuture tokens
 *   - NEVER touched on Malaysia: price, special price, trainer, venue / delivery options,
 *     schedules and every other custom option, status, checkout and payment settings
 *   - a changed URL gets one-step 301s from every old URL (enabled courses), and older
 *     redirects pointing at an old URL are re-pointed (no chains)
 *   - new SG courses are created as DISABLED drafts: Malaysia fee by the per-day rule, SG
 *     option prices zeroed, evening labels "(…, 2 evenings)"; staff review and publish
 *   - Singapore-only categories (WSQ / SkillsFuture / IBF / UTAP / PSEA / SFEC) and SG
 *     funding badges are never imported; new shared categories are created hidden
 *   - courses retired on SG and fee changes implied by a new duration are reported only
 *   - the schedules op is refused: Malaysia manages its own class dates
 */
class MMD_RoleManager_Model_Sync_MalaysiaSync extends MMD_RoleManager_Model_CourseSyncService
{
    const STORE        = 2;
    const RUN_TTL_HRS  = 48;
    const PROTECTED_FIELDS_PATH = 'mmd/my_sync/protected_fields';
    const RUN_TABLE    = 'mmd_my_sync_run';
    const CHANGE_TABLE = 'mmd_my_sync_change';
    const RATE_NORMAL  = 1100;
    const RATE_CERT    = 1500;

    private static $_contentFields = array('short_description', 'description', 'course_lo_html',
        'prerequisite', 'whoshouldattend', 'additional_note');
    private static $_categoryFields = array('name', 'description', 'meta_description', 'meta_keywords');

    /** @var MMD_RoleManager_Model_Sync_MyLocaliser */
    protected $_loc;
    protected $_attrs = array();
    protected $_seq = 0;
    protected $_historySnap = array();

    /** Malaysia partner site? */
    public static function isActive()
    {
        $store = Mage::app()->getDefaultStoreView();
        return $store && $store->getCode() === 'malaysia' && strtolower((string) getenv('MMS_MODE')) === 'country';
    }

    // ------------------------------------------------------------------ dry run

    /** Dry run for courses (all, or one SKU). Returns the run summary incl. run_id. */
    public function planCourses($by, $sku = null)
    {
        if (!$this->isConfigured()) {
            throw new Exception('SG sync URL / API key not configured (mmd/course_sync/sg_url + api_key).');
        }
        $courses = array();
        if ($sku !== null && $sku !== '') {
            $payload = $this->_fetchPage(1, 1, $sku);
            $courses = isset($payload['courses']) ? (array) $payload['courses'] : array();
            if (!$courses) {
                throw new Exception('SG returned no course for ' . $sku);
            }
        } else {
            $page = 1;
            do {
                $payload = $this->_fetchPage($page, 50);
                $courses = array_merge($courses, isset($payload['courses']) ? (array) $payload['courses'] : array());
                $total = isset($payload['total_pages']) ? (int) $payload['total_pages'] : 1;
                $page++;
            } while ($page <= $total);
        }

        $runId = $this->_startRun('courses', $by, $sku);
        $sum = array('fetched' => count($courses), 'courses_changed' => 0, 'drafts' => 0, 'field_changes' => 0,
            'category_changes' => 0, 'redirects' => 0, 'notices' => 0, 'skipped' => 0);
        $seen = array();
        foreach ($courses as $c) {
            $code = trim((string) ($c['sku'] ?? ''));
            if ($code === '' || strtoupper($code[0]) !== 'C') {
                $sum['skipped']++;
                continue;
            }
            $seen[$code] = true;
            $pid = (int) Mage::getModel('catalog/product')->getIdBySku($code);
            $sgEnabled = (int) ($c['status'] ?? 1) === 1;
            if (!$pid) {
                if ($sgEnabled) {
                    $this->_change($runId, 'product', null, $code, 'create', null, null, $this->_draftPayload($c));
                    $sum['drafts']++;
                } else {
                    $sum['skipped']++;
                }
                continue;
            }
            if (!$sgEnabled) {
                if ($this->_productEnabled($pid)) {
                    $this->_notice($runId, 'product', $pid, $code, 'Retired on Singapore — still enabled on Malaysia (review).');
                    $sum['notices']++;
                }
                continue;
            }
            $n = $this->_planCourseUpdate($runId, $pid, $code, $c, $sum);
            if ($n) {
                $sum['courses_changed']++;
            }
        }
        if ($sku === null || $sku === '') {
            $read = $this->_read();
            foreach ($read->fetchCol("SELECT sku FROM catalog_product_entity WHERE sku LIKE 'C%'") as $local) {
                if (!isset($seen[$local]) && $this->_productEnabled((int) Mage::getModel('catalog/product')->getIdBySku($local))) {
                    $this->_notice($runId, 'product', null, $local, 'Not in the Singapore export — Malaysia-only course kept as is.');
                    $sum['notices']++;
                }
            }
        }
        return $this->_finishPlan($runId, $sum);
    }

    /** Dry run for the category tree. */
    public function planCategories($by)
    {
        $payload = Mage::getModel('mmd_rolemanager/categorySyncService')->fetchExport();
        $cats = isset($payload['categories']) ? (array) $payload['categories'] : array();
        $runId = $this->_startRun('categories', $by, null);
        $sum = array('fetched' => count($cats), 'categories_changed' => 0, 'field_changes' => 0,
            'new_hidden' => 0, 'skipped_sg_only' => 0, 'notices' => 0);
        $loc = $this->_loc();
        $planned = array();   // url keys created in this plan (parents-first export)
        foreach ($cats as $c) {
            $path = trim((string) ($c['path'] ?? ''), '/');
            $parts = array_values(array_filter(explode('/', $path)));
            if (!$parts) {
                continue;
            }
            $key = end($parts);
            $name = trim((string) ($c['name'] ?? ''));
            if ($loc->isSgOnlyCategory($key, $name)) {
                $sum['skipped_sg_only']++;
                continue;
            }
            $want = array(
                'name'             => $name,
                'description'      => $loc->localise((string) ($c['description'] ?? '')),
                'meta_description' => $loc->metaDescription((string) ($c['meta_description'] ?? '')),
                'meta_keywords'    => $loc->keywords((string) ($c['meta_keywords'] ?? '')),
            );
            $catId = $this->_categoryByKey($key);
            if (!$catId) {
                $parentKey = count($parts) > 1 ? $parts[count($parts) - 2] : null;
                if ($parentKey !== null && !$this->_categoryByKey($parentKey) && !isset($planned[$parentKey])) {
                    $this->_notice($runId, 'category', null, $key, "Parent category '$parentKey' is not on Malaysia — not created.");
                    $sum['notices']++;
                    continue;
                }
                $this->_change($runId, 'category', null, $key, 'create', null, null,
                    array('url_key' => $key, 'parent_key' => $parentKey) + $want);
                $planned[$key] = true;
                $sum['new_hidden']++;
                continue;
            }
            $changed = 0;
            foreach (self::$_categoryFields as $f) {
                if ($want[$f] === '' && $f !== 'name') {
                    continue;   // SG has nothing — keep Malaysia's
                }
                $changed += $this->_planAttr($runId, 'category', $catId, $key, $f, $want[$f]);
            }
            if ($changed) {
                $sum['categories_changed']++;
                $sum['field_changes'] += $changed;
            }
        }
        return $this->_finishPlan($runId, $sum);
    }

    protected function _planCourseUpdate($runId, $pid, $sku, array $c, array &$sum)
    {
        $a = (array) $c['attributes'];
        $loc = $this->_loc();
        $n = 0;
        $name = trim(html_entity_decode((string) $a['name'], ENT_QUOTES, 'UTF-8'));
        $oldKey = (string) $this->_effective('product', $pid, 'url_key');
        $newKey = $loc->urlKey($a['url_key'] ?? '');
        if ($newKey !== '' && $newKey !== $oldKey && $this->_urlKeyTaken($newKey, $pid)) {
            $this->_notice($runId, 'product', $pid, $sku, "URL key '$newKey' is used by another course — URL kept.");
            $sum['notices']++;
            $newKey = $oldKey;
        }
        $want = array(
            'name' => $name, 'meta_title' => $name,
            'url_key' => $newKey, 'url_path' => $newKey . '.html',
            'meta_description' => $loc->metaDescription($a['meta_description'] ?? ''),
            'meta_keyword' => $loc->keywords($a['meta_keyword'] ?? ''),
            'duration' => (string) ($a['duration'] ?? ''), 'sessions' => (string) ($a['sessions'] ?? ''),
            'level' => $this->_optionId('product', 'level', (string) ($a['level'] ?? '')),
        );
        foreach (self::$_contentFields as $f) {
            $want[$f] = $loc->localise($a[$f] ?? '');
            if (trim(strip_tags($want[$f])) === '') {
                $want[$f] = '';
            }
        }
        $oldDuration = (string) $this->_effective('product', $pid, 'duration');
        // "SKU:field" pairs Malaysia fixed by hand (e.g. "C523:prerequisite") — never overwritten by the sync
        $protected = array_map('trim', explode(',', (string) Mage::getStoreConfig(self::PROTECTED_FIELDS_PATH)));
        foreach ($want as $f => $v) {
            if ($v === '' || $v === null || ($f === 'url_key' && $newKey === '')) {
                continue;   // SG has nothing — keep Malaysia's value
            }
            if (in_array($sku . ':' . $f, $protected, true)) {
                continue;   // Malaysia-owned wording
            }
            $n += $this->_planAttr($runId, 'product', $pid, $sku, $f, $v);
        }
        $sum['field_changes'] += $n;

        // fee review when the number of training days changes (fees are never synced)
        if ($want['duration'] !== '' && $oldDuration !== '' && $this->_days($oldDuration) !== $this->_days($want['duration'])) {
            $price = (float) $this->_effective('product', $pid, 'price');
            $this->_notice($runId, 'product', $pid, $sku, sprintf('Duration %s -> %s days: fee stays RM%s — by the Malaysia rule it would be RM%s (review).',
                $this->_days($oldDuration), $this->_days($want['duration']), number_format($price, 0),
                number_format($this->_days($want['duration']) * $this->_rate((array) ($c['categories'] ?? array())), 0)));
            $sum['notices']++;
        }

        // one-step 301s from every old URL when the URL key changes (enabled courses only)
        if ($newKey !== $oldKey && $this->_productEnabled($pid)) {
            foreach ($this->_read()->fetchCol("SELECT request_path FROM core_url_rewrite WHERE store_id = ? AND product_id = ? AND is_system = 1",
                array(self::STORE, $pid)) as $path) {
                $this->_change($runId, 'product', $pid, $sku, 'redirect', null, $path, $newKey . '.html');
                $sum['redirects']++;
            }
        }

        // shared categories (Singapore-only and retired ones never used)
        $wantCats = array();
        foreach ((array) ($c['categories'] ?? array()) as $path) {
            $key = basename((string) $path);
            if ($loc->isSgOnlyCategory($key)) {
                continue;
            }
            $id = $this->_categoryByKey($key);
            if ($id) {
                $wantCats[$id] = true;
            }
        }
        if ($wantCats) {
            $have = $this->_productCategoryPositions($pid);   // category_id => position (restored on rollback)
            // add-only: Malaysia's own category assignments are never removed (group decision 14 Oct)
            $catIds = array_values(array_unique(array_merge(array_map('intval', array_keys($have)), array_keys($wantCats))));
            sort($catIds);
            if ($this->_productCategories($pid) !== $catIds) {
                $this->_change($runId, 'product', $pid, $sku, 'categories', null, (object) $have, $catIds);
                $sum['category_changes']++;
                $n++;
            }
        }
        return $n;
    }

    /** New SG course -> disabled Malaysia draft (applied by _createDraft()). */
    protected function _draftPayload(array $c)
    {
        $a = (array) $c['attributes'];
        $loc = $this->_loc();
        $name = trim(html_entity_decode((string) $a['name'], ENT_QUOTES, 'UTF-8'));
        $key = $loc->urlKey($a['url_key'] ?? '') ?: $loc->urlKey(preg_replace('/[^a-z0-9]+/i', '-', $name));
        if ($this->_urlKeyTaken($key, 0)) {
            $key .= '-my';
        }
        $attrs = array(
            'name' => $name, 'meta_title' => $name, 'url_key' => $key,
            'meta_description' => $loc->metaDescription($a['meta_description'] ?? ''),
            'meta_keyword' => $loc->keywords($a['meta_keyword'] ?? ''),
            'duration' => (string) ($a['duration'] ?? ''), 'sessions' => (string) ($a['sessions'] ?? ''),
            'level' => (string) ($a['level'] ?? ''), 'course_image_url' => (string) ($a['course_image_url'] ?? ''),
            'agegroup' => (string) ($a['agegroup'] ?? ''),
        );
        foreach (self::$_contentFields as $f) {
            $attrs[$f] = $loc->localise($a[$f] ?? '');
        }
        $cats = array();
        foreach ((array) ($c['categories'] ?? array()) as $path) {
            $k = basename((string) $path);
            if (!$loc->isSgOnlyCategory($k) && ($id = $this->_categoryByKey($k))) {
                $cats[] = $id;
            }
        }
        $options = array();
        foreach ((array) ($c['custom_options'] ?? array()) as $o) {
            foreach ((array) ($o['values'] ?? array()) as $i => $v) {
                $o['values'][$i]['title'] = $loc->eveningLabel((string) ($v['title'] ?? ''));
                $o['values'][$i]['price'] = '0';   // never import Singapore option fees
            }
            $options[] = $o;
        }
        return array(
            'sku' => trim((string) $c['sku']), 'type_id' => (string) ($c['type_id'] ?? 'virtual'),
            'attribute_set' => (string) ($c['attribute_set'] ?? 'Courses'),
            'price' => $this->_days($attrs['duration']) * $this->_rate((array) ($c['categories'] ?? array())),
            'attrs' => array_filter($attrs, function ($v) { return $v !== ''; }),
            'categories' => array_values(array_unique($cats)), 'options' => $options,
        );
    }

    // ------------------------------------------------------------------ apply / rollback

    public function apply($runId, $by)
    {
        $run = $this->getRun($runId);
        if (!$run || $run['status'] !== 'planned') {
            throw new Exception('Only a planned (dry-run) sync can be applied.');
        }
        if (strtotime($run['planned_at']) < time() - self::RUN_TTL_HRS * 3600) {
            throw new Exception('This dry run is older than ' . self::RUN_TTL_HRS . ' hours — run a new dry run first.');
        }
        $w = $this->_write();
        $done = array('applied' => 0, 'conflicts' => 0, 'errors' => 0);
        $changes = $this->getChanges($runId);
        $this->_seq = $changes ? (int) max(array_column($changes, 'seq')) : 0;   // apply-time audit rows follow the plan
        $redirects = array();
        $this->_withCategoryFlatOff(function () use ($changes, $w, &$done, &$redirects) {
            foreach ($changes as $ch) {
                if ($ch['kind'] === 'notice') {
                    continue;
                }
                if ($ch['kind'] === 'redirect') {
                    $redirects[] = $ch;
                    continue;
                }
                try {
                    $outcome = $this->_applyChange($ch);
                } catch (Exception $e) {
                    $outcome = 'error: ' . substr($e->getMessage(), 0, 20);
                    Mage::log('MalaysiaSync apply ' . $ch['change_id'] . ': ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
                }
                $w->update($this->_t(self::CHANGE_TABLE), array('outcome' => $outcome), array('change_id = ?' => $ch['change_id']));
                $done[$outcome === 'applied' ? 'applied' : ($outcome === 'conflict' ? 'conflicts' : 'errors')]++;
            }
        });
        $this->_reindexAll();
        $done['history_redirects_kept'] = $this->_keepHistoryRedirects($runId);
        foreach ($redirects as $ch) {
            $this->_applyRedirect($runId, $ch);
            $done['applied']++;
        }
        Mage::app()->getCacheInstance()->flush();
        $w->update($this->_t(self::RUN_TABLE), array('status' => 'applied', 'applied_at' => now(), 'applied_by' => (string) $by),
            array('run_id = ?' => $runId));
        $this->_logSummary($run['op'], 'applied #' . $runId . ' by ' . $by, $done);
        return $done;
    }

    public function rollback($runId, $by)
    {
        $run = $this->getRun($runId);
        if (!$run || $run['status'] !== 'applied') {
            throw new Exception('Only an applied sync can be rolled back.');
        }
        $w = $this->_write();
        $done = array('restored' => 0, 'errors' => 0);
        $changes = array_reverse($this->getChanges($runId));
        $this->_withCategoryFlatOff(function () use ($changes, $w, &$done) {
            foreach ($changes as $ch) {
                if ($ch['outcome'] !== 'applied') {
                    continue;
                }
                try {
                    $this->_rollbackChange($ch);
                    $w->update($this->_t(self::CHANGE_TABLE), array('outcome' => 'rolled_back'), array('change_id = ?' => $ch['change_id']));
                    $done['restored']++;
                } catch (Exception $e) {
                    $done['errors']++;
                    Mage::log('MalaysiaSync rollback ' . $ch['change_id'] . ': ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
                }
            }
        });
        $this->_reindexAll();
        Mage::app()->getCacheInstance()->flush();
        $w->update($this->_t(self::RUN_TABLE), array('status' => 'rolled_back', 'rolled_back_at' => now(), 'rolled_back_by' => (string) $by),
            array('run_id = ?' => $runId));
        $this->_logSummary($run['op'], 'rolled back #' . $runId . ' by ' . $by, $done);
        return $done;
    }

    protected function _applyChange(array $ch)
    {
        $old = json_decode((string) $ch['old_value'], true);
        $new = json_decode((string) $ch['new_value'], true);
        switch ($ch['kind']) {
            case 'attr':
                $meta = $this->_attr($ch['entity'], $ch['field']);
                if ($this->_readStores($meta, (int) $ch['entity_id']) != $old) {
                    return 'conflict';   // edited on Malaysia since the dry run
                }
                $vals = array(0 => $new);
                if (array_key_exists(self::STORE, $old) && $old[self::STORE] !== null) {
                    $vals[self::STORE] = $new;   // keep a Malaysia store override in step
                }
                $this->_writeStores($meta, (int) $ch['entity_id'], $vals);
                return 'applied';
            case 'categories':
                $pid = (int) $ch['entity_id'];
                $oldIds = array_map('intval', array_keys((array) $old));
                sort($oldIds);
                if ($this->_productCategories($pid) !== $oldIds) {
                    return 'conflict';
                }
                $keep = array();
                foreach ($new as $cid) {
                    $keep[$cid] = isset($old[$cid]) ? (int) $old[$cid] : 0;   // keep positions of categories that stay
                }
                $this->_snapshotHistoryRedirects($ch, array_diff($oldIds, $new));
                $this->_setProductCategories($pid, $keep);
                return 'applied';
            case 'create':
                $id = $ch['entity'] === 'category' ? $this->_createCategory($new) : $this->_createDraft($new);
                $this->_write()->update($this->_t(self::CHANGE_TABLE), array('entity_id' => $id), array('change_id = ?' => $ch['change_id']));
                return 'applied';
            case 'redirect_flatten':
                $this->_write()->update($this->_t('core/url_rewrite'), array('target_path' => $new),
                    array('url_rewrite_id = ?' => (int) $ch['entity_id']));
                return 'applied';
        }
        return 'skipped';
    }

    protected function _rollbackChange(array $ch)
    {
        $old = json_decode((string) $ch['old_value'], true);
        $w = $this->_write();
        switch ($ch['kind']) {
            case 'attr':
                $this->_writeStores($this->_attr($ch['entity'], $ch['field']), (int) $ch['entity_id'], $old);
                break;
            case 'categories':
                $this->_setProductCategories((int) $ch['entity_id'], (array) $old);
                break;
            case 'redirect_keep':
                // put Magento's original history redirect back (the product is back in its category)
                $w->delete($this->_t('core/url_rewrite'), array('store_id = ?' => (int) $old['store_id'],
                    'id_path = ?' => 'mysync-' . md5($old['request_path'])));
                unset($old['url_rewrite_id']);
                $w->insertIgnore($this->_t('core/url_rewrite'), $old);
                break;
            case 'create':
                if ($ch['entity'] === 'product') {
                    // direct delete: loading a product needs an admin session (custom-options module),
                    // which CLI / API runs don't have; and these tables have no FK cascades
                    $this->_deleteProductRows((int) $ch['entity_id']);
                    break;
                }
                Mage::register('isSecureArea', true, true);
                try {
                    $model = Mage::getModel($ch['entity'] === 'category' ? 'catalog/category' : 'catalog/product')
                        ->setStoreId(0)->load((int) $ch['entity_id']);
                    if ($model->getId()) {
                        $model->delete();
                    }
                } finally {
                    Mage::unregister('isSecureArea');
                }
                break;
            case 'redirect':
                $w->delete($this->_t('core/url_rewrite'), array('store_id = ?' => self::STORE, 'id_path = ?' => 'mysync-' . md5($old)));
                break;
            case 'redirect_flatten':
                $w->update($this->_t('core/url_rewrite'), array('target_path' => $old), array('url_rewrite_id = ?' => (int) $ch['entity_id']));
                break;
        }
    }

    /** Old URL -> one-step 301 to the new URL; redirects that pointed at the old URL are re-pointed. */
    protected function _applyRedirect($runId, array $ch)
    {
        $w = $this->_write();
        $src = json_decode($ch['old_value'], true);
        $dst = json_decode($ch['new_value'], true);
        $t = $this->_t('core/url_rewrite');
        $w->delete($t, array('store_id IN (?)' => array(0, self::STORE), 'request_path = ?' => $src,
            "(id_path IS NULL OR (id_path NOT LIKE 'mysync-%' AND id_path NOT LIKE 'b2my-%'))"));
        $w->insertOnDuplicate($t, array('store_id' => self::STORE, 'id_path' => 'mysync-' . md5($src), 'request_path' => $src,
            'target_path' => $dst, 'is_system' => 0, 'options' => 'RP'), array('target_path', 'options'));
        foreach ($w->fetchAll("SELECT url_rewrite_id, target_path FROM $t WHERE store_id IN (0, ?) AND options IN ('R','RP')
                                AND target_path = ? AND request_path <> ?", array(self::STORE, $src, $dst)) as $r) {
            $this->_change($runId, 'product', (int) $r['url_rewrite_id'], $ch['ref'], 'redirect_flatten', null, $r['target_path'], $dst, 'applied');
            $w->update($t, array('target_path' => $dst), array('url_rewrite_id = ?' => $r['url_rewrite_id']));
        }
        $w->update($this->_t(self::CHANGE_TABLE), array('outcome' => 'applied'), array('change_id = ?' => $ch['change_id']));
    }

    protected function _createDraft(array $p)
    {
        $product = Mage::getModel('catalog/product')->setStoreId(0);
        $product->setTypeId($p['type_id'])
            ->setAttributeSetId($this->_resolveAttributeSetId($p['attribute_set']))
            ->setSku($p['sku'])
            ->setStatus(Mage_Catalog_Model_Product_Status::STATUS_DISABLED)   // draft: staff review + publish
            ->setVisibility(4)
            ->setWebsiteIds(array_keys(Mage::app()->getWebsites()))
            ->setPrice($p['price'])
            ->setTaxClassId(0)
            ->setStockData(array('use_config_manage_stock' => 0, 'manage_stock' => 0, 'is_in_stock' => 1, 'qty' => 9999));
        foreach ($p['attrs'] as $code => $value) {
            $local = $this->_resolveAttrValue($code, $value);
            if ($local !== null) {
                $product->setData($code, $local);
            }
        }
        $product->save();
        $id = (int) $product->getId();
        $this->_setProductCategories($id, array_fill_keys($p['categories'], 0));
        if ($p['options']) {
            $this->_recreateCustomOptions($id, $p['options']);
        }
        return $id;
    }

    protected function _createCategory(array $p)
    {
        $parentId = $p['parent_key'] !== null ? $this->_categoryByKey($p['parent_key']) : 0;
        $parent = Mage::getModel('catalog/category')->setStoreId(0)->load($parentId ?: Mage::app()->getDefaultStoreView()->getRootCategoryId());
        $cat = Mage::getModel('catalog/category')->setStoreId(0)
            ->setPath($parent->getPath())->setParentId($parent->getId())
            ->setName($p['name'])->setUrlKey($p['url_key'])
            ->setDescription($p['description'])->setMetaDescription($p['meta_description'])->setMetaKeywords($p['meta_keywords'])
            ->setIsActive(0)->setIncludeInMenu(0)->setIsAnchor(1);   // hidden until reviewed
        $cat->save();
        return (int) $cat->getId();
    }

    // ------------------------------------------------------------------ report

    public function getRun($runId)
    {
        return $this->_read()->fetchRow("SELECT * FROM " . $this->_t(self::RUN_TABLE) . " WHERE run_id = ?", array((int) $runId)) ?: null;
    }

    public function getRuns($limit = 10)
    {
        return $this->_read()->fetchAll("SELECT * FROM " . $this->_t(self::RUN_TABLE) . " ORDER BY run_id DESC LIMIT " . (int) $limit);
    }

    public function getChanges($runId)
    {
        return $this->_read()->fetchAll("SELECT * FROM " . $this->_t(self::CHANGE_TABLE) . " WHERE run_id = ? ORDER BY seq, change_id",
            array((int) $runId));
    }

    // ------------------------------------------------------------------ helpers

    protected function _planAttr($runId, $entity, $id, $ref, $field, $value)
    {
        $meta = $this->_attr($entity, $field);
        if (!$meta) {
            return 0;
        }
        $stores = $this->_readStores($meta, $id);
        $current = $stores[self::STORE] !== null ? $stores[self::STORE] : $stores[0];
        if ((string) $current === (string) $value) {
            return 0;
        }
        $this->_change($runId, $entity, $id, $ref, 'attr', $field, $stores, (string) $value);
        return 1;
    }

    protected function _change($runId, $entity, $id, $ref, $kind, $field, $old, $new, $outcome = null)
    {
        $this->_write()->insert($this->_t(self::CHANGE_TABLE), array(
            'run_id' => $runId, 'seq' => ++$this->_seq, 'entity' => $entity, 'entity_id' => $id, 'ref' => (string) $ref,
            'kind' => $kind, 'field' => $field,
            'old_value' => $old === null ? null : json_encode($old, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            'new_value' => $new === null ? null : json_encode($new, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            'outcome' => $outcome,
        ));
    }

    protected function _notice($runId, $entity, $id, $ref, $text)
    {
        $this->_change($runId, $entity, $id, $ref, 'notice', null, null, $text);
    }

    protected function _startRun($op, $by, $scope)
    {
        $w = $this->_write();
        // an older dry run of the same op can no longer be applied
        $w->update($this->_t(self::RUN_TABLE), array('status' => 'superseded'), array('op = ?' => $op, "status = 'planned'"));
        $w->insert($this->_t(self::RUN_TABLE), array('op' => $op, 'scope' => $scope ?: null, 'planned_by' => (string) $by));
        $this->_seq = 0;
        return (int) $w->lastInsertId();
    }

    protected function _finishPlan($runId, array $sum)
    {
        $this->_write()->update($this->_t(self::RUN_TABLE), array('summary' => json_encode($sum)), array('run_id = ?' => $runId));
        $this->_logSummary('', 'dry run #' . $runId, $sum);
        return array('success' => true, 'run_id' => $runId, 'dry_run' => true) + $sum;
    }

    protected function _logSummary($op, $what, array $counts)
    {
        Mage::log('MalaysiaSync ' . trim($op . ' ' . $what) . ' ' . json_encode($counts), Zend_Log::INFO, self::LOG_FILE, true);
    }

    /** ['code' => [attribute_id, table, frontend_input]] per entity ('product' | 'category'). */
    protected function _attr($entity, $code)
    {
        if (!isset($this->_attrs[$entity])) {
            $type = $entity === 'category' ? 'catalog_category' : 'catalog_product';
            $this->_attrs[$entity] = array();
            foreach ($this->_read()->fetchAll("SELECT a.attribute_id, a.attribute_code, a.backend_type, a.frontend_input, t.entity_type_id
                    FROM eav_attribute a JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                   WHERE t.entity_type_code = ? AND a.backend_type <> 'static'", array($type)) as $r) {
                $this->_attrs[$entity][$r['attribute_code']] = array((int) $r['attribute_id'],
                    $type . '_entity_' . $r['backend_type'], $r['frontend_input'], (int) $r['entity_type_id']);
            }
        }
        return isset($this->_attrs[$entity][$code]) ? $this->_attrs[$entity][$code] : null;
    }

    /** Default (0) and Malaysia (2) store values; null = no row. */
    protected function _readStores($meta, $id)
    {
        $rows = $this->_read()->fetchPairs("SELECT store_id, value FROM {$meta[1]} WHERE attribute_id = ? AND entity_id = ? AND store_id IN (0, ?)",
            array($meta[0], $id, self::STORE));
        return array(0 => isset($rows[0]) ? (string) $rows[0] : null, self::STORE => isset($rows[self::STORE]) ? (string) $rows[self::STORE] : null);
    }

    protected function _writeStores($meta, $id, array $vals)
    {
        $w = $this->_write();
        foreach ($vals as $store => $v) {
            if ($v === null) {
                $w->delete($meta[1], array('attribute_id = ?' => $meta[0], 'entity_id = ?' => $id, 'store_id = ?' => (int) $store));
            } else {
                $w->insertOnDuplicate($meta[1], array('entity_type_id' => $meta[3], 'attribute_id' => $meta[0],
                    'store_id' => (int) $store, 'entity_id' => $id, 'value' => $v), array('value'));
            }
        }
    }

    protected function _effective($entity, $id, $code)
    {
        $meta = $this->_attr($entity, $code);
        if (!$meta) {
            return null;
        }
        $s = $this->_readStores($meta, $id);
        return $s[self::STORE] !== null ? $s[self::STORE] : $s[0];
    }

    protected function _productEnabled($pid)
    {
        return $pid && (int) $this->_effective('product', $pid, 'status') === 1;
    }

    protected function _productCategories($pid)
    {
        $ids = array_map('intval', $this->_read()->fetchCol("SELECT category_id FROM " . $this->_t('catalog/category_product')
            . " WHERE product_id = ?", array($pid)));
        sort($ids);
        return $ids;
    }

    protected function _productCategoryPositions($pid)
    {
        return array_map('intval', $this->_read()->fetchPairs("SELECT category_id, position FROM " . $this->_t('catalog/category_product')
            . " WHERE product_id = ? ORDER BY category_id", array($pid)));
    }

    /** @param array $positions category_id => position */
    protected function _setProductCategories($pid, array $positions)
    {
        $w = $this->_write();
        $t = $this->_t('catalog/category_product');
        $w->delete($t, array('product_id = ?' => $pid));
        foreach ($positions as $cid => $pos) {
            $w->insertIgnore($t, array('category_id' => (int) $cid, 'product_id' => $pid, 'position' => (int) $pos));
        }
    }

    /**
     * Reindexing deletes every URL (incl. Magento's history 301s) of a course in a category it
     * left. Remember them now; _keepHistoryRedirects() turns any that vanished into one-step 301s.
     */
    protected function _snapshotHistoryRedirects(array $ch, array $removedCatIds)
    {
        if ($removedCatIds) {
            $this->_historySnap[] = array($ch, $this->_read()->fetchAll("SELECT * FROM " . $this->_t('core/url_rewrite')
                . " WHERE product_id = ? AND category_id IN (" . implode(',', array_map('intval', $removedCatIds)) . ")",
                array((int) $ch['entity_id'])));
        }
    }

    protected function _keepHistoryRedirects($runId)
    {
        $w = $this->_write();
        $t = $this->_t('core/url_rewrite');
        $kept = 0;
        foreach ($this->_historySnap as $snap) {
            list($ch, $rows) = $snap;
            foreach ($rows as $row) {
                if ($w->fetchOne("SELECT 1 FROM $t WHERE url_rewrite_id = ?", array($row['url_rewrite_id']))) {
                    continue;   // still there
                }
                $dst = $w->fetchOne("SELECT request_path FROM $t WHERE store_id = ? AND product_id = ? AND category_id IS NULL AND is_system = 1 LIMIT 1",
                    array($row['store_id'], $row['product_id']));
                if (!$dst || $dst === $row['request_path']) {
                    continue;
                }
                $w->insertOnDuplicate($t, array('store_id' => $row['store_id'], 'id_path' => 'mysync-' . md5($row['request_path']),
                    'request_path' => $row['request_path'], 'target_path' => $dst, 'is_system' => 0, 'options' => 'RP'),
                    array('target_path', 'options'));
                $this->_change($runId, 'product', (int) $row['product_id'], $ch['ref'], 'redirect_keep', null, $row, $dst, 'applied');
                $kept++;
            }
        }
        $this->_historySnap = array();
        return $kept;
    }

    /** Rows of a draft product in tables without FK cascades (options chain, links, stock, URLs). */
    protected function _deleteProductRows($pid)
    {
        $w = $this->_write();
        $optionIds = $w->fetchCol("SELECT option_id FROM " . $this->_t('catalog/product_option') . " WHERE product_id = ?", array($pid));
        if ($optionIds) {
            $valueIds = $w->fetchCol($w->select()->from($this->_t('catalog/product_option_type_value'), 'option_type_id')
                ->where('option_id IN (?)', $optionIds));
            if ($valueIds) {
                foreach (array('catalog/product_option_type_title', 'catalog/product_option_type_price') as $tbl) {
                    $w->delete($this->_t($tbl), array('option_type_id IN (?)' => $valueIds));
                }
                $w->delete($this->_t('catalog/product_option_type_value'), array('option_id IN (?)' => $optionIds));
            }
            foreach (array('catalog/product_option_title', 'catalog/product_option_price') as $tbl) {
                $w->delete($this->_t($tbl), array('option_id IN (?)' => $optionIds));
            }
            $w->delete($this->_t('catalog/product_option'), array('product_id = ?' => $pid));
        }
        foreach (array('catalog/category_product' => 'product_id', 'core/url_rewrite' => 'product_id',
                       'catalog/product_website' => 'product_id', 'cataloginventory/stock_item' => 'product_id',
                       'cataloginventory/stock_status' => 'product_id') as $tbl => $col) {
            $w->delete($this->_t($tbl), array("$col = ?" => $pid));
        }
        foreach (array('varchar', 'int', 'text', 'decimal', 'datetime', 'media_gallery', 'tier_price', 'group_price') as $type) {
            $tbl = $this->_t('catalog_product_entity_' . $type);
            if ($w->isTableExists($tbl)) {
                $w->delete($tbl, array('entity_id = ?' => $pid));
            }
        }
        $w->delete($this->_t('catalog/product'), array('entity_id = ?' => $pid));
    }

    /** Active-or-hidden Malaysia category by URL key (store 0), excluding retired ones. */
    protected function _categoryByKey($key)
    {
        static $cache = array();
        if (!array_key_exists($key, $cache)) {
            $meta = $this->_attr('category', 'url_key');
            $cache[$key] = (int) $this->_read()->fetchOne("SELECT entity_id FROM {$meta[1]} WHERE attribute_id = ? AND store_id = 0 AND value = ? LIMIT 1",
                array($meta[0], $key));
        }
        return $cache[$key];
    }

    protected function _urlKeyTaken($key, $pid)
    {
        $meta = $this->_attr('product', 'url_key');
        return (bool) $this->_read()->fetchOne("SELECT entity_id FROM {$meta[1]} WHERE attribute_id = ? AND value = ? AND entity_id <> ? LIMIT 1",
            array($meta[0], $key, (int) $pid));
    }

    /** Existing dropdown option id for a label (never creates options during a dry run). */
    protected function _optionId($entity, $code, $label)
    {
        $meta = $this->_attr($entity, $code);
        if (!$meta || $label === '') {
            return null;
        }
        $id = $this->_read()->fetchOne("SELECT o.option_id FROM eav_attribute_option o
              JOIN eav_attribute_option_value v ON v.option_id = o.option_id AND v.store_id = 0
             WHERE o.attribute_id = ? AND v.value = ?", array($meta[0], $label));
        return $id ? (string) $id : null;
    }

    protected function _days($hours)
    {
        return max(1, (int) round(((float) $hours) / 7.5));
    }

    /** RM per training day: certificate courses (SG Certification Exam Prep tree) 1,500, others 1,100. */
    protected function _rate(array $sgCategoryPaths)
    {
        foreach ($sgCategoryPaths as $p) {
            if (strpos((string) $p, 'certification-exam-prep') !== false) {
                return self::RATE_CERT;
            }
        }
        return self::RATE_NORMAL;
    }

    protected function _loc()
    {
        if (!$this->_loc) {
            $r = $this->_read();
            $this->_loc = new MMD_RoleManager_Model_Sync_MyLocaliser(array_merge(
                $r->fetchCol("SELECT request_path FROM " . $this->_t('core/url_rewrite') . " WHERE store_id IN (0, ?)", array(self::STORE)),
                $r->fetchCol("SELECT identifier FROM " . $this->_t('cms/page') . " WHERE is_active = 1")
            ));
        }
        return $this->_loc;
    }

    /** Category saves fail on the read-only flat resource — switch category flat off around writes. */
    protected function _withCategoryFlatOff($fn)
    {
        $path = 'catalog/frontend/flat_catalog_category';
        $was = (string) Mage::getStoreConfig($path);
        $touched = $was !== '' && $was !== '0';
        if ($touched) {
            Mage::getConfig()->saveConfig($path, '0', 'default', 0);
            Mage::getConfig()->reinit();
            Mage::app()->reinitStores();
        }
        try {
            $fn();
        } finally {
            if ($touched) {
                Mage::getConfig()->saveConfig($path, $was, 'default', 0);
                Mage::getConfig()->reinit();
                Mage::app()->reinitStores();
            }
        }
    }

    protected function _reindexAll()
    {
        $this->_reindex();
        foreach (array('catalog_category_product', 'catalog_product_price') as $code) {
            try {
                Mage::getModel('index/indexer')->getProcessByCode($code)->reindexEverything();
            } catch (Exception $e) {
                Mage::log('MalaysiaSync reindex ' . $code . ': ' . $e->getMessage(), Zend_Log::WARN, self::LOG_FILE);
            }
        }
    }

    protected function _t($name)
    {
        return Mage::getSingleton('core/resource')->getTableName($name);
    }

    protected function _read()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_read');
    }

    protected function _write()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_write');
    }
}
