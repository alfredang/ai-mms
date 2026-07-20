<?php
class MMD_RoleManager_Adminhtml_CoursesaveController extends Mage_Adminhtml_Controller_Action
{
    public function saveAction()
    {
        try {
            $req      = $this->getRequest();
            $courseId = (int) $req->getParam('course_id');
            if (!$courseId) {
                throw new Exception('No course ID provided');
            }

            $product = Mage::getModel('catalog/product')->load($courseId);
            if (!$product->getId()) {
                throw new Exception('Course not found');
            }

            // Preserve attributes that Magento's default load doesn't populate so a full
            // $product->save() doesn't silently wipe them. Pull them directly from the DB
            // and seed onto the model.
            try {
                $resource = Mage::getSingleton('core/resource');
                $read = $resource->getConnection('core_read');
                $tpAttrId = (int)$read->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='trainerprofile' AND entity_type_id=4");
                if ($tpAttrId) {
                    $tpValExisting = $read->fetchOne(
                        "SELECT value FROM catalog_product_entity_text WHERE entity_id=? AND attribute_id=? AND value IS NOT NULL AND value != '' ORDER BY store_id LIMIT 1",
                        array($courseId, $tpAttrId)
                    );
                    if ($tpValExisting !== false && $tpValExisting !== null) {
                        $product->setData('trainerprofile', $tpValExisting);
                    }
                }
                $trValExisting = $read->fetchOne(
                    "SELECT value FROM catalog_product_entity_text WHERE entity_id=? AND attribute_id=170 AND value IS NOT NULL AND value != '' ORDER BY store_id LIMIT 1",
                    array($courseId)
                );
                if ($trValExisting !== false && $trValExisting !== null) {
                    $product->setData('trainers', $trValExisting);
                }
                // Preserve news_from_date / news_to_date the same way — without
                // this, a partial save (e.g. trainer-only AJAX from the Assign
                // Trainer panel) can clear the dates if Magento's load didn't
                // populate them onto the model from the active store scope.
                foreach (array('news_from_date', 'news_to_date') as $_dateAttr) {
                    $_dAid = (int)$read->fetchOne(
                        "SELECT attribute_id FROM eav_attribute WHERE attribute_code=? AND entity_type_id=4",
                        array($_dateAttr)
                    );
                    if (!$_dAid) continue;
                    $_dVal = $read->fetchOne(
                        "SELECT value FROM catalog_product_entity_datetime WHERE entity_id=? AND attribute_id=? AND value IS NOT NULL ORDER BY store_id LIMIT 1",
                        array($courseId, $_dAid)
                    );
                    if ($_dVal !== false && $_dVal !== null && $_dVal !== '') {
                        $product->setData($_dateAttr, $_dVal);
                    }
                }
            } catch (Exception $e) {}

            // Country-mode SKU guardrail: block C-prefix and TGS- SKUs being set or
            // changed. C-courses are SG-owned and overwritten by the sync; a locally-
            // created C-SKU would be silently clobbered on the next import. Only fires
            // when the submitted SKU actually DIFFERS from the current one so editing
            // other fields on an already-synced C-course (where the form echoes back
            // the existing SKU) isn't blocked.
            if (strtolower((string) getenv('MMS_MODE')) === 'country') {
                $_proposedSku = $req->getParam('course_code');
                if ($_proposedSku === null || $_proposedSku === '') {
                    $_proposedSku = $req->getParam('general_course_code');
                }
                if ($_proposedSku !== null && $_proposedSku !== '') {
                    $_proposedUpper = strtoupper(ltrim((string) $_proposedSku));
                    $_isReserved = (substr($_proposedUpper, 0, 1) === 'C')
                               || (substr($_proposedUpper, 0, 4) === 'TGS-');
                    $_isChanging  = (string) $_proposedSku !== (string) $product->getSku();
                    if ($_isReserved && $_isChanging) {
                        throw new Exception(
                            '"C…" and "TGS-…" course codes are reserved for SG-synced courses '
                            . 'and cannot be used in this country instance. '
                            . 'Use your country prefix (e.g. NG…) instead.'
                        );
                    }
                }
            }

            // Basic fields
            if (($v = $req->getParam('course_name'))  !== null && $v !== '') $product->setName($v);
            if (($v = $req->getParam('course_code'))  !== null && $v !== '') $product->setSku($v);
            if (($v = $req->getParam('image_url'))    !== null)              $product->setData('course_image_url', $v);
            if (($v = $req->getParam('brochure_url')) !== null)              $product->setData('course_brochure_url', $v);
            if (($v = $req->getParam('duration'))     !== null && $v !== '') $product->setData('duration', $v);
            if (($v = $req->getParam('training_hours')) !== null && $v !== '') $product->setData('duration', $v);
            if (($v = $req->getParam('price'))        !== null && $v !== '') $product->setPrice((float)$v);

            // Trainer pool (account-based — Phase 2). The Edit Course →
            // Trainer Details tab posts trainer_user_ids (admin_user ids of
            // trainer-role accounts); persist to mmd_product_trainer. The
            // legacy EAV `trainers` multiselect is no longer written here —
            // it stays as a hybrid display/invite fallback only.
            $trainerProfileChanged = false;
            if (($v = $req->getParam('trainer_user_ids')) !== null) {
                $this->_persistProductTrainerPool($courseId, $v);
            }
            // Strip legacy trainer names from the trainerprofile HTML when the × was clicked
            $legacyRemove = trim((string)$req->getParam('legacy_trainer_remove', ''));
            if ($legacyRemove !== '') {
                $resource = Mage::getSingleton('core/resource');
                $read = $resource->getConnection('core_read');
                $tpAttrId = (int)$read->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='trainerprofile' AND entity_type_id=4");
                $currentTp = (string)$read->fetchOne(
                    "SELECT value FROM catalog_product_entity_text WHERE entity_id=? AND attribute_id=? AND value IS NOT NULL AND value != '' ORDER BY store_id LIMIT 1",
                    array($courseId, $tpAttrId)
                );
                if ($currentTp !== '') {
                    $namesToRemove = array_filter(array_map('trim', explode('|', $legacyRemove)));
                    foreach ($namesToRemove as $name) {
                        // Remove <p>...<strong>Name:</strong>...content until next <p><strong> or end
                        $escaped = preg_quote($name, '#');
                        // Pattern: <p>...<strong>NAME:</strong>...</p> (and any following content until next <strong>NAME:</strong> paragraph or <h2>/end)
                        $currentTp = preg_replace(
                            '#<p[^>]*>\s*<strong>\s*' . $escaped . '\s*:\s*</strong>.*?(?=<p[^>]*>\s*<strong>[^<:]+:\s*</strong>|<h[1-6]|\z)#si',
                            '',
                            $currentTp
                        );
                    }
                    $product->setData('trainerprofile', $currentTp);
                    $trainerProfileChanged = true;
                }
            }
            // Only write trainerprofile if the form actually submitted trainer_names (legacy textarea).
            // Never wipe it from a submission that lacks that field.
            $tnRaw = $req->getParam('trainer_names');
            if ($tnRaw !== null && trim((string)$tnRaw) !== '') {
                $lines = array_filter(array_map('trim', preg_split('/\r?\n/', $tnRaw)));
                $html  = '';
                foreach ($lines as $line) {
                    $html .= '<p><strong>' . htmlspecialchars($line) . ':</strong></p>' . "\n";
                }
                $product->setData('trainerprofile', $html);
                $trainerProfileChanged = true;
            }
            if (($v = $req->getParam('learning_outcomes')) !== null) $product->setData('description', $v);
            if (($v = $req->getParam('course_description')) !== null) $product->setData('short_description', $v);
            if (($v = $req->getParam('who_should_attend')) !== null) $product->setData('whoshouldattend', $v);
            if (($v = $req->getParam('prerequisite'))      !== null) $product->setData('prerequisite', $v);

            // Course Information fields (back the storefront rightData tab):
            // sessions (text), level (select option_id), additional_note (textarea).
            if (($v = $req->getParam('sessions'))        !== null) $product->setData('sessions',        $v === '' ? null : $v);
            if (($v = $req->getParam('level'))           !== null) $product->setData('level',           $v === '' ? null : (int)$v);
            if (($v = $req->getParam('additional_note')) !== null) $product->setData('additional_note', $v);
            if (($v = $req->getParam('assessment_duration')) !== null) $product->setData('assessment_duration', $v === '' ? null : (int)$v);

            // Assessment Methods (multiselect EAV `assessment_methods`).
            // The form always submits a hidden `_assessment_methods_loaded`
            // sentinel so we can tell "user unchecked everything" (sentinel
            // present, checkbox array absent or empty) from "form panel
            // wasn't rendered at all" (sentinel absent — never touch).
            if ($req->getParam('_assessment_methods_loaded') !== null) {
                $_methods = $req->getParam('assessment_methods');
                if (!is_array($_methods)) { $_methods = []; }
                $_methods = array_values(array_unique(array_map('intval', array_filter($_methods, 'strlen'))));
                sort($_methods, SORT_NUMERIC);
                $product->setData('assessment_methods', $_methods ? implode(',', $_methods) : null);
            }

            // Per-course CMS block sections (Learning Outcomes, Brochure,
            // Skills Framework, Certification, WSQ Funding). Identifier
            // convention: course_<sku>_<section>. Empty submission deletes
            // the row; non-empty upserts. See scripts/local-dev/cms-block-phase01.php
            // for the bootstrap that initially populated these from short_description.
            $_cmsSections = [
                'learning_outcomes' => 'Learning Outcomes',
                'brochure'          => 'Brochure',
                'skills_framework'  => 'Skills Framework',
                'certification'     => 'Certification',
                'funding_and_grant' => 'Funding and Grant',
            ];
            $_cmsSku = (string) $product->getSku();
            foreach ($_cmsSections as $_sec => $_label) {
                $_v = $req->getParam('cms_block_' . $_sec);
                if ($_v === null || $_cmsSku === '') continue;
                $_v  = trim((string) $_v);
                $_id = 'course_' . $_cmsSku . '_' . $_sec;
                $_b  = Mage::getModel('cms/block')->load($_id, 'identifier');
                if ($_v === '') {
                    if ($_b->getId()) { $_b->delete(); }
                    continue;
                }
                if (!$_b->getId()) {
                    $_b->setIdentifier($_id)
                       ->setTitle('Course ' . $_cmsSku . ' — ' . $_label)
                       ->setIsActive(1)
                       ->setStores([0]);
                }
                $_b->setContent($_v)->save();
            }

            // SEO — per-country store view.
            //
            // The dashboard template emits a hidden seo_target_store_id
            // matching the country tab the admin is on (1=SG, 3=GH, …).
            // When that's > 0 we persist the three meta fields at THAT
            // store view only (via saveAttribute, scoped writes), so
            // generating for one country doesn't overwrite Singapore's meta
            // and vice versa. Without a target (0 = default scope) we
            // fall back to the historical behaviour: write at scope 0.
            $_seoTargetStoreId = (int) $req->getParam('seo_target_store_id', 0);
            if ($_seoTargetStoreId > 0) {
                $_seoUpdates = array();
                if (($v = $req->getParam('meta_title'))       !== null) $_seoUpdates['meta_title']       = $v;
                if (($v = $req->getParam('meta_description')) !== null) $_seoUpdates['meta_description'] = $v;
                if (($v = $req->getParam('meta_keyword'))     !== null) $_seoUpdates['meta_keyword']     = $v;
                if (!empty($_seoUpdates)) {
                    try {
                        $_seoScopedProduct = Mage::getModel('catalog/product')
                            ->setStoreId($_seoTargetStoreId)
                            ->load($courseId);
                        if ($_seoScopedProduct && $_seoScopedProduct->getId()) {
                            foreach ($_seoUpdates as $_attrCode => $_attrVal) {
                                $_seoScopedProduct->setData($_attrCode, $_attrVal);
                                $_seoScopedProduct->getResource()
                                    ->saveAttribute($_seoScopedProduct, $_attrCode);
                            }
                        }
                    } catch (Exception $_seoSaveEx) {
                        Mage::log('SEO per-store save failed: ' . $_seoSaveEx->getMessage(), null, 'mmd_rolemanager.log');
                    }
                }
            } else {
                if (($v = $req->getParam('meta_title'))        !== null) $product->setMetaTitle($v);
                if (($v = $req->getParam('meta_description'))  !== null) $product->setMetaDescription($v);
                if (($v = $req->getParam('meta_keyword'))      !== null) $product->setMetaKeyword($v);
            }

            // === General tab (Magento-style fields). Name/SKU also accept general_*
            // aliases — frontend JS keeps them in sync with course_name/course_code.
            if (($v = $req->getParam('general_course_name'))            !== null && $v !== '') $product->setName($v);
            if (($v = $req->getParam('general_course_code'))            !== null && $v !== '') $product->setSku($v);
            if (($v = $req->getParam('general_tax_class'))              !== null && $v !== '') $product->setData('tax_class_id', (int)$v);
            if (($v = $req->getParam('general_news_from_date'))         !== null) $product->setData('news_from_date', $v ?: null);
            if (($v = $req->getParam('general_news_to_date'))           !== null) $product->setData('news_to_date',   $v ?: null);
            if (($v = $req->getParam('general_status'))                 !== null && $v !== '') $product->setData('status', (int)$v);
            if (($v = $req->getParam('general_url_key'))                !== null) $product->setData('url_key', $v);
            if (($v = $req->getParam('general_visibility'))             !== null && $v !== '') $product->setData('visibility', (int)$v);
            if (($v = $req->getParam('general_ebizmarts_mark_visited')) !== null) $product->setData('ebizmarts_mark_visited', (int)$v);
            // URL-redirect checkbox is only in the General tab — absence means unchecked.
            $product->setData('save_rewrites_history', $req->getParam('general_url_redirect') ? 1 : 0);

            // === Price (lives on the General tab) ===
            // Other Magento pricing attributes (special_price, cost, msrp,
            // msrp_enabled, msrp_display_actual_price_type, group_price,
            // tier_price) are intentionally not edited here. Existing DB
            // values are preserved because the inputs aren't submitted —
            // $req->getParam(...) returns null and the setData calls are
            // skipped. If those values ever need editing, the standard
            // Magento product editor still works.
            if (($v = $req->getParam('prices_price')) !== null && $v !== '') $product->setData('price', (float)$v);

            // === Trainer Details tab — Trainer Profile rich text ===
            if (($v = $req->getParam('trainer_profile')) !== null) $product->setData('trainerprofile', $v);

            // === Design tab ===
            foreach (array(
                'design_custom_design'        => 'custom_design',
                'design_custom_design_from'   => 'custom_design_from',
                'design_custom_design_to'     => 'custom_design_to',
                'design_custom_layout_update' => 'custom_layout_update',
                'design_page_layout'          => 'page_layout',
                'design_options_container'    => 'options_container',
            ) as $_p => $_a) {
                $_v = $req->getParam($_p);
                if ($_v !== null) $product->setData($_a, $_v ?: null);
            }

            // === Gift Options — checkbox-driven Use Config Settings ===
            if ($req->getParam('gift_use_config')) {
                $product->setData('use_config_gift_message_available', 1);
            } else if (($v = $req->getParam('gift_allow_gift_message')) !== null) {
                $product->setData('use_config_gift_message_available', 0);
                $product->setData('gift_message_available', strtolower($v) === 'yes' ? 1 : 0);
            }

            // === Inventory tab — merge into stock data, honour Use Config Settings ===
            $_invMap = array(
                'inv_manage_stock'   => 'manage_stock',
                'inv_min_qty'        => 'min_sale_qty',
                'inv_max_qty'        => 'max_sale_qty',
                'inv_enable_qty_inc' => 'enable_qty_increments',
            );
            $_stockOverrides = array();
            foreach ($_invMap as $_p => $_k) {
                $_useCfg = (bool) $req->getParam($_p . '_use_config');
                $_stockOverrides['use_config_' . $_k] = $_useCfg ? 1 : 0;
                if (!$_useCfg) {
                    $_v = $req->getParam($_p);
                    if ($_v !== null && $_v !== '') {
                        if ($_p === 'inv_manage_stock' || $_p === 'inv_enable_qty_inc') {
                            $_stockOverrides[$_k] = (strtolower($_v) === 'yes') ? 1 : 0;
                        } else {
                            $_stockOverrides[$_k] = (int) $_v;
                        }
                    }
                }
            }
            // Only touch stock_data if the inventory tab was actually rendered/submitted
            // — detectable by any inv_* value OR use_config checkbox being present.
            $_anyInv = false;
            foreach (array_keys($_invMap) as $_p) {
                if ($req->getParam($_p) !== null || $req->getParam($_p . '_use_config') !== null) {
                    $_anyInv = true;
                    break;
                }
            }
            if ($_anyInv) {
                $product->setStockData(array_merge((array) $product->getStockData(), $_stockOverrides));
            }

            // === Categories tab ===
            // Only update category assignments if the Categories tab was actually
            // rendered (the hidden _categories_loaded flag confirms that). Without
            // this guard, a save from any other context would wipe all categories
            // because unchecked checkboxes don't submit, leaving categories[] empty.
            if ($req->getParam('_categories_loaded')) {
                $_catIds = (array) $req->getParam('categories', array());
                $_catIds = array_values(array_unique(array_filter(array_map('intval', $_catIds))));
                $product->setCategoryIds($_catIds);
            }

            // === Websites tab — same guard pattern as Categories ===
            if ($req->getParam('_websites_loaded')) {
                $_webIds = (array) $req->getParam('websites', array());
                $_webIds = array_values(array_unique(array_filter(array_map('intval', $_webIds))));
                $product->setWebsiteIds($_webIds);
            }

            // === Images tab — labels, positions, disabled flags, role assignments,
            //    per-row removal, AND new file uploads. New files go via Magento's
            //    media backend, are added to the gallery, and (if no role is set on
            //    an existing image) automatically claim base/small/thumbnail.
            if ($req->getParam('_images_loaded')) {
                $_imgGallery = (array) $product->getMediaGallery('images');
                $_imgRemove   = (array) $req->getParam('img_remove',   array());
                $_imgLabel    = (array) $req->getParam('img_label',    array());
                $_imgPosition = (array) $req->getParam('img_position', array());
                $_imgDisabled = (array) $req->getParam('img_disabled', array());
                foreach ($_imgGallery as &$_imgRow) {
                    $_vid = (int) (isset($_imgRow['value_id']) ? $_imgRow['value_id'] : 0);
                    if ($_vid <= 0) continue;
                    if (!empty($_imgRemove[$_vid])) {
                        $_imgRow['removed'] = 1;
                    } else {
                        if (isset($_imgLabel[$_vid]))    $_imgRow['label']    = (string) $_imgLabel[$_vid];
                        if (isset($_imgPosition[$_vid])) $_imgRow['position'] = (int)    $_imgPosition[$_vid];
                        $_imgRow['disabled'] = !empty($_imgDisabled[$_vid]) ? 1 : 0;
                    }
                }
                unset($_imgRow);
                $product->setMediaGallery(array('images' => $_imgGallery, 'values' => isset($product->getMediaGallery()['values']) ? $product->getMediaGallery()['values'] : array()));
                // Role assignments — base / small / thumbnail point at a file path.
                foreach (array('image' => 'img_role_image', 'small_image' => 'img_role_small_image', 'thumbnail' => 'img_role_thumbnail') as $_attr => $_param) {
                    $_v = $req->getParam($_param);
                    if ($_v !== null && $_v !== '') $product->setData($_attr, (string) $_v);
                }

                // New uploads — multi-file <input name="image_upload[]">.
                if (!empty($_FILES['image_upload']['name'][0])) {
                    try {
                        $_mediaBackend = $product->getResource()->getAttribute('media_gallery')->getBackend();
                        $_uploadDir = Mage::getBaseDir('media') . DS . 'tmp' . DS . 'catalog' . DS . 'product';
                        if (!is_dir($_uploadDir)) @mkdir($_uploadDir, 0775, true);
                        $_count = count($_FILES['image_upload']['name']);
                        $_isFirstUploadFile = empty($_imgGallery); // assign roles only if no existing media
                        for ($_i = 0; $_i < $_count; $_i++) {
                            if (empty($_FILES['image_upload']['tmp_name'][$_i])) continue;
                            if ((int) $_FILES['image_upload']['error'][$_i] !== UPLOAD_ERR_OK) continue;
                            $_origName = (string) $_FILES['image_upload']['name'][$_i];
                            // Move tmp to media/tmp/ and pass to addImage
                            $_safe = preg_replace('/[^A-Za-z0-9._-]/', '_', $_origName);
                            $_dst  = $_uploadDir . DS . uniqid('up_') . '_' . $_safe;
                            if (!@move_uploaded_file($_FILES['image_upload']['tmp_name'][$_i], $_dst)) continue;
                            // Decide which media attributes to claim.
                            // First-ever upload: take base/small/thumbnail. Otherwise just add to gallery.
                            $_claim = $_isFirstUploadFile && $_i === 0
                                ? array('image', 'small_image', 'thumbnail')
                                : array();
                            try {
                                $_mediaBackend->addImage($product, $_dst, $_claim, true /*move=true → clean up tmp*/, false /*exclude*/);
                            } catch (Exception $_addEx) {
                                // try-add-failed → ignore that file but continue
                            }
                        }
                    } catch (Exception $_upEx) { /* keep saving the rest */ }
                }
            }

            // === Related / Up-sells / Cross-sells — diff against current links ===
            //    Each tab has a remove[] map, a position[] map, and an add_skus
            //    free-text. We rebuild the link set per-tab from those.
            $_linkConfigs = array(
                'related'    => array('flag' => '_related_loaded',    'getter' => 'getRelatedProductCollection',   'setter' => 'setRelatedLinkData'),
                'upsells'    => array('flag' => '_upsells_loaded',    'getter' => 'getUpSellProductCollection',    'setter' => 'setUpSellLinkData'),
                'crosssells' => array('flag' => '_crosssells_loaded', 'getter' => 'getCrossSellProductCollection', 'setter' => 'setCrossSellLinkData'),
            );
            foreach ($_linkConfigs as $_lkKey => $_lkCfg) {
                if (!$req->getParam($_lkCfg['flag'])) continue;
                $_remove   = (array) $req->getParam($_lkKey . '_remove',   array());
                $_position = (array) $req->getParam($_lkKey . '_position', array());
                $_addSkusRaw = (string) $req->getParam($_lkKey . '_add_skus', '');
                $_linkData = array();
                // Existing rows that weren't marked for removal
                foreach ($product->{$_lkCfg['getter']}() as $_lp) {
                    $_pid = (int) $_lp->getId();
                    if (!empty($_remove[$_pid])) continue;
                    $_pos = isset($_position[$_pid]) ? (int) $_position[$_pid] : (int) $_lp->getPosition();
                    $_linkData[$_pid] = array('position' => $_pos);
                }
                // New rows resolved from the free-text SKU input
                if ($_addSkusRaw !== '') {
                    foreach (preg_split('/[\s,]+/', $_addSkusRaw) as $_sku) {
                        $_sku = trim($_sku);
                        if ($_sku === '') continue;
                        $_addPid = (int) Mage::getModel('catalog/product')->getResource()->getIdBySku($_sku);
                        if ($_addPid > 0 && $_addPid !== (int) $courseId && !isset($_linkData[$_addPid])) {
                            $_linkData[$_addPid] = array('position' => 0);
                        }
                    }
                }
                $product->{$_lkCfg['setter']}($_linkData);
            }

            $product->save();

            // === Course Schedule tab — edit/remove existing custom_option values
            //     and append new ones. Mirrors the schema used by addSessionAction()
            //     and deleteSessionAction(): catalog_product_option_type_value (the
            //     row), _type_title (per-store title), _type_price (per-store price).
            //     All writes are scoped to options owned by THIS product so a
            //     forged option_type_id can't touch another course's data.
            if ($req->getParam('_schedule_loaded')) {
                $_resource     = Mage::getSingleton('core/resource');
                $_read         = $_resource->getConnection('core_read');
                $_write        = $_resource->getConnection('core_write');
                $_optTable     = $_resource->getTableName('catalog/product_option');
                $_optTypeTable = $_resource->getTableName('catalog/product_option_type_value');
                $_optTypeTitle = $_resource->getTableName('catalog/product_option_type_title');
                $_optTypePrice = $_resource->getTableName('catalog/product_option_type_price');

                // Build the set of option_ids that belong to this product — we'll
                // reject any POSTed value/option_id outside this set.
                $_ownedOptionIds = $_read->fetchCol(
                    "SELECT option_id FROM {$_optTable} WHERE product_id = ?",
                    array($courseId)
                );
                $_ownedOptionIds = array_map('intval', $_ownedOptionIds);

                // Same lookup for option_type_value rows (so we can verify each
                // value_id is on one of THIS product's options).
                $_ownedValueIds = array();
                if (!empty($_ownedOptionIds)) {
                    $_ownedValueIds = $_read->fetchCol(
                        "SELECT option_type_id FROM {$_optTypeTable} WHERE option_id IN (" . implode(',', $_ownedOptionIds) . ")"
                    );
                    $_ownedValueIds = array_map('intval', $_ownedValueIds);
                }

                // 1. Remove rows the user marked for deletion. delete from
                //    _type_value cascades to _title and _price via FK.
                $_removeMap = (array) $req->getParam('schedule_remove', array());
                foreach ($_removeMap as $_vid => $_flag) {
                    $_vid = (int) $_vid;
                    if ($_flag !== '1' || $_vid <= 0) continue;
                    if (!in_array($_vid, $_ownedValueIds, true)) continue;
                    $_write->delete($_optTypeTable, array('option_type_id = ?' => $_vid));
                }

                // 2. Update existing rows (title / price / sort_order). We re-fetch
                //    the owned set after deletion to skip rows the user removed.
                $_remainingValueIds = array_diff($_ownedValueIds, array_map('intval', array_keys(array_filter($_removeMap, function($v){ return $v === '1'; }))));
                $_valueMap = (array) $req->getParam('schedule_value', array());
                $_writeCount = 0;
                foreach ($_valueMap as $_vid => $_fields) {
                    $_vid = (int) $_vid;
                    if ($_vid <= 0 || !in_array($_vid, $_remainingValueIds, true)) continue;
                    $_writeCount++;
                    $_title = isset($_fields['title']) ? trim((string) $_fields['title']) : null;
                    $_priceRaw = isset($_fields['price']) ? trim((string) $_fields['price']) : null;
                    $_sort  = isset($_fields['sort'])  ? (int) $_fields['sort']  : null;
                    $_regIso = isset($_fields['reg_course']) ? trim((string) $_fields['reg_course']) : null;

                    if ($_title !== null && $_title !== '') {
                        $_write->update(
                            $_optTypeTitle,
                            array('title' => $_title),
                            $_write->quoteInto('option_type_id = ? AND store_id = 0', $_vid)
                        );
                    }
                    if ($_sort !== null) {
                        $_write->update(
                            $_optTypeTable,
                            array('sort_order' => $_sort),
                            $_write->quoteInto('option_type_id = ?', $_vid)
                        );
                    }
                    if ($_regIso !== null) {
                        // HTML date input is Y-m-d; reg_course column stores m/d/y. Empty clears.
                        $_regOut = '';
                        if ($_regIso !== '') {
                            $_dt = DateTime::createFromFormat('Y-m-d', $_regIso);
                            if ($_dt instanceof DateTime) $_regOut = $_dt->format('n/j/y');
                        }
                        $_write->update(
                            $_optTypeTable,
                            array('reg_course' => $_regOut),
                            $_write->quoteInto('option_type_id = ?', $_vid)
                        );
                    }
                    if ($_priceRaw !== null) {
                        $_priceVal = $_priceRaw === '' ? 0.0 : (float) $_priceRaw;
                        // _type_price row may not exist (free sessions skip it).
                        // Upsert: try update, insert if no row was affected.
                        $_existsPrice = (int) $_read->fetchOne(
                            "SELECT option_type_price_id FROM {$_optTypePrice} WHERE option_type_id = ? AND store_id = 0",
                            array($_vid)
                        );
                        if ($_existsPrice) {
                            $_write->update(
                                $_optTypePrice,
                                array('price' => $_priceVal, 'price_type' => 'fixed'),
                                $_write->quoteInto('option_type_price_id = ?', $_existsPrice)
                            );
                        } elseif ($_priceVal > 0) {
                            $_write->insert($_optTypePrice, array(
                                'option_type_id' => $_vid,
                                'store_id'       => 0,
                                'price'          => $_priceVal,
                                'price_type'     => 'fixed',
                            ));
                        }
                    }
                }

                // 3. Insert new rows queued by the "+ Add session" button.
                $_newMap = (array) $req->getParam('schedule_new', array());
                foreach ($_newMap as $_optId => $_rows) {
                    $_optId = (int) $_optId;
                    if (!in_array($_optId, $_ownedOptionIds, true)) continue;
                    if (!is_array($_rows)) continue;
                    foreach ($_rows as $_row) {
                        if (!is_array($_row)) continue;
                        $_title = isset($_row['title']) ? trim((string) $_row['title']) : '';
                        if ($_title === '') continue;  // skip blank rows
                        $_sort  = isset($_row['sort'])  ? (int) $_row['sort']  : 0;
                        $_priceRaw = isset($_row['price']) ? trim((string) $_row['price']) : '';
                        $_priceVal = $_priceRaw === '' ? 0.0 : (float) $_priceRaw;
                        $_regIso = isset($_row['reg_course']) ? trim((string) $_row['reg_course']) : '';
                        $_regOut = '';
                        if ($_regIso !== '') {
                            $_dt = DateTime::createFromFormat('Y-m-d', $_regIso);
                            if ($_dt instanceof DateTime) $_regOut = $_dt->format('n/j/y');
                        }

                        $_write->insert($_optTypeTable, array(
                            'option_id'  => $_optId,
                            'sku'        => '',
                            'sort_order' => $_sort,
                            'reg_course' => $_regOut,
                        ));
                        $_newVid = (int) $_write->lastInsertId();
                        $_write->insert($_optTypeTitle, array(
                            'option_type_id' => $_newVid,
                            'store_id'       => 0,
                            'title'          => $_title,
                        ));
                        if ($_priceVal > 0) {
                            $_write->insert($_optTypePrice, array(
                                'option_type_id' => $_newVid,
                                'store_id'       => 0,
                                'price'          => $_priceVal,
                                'price_type'     => 'fixed',
                            ));
                        }
                    }
                }

                Mage::log(sprintf(
                    'coursesave/schedule pid=%d ownedOpts=%d ownedVals=%d postedRemove=%d postedValueRows=%d updatedRows=%d postedNewGroups=%d',
                    $courseId,
                    count($_ownedOptionIds),
                    count($_ownedValueIds),
                    count(array_filter($_removeMap, function($v){ return $v === '1'; })),
                    count($_valueMap),
                    $_writeCount,
                    count($_newMap)
                ), null, 'mmd_schedule_save.log', true);

                Mage::app()->cleanCache();
            }

            // Save courseware URLs into the dedicated course_courseware table (upsert by product_id).
            // Only runs if the form actually submitted any courseware_* field.
            $_cwFields = array(
                'lesson_plan_url', 'learner_guide_url',
                'learner_slides_url', 'trainer_slides_url',
                'lab_url',
                'courseware_link', 'brochure_link',
                'google_meet_url', 'certificate_url',
            );
            $_cwAny = false;
            $_cwData = array();
            foreach ($_cwFields as $_k) {
                $_val = $req->getParam('courseware_' . $_k);
                if ($_val !== null) {
                    $_cwData[$_k] = (string) $_val;
                    $_cwAny = true;
                }
            }
            if ($_cwAny) {
                try {
                    $_w = Mage::getSingleton('core/resource')->getConnection('core_write');
                    $_r = Mage::getSingleton('core/resource')->getConnection('core_read');
                    $_existing = $_r->fetchOne("SELECT id FROM course_courseware WHERE product_id = ?", array($courseId));
                    if ($_existing) {
                        $_w->update('course_courseware', $_cwData, array('id = ?' => (int)$_existing));
                    } else {
                        $_cwData['product_id'] = $courseId;
                        $_w->insert('course_courseware', $_cwData);
                    }
                } catch (Exception $_cwEx) {
                    // Table may not exist yet on fresh DBs — silently ignore
                }
            }

            // Save Additional Documents (per-course list). The form
            // submits parallel arrays course_doc_id[], course_doc_filename[],
            // course_doc_url[]; an empty filename row is treated as a
            // delete request. Strategy: delete-then-insert all rows for
            // this product when ANY course_doc_filename[] is in the
            // post, so the editor can fully control the list. Skips
            // entirely when the form didn't submit a course_doc_*[]
            // (e.g. courses being saved by another flow).
            $_docFilenames = $req->getParam('course_doc_filename');
            if (is_array($_docFilenames)) {
                try {
                    $_w = Mage::getSingleton('core/resource')->getConnection('core_write');
                    $_w->delete('course_documents', array('product_id = ?' => (int)$courseId));
                    $_docUrls   = (array) $req->getParam('course_doc_url');
                    $_uploader  = '';
                    try {
                        $_u = Mage::getSingleton('admin/session')->getUser();
                        if ($_u) $_uploader = (string) $_u->getEmail();
                    } catch (Exception $_e) {}
                    foreach ($_docFilenames as $_idx => $_fn) {
                        $_fn = trim((string)$_fn);
                        if ($_fn === '') continue; // empty row = delete-only
                        $_w->insert('course_documents', array(
                            'product_id'  => (int)$courseId,
                            'filename'    => $_fn,
                            'file_url'    => isset($_docUrls[$_idx]) ? trim((string)$_docUrls[$_idx]) : '',
                            'uploaded_by' => $_uploader,
                        ));
                    }
                } catch (Exception $_docEx) {
                    // course_documents table not yet on this DB — ignore
                }
            }

            // Force-save trainerprofile (bio HTML) directly when it changed —
            // Magento's normal save can miss text attributes. Trainer pool is
            // account-based now (mmd_product_trainer), so no EAV `trainers` write.
            if ($trainerProfileChanged) {
                $product->getResource()->saveAttribute($product, 'trainerprofile');
            }

            $continueEdit = $req->getParam('continue_edit');
            $devBack = trim((string) $req->getParam('dev_back', ''));
            $devBackSuffix = $devBack !== '' ? '?dev_back=' . urlencode($devBack) : '';
            $dashboardUrl = Mage::helper('adminhtml')->getUrl('adminhtml/dashboard');

            if ($continueEdit) {
                // Save & Continue — stay in editor, preserve back-state
                $editUrl = Mage::helper('adminhtml')->getUrl('adminhtml/dashboard', array(
                    'course_id' => $courseId,
                    'mode' => 'editing',
                )) . $devBackSuffix;
                $this->_redirectUrl($editUrl);
            } elseif ($devBack !== '') {
                // Save Changes with back-state — drop back on the filtered list
                $this->_redirectUrl($dashboardUrl . '?' . $devBack . '#courses');
            } else {
                // Save Changes without back-state (legacy entry) — read-only view
                $viewUrl = Mage::helper('adminhtml')->getUrl('adminhtml/dashboard', array(
                    'course_id' => $courseId,
                    'mode' => 'edit',
                ));
                $this->_redirectUrl($viewUrl);
            }
            return;
        } catch (Exception $e) {
            // Stay in the editor on failure. Redirecting to the bare dashboard
            // dropped course_id/mode, so COURSE_EDIT_ACTIVE went false and the
            // panel-switcher JS hid every panel — the admin saw a blank screen
            // with no clue what went wrong (reported 2026-07-19 saving a
            // Courseware Link). Only fall back to the dashboard when we never
            // resolved a course to return to.
            Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
            $courseId = (int) $this->getRequest()->getParam('course_id');
            if ($courseId) {
                $devBack = trim((string) $this->getRequest()->getParam('dev_back', ''));
                $this->_redirectUrl(
                    Mage::helper('adminhtml')->getUrl('adminhtml/dashboard', array(
                        'course_id' => $courseId,
                        'mode'      => 'editing',
                    )) . ($devBack !== '' ? '?dev_back=' . urlencode($devBack) : '')
                );
            } else {
                $this->_redirectUrl(Mage::helper('adminhtml')->getUrl('adminhtml/dashboard'));
            }
        }
    }
    /**
     * Create New Class — backs the admin Create New Class form.
     *
     * Writes a course_runs row capturing every field the admin entered
     * (venue, mode, vacancy, registration window, course dates, trainer
     * option_id) so the trainer's "My Assigned Classes" card can show
     * exactly what was submitted instead of the underlying product
     * attributes. Also appends the trainer to the product's `trainers`
     * EAV multiselect so the existing trainer-match filter in the
     * dashboard continues to surface the class.
     *
     * POST: course_sku, trainer_option_id, start_date (YYYY-MM-DD),
     *       end_date, reg_open_date, reg_close_date, venue_block,
     *       venue_street, venue_building, venue_floor, venue_unit,
     *       postal_code, room, wheelchair (Yes/No), mode_of_training
     *       (1-4), admin_email, vacancy (A/L/F)
     * Returns JSON { success, product_id?, run_id?, message? }
     */
    public function createNewClassAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $req = $this->getRequest();
            $sku       = trim((string) $req->getParam('course_sku'));
            $trainerUid = (int)        $req->getParam('trainer_user_id');
            $startDate = trim((string) $req->getParam('start_date'));
            $endDate   = trim((string) $req->getParam('end_date'));
            $regOpen   = trim((string) $req->getParam('reg_open_date'));
            $regClose  = trim((string) $req->getParam('reg_close_date'));
            if ($sku === '') throw new Exception('course_sku is required');

            $resource = Mage::getSingleton('core/resource');
            $read     = $resource->getConnection('core_read');
            $write    = $resource->getConnection('core_write');
            $eavTx    = $resource->getTableName('catalog_product_entity_text');
            $eavDt    = $resource->getTableName('catalog_product_entity_datetime');

            // Look up the product by SKU
            $productId = (int) $read->fetchOne(
                "SELECT entity_id FROM " . $resource->getTableName('catalog_product_entity') . " WHERE sku = ? LIMIT 1",
                array($sku)
            );
            if (!$productId) throw new Exception('No course found with SKU "' . $sku . '"');
            $result['product_id'] = $productId;

            // Validate the chosen trainer is a real, active trainer account
            // (Phase 2 — account-based assignment). Silently drop otherwise.
            if ($trainerUid > 0) {
                $okTrainer = (int) $read->fetchOne(
                    "SELECT u.user_id FROM " . $resource->getTableName('admin_user') . " u
                       JOIN " . $resource->getTableName('mmd_user_role_map') . " r
                         ON r.user_id = u.user_id AND r.role_code = 'trainer'
                      WHERE u.is_active = 1 AND u.user_id = ? LIMIT 1",
                    array($trainerUid)
                );
                if (!$okTrainer) $trainerUid = 0;
            }

            // Persist all the form fields to course_runs.
            $startTime = trim((string) $req->getParam('start_time'));
            $endTime   = trim((string) $req->getParam('end_time'));

            // Determine country prefix from the admin's active website.
            $_helper   = Mage::helper('mmd_rolemanager');
            $_widForCC = (int) (method_exists($_helper, 'getActiveStoreId') ? $_helper->getActiveStoreId() : 0);
            if (!$_widForCC) {
                $_widForCC = (int) $read->fetchOne(
                    "SELECT website_id FROM catalog_product_website WHERE product_id = ? ORDER BY website_id LIMIT 1",
                    array($productId)
                );
            }
            $_runTable = $resource->getTableName('course_runs');
            $_cc       = MMD_RoleManager_Helper_Data::countryCodeForProduct($read, $productId, $_widForCC);
            $_classId  = MMD_RoleManager_Helper_Data::nextClassId($write, $_runTable, $_cc);

            $runRow = array(
                'class_id'          => $_classId,
                'product_id'        => $productId,
                'course_sku'        => $sku,
                // No direct trainer assignment on create — the chosen trainer is
                // added to the candidate pool below and only becomes the
                // confirmed trainer_user_id when they accept an invitation
                // (LMS model: assign = candidate, accept = confirmed).
                'reg_open_date'     => preg_match('/^\d{4}-\d{2}-\d{2}$/', $regOpen)   ? $regOpen   : null,
                'reg_close_date'    => preg_match('/^\d{4}-\d{2}-\d{2}$/', $regClose)  ? $regClose  : null,
                'course_start_date' => preg_match('/^\d{4}-\d{2}-\d{2}$/', $startDate) ? $startDate : null,
                'course_end_date'   => preg_match('/^\d{4}-\d{2}-\d{2}$/', $endDate)   ? $endDate   : null,
                'course_start_time' => preg_match('/^\d{2}:\d{2}(:\d{2})?$/', $startTime) ? $startTime : null,
                'course_end_time'   => preg_match('/^\d{2}:\d{2}(:\d{2})?$/', $endTime)   ? $endTime   : null,
                'venue_block'       => trim((string) $req->getParam('venue_block')),
                'venue_street'      => trim((string) $req->getParam('venue_street')),
                'venue_building'    => trim((string) $req->getParam('venue_building')),
                'venue_floor'       => trim((string) $req->getParam('venue_floor')),
                'venue_unit'        => trim((string) $req->getParam('venue_unit')),
                'postal_code'       => trim((string) $req->getParam('postal_code')),
                'room'              => trim((string) $req->getParam('room')),
                'wheelchair'        => strtolower(trim((string) $req->getParam('wheelchair'))) === 'yes' ? 1 : 0,
                'mode_of_training'  => (int) $req->getParam('mode_of_training') ?: 1,
                'admin_email'       => trim((string) $req->getParam('admin_email')),
                'vacancy'           => substr(strtoupper(trim((string) $req->getParam('vacancy'))), 0, 1) ?: 'A',
                'created_by'        => (($_u = Mage::getSingleton('admin/session')->getUser()) ? strtolower(trim((string) $_u->getEmail())) : ''),
            );
            $write->insert($_runTable, $runRow);
            $result['run_id']   = (int) $write->lastInsertId();
            $result['class_id'] = $_classId;

            // Add the chosen trainer account to the course's approved pool
            // (mmd_product_trainer) so the Assign Trainer modal + invitation
            // system include them. Idempotent. Account-based (Phase 2) — no
            // longer writes the legacy EAV `trainers` multiselect.
            if ($trainerUid > 0) {
                try {
                    $ptTbl  = $resource->getTableName('mmd_product_trainer');
                    $exists = (int) $read->fetchOne(
                        "SELECT id FROM {$ptTbl} WHERE product_id=? AND user_id=? LIMIT 1",
                        array($productId, $trainerUid)
                    );
                    if (!$exists) {
                        $nextSort = (int) $read->fetchOne(
                            "SELECT COALESCE(MAX(sort_order),-1)+1 FROM {$ptTbl} WHERE product_id=?",
                            array($productId)
                        );
                        $write->insert($ptTbl, array(
                            'product_id' => $productId,
                            'user_id'    => $trainerUid,
                            'sort_order' => $nextSort,
                        ));
                        $result['trainer_added'] = true;
                    } else {
                        $result['trainer_added'] = false; // already in pool
                    }
                } catch (Exception $e) { Mage::logException($e); }
            }

            // Update news_from_date / news_to_date — these power the
            // dashboard's Ongoing/Upcoming/Completed bucketing and the
            // Course Dates shown on the trainer's class card.
            $writeDate = function ($attrCode, $date) use ($read, $write, $eavDt, $productId) {
                if ($date === '' || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) return;
                $aid = (int) $read->fetchOne(
                    "SELECT attribute_id FROM eav_attribute WHERE attribute_code=? AND entity_type_id=4",
                    array($attrCode)
                );
                if (!$aid) return;
                $existing = $read->fetchOne(
                    "SELECT value_id FROM {$eavDt} WHERE entity_id=? AND attribute_id=? AND store_id=0 LIMIT 1",
                    array($productId, $aid)
                );
                if ($existing) {
                    $write->update($eavDt, array('value' => $date . ' 00:00:00'),
                        array('value_id = ?' => $existing));
                } else {
                    $write->insert($eavDt, array(
                        'entity_type_id' => 4,
                        'attribute_id'   => $aid,
                        'store_id'       => 0,
                        'entity_id'      => $productId,
                        'value'          => $date . ' 00:00:00',
                    ));
                }
            };
            $writeDate('news_from_date', $startDate);
            $writeDate('news_to_date',   $endDate);

            $result['success'] = true;
            $result['message'] = $trainerUid > 0
                ? 'Class scheduled. The trainer was added to this course\'s candidate list — send them an invitation from Assign Trainer to confirm them.'
                : 'Class scheduled.';
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Delete a course (product) by product_id.
     *
     * POST-only. Accepts product_id. Returns JSON {success, message}.
     * Blocks C-prefix / TGS- SKUs in country mode (sync-owned courses).
     * _validateFormKey() returns true so no URL-key CSRF issue.
     */
    public function deleteCourseAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $productId = (int) $this->getRequest()->getParam('product_id');
            if (!$productId) {
                throw new Exception('product_id required');
            }

            $product = Mage::getModel('catalog/product')->load($productId);
            if (!$product->getId()) {
                throw new Exception('Course not found');
            }

            if (strtolower((string) getenv('MMS_MODE')) === 'country') {
                $skuUpper = strtoupper(ltrim((string) $product->getSku()));
                if (substr($skuUpper, 0, 1) === 'C' || substr($skuUpper, 0, 4) === 'TGS-') {
                    throw new Exception(
                        'Course "' . $product->getSku() . '" is synced from Singapore '
                        . '(C-prefix / TGS-prefix) and cannot be deleted here — '
                        . 'it will be restored on the next sync.'
                    );
                }
            }

            $sku = $product->getSku();
            $product->delete();
            $result['success'] = true;
            $result['message'] = 'Course "' . $sku . '" deleted.';
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    protected function _sendJson(array $data)
    {
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($data));
    }

    protected function _validateFormKey()
    {
        return true;
    }

    /**
     * Replace a product's trainer multiselect with the given list.
     * Posted from the Assign Trainer panel modal.
     *
     * Inputs:
     *   product_id           — int, required
     *   trainer_option_ids   — comma-separated existing option_ids
     *   new_trainer_names    — pipe-separated free-text names that
     *                          should be created as new options first
     *
     * Final stored value: CSV of all option_ids on the catalog_product_entity_text
     * row for attribute_id of `trainers` (entity_type=4), store_id=0.
     */
    public function saveTrainersAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $req = $this->getRequest();
            $productId = (int) $req->getParam('product_id');
            if (!$productId) throw new Exception('product_id required');

            $resource = Mage::getSingleton('core/resource');
            $read     = $resource->getConnection('core_read');
            $write    = $resource->getConnection('core_write');

            // Resolve trainers attribute_id (cached lookup not necessary,
            // this action runs at human speed).
            $attrId = (int) $read->fetchOne(
                "SELECT attribute_id FROM " . $resource->getTableName('eav_attribute')
              . " WHERE attribute_code='trainers' AND entity_type_id=4"
            );
            if (!$attrId) throw new Exception('trainers attribute not found');

            $oidsRaw = (string) $req->getParam('trainer_option_ids');
            $oids = array();
            foreach (explode(',', $oidsRaw) as $v) {
                $v = (int) trim($v);
                if ($v > 0) $oids[$v] = $v;
            }

            // Create option rows for any free-text names from the
            // "Enter manually" mode, then merge into $oids.
            $newRaw = (string) $req->getParam('new_trainer_names');
            $optionTbl   = $resource->getTableName('eav_attribute_option');
            $optionValTbl= $resource->getTableName('eav_attribute_option_value');
            if (trim($newRaw) !== '') {
                foreach (explode('|', $newRaw) as $rawName) {
                    $name = trim($rawName);
                    if ($name === '') continue;
                    if (mb_strlen($name) > 200) $name = mb_substr($name, 0, 200);
                    // Reuse existing option if a row already exists with the
                    // same label at the default store, so manual entries
                    // don't create duplicates.
                    $existing = (int) $read->fetchOne(
                        "SELECT v.option_id FROM {$optionValTbl} v
                          JOIN {$optionTbl} o ON o.option_id=v.option_id
                          WHERE o.attribute_id=? AND v.store_id=0 AND v.value=? LIMIT 1",
                        array($attrId, $name)
                    );
                    if ($existing > 0) {
                        $oids[$existing] = $existing;
                        continue;
                    }
                    $write->insert($optionTbl, array(
                        'attribute_id' => $attrId,
                        'sort_order'   => 0,
                    ));
                    $newOid = (int) $write->lastInsertId();
                    $write->insert($optionValTbl, array(
                        'option_id' => $newOid,
                        'store_id'  => 0,
                        'value'     => $name,
                    ));
                    $oids[$newOid] = $newOid;
                }
            }

            // Persist as CSV on the catalog_product_entity_text row at
            // store_id=0. Even when the final list is empty, keep the
            // row (with value='') so the trainer dashboard knows the
            // admin explicitly cleared assignments — without that flag
            // it would fall back to trainerprofile-bio matching and
            // re-show the course to a trainer who was just removed.
            $textTbl = $resource->getTableName('catalog_product_entity_text');
            $csv = implode(',', array_values($oids));
            $existingRowId = (int) $read->fetchOne(
                "SELECT value_id FROM {$textTbl} WHERE entity_id=? AND attribute_id=? AND store_id=0",
                array($productId, $attrId)
            );
            if ($existingRowId) {
                $write->update($textTbl, array('value' => $csv), array('value_id=?' => $existingRowId));
            } else {
                $write->insert($textTbl, array(
                    'entity_type_id' => 4,
                    'attribute_id'   => $attrId,
                    'store_id'       => 0,
                    'entity_id'      => $productId,
                    'value'          => $csv,
                ));
            }

            // course_runs cascade: any scheduled run for this product
            // whose trainer was just removed gets its trainer_option_id
            // nulled — keeps the schedule but unassigns the trainer so
            // it stops showing on their My Assigned Classes.
            try {
                $runsTbl = $resource->getTableName('course_runs');
                if (empty($oids)) {
                    $write->update($runsTbl, array('trainer_option_id' => null), array('product_id=?' => $productId));
                } else {
                    $write->update(
                        $runsTbl,
                        array('trainer_option_id' => null),
                        array(
                            'product_id=?'                  => $productId,
                            'trainer_option_id NOT IN (?)'  => array_values($oids),
                        )
                    );
                }
            } catch (Exception $e) {}

            // Bust catalog block / flat caches so the next page render
            // sees the new value.
            try { Mage::app()->getCacheInstance()->cleanType('block_html'); } catch (Exception $e) {}

            $result['success']   = true;
            $result['option_ids']= array_values($oids);
            $result['message']   = 'Trainers updated.';
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);
        $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
    }

    /**
     * Phase 2 — account-based trainer assignment. Replaces a course's
     * approved-trainer pool with real operator accounts (admin_user with
     * the 'trainer' role) stored in mmd_product_trainer, instead of the
     * legacy EAV `trainers` multiselect. The trainer invitation system
     * reads mmd_product_trainer first (see TrainerInvitationService::
     * _buildQueue), so this is what drives invitations going forward.
     *
     * Legacy EAV assignments are left untouched (hybrid fallback) — this
     * action never writes catalog_product_entity_text. Previously assigned
     * EAV trainers keep resolving for display + as the invite fallback
     * until an admin re-saves the pool here with accounts.
     *
     * Inputs:
     *   product_id        — int, required
     *   trainer_user_ids  — comma-separated admin_user.user_id (trainer role)
     *
     * Returns JSON: { success, user_ids:[...], message }.
     */
    public function saveTrainerAccountsAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $productId = (int) $this->getRequest()->getParam('product_id');
            if (!$productId) throw new Exception('product_id required');

            $valid = $this->_persistProductTrainerPool(
                $productId, $this->getRequest()->getParam('trainer_user_ids')
            );
            try { Mage::app()->getCacheInstance()->cleanType('block_html'); } catch (Exception $e) {}

            $result['success']  = true;
            $result['user_ids'] = $valid;
            $result['message']  = 'Trainer pool updated.';
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);
        $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
    }

    /**
     * Replace a product's account-based trainer pool (mmd_product_trainer)
     * with the given user_ids, validating each is an active trainer account.
     * Cascades course_runs.trainer_user_id (nulls runs whose confirmed
     * trainer was dropped from the pool). Never touches the legacy EAV
     * `trainers` multiselect — that stays as a hybrid display/invite
     * fallback. Returns the validated user_id list.
     *
     * Shared by saveTrainerAccountsAction (Assign Trainer modal) and
     * saveAction (Edit Course → Trainer Details tab).
     */
    protected function _persistProductTrainerPool($productId, $rawUserIds)
    {
        $productId = (int) $productId;
        if (!$productId) return array();

        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $write    = $resource->getConnection('core_write');
        $ptTbl    = $resource->getTableName('mmd_product_trainer');

        // Parse + de-dupe the requested user_ids, preserving order so
        // sort_order reflects the admin's intended display sequence.
        $requested = array();
        foreach (explode(',', (string) $rawUserIds) as $v) {
            $v = (int) trim($v);
            if ($v > 0 && !in_array($v, $requested, true)) $requested[] = $v;
        }

        // Validate against real, active trainer-role accounts — silently
        // drop anything else so the pool can't be poisoned.
        $valid = array();
        if (!empty($requested)) {
            $au = $resource->getTableName('admin_user');
            $rm = $resource->getTableName('mmd_user_role_map');
            $in = implode(',', array_map('intval', $requested));
            $okIds = $read->fetchCol(
                "SELECT DISTINCT u.user_id
                   FROM `$au` u
                   JOIN `$rm` r ON r.user_id = u.user_id AND r.role_code = 'trainer'
                  WHERE u.is_active = 1 AND u.user_id IN ($in)"
            );
            $okSet = array_flip(array_map('intval', $okIds));
            foreach ($requested as $uid) {
                if (isset($okSet[$uid])) $valid[] = $uid;
            }
        }

        // Replace the pool: clear then re-insert in order.
        $write->delete($ptTbl, array('product_id = ?' => $productId));
        $sort = 0;
        foreach ($valid as $uid) {
            $write->insert($ptTbl, array(
                'product_id' => $productId,
                'user_id'    => $uid,
                'sort_order' => $sort++,
            ));
        }

        // course_runs cascade: any run for this product whose confirmed
        // account trainer was dropped from the pool gets trainer_user_id
        // nulled. Never touches trainer_option_id (legacy preserved).
        try {
            $runsTbl = $resource->getTableName('course_runs');
            if (empty($valid)) {
                $write->update($runsTbl, array('trainer_user_id' => null),
                    array('product_id = ?' => $productId));
            } else {
                $write->update($runsTbl, array('trainer_user_id' => null), array(
                    'product_id = ?'              => $productId,
                    'trainer_user_id NOT IN (?)'  => $valid,
                ));
            }
        } catch (Exception $e) {}

        return $valid;
    }

    /**
     * List learners attached to a product. Union of sales_flat_order
     * customers (historical purchases) and course_run_enrolments rows
     * (admin-driven enrolments via the Assign Learners panel).
     */
    public function loadLearnersAction()
    {
        $result = array('success' => false, 'learners' => array());
        try {
            $productId = (int) $this->getRequest()->getParam('product_id');
            $runId     = (int) $this->getRequest()->getParam('run_id');
            if (!$productId) throw new Exception('product_id required');

            $resource = Mage::getSingleton('core/resource');
            $read     = $resource->getConnection('core_read');

            // RUN-SCOPED roster (this exact class). The authoritative source is
            // course_run_enrolments for that run_id — orders are materialised
            // into it by class formation / backfill, so it is the single source
            // of truth per run (same source the attendance page uses). Minus
            // the per-course exclusion list. This makes the Assign Learners
            // modal match the per-run row it was opened from.
            if ($runId > 0) {
                $enrolTbl = $resource->getTableName('course_run_enrolments');
                $exclSet  = array_flip(array_map('strtolower', $read->fetchCol(
                    "SELECT learner_email FROM " . $resource->getTableName('course_learner_excludes') . " WHERE product_id = ?",
                    array($productId)
                )));
                $byEmail = array();
                foreach ($read->fetchAll(
                    "SELECT enrolment_id, learner_email, learner_name FROM `$enrolTbl` WHERE run_id = ? ORDER BY learner_name",
                    array($runId)
                ) as $r) {
                    $email = strtolower((string) $r['learner_email']);
                    if ($email === '' || isset($exclSet[$email])) continue;
                    $byEmail[$email] = array(
                        'email'    => $email,
                        'name'     => $r['learner_name'] ?: $email,
                        'source'   => 'manual',
                        'enrol_id' => (int) $r['enrolment_id'],
                    );
                }
                $result['learners'] = array_values($byEmail);
                $result['success']  = true;
                $this->getResponse()->setHeader('Content-Type', 'application/json', true);
                $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
                return;
            }

            $wid      = (int) Mage::helper('mmd_rolemanager')->getActiveWebsiteId();

            // Order-based learners (paid + processing only — pending /
            // payment_review aren't real attendees), scoped to the
            // logged-in admin's country website.
            $orderRows = $read->fetchAll(
                "SELECT DISTINCT
                        LOWER(o.customer_email) AS email,
                        COALESCE(NULLIF(TRIM(CONCAT(IFNULL(o.customer_firstname,''),' ',IFNULL(o.customer_lastname,''))),''), o.customer_email) AS name
                 FROM sales_flat_order o
                 JOIN sales_flat_order_item oi ON oi.order_id=o.entity_id
                 JOIN core_store cs ON cs.store_id=o.store_id AND cs.website_id=?
                 WHERE oi.product_id = ?
                   AND o.state IN ('complete','processing')
                   AND o.customer_email IS NOT NULL
                 ORDER BY name",
                array($wid, $productId)
            );
            $byEmail = array();
            foreach ($orderRows as $r) {
                $byEmail[$r['email']] = array(
                    'email'     => $r['email'],
                    'name'      => $r['name'],
                    'source'    => 'order',
                    'enrol_id'  => 0,
                );
            }

            // Admin-driven enrolments — survive even if no order exists.
            $enrolRows = $read->fetchAll(
                "SELECT enrolment_id, learner_email, learner_name
                 FROM " . $resource->getTableName('course_run_enrolments') . "
                 WHERE product_id = ?",
                array($productId)
            );
            foreach ($enrolRows as $r) {
                $email = strtolower((string) $r['learner_email']);
                $byEmail[$email] = array(
                    'email'    => $email,
                    'name'     => $r['learner_name'] ?: $email,
                    'source'   => 'manual',
                    'enrol_id' => (int) $r['enrolment_id'],
                );
            }

            // Honour the per-course exclusion list — lets Remove hide a
            // learner from this course's roster without touching the order.
            $excludes = $read->fetchCol(
                "SELECT learner_email
                 FROM " . $resource->getTableName('course_learner_excludes') . "
                 WHERE product_id = ?",
                array($productId)
            );
            foreach ($excludes as $exEmail) {
                unset($byEmail[strtolower((string) $exEmail)]);
            }

            $result['learners'] = array_values($byEmail);
            $result['success']  = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);
        $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
    }

    /**
     * Add an admin-driven learner enrolment. INSERT IGNORE on the
     * (product, run, email) unique key, so re-adding the same learner
     * is a no-op rather than an error.
     */
    public function addLearnerAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $req = $this->getRequest();
            $productId = (int) $req->getParam('product_id');
            $email     = strtolower(trim((string) $req->getParam('learner_email')));
            $name      = trim((string) $req->getParam('learner_name'));
            if (!$productId) throw new Exception('product_id required');
            if ($email === '' || strpos($email, '@') === false) throw new Exception('Valid learner email required');

            $resource = Mage::getSingleton('core/resource');
            $read     = $resource->getConnection('core_read');
            $write    = $resource->getConnection('core_write');
            $tbl      = $resource->getTableName('course_run_enrolments');

            // Run target: prefer the explicit run_id the modal was opened from
            // (run-scoped enrol — attaches to THAT exact class, incl. ongoing/
            // past). Validate it belongs to this product. Fall back to the
            // product's latest run only when no valid run_id is supplied
            // (back-compat for callers that don't pass one).
            $reqRunId = (int) $req->getParam('run_id');
            if ($reqRunId > 0) {
                $runId = (int) $read->fetchOne(
                    "SELECT run_id FROM " . $resource->getTableName('course_runs') . " WHERE run_id=? AND product_id=? LIMIT 1",
                    array($reqRunId, $productId)
                );
                $runId = $runId ?: null;
            } else {
                $runId = $read->fetchOne(
                    "SELECT MAX(run_id) FROM " . $resource->getTableName('course_runs') . " WHERE product_id=?",
                    array($productId)
                );
                $runId = $runId ? (int) $runId : null;
            }

            // Auto-fill name from existing customer record if blank.
            if ($name === '') {
                $name = (string) $read->fetchOne(
                    "SELECT COALESCE(NULLIF(TRIM(CONCAT(IFNULL(o.customer_firstname,''),' ',IFNULL(o.customer_lastname,''))),''), o.customer_email)
                     FROM sales_flat_order o
                     WHERE LOWER(o.customer_email)=? ORDER BY o.entity_id DESC LIMIT 1",
                    array($email)
                );
                if ($name === '') $name = $email;
            }

            $write->query(
                "INSERT IGNORE INTO {$tbl} (product_id, run_id, learner_email, learner_name) VALUES (?, ?, ?, ?)",
                array($productId, $runId, $email, $name)
            );
            // If this learner was previously hidden via Remove, clear the
            // exclusion so they reappear in the roster.
            $write->delete(
                $resource->getTableName('course_learner_excludes'),
                array('product_id=?' => $productId, 'learner_email=?' => $email)
            );
            $result['success'] = true;
            $result['email']   = $email;
            $result['name']    = $name;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);
        $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
    }

    /**
     * Hide a learner from this course's roster. Manual enrolments are
     * deleted outright; order-sourced learners are added to the
     * course_learner_excludes suppression list so the underlying order
     * is untouched. Reversible via addLearnerAction (which clears the
     * exclusion row).
     */
    public function removeLearnerAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $req = $this->getRequest();
            $productId = (int) $req->getParam('product_id');
            $runId     = (int) $req->getParam('run_id');
            $email     = strtolower(trim((string) $req->getParam('learner_email')));
            if (!$productId || $email === '') throw new Exception('product_id + learner_email required');

            $resource = Mage::getSingleton('core/resource');
            $write    = $resource->getConnection('core_write');

            if ($runId > 0) {
                // RUN-SCOPED remove: drop the enrolment for THIS run only.
                // No product-wide exclude — removing from one class must not
                // hide the learner from the course's other runs. The per-run
                // roster reads from course_run_enrolments, so deleting the row
                // is sufficient (class formation is idempotent + won't re-add).
                $write->delete(
                    $resource->getTableName('course_run_enrolments'),
                    array('run_id=?' => $runId, 'learner_email=?' => $email)
                );
                $result['success'] = true;
            } else {
                // Product-scoped remove (legacy path, no run_id supplied).
                // Drop the manual enrolment if any — covers learners added via
                // Add Learner. For order-sourced learners this is a no-op.
                $write->delete(
                    $resource->getTableName('course_run_enrolments'),
                    array('product_id=?' => $productId, 'learner_email=?' => $email)
                );
                // Suppress the (product, email) pair so order-sourced learners
                // also disappear from the roster. Reversible via Add Learner.
                $adminUser = Mage::getSingleton('admin/session')->getUser();
                $excludedBy = $adminUser ? (int) $adminUser->getId() : null;
                $write->insertOnDuplicate(
                    $resource->getTableName('course_learner_excludes'),
                    array(
                        'product_id'    => $productId,
                        'learner_email' => $email,
                        'excluded_by'   => $excludedBy,
                    ),
                    array('excluded_by', 'excluded_at')
                );
                $result['success'] = true;
            }
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);
        $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
    }

    /**
     * Autocomplete for the "Select from list" trainer dropdown — returns
     * up to 30 customers whose email or name contains the query string.
     * Read-only, draws from sales_flat_order to bias toward customers
     * who have placed orders before.
     */
    public function searchLearnersAction()
    {
        $result = array('success' => false, 'learners' => array());
        try {
            $q = strtolower(trim((string) $this->getRequest()->getParam('q')));
            if (mb_strlen($q) < 2) {
                $result['success'] = true;
                $this->getResponse()->setHeader('Content-Type', 'application/json', true);
                $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
                return;
            }
            $resource = Mage::getSingleton('core/resource');
            $read     = $resource->getConnection('core_read');
            $wid      = (int) Mage::helper('mmd_rolemanager')->getActiveWebsiteId();
            $like = '%' . $q . '%';

            // Resolve customer firstname/lastname attribute IDs once.
            // OpenMage customer entity_type_id is 1.
            $fnId = (int) $read->fetchOne(
                "SELECT attribute_id FROM eav_attribute
                 WHERE entity_type_id=1 AND attribute_code='firstname'"
            );
            $lnId = (int) $read->fetchOne(
                "SELECT attribute_id FROM eav_attribute
                 WHERE entity_type_id=1 AND attribute_code='lastname'"
            );

            // Search three sources so any user who could be a learner is
            // findable, regardless of whether they've placed an order:
            //   1. sales_flat_order — guests + customers with orders
            //   2. customer_entity  — every registered account on the website
            //   3. admin_user joined to mmd_user_role_map — admin-side
            //      accounts assigned the 'learner' role. Added 2026-05-07
            //      because admin-created test users with the learner role
            //      never go through the storefront, so they don't appear
            //      in customer_entity / sales_flat_order. Without this
            //      branch they were unreachable from Assign Learner.
            // UNION dedupes on (email, name).
            $rows = $read->fetchAll(
                "SELECT email, name FROM (
                    SELECT DISTINCT
                            LOWER(o.customer_email) AS email,
                            COALESCE(NULLIF(TRIM(CONCAT(IFNULL(o.customer_firstname,''),' ',IFNULL(o.customer_lastname,''))),''), o.customer_email) AS name
                     FROM sales_flat_order o
                     JOIN core_store cs ON cs.store_id=o.store_id AND cs.website_id=?
                     WHERE o.customer_email IS NOT NULL
                       AND (LOWER(o.customer_email) LIKE ?
                            OR LOWER(CONCAT(IFNULL(o.customer_firstname,''),' ',IFNULL(o.customer_lastname,''))) LIKE ?)
                    UNION
                    SELECT DISTINCT
                            LOWER(ce.email) AS email,
                            COALESCE(NULLIF(TRIM(CONCAT(IFNULL(fn.value,''),' ',IFNULL(ln.value,''))),''), ce.email) AS name
                     FROM customer_entity ce
                     LEFT JOIN customer_entity_varchar fn ON fn.entity_id=ce.entity_id AND fn.attribute_id=?
                     LEFT JOIN customer_entity_varchar ln ON ln.entity_id=ce.entity_id AND ln.attribute_id=?
                     WHERE ce.website_id=?
                       AND ce.email IS NOT NULL
                       AND (LOWER(ce.email) LIKE ?
                            OR LOWER(CONCAT(IFNULL(fn.value,''),' ',IFNULL(ln.value,''))) LIKE ?)
                    UNION
                    SELECT DISTINCT
                            LOWER(au.email) AS email,
                            COALESCE(NULLIF(TRIM(CONCAT(IFNULL(au.firstname,''),' ',IFNULL(au.lastname,''))),''), au.email) AS name
                     FROM admin_user au
                     INNER JOIN mmd_user_role_map mrm
                            ON mrm.user_id = au.user_id
                           AND mrm.role_code = 'learner'
                     WHERE au.email IS NOT NULL
                       AND au.is_active = 1
                       AND (LOWER(au.email) LIKE ?
                            OR LOWER(CONCAT(IFNULL(au.firstname,''),' ',IFNULL(au.lastname,''))) LIKE ?)
                ) s
                ORDER BY name
                LIMIT 60",
                array($wid, $like, $like, $fnId, $lnId, $wid, $like, $like, $like, $like)
            );
            $result['learners'] = $rows;
            $result['success']  = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->getResponse()->setHeader('Content-Type', 'application/json', true);
        $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
    }

    /**
     * Admin AJAX: generate SEO Meta (title, keywords, description) via Claude CLI.
     *
     * Mode is explicit — the admin clicks either the "WSQ" or "Non-WSQ"
     * button beside the SEO Meta panel header, and that selection rides
     * through as the `mode` POST param. We do NOT auto-detect from SKU
     * because some non-TGS courses are still WSQ-funded (and vice versa).
     * Inputs come from the modal that the admin reviews before clicking
     * Generate; the modal pre-fills them from the current edit form so the
     * caller doesn't need to re-type Course Name / Learning Outcomes /
     * Course Description.
     *
     * Powered by the `claude` binary installed in the web container
     * (Dockerfile) and authenticated via the host's ~/.claude mount
     * (docker-compose.yml). Local-dev only for now.
     */
    public function aiSeoAction()
    {
        $resp = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $productId = (int) $this->getRequest()->getParam('product_id');
            if ($productId <= 0) {
                throw new Exception('product_id missing');
            }
            $product = Mage::getModel('catalog/product')->load($productId);
            if (!$product->getId()) {
                throw new Exception('Course not found');
            }

            // Mode → prompt template + input shape.
            //   wsq    = SG WSQ-funded course (training/competency inputs)
            //   non_wsq = generic Non-WSQ (course_name / key_topics /
            //             course_highlights — used for SG non-funded and
            //             all other countries)
            $mode   = (string) $this->getRequest()->getParam('mode');
            $tplMap = array(
                'wsq'     => 'wsq.md',
                'non_wsq' => 'non-wsq.md',
            );
            if (!isset($tplMap[$mode])) {
                $mode = 'non_wsq';
            }
            $isWsq    = ($mode === 'wsq');
            $isWsqLike = $isWsq;

            $tplFile = Mage::getBaseDir('code')
                . '/local/MMD/RoleManager/etc/ai-seo/'
                . $tplMap[$mode];
            if (!is_readable($tplFile)) {
                throw new Exception('Prompt template missing: ' . basename($tplFile));
            }
            $tpl = file_get_contents($tplFile);

            // Country name that lands at the tail of the meta title
            // ("... | Tertiary Courses Singapore"). Whitelisted so a typo
            // or injection in the POST can't pollute the prompt.
            $countryWhitelist = array(
                'Singapore', 'Nigeria',
            );
            $country = (string) $this->getRequest()->getParam('country');
            if (!in_array($country, $countryWhitelist, true)) {
                $country = 'Singapore';
            }

            $vals = $isWsqLike ? array(
                'course_title'      => (string) $this->getRequest()->getParam('course_title'),
                'learning_outcomes' => (string) $this->getRequest()->getParam('learning_outcomes'),
                'topics'            => (string) $this->getRequest()->getParam('topics'),
                'country'           => $country,
            ) : array(
                'course_name'       => (string) $this->getRequest()->getParam('course_name'),
                'key_topics'        => (string) $this->getRequest()->getParam('key_topics'),
                'course_highlights' => (string) $this->getRequest()->getParam('course_highlights'),
                'country'           => $country,
            );
            foreach ($vals as $k => $v) {
                $tpl = str_replace('{' . $k . '}', $v, $tpl);
            }

            // Two-tier generation strategy:
            //   1. If a real Anthropic API key (sk-ant-api*) is set,
            //      call the Messages API directly (3–8s).
            //   2. Otherwise (or if API fails) fall through to the
            //      `claude` CLI which uses the host's mounted ~/.claude
            //      auth — this works even when the OAuth token in
            //      local.xml is rate-limited (different auth path).
            //   3. Last resort: deterministic stub keyed off the course
            //      data so the UI always gets *something* usable.
            $cfg     = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
            $apiKey  = trim((string) ($cfg['anthropic_key']   ?? ''));
            $model   = trim((string) ($cfg['anthropic_model'] ?? '')) ?: 'claude-sonnet-4-6';
            $stdout  = '';
            $stubbed = false;
            $stubReason = '';

            // Tier 1 — direct API, only when a real `sk-ant-api*` key is
            // configured. OAuth tokens (sk-ant-oat*) are skipped here
            // because they hit aggressive rate limits and consistently
            // 429; we go straight to the CLI instead.
            if (stripos($apiKey, 'sk-ant-api') === 0) {
                try {
                    $body = json_encode(array(
                        'model'      => $model,
                        'max_tokens' => 1500,
                        'system'     => 'You are an SEO copywriter for Tertiary Courses, a training provider operating in ' . $country . '. The meta title brand suffix MUST be exactly "| Tertiary Courses ' . $country . '" — do not substitute any other country. Output exactly the labeled sections requested, no preamble.',
                        'messages'   => array(array('role' => 'user', 'content' => $tpl)),
                    ));
                    $ch = curl_init('https://api.anthropic.com/v1/messages');
                    curl_setopt_array($ch, array(
                        CURLOPT_POST           => true,
                        CURLOPT_POSTFIELDS     => $body,
                        CURLOPT_RETURNTRANSFER => true,
                        CURLOPT_TIMEOUT        => 30,
                        CURLOPT_CONNECTTIMEOUT => 10,
                        CURLOPT_HTTPHEADER     => array(
                            'anthropic-version: 2023-06-01',
                            'content-type: application/json',
                            'x-api-key: ' . $apiKey,
                        ),
                    ));
                    $raw  = curl_exec($ch);
                    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
                    curl_close($ch);
                    $rsp = json_decode($raw, true);
                    if ($code >= 400 || !isset($rsp['content'][0]['text'])) {
                        $msg = $rsp['error']['message'] ?? substr($raw, 0, 150);
                        throw new Exception('API HTTP ' . $code . ': ' . $msg);
                    }
                    $stdout = (string) $rsp['content'][0]['text'];
                } catch (Exception $e) {
                    $stubReason = $e->getMessage();
                }
            }

            // Tier 2 — `claude` CLI. This uses the host's mounted
            // ~/.claude OAuth which is a different auth path from the
            // API key; bypasses the 429 the API path hits. We bound it
            // with `timeout 75s` so a hung CLI can never lock up an
            // Apache worker for minutes again.
            if ($stdout === '') {
                $descriptors = array(
                    0 => array('pipe', 'r'),
                    1 => array('pipe', 'w'),
                    2 => array('pipe', 'w'),
                );
                $env = array();
                foreach ($_ENV as $k => $v) {
                    if ($k !== 'CLAUDECODE') $env[$k] = $v;
                }
                foreach (array('PATH', 'HOME') as $k) {
                    if (!isset($env[$k]) && getenv($k) !== false) {
                        $env[$k] = getenv($k);
                    }
                }
                // Apache runs as www-data with HOME=/var/www. The
                // `claude` CLI reads credentials from $HOME/.claude.
                // The host's ~/.claude is mounted at /root/.claude but
                // /root is 0700 root-only so www-data can't reach it —
                // result: CLI sits at the auth prompt until our
                // timeout fires and we wrongly fall to the stub.
                // Fix: read creds from /var/www/.claude (copied at
                // container start, owned by www-data).
                if (is_dir('/var/www/.claude')) {
                    $env['HOME'] = '/var/www';
                } elseif (is_dir('/root/.claude') && is_readable('/root')) {
                    $env['HOME'] = '/root';
                }
                $proc = @proc_open(
                    'timeout 100 claude -p --output-format text',
                    $descriptors, $pipes, null, $env
                );
                if (is_resource($proc)) {
                    fwrite($pipes[0], $tpl);
                    fclose($pipes[0]);
                    stream_set_blocking($pipes[1], false);
                    stream_set_blocking($pipes[2], false);
                    $deadline = time() + 105;
                    $cliOut = ''; $cliErr = '';
                    $finalExit = -1;
                    // Important gotcha: once proc_get_status returns
                    // running=false, PHP records the exit code and
                    // proc_close() returns -1 (process already reaped).
                    // So we MUST capture exitcode from proc_get_status
                    // — not from proc_close — or the success path is
                    // unreachable.
                    while (time() < $deadline) {
                        $status = proc_get_status($proc);
                        $cliOut .= stream_get_contents($pipes[1]);
                        $cliErr .= stream_get_contents($pipes[2]);
                        if (!$status['running']) {
                            $finalExit = $status['exitcode'];
                            break;
                        }
                        usleep(200000);
                    }
                    // Force-kill if we fell out of the loop without it
                    // exiting on its own.
                    $status = proc_get_status($proc);
                    if ($status['running']) {
                        proc_terminate($proc, 9);
                        $finalExit = 137; // 128 + SIGKILL
                    }
                    $cliOut .= stream_get_contents($pipes[1]);
                    $cliErr .= stream_get_contents($pipes[2]);
                    fclose($pipes[1]);
                    fclose($pipes[2]);
                    proc_close($proc);  // reaps the resource; return value ignored
                    if ($finalExit === 0 && trim($cliOut) !== '') {
                        $stdout = $cliOut;
                        $stubReason = '';  // CLI succeeded — clear API-tier error
                    } elseif ($stubReason === '') {
                        $stubReason = 'CLI exit ' . $finalExit . ': ' . trim($cliErr);
                    }
                }
            }

            // Tier 3 — deterministic stub. Last resort.
            if ($stdout === '') {
                $stubbed = true;
                if ($stubReason === '') $stubReason = 'no generator available';
                $stdout  = $this->_buildAiSeoStub($mode, $vals, $product);
            }

            $sections = $this->_parseAiSeoSections($stdout);

            $resp['success']          = true;
            $resp['mode']             = $mode;
            $resp['meta_title']       = $sections['meta_title']       ?? '';
            $resp['meta_keyword']     = $sections['meta_keywords']    ?? '';
            $resp['meta_description'] = $sections['meta_description'] ?? '';
            $resp['raw']              = $stdout;
            $resp['stubbed']          = $stubbed;
            if ($stubbed) $resp['stub_reason'] = $stubReason;

            // When the client passes save=1 + seo_target_store_id we
            // persist the generated meta to that store scope immediately
            // (skip on stubbed output — we don't want to overwrite real
            // editorial content with a deterministic fallback).
            $saveStoreId = (int) $this->getRequest()->getParam('seo_target_store_id', 0);
            if ($this->getRequest()->getParam('save') && $saveStoreId > 0 && !$stubbed) {
                Mage::getModel('mmd_rolemanager/aiSeo')->persistToStore(
                    $productId,
                    $saveStoreId,
                    $resp['meta_title'],
                    $resp['meta_keyword'],
                    $resp['meta_description']
                );
                $resp['saved']          = true;
                $resp['saved_store_id'] = $saveStoreId;
            }
        } catch (Exception $e) {
            $resp['message'] = $e->getMessage();
        }
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(Mage::helper('core')->jsonEncode($resp));
    }

    /**
     * Generate SEO meta for ONE course across ALL country store views in a
     * single AI call (the multi-store prompt produces 5 country titles +
     * shared keywords + 2 description variants), then persist each piece
     * to the appropriate store scope.
     *
     * Cost: 1 Claude call per product instead of 5.
     */
    public function aiSeoAllStoresAction()
    {
        $resp = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $productId = (int) $this->getRequest()->getParam('product_id');
            if ($productId <= 0) {
                throw new Exception('product_id missing');
            }
            $product = Mage::getModel('catalog/product')->load($productId);
            if (!$product->getId()) {
                throw new Exception('Course not found');
            }

            $aiSeo = Mage::getModel('mmd_rolemanager/aiSeo');
            $result = $aiSeo->generateMultiStore(
                $product,
                (string) $this->getRequest()->getParam('course_title'),
                (string) $this->getRequest()->getParam('learning_outcomes'),
                (string) $this->getRequest()->getParam('course_highlights')
            );

            if (!$result['stubbed']) {
                foreach ($result['per_store'] as $storeId => $row) {
                    $aiSeo->persistToStore(
                        $productId, $storeId,
                        $row['meta_title'], $row['meta_keyword'], $row['meta_description']
                    );
                }
            }

            $resp['success']     = true;
            $resp['stubbed']     = $result['stubbed'];
            if ($result['stubbed']) $resp['stub_reason'] = $result['stub_reason'];
            $resp['per_store']   = $result['per_store'];
            $resp['raw']         = $result['raw'];
        } catch (Exception $e) {
            $resp['message'] = $e->getMessage();
        }
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(Mage::helper('core')->jsonEncode($resp));
    }


    /**
     * One-click brochure generator. Mirrors aiSeoAction's plumbing:
     *
     *   1. Collect course data verbatim from the product entity + the
     *      per-course CMS blocks (`course_<sku>_<section>`).
     *   2. Ask Claude to polish three prose fields (description,
     *      learning outcomes, who-should-attend). Tier-1 direct API,
     *      tier-2 `claude` CLI, tier-3 pass-through stub. AI never
     *      touches factual fields (price, dates, SKUs, codes).
     *   3. Render the brochure.phtml template (text-only A4, no images)
     *      and pipe it through mPDF.
     *   4. Write to media/courses/brochures/<sku>.pdf and return its URL
     *      so the JS can drop a "Download Course Brochure" anchor into
     *      the brochure CMS-block textarea.
     */
    public function generateBrochureAction()
    {
        $resp = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $productId = (int) $this->getRequest()->getParam('product_id');
            if ($productId <= 0) {
                throw new Exception('product_id missing');
            }
            $product = Mage::getModel('catalog/product')->load($productId);
            if (!$product->getId()) {
                throw new Exception('Course not found');
            }
            if (!class_exists('\\Mpdf\\Mpdf')) {
                throw new Exception('mPDF not installed — run composer require mpdf/mpdf');
            }
            // Supported scope: two country storefronts (SG/NG).
            //
            // Country pick:
            //   1. Trust the POST `wid` first — that's the Store-View
            //      pill the admin clicked on this page load. The
            //      dashboard JS reads it at render and POSTs it
            //      because the fetch URL has no ?store= of its own.
            //      Falls back to the rolemanager helper if missing
            //      (direct-POST tools, smoke tests).
            //   2. Accept View-As ONLY when the course is actually
            //      published there. Brochures pull country-scoped
            //      venue / store_info / price — generating a "-SG.pdf"
            //      for another-country course would produce a Frankenstein
            //      with SG venue + wrong price.
            //      Roles don't override this: even developers must
            //      have the course on the country they're generating
            //      for. The Store-View bar already lets any role
            //      switch country.
            //   3. Otherwise fall back to the course's smallest-id
            //      supported website so the button always produces a
            //      coherent brochure.
            //
            // Throws only when the course isn't on any supported
            // active country.
            $supported   = array(1, 4);
            $productWids = $this->_courseWebsiteIds((int) $product->getId());

            $viewAsWid = (int) $this->getRequest()->getParam('wid');
            if ($viewAsWid <= 0) {
                try { $viewAsWid = (int) Mage::helper('mmd_rolemanager')->getActiveWebsiteId(); }
                catch (Exception $e) { $viewAsWid = 0; }
            }

            $broWid = 0;
            if (in_array($viewAsWid, $supported, true)
                && in_array($viewAsWid, $productWids, true)) {
                $broWid = $viewAsWid;
            } else {
                foreach ($productWids as $wid) {
                    if (in_array($wid, $supported, true)) {
                        $broWid = (int) $wid;
                        break;
                    }
                }
            }
            if ($broWid <= 0) {
                throw new Exception('This course is not assigned to any of the supported country storefronts (SG / NG). Assign it to a country before generating a brochure.');
            }

            $context = $this->_collectBrochureContext($product, $broWid);

            $stubbed    = false;
            $stubReason = '';
            $polish     = $this->_polishBrochureProse($context, $stubbed, $stubReason);

            // Merge polished prose back into context only when AI
            // produced non-empty output — never overwrite real data
            // with empty AI strings.
            if (trim((string) $polish['description']) !== '') {
                $context['description'] = $polish['description'];
            }
            if (!empty($polish['learning_outcomes'])) {
                $context['outcomes'] = $polish['learning_outcomes'];
            }
            if (trim((string) $polish['who_should_attend']) !== '') {
                $context['who_attend'] = $polish['who_should_attend'];
            }

            $url = $this->_renderBrochurePdf($product, $context);

            $resp['success']    = true;
            $resp['url']        = $url;
            $resp['stubbed']    = $stubbed;
            if ($stubbed) {
                $resp['stub_reason'] = $stubReason;
            }
            // Drive upload result (populated inside _renderBrochurePdf
            // via _uploadBrochureToDrive). May be null when no key file
            // is configured on this environment.
            if (isset($context['drive_result']) && is_array($context['drive_result'])) {
                $resp['drive'] = $context['drive_result'];
            }
        } catch (Exception $e) {
            $resp['message'] = $e->getMessage();
        }
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(Mage::helper('core')->jsonEncode($resp));
    }

    /**
     * Walk the product entity and per-course CMS blocks to collect a
     * flat $context array consumed by brochure.phtml. No AI; this is
     * the source-of-truth snapshot.
     *
     * Resolves the admin's currently-active website (RoleManager "View
     * As" scope) and pulls store_information / WhatsApp / price / GST
     * from that scope so the brochure is country-correct — provider
     * name, phone, currency, funding tiers all change to match.
     */
    protected function _collectBrochureContext($product, $widOverride = null)
    {
        $sku = (string) $product->getSku();

        // ---- Active country --------------------------------------
        // generateBrochureAction picks the country (View-As if the
        // course is on it, else the course's smallest-id supported
        // website) and passes it down — see the entry-gate comment.
        // When called directly (smoke tests etc.) we fall back to the
        // admin's View-As, then to SG (1).
        $activeWid = (int) $widOverride;
        if ($activeWid <= 0) {
            try { $activeWid = (int) Mage::helper('mmd_rolemanager')->getActiveWebsiteId(); }
            catch (Exception $e) { $activeWid = 0; }
        }
        if ($activeWid <= 0) $activeWid = 1;
        $scopeStoreId = null;
        try {
            $website = Mage::app()->getWebsite($activeWid);
            $group   = $website->getDefaultGroup();
            if ($group) $scopeStoreId = (int) $group->getDefaultStoreId();
        } catch (Exception $e) {
            $scopeStoreId = null;
        }

        // Load product in the country's store scope so per-store EAV
        // overrides (e.g. localised description) win over the default.
        $admin = Mage::getModel('catalog/product')
            ->setStoreId($scopeStoreId !== null ? $scopeStoreId : Mage_Core_Model_App::ADMIN_STORE_ID)
            ->load($product->getId());

        $self = $this;
        $cmsHtml = function ($code) use ($sku, $self) {
            if ($sku === '') return '';
            $b = Mage::getModel('cms/block')->load('course_' . $sku . '_' . $code, 'identifier');
            if (!$b->getId() || !$b->getIsActive()) return '';
            return $self->_sanitizeRichHtml((string) $b->getContent());
        };

        // ---- Funding badges (plain text), filtered per country ------
        // getProductBadges() returns every funding tag set on the
        // product — for a course on multiple sites that can include
        // SG schemes (WSQ, SkillsFuture Credit, etc.). The brochure must
        // show only the badges that apply to the country it's being generated
        // for, else a non-SG brochure ends up advertising SG funding.
        //
        // Canonical badge map per country (CLAUDE.md):
        //   SG → WSQ, SkillsFuture Credit, PSEA, UTAP, IBF, SFEC,
        //        Absentee Payroll, MCES
        //   NG → no funding badges yet (the schemes haven't
        //        been wired in; leave empty rather than show wrong ones)
        $countryBadgeMap = array(
            1 => array('WSQ', 'SkillsFuture Credit', 'PSEA', 'UTAP', 'IBF',
                       'SFEC', 'Absentee Payroll', 'MCES'),
            4 => array(),
        );
        $allowedBadges = $countryBadgeMap[(int) $activeWid] ?? array();
        $badges = array();
        try {
            $h = Mage::helper('mmd_courseimage');
            if ($h && is_callable(array($h, 'getProductBadges'))) {
                $b = $h->getProductBadges($admin);
                if (is_array($b)) {
                    foreach ($b as $name) {
                        if (in_array((string) $name, $allowedBadges, true)) {
                            $badges[] = $name;
                        }
                    }
                }
            }
        } catch (Exception $e) {
            $badges = array();
        }

        // ---- Price + GST + WSQ funding tiers ------------------------
        // SG: 9% GST on top of catalog price. WSQ funded tiers come
        // from the same formulas used on the storefront
        // (catalog/product/view.phtml around line 782):
        //   Baseline Nett = price * 0.50 + GST   (SG/PR 21+, 50% funded)
        //   MCES/SME Nett = price * 0.30 + GST   (SG 40+,    70% funded)
        // Only emitted for Singapore + WSQ-coded SKUs (TGS-*); other
        // stores get just bef-GST / incl-GST.
        $rawPrice = (float) $admin->getPrice();
        $isSg     = ($activeWid === 1);
        $isWsq    = $isSg && (strpos(strtoupper($sku), 'TGS-') === 0);
        $gstRate  = $isSg ? 0.09 : 0.0;
        $cur      = $this->_currencySymbolForWebsite($activeWid);
        $fmt      = function ($v) use ($cur) { return $cur . number_format((float) $v, 2); };

        $price          = $rawPrice > 0 ? $fmt($rawPrice) : '';
        $price_gst      = $rawPrice > 0 && $gstRate > 0 ? $fmt($rawPrice * $gstRate) : '';
        $price_incl_gst = $rawPrice > 0 ? $fmt($rawPrice * (1 + $gstRate)) : '';

        $funded_tiers = array();
        if ($isWsq && $rawPrice > 0) {
            $gst = $rawPrice * $gstRate;
            $funded_tiers = array(
                array(
                    'label' => 'Baseline Nett',
                    'value' => $fmt($rawPrice * 0.50 + $gst),
                    'hint'  => 'SG/PR age 21+ · 50% funded · incl. GST',
                ),
                array(
                    'label' => 'MCES / SME Nett',
                    'value' => $fmt($rawPrice * 0.30 + $gst),
                    'hint'  => 'SG age 40+ · 70% funded · incl. GST',
                ),
            );
        }

        // ---- Level (option label, not raw id) -----------------------
        $level = '';
        try {
            $level = (string) $admin->getAttributeText('level');
        } catch (Exception $e) {
            $level = '';
        }
        if ($level === '') $level = (string) $admin->getData('level');

        // ---- Store info (per active website) ------------------------
        $store = Mage::getStoreConfig('general/store_information', $scopeStoreId);
        if (!is_array($store)) $store = array();

        // WhatsApp number — per-website config, set by migration 123.
        $whatsapp = '';
        try {
            $whatsapp = (string) Mage::getStoreConfig('mmd_whatsapp/general/number', $scopeStoreId);
        } catch (Exception $e) {
            $whatsapp = '';
        }
        // Email override that the contacts CMS block uses — fall back
        // to the generic Magento contact email if no merchant_email set.
        $storeEmail = (string) ($store['merchant_email']
            ?? Mage::getStoreConfig('trans_email/ident_general/email', $scopeStoreId));

        // ---- Storefront product URL (registration link) ------------
        // Builds against the COUNTRY'S PRODUCTION domain so the link
        // in the printed brochure always lands on the right storefront
        // — clicking a GH brochure's Sign Up link opens
        // tertiarycourses.com.ng, etc.
        // (the Apache vhost routes via MAGE_RUN_CODE on the Host
        // header — see /var/www/html/.htaccess SetEnvIf lines).
        // Mage::getBaseUrl() / $product->getProductUrl() would point
        // at localhost when generating in dev, defeating the link's
        // purpose since the brochure is meant to be shared with
        // learners.
        $prodHosts = array(
            1 => 'https://www.tertiarycourses.com.sg/',
            4 => 'https://www.tertiarycourses.com.ng/',
        );
        $prodBase = $prodHosts[(int) $activeWid] ?? $prodHosts[1];
        $registrationUrl = '';
        try {
            $urlKey = (string) $admin->getData('url_key');
            if ($urlKey === '') $urlKey = (string) $admin->getUrlKey();
            if ($urlKey !== '') {
                $registrationUrl = $prodBase . $urlKey . '.html';
            } else {
                $registrationUrl = $prodBase;
            }
        } catch (Exception $e) {
            $registrationUrl = $prodBase;
        }

        $descRaw = (string) ($admin->getData('description') ?: $admin->getData('short_description'));

        // ---- Storefront-style formatted facts -----------------------
        $sessionsRaw = trim((string) $admin->getData('sessions'));
        $sessionsFmt = $sessionsRaw !== ''
            ? $sessionsRaw . ' day' . ((int) $sessionsRaw === 1 ? '' : 's') : '';
        $durationRaw = trim((string) $admin->getData('duration'));
        $durationFmt = $durationRaw !== '' ? $durationRaw . ' hrs' : '';

        // assessment_duration attribute → "1 hr" / "2 hrs" / "NA". The
        // attribute is a varchar (no source model), so getAttributeText
        // would TypeError on getSource() — fall back to raw data via
        // Throwable catch so a missing/misconfigured attribute doesn't
        // sink the whole brochure render.
        $assessDur = '';
        try { $assessDur = (string) $admin->getAttributeText('assessment_duration'); }
        catch (Throwable $e) { $assessDur = (string) $admin->getData('assessment_duration'); }
        $assessDurFmt = '';
        if ($assessDur !== '' && $assessDur !== false) {
            $assessDurFmt = ($assessDur === 'NA') ? 'NA'
                : ($assessDur . ' hr' . ($assessDur === '1' ? '' : 's'));
        }
        // WSQ default: every WSQ course has a Written + Practical
        // assessment of ~1 hour by convention. If the admin hasn't
        // filled the attribute yet (common for older SKUs), populate
        // the tile with the standard 1 hr instead of an em-dash so
        // the brochure doesn't ship a "—" where a real time should be.
        if ($assessDurFmt === '' && $isWsq) {
            $assessDurFmt = '1 hr';
        }

        // assessment_methods multiselect — list of method labels.
        $assessMethods = array();
        try {
            $raw = $admin->getAttributeText('assessment_methods');
            if (is_array($raw)) {
                $assessMethods = array_values(array_filter(array_map('trim', $raw)));
            } elseif (is_string($raw) && trim($raw) !== '') {
                $assessMethods = array_values(array_filter(array_map('trim', explode(',', $raw))));
            }
        } catch (Throwable $e) {
            $assessMethods = array();
        }

        // ---- Skills Framework extraction (TSC title + code) ---------
        // Port of the storefront regex in view.phtml line 233. Looks
        // for uppercase-dash-digits patterns inside the skills_framework
        // CMS block body and pulls out the human title around it.
        $sfRaw = $cmsHtml('skills_framework');
        $skillsTitle = '';
        $skillsCode  = '';
        if ($sfRaw !== '') {
            $hay = html_entity_decode(strip_tags($sfRaw), ENT_QUOTES, 'UTF-8');
            $hay = preg_replace('#[\x{00A0}\x{2007}\x{202F}]#u', ' ', $hay);
            $hay = preg_replace('#\s+#u', ' ', trim($hay));
            $codeFull = '';
            if (preg_match('#([A-Z]{2,}(?:-[A-Z][A-Z0-9]*)+(?:[-.][0-9][0-9.\-]*)?)\s+(T(?:SC)?)\b#u', $hay, $cm)) {
                $skillsCode = trim($cm[1] . ' ' . $cm[2]);
                $codeFull   = $cm[0];
            } elseif (preg_match('#([A-Z]{2,}(?:-[A-Z][A-Z0-9]*)+(?:[-.][0-9][0-9.\-]*))#u', $hay, $cm)) {
                $skillsCode = trim($cm[1]);
                $codeFull   = $cm[0];
            }
            $titleSrc = $hay;
            if ($codeFull !== '') {
                $titleSrc = preg_replace('#\s*' . preg_quote($codeFull, '#') . '\s*#u', ' ', $titleSrc);
            }
            $titleSrc = preg_replace('#^.*?follows\s+the\s+guideline\s+of\s+#iu', '', $titleSrc);
            $titleSrc = preg_replace('#\s+under\s+.*?Skills\s+Framework\s*\.?\s*$#iu', '', $titleSrc);
            $skillsTitle = trim($titleSrc);
        }

        // ---- Country-aware certification text -----------------------
        // Mirrors storefront view.phtml lines 275-314:
        //   SG → hardcoded "Certificate of Completion …" + (WSQ-only)
        //        "OpenCerts from SkillsFuture Singapore" bullets;
        //        per-course block contributes only a Pearson Vue
        //        supplement (CompTIA courses) if present.
        //   Other countries → per-course `course_<sku>_certification`
        //        CMS block wins; falls back to the per-store global
        //        `course_certification` CMS block (created by migration
        //        143 — carries "Certificate of Completion from Tertiary
        //        Courses" for NG). If still empty, the
        //        Certification card is suppressed.
        $certificateHtml = $cmsHtml('certification');
        if ($isSg) {
            $certificateHtml  = '<ul>';
            $certificateHtml .= '<li><strong>Certificate of Completion from Tertiary Courses</strong> - Upon meeting at least 75% attendance and passing the assessment(s), participants will receive a Certificate of Completion from Tertiary Courses.</li>';
            if ($isWsq) {
                $certificateHtml .= '<li><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive an OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have achieved the Competency Standard(s) in the above Skills Framework.</li>';
            }
            $certificateHtml .= '</ul>';
            $certBlock = $cmsHtml('certification');
            if ($certBlock !== '' && preg_match('#<p>\s*<strong>\s*Certification Exam at Pearson Vue\s*</strong>\s*</p>.*$#siu', $certBlock, $pvMatch)) {
                $certificateHtml .= $pvMatch[0];
            }
        } elseif ($certificateHtml === '') {
            // Per-store global fallback for non-SG countries.
            try {
                $gb = Mage::getModel('cms/block')
                    ->setStoreId($scopeStoreId)
                    ->load('course_certification', 'identifier');
                if ($gb->getId() && $gb->getIsActive()) {
                    $certificateHtml = $this->_sanitizeRichHtml((string) $gb->getContent());
                }
            } catch (Exception $e) {
                // leave certificateHtml as the empty per-course value
            }
        }

        // ---- Venue (per-store CMS block) ----------------------------
        // Block identifier convention in this DB:
        //   SG (1)  → sg_venue_address           (KL — Singapore HQ)
        //   SG  ┕ special-case SKU TGS-2025053916 → sg_venue_address_hydroponics
        //   NG (4) → my_venue_address scoped to the
        //          active store (each non-SG store has its own row in
        //          cms_block_store with that country's address). Yes,
        //          the identifier is `my_*` for all of them — naming
        //          legacy from when MY was the only non-SG store, but
        //          the per-store content is correct.
        if ($activeWid === 1) {
            $venueBlockId = ($sku === 'TGS-2025053916')
                ? 'sg_venue_address_hydroponics'
                : 'sg_venue_address';
        } else {
            $venueBlockId = 'my_venue_address';
        }
        $venueHtml = '';
        try {
            $vb = Mage::getModel('cms/block')
                ->setStoreId($scopeStoreId)
                ->load($venueBlockId, 'identifier');
            if ($vb->getId() && $vb->getIsActive()) {
                $venueHtml = $this->_sanitizeRichHtml((string) $vb->getContent());
            }
        } catch (Exception $e) {
            $venueHtml = '';
        }

        return array(
            'title'              => (string) $admin->getName(),
            'sku'                => $sku,
            'price'              => $price,
            'price_gst'          => $price_gst,
            'price_incl_gst'     => $price_incl_gst,
            'gst_rate_pct'       => $gstRate > 0 ? (int) round($gstRate * 100) : 0,
            'funded_tiers'       => $funded_tiers,
            'duration'           => $durationRaw,
            'duration_fmt'       => $durationFmt,
            'sessions'           => $sessionsRaw,
            'sessions_fmt'       => $sessionsFmt,
            'assessment_dur'     => $assessDurFmt,
            'assessment_methods' => $assessMethods,
            'skills_title'       => $skillsTitle,
            'skills_code'        => $skillsCode,
            'venue_html'         => $venueHtml,
            'is_wsq'             => $isWsq,
            'is_sg'              => $isSg,
            'active_wid'         => $activeWid,
            'level'              => trim($level),
            'badges'             => $badges,
            'description'        => $this->_truncateProse(trim($this->_htmlToText($descRaw)), 520),
            // Cap outcomes at 6 so the 1-page layout doesn't overflow.
            // The full list still ships on the storefront — the brochure
            // is a recruiting handout, not the legal scope document.
            'outcomes'           => array_slice(
                $this->_extractOutcomesArray($admin, $cmsHtml('learning_outcomes')),
                0, 6
            ),
            'who_attend'         => trim($this->_htmlToText((string) $admin->getData('whoshouldattend'))),
            'prerequisite'       => trim($this->_htmlToText((string) $admin->getData('prerequisite'))),
            'additional_note'    => trim($this->_htmlToText((string) $admin->getData('additional_note'))),
            'outline_html'       => $cmsHtml('learning_outcomes'),
            'assessment_html'    => $sfRaw,  // alias for back-compat
            'skills_html'        => $sfRaw,
            'certificate_html'   => $certificateHtml,
            'funding_html'       => $cmsHtml('funding_and_grant'),
            'trainer_html'       => $this->_sanitizeRichHtml((string) $admin->getData('trainerprofile')),
            // Read the provider name from the DB per country —
            // general/store_information/name carries the consumer
            // brand for each storefront: Tertiary Courses Singapore /
            // Nigeria. Falls back
            // to the academy umbrella brand if the row is empty.
            'store_name'         => (string) ($store['name'] ?: 'Tertiary Courses'),
            'store_phone'        => (string) ($store['phone'] ?? ''),
            'store_email'        => $storeEmail,
            'store_address'      => (string) ($store['address'] ?? ''),
            'whatsapp'           => $whatsapp,
            'registration_url'   => $registrationUrl,
            'qr_data_uri'        => $this->_renderQrDataUri($registrationUrl),
            'generated_at'       => date('Y-m-d H:i'),
        );
    }

    /**
     * Render the storefront registration URL as a PNG QR data URI for
     * the brochure template.
     *
     * Why not mPDF's <barcode type="QR"> tag: it's inline-only and never
     * advances the text cursor by its drawn height, so the next sibling
     * element (the "Scan to register" caption) overlaps the bottom of
     * the QR pixels — confirmed with the M1872-MY incident. <img> tags
     * with explicit width respect block flow and the caption clears
     * naturally below.
     *
     * 200 px is enough for any printer/scanner (20mm at 254 DPI).
     */
    protected function _renderQrDataUri($url)
    {
        $url = trim((string) $url);
        if ($url === '') return '';
        try {
            $qr = new \Mpdf\QrCode\QrCode($url);
            $png = (new \Mpdf\QrCode\Output\Png())->output($qr, 260);
            if ($png === '' || $png === false) return '';
            return 'data:image/png;base64,' . base64_encode($png);
        } catch (Throwable $e) {
            return '';
        }
    }

    /**
     * Upload the just-generated brochure PDF to Google Drive, into the
     * country-named subfolder under the configured parent. Mirrors the
     * pattern of "create or update if a file with the same name already
     * exists" so re-generating overwrites instead of accumulating
     * duplicates — the link stays stable across regenerates.
     *
     * Skipped silently (no error) when the service-account JSON key
     * isn't present at app/etc/google-drive-key.json — admins running
     * locally without Drive set up still get a working brochure. When
     * the key IS present, any failure (auth, network, missing folder)
     * is captured and returned as part of the response so the JS can
     * surface "Drive upload failed: ..." in the success line without
     * blocking the rest of the flow.
     *
     * Scope: drive.file only — even with broader folder share, the SA
     * can only see/edit files it created itself. Worst-case credential
     * leak still can't touch anything it didn't put there.
     *
     * Returns ['uploaded' => bool, 'skipped' => bool, 'message' => str,
     *          'drive_url' => str, 'folder' => str].
     */
    protected function _uploadBrochureToDrive($absPath, $filename, $countryCode)
    {
        $keyFile = Mage::getBaseDir() . '/app/etc/google-drive-key.json';
        if (!is_readable($keyFile)) {
            return array(
                'uploaded' => false,
                'skipped'  => true,
                'message'  => 'Drive key not configured (app/etc/google-drive-key.json missing)',
            );
        }
        if (!class_exists('\\Google\\Client')) {
            return array(
                'uploaded' => false,
                'skipped'  => true,
                'message'  => 'google/apiclient not installed',
            );
        }

        // Country code → folder name (matches the actual Drive folder
        // names exactly: "Singapore", "Nigeria".
        // Anything else aborts cleanly.
        $countryNames = array(
            'SG' => 'Singapore', 'NG' => 'Nigeria',
        );
        $folderName = $countryNames[strtoupper((string) $countryCode)] ?? '';
        if ($folderName === '') {
            return array(
                'uploaded' => false,
                'skipped'  => true,
                'message'  => 'Unknown country code: ' . $countryCode,
            );
        }

        // Shared Drive (or folder inside it) that holds the country
        // subfolders — Singapore / Nigeria.
        // Must be a Shared Drive (not My Drive) because
        // service accounts can't own files in a personal Drive — they
        // hit a "storage quota exceeded" error.
        $parentFolderId = '16S5PAreCxFQ7Kcbu7eE6djMfhNq7wz2B';

        try {
            $client = new \Google\Client();
            $client->setAuthConfig($keyFile);
            // `drive` scope = read + write access to files the SA has
            // been granted access to (via Drive sharing). The narrower
            // `drive.file` scope would have been ideal — "only files
            // the app created" — but it can't see the country
            // folders since those were created by a human in the
            // Drive UI, so the lookup would fail with "folder not
            // found." Access is still bounded: the SA has no GCP IAM
            // role and only sees folders explicitly shared with its
            // email (parent "5 Course Brochures" + 5 country subfolders).
            $client->setScopes(array(\Google\Service\Drive::DRIVE));
            $drive = new \Google\Service\Drive($client);

            // Per-request folder-ID cache so back-to-back uploads
            // (multi-country admin workflow) don't repeat the lookup.
            // We list ALL subfolders of the parent in one query and
            // match by TRIMMED name in PHP — Drive's `name = '…'`
            // operator is exact, but some country folders in this
            // Drive have trailing whitespace, so a literal match misses them.
            static $folderIdCache = null;
            if ($folderIdCache === null) {
                $folderIdCache = array();
                $q = sprintf(
                    "mimeType = 'application/vnd.google-apps.folder' and '%s' in parents and trashed = false",
                    addslashes($parentFolderId)
                );
                $resp = $drive->files->listFiles(array(
                    'q'                         => $q,
                    'fields'                    => 'files(id, name)',
                    'supportsAllDrives'         => true,
                    'includeItemsFromAllDrives' => true,
                    'pageSize'                  => 50,
                ));
                foreach ($resp->getFiles() as $f) {
                    $folderIdCache[trim((string) $f->getName())] = $f->getId();
                }
            }
            if (!isset($folderIdCache[$folderName])) {
                throw new Exception("Country folder '$folderName' not found under parent — share it with the service account.");
            }
            $folderId = $folderIdCache[$folderName];

            // Find existing file with the same name in that folder so
            // we can UPDATE rather than create-a-duplicate.
            $existingId = null;
            $q = sprintf(
                "name = '%s' and '%s' in parents and trashed = false",
                addslashes($filename),
                addslashes($folderId)
            );
            $resp = $drive->files->listFiles(array(
                'q'                         => $q,
                'fields'                    => 'files(id, name)',
                'supportsAllDrives'         => true,
                'includeItemsFromAllDrives' => true,
                'pageSize'                  => 5,
            ));
            $existing = $resp->getFiles();
            if (count($existing) > 0) {
                $existingId = $existing[0]->getId();
            }

            $content = (string) file_get_contents($absPath);
            $params = array(
                'data'       => $content,
                'mimeType'   => 'application/pdf',
                'uploadType' => 'multipart',
                'fields'     => 'id, webViewLink, webContentLink',
                'supportsAllDrives' => true,
            );

            if ($existingId !== null) {
                // Update existing file. Don't set name/parents in the
                // metadata — Drive rejects "parents" on update; the
                // existing file stays in the same folder by definition.
                $meta = new \Google\Service\Drive\DriveFile();
                $uploaded = $drive->files->update($existingId, $meta, $params);
            } else {
                $meta = new \Google\Service\Drive\DriveFile(array(
                    'name'    => $filename,
                    'parents' => array($folderId),
                ));
                $uploaded = $drive->files->create($meta, $params);
            }

            return array(
                'uploaded'  => true,
                'skipped'   => false,
                'message'   => $existingId ? 'Updated existing Drive file' : 'Created new Drive file',
                'drive_url' => (string) $uploaded->getWebViewLink(),
                'folder'    => $folderName,
            );
        } catch (Throwable $e) {
            return array(
                'uploaded' => false,
                'skipped'  => false,
                'message'  => 'Drive upload failed: ' . $e->getMessage(),
            );
        }
    }

    /**
     * Resolve a product's primary country (website_id). Mirrors
     * MMD_RoleManager_Helper_Data::getRunIdPrefixForProduct(): pick
     * the smallest website_id from catalog_product_website. Defaults
     * to 1 (Singapore) when nothing's assigned — same fallback as the
     * Run-ID prefix logic so the two never disagree for a given SKU.
     *
     * Cached per request: the brochure controller may invoke this
     * twice (once in the entry gate, once in _collectBrochureContext)
     * for the same product.
     */
    protected function _brochureWidForProduct($productId)
    {
        static $cache = array();
        $productId = (int) $productId;
        if ($productId <= 0) return 1;
        if (isset($cache[$productId])) return $cache[$productId];
        try {
            $wid = (int) Mage::getSingleton('core/resource')->getConnection('core_read')->fetchOne(
                "SELECT website_id FROM catalog_product_website WHERE product_id=? ORDER BY website_id LIMIT 1",
                array($productId)
            );
        } catch (Exception $e) {
            $wid = 0;
        }
        if ($wid <= 0) $wid = 1;
        $cache[$productId] = $wid;
        return $wid;
    }

    /**
     * Every website_id a course is assigned to. Used by the entry
     * gate to verify the admin's active country is one the course is
     * actually on (so you can't accidentally generate an MY brochure
     * for an SG-only course while viewing another country). Sorted ASC
     * for stable iteration.
     */
    protected function _courseWebsiteIds($productId)
    {
        static $cache = array();
        $productId = (int) $productId;
        if ($productId <= 0) return array();
        if (isset($cache[$productId])) return $cache[$productId];
        try {
            $rows = Mage::getSingleton('core/resource')->getConnection('core_read')->fetchCol(
                "SELECT website_id FROM catalog_product_website WHERE product_id=? ORDER BY website_id ASC",
                array($productId)
            );
            $cache[$productId] = array_map('intval', (array) $rows);
        } catch (Exception $e) {
            $cache[$productId] = array();
        }
        return $cache[$productId];
    }

    /**
     * website_id → ISO-ish 2-letter country code used in the brochure
     * filename. Keeps the URL human-readable and pairs naturally with
     * MMD_RoleManager_Helper_Data's existing prefix map.
     */
    protected function _brochureCountryCodeForWebsite($wid)
    {
        $map = array(1 => 'SG', 4 => 'NG');
        return $map[(int) $wid] ?? 'SG';
    }

    /**
     * Map website_id → currency symbol used on its storefront. Magento
     * stores currency_code per website (`currency/options/default`),
     * but the symbol mapping is short enough to inline here. Returns
     * the symbol with a non-breaking space afterwards so number_format
     * output reads cleanly.
     */
    protected function _currencySymbolForWebsite($wid)
    {
        $map = array(
            1 => 'S$',  // Singapore
            4 => 'NGN ',// Nigeria
        );
        return $map[(int) $wid] ?? '$';
    }

    /**
     * Word-boundary truncate prose to keep the 1-page brochure layout
     * from overflowing. Returns the input as-is when within limit;
     * otherwise cuts at the nearest space before $max and appends "…".
     */
    protected function _truncateProse($text, $max)
    {
        $s = (string) $text;
        if (strlen($s) <= $max) return $s;
        $cut = substr($s, 0, $max);
        $sp  = strrpos($cut, ' ');
        if ($sp !== false && $sp > $max * 0.6) {
            $cut = substr($cut, 0, $sp);
        }
        return rtrim($cut, ",;:.—-") . '…';
    }

    /**
     * Sanitize CMS-block / trainer-profile HTML before it goes into
     * mPDF. The TinyMCE-pasted content in our DB tends to have runaway
     * <br><br><br><br> cascades and lots of empty <p>&nbsp;</p> blocks —
     * mPDF treats those as real layout and (combined with our content
     * volumes) generated a 17,000-page artefact. This trims the worst
     * offenders without removing semantic structure.
     *
     * Must be public so the closure in _collectBrochureContext can call
     * it through `$self->_sanitizeRichHtml(...)`.
     */
    public function _sanitizeRichHtml($html)
    {
        if ($html === '' || $html === null) return '';
        $s = (string) $html;
        // mPDF supports <img> but the brochure is graphics-free.
        $s = preg_replace('#<img\b[^>]*>#i', '', $s);
        // Drop inline style attributes — they can pull in fonts/colors
        // that bloat the PDF and never look right at A4 scale anyway.
        $s = preg_replace('/\sstyle\s*=\s*"[^"]*"/i', '', $s);
        $s = preg_replace("/\sstyle\s*=\s*'[^']*'/i", '', $s);
        // Collapse runaway <br> cascades to at most two (a paragraph
        // break visually).
        $s = preg_replace('#(?:<br\s*/?>\s*){3,}#i', '<br /><br />', $s);
        // Strip empty paragraphs / list items.
        $s = preg_replace('#<p[^>]*>(\s|&nbsp;|<br\s*/?>)*</p>#iu', '', $s);
        $s = preg_replace('#<li[^>]*>(\s|&nbsp;|<br\s*/?>)*</li>#iu', '', $s);
        // Collapse 3+ consecutive newlines.
        $s = preg_replace("/(\r?\n){3,}/", "\n\n", $s);
        return $s;
    }

    /**
     * Turn HTML chunks (description, learning outcomes) into a plain
     * string with paragraph breaks preserved. strip_tags loses block
     * structure, so we map <br>, <p>, <li> to newlines first.
     */
    protected function _htmlToText($html)
    {
        if ($html === '' || $html === null) return '';
        $s = (string) $html;
        $s = preg_replace('#<br\s*/?>#i', "\n",  $s);
        $s = preg_replace('#</p\s*>#i',    "\n\n", $s);
        $s = preg_replace('#</li\s*>#i',   "\n",  $s);
        $s = preg_replace('#</h[1-6]\s*>#i', "\n\n", $s);
        $s = strip_tags($s);
        $s = html_entity_decode($s, ENT_QUOTES | ENT_HTML5, 'UTF-8');
        // Collapse runs of 3+ blank lines to 2.
        $s = preg_replace("/\n{3,}/", "\n\n", $s);
        return $s;
    }

    /**
     * Best-effort outcome extraction. The site stores LOs across two
     * places (the `learning_outcomes` EAV textarea + the `learning_outcomes`
     * CMS block); pick whichever has content, split on <li>/newlines,
     * and normalise into a flat array of clean strings. AI will then
     * rewrite them; if AI is unavailable we ship these raw.
     */
    protected function _extractOutcomesArray($product, $cmsHtml)
    {
        $src = trim((string) $cmsHtml);
        if ($src === '') {
            $src = (string) $product->getData('learning_outcomes');
        }
        if ($src === '') return array();

        // Pull <li> content if the source is a list, else split on newlines.
        $out = array();
        if (preg_match_all('#<li[^>]*>(.*?)</li>#is', $src, $m)) {
            foreach ($m[1] as $item) {
                $out[] = trim($this->_htmlToText($item));
            }
        } else {
            foreach (preg_split('/[\r\n]+/', $this->_htmlToText($src)) as $line) {
                $line = trim($line);
                if ($line !== '') $out[] = $line;
            }
        }
        // Strip leading "LO1:", "LO 2 -", "1.", "1)" prefixes.
        $out = array_map(function ($s) {
            $s = preg_replace('/^\s*(LO|L|O)\s*\d+\s*[:\-\.\)]\s*/i', '', $s);
            $s = preg_replace('/^\s*\d+\s*[:\-\.\)]\s*/', '', $s);
            return trim($s);
        }, $out);
        $out = array_values(array_filter($out, function ($s) { return $s !== ''; }));
        return $out;
    }

    /**
     * Ask Claude to polish description / outcomes / who-should-attend.
     * Three-tier fallback mirroring aiSeoAction. Returns array with
     * keys: description (string), learning_outcomes (array), who_should_attend (string).
     * Sets $stubbed=true when we fell to the pass-through.
     */
    protected function _polishBrochureProse(array $ctx, &$stubbed, &$stubReason)
    {
        $tplFile = Mage::getBaseDir('code')
            . '/local/MMD/RoleManager/etc/ai-brochure/brochure.md';
        if (!is_readable($tplFile)) {
            $stubbed = true;
            $stubReason = 'prompt template missing';
            return array(
                'description'       => $ctx['description'],
                'learning_outcomes' => $ctx['outcomes'],
                'who_should_attend' => $ctx['who_attend'],
            );
        }
        $tpl = file_get_contents($tplFile);
        $outcomeText = '';
        foreach ($ctx['outcomes'] as $i => $o) {
            $outcomeText .= ($i + 1) . '. ' . $o . "\n";
        }
        $vals = array(
            'course_title'      => $ctx['title'],
            'course_sku'        => $ctx['sku'],
            'duration'          => $ctx['duration'],
            'level'             => $ctx['level'],
            'description'       => $ctx['description'],
            'learning_outcomes' => trim($outcomeText),
            'who_should_attend' => $ctx['who_attend'],
        );
        foreach ($vals as $k => $v) {
            $tpl = str_replace('{' . $k . '}', $v, $tpl);
        }

        $cfg     = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
        $apiKey  = trim((string) ($cfg['anthropic_key']   ?? ''));
        $model   = trim((string) ($cfg['anthropic_model'] ?? '')) ?: 'claude-sonnet-4-6';
        $stdout  = '';
        $stubbed = false;
        $stubReason = '';

        // Tier 1 — direct API (sk-ant-api* keys only).
        if (stripos($apiKey, 'sk-ant-api') === 0) {
            try {
                $body = json_encode(array(
                    'model'      => $model,
                    'max_tokens' => 1800,
                    'system'     => 'You are a brochure copywriter. Output ONLY the JSON object requested — no preamble, no markdown fence.',
                    'messages'   => array(array('role' => 'user', 'content' => $tpl)),
                ));
                $ch = curl_init('https://api.anthropic.com/v1/messages');
                curl_setopt_array($ch, array(
                    CURLOPT_POST           => true,
                    CURLOPT_POSTFIELDS     => $body,
                    CURLOPT_RETURNTRANSFER => true,
                    CURLOPT_TIMEOUT        => 30,
                    CURLOPT_CONNECTTIMEOUT => 10,
                    CURLOPT_HTTPHEADER     => array(
                        'anthropic-version: 2023-06-01',
                        'content-type: application/json',
                        'x-api-key: ' . $apiKey,
                    ),
                ));
                $raw  = curl_exec($ch);
                $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
                curl_close($ch);
                $rsp = json_decode($raw, true);
                if ($code >= 400 || !isset($rsp['content'][0]['text'])) {
                    $msg = $rsp['error']['message'] ?? substr((string) $raw, 0, 150);
                    throw new Exception('API HTTP ' . $code . ': ' . $msg);
                }
                $stdout = (string) $rsp['content'][0]['text'];
            } catch (Exception $e) {
                $stubReason = $e->getMessage();
            }
        }

        // Tier 2 — `claude` CLI piped over stdin (host's ~/.claude OAuth).
        if ($stdout === '') {
            $descriptors = array(
                0 => array('pipe', 'r'),
                1 => array('pipe', 'w'),
                2 => array('pipe', 'w'),
            );
            $env = array();
            foreach ($_ENV as $k => $v) {
                if ($k !== 'CLAUDECODE') $env[$k] = $v;
            }
            foreach (array('PATH', 'HOME') as $k) {
                if (!isset($env[$k]) && getenv($k) !== false) {
                    $env[$k] = getenv($k);
                }
            }
            if (is_dir('/var/www/.claude')) {
                $env['HOME'] = '/var/www';
            } elseif (is_dir('/root/.claude') && is_readable('/root')) {
                $env['HOME'] = '/root';
            }
            $proc = @proc_open(
                'timeout 100 claude -p --output-format text',
                $descriptors, $pipes, null, $env
            );
            if (is_resource($proc)) {
                fwrite($pipes[0], $tpl);
                fclose($pipes[0]);
                stream_set_blocking($pipes[1], false);
                stream_set_blocking($pipes[2], false);
                $deadline = time() + 105;
                $cliOut = ''; $cliErr = '';
                $finalExit = -1;
                while (time() < $deadline) {
                    $status = proc_get_status($proc);
                    $cliOut .= stream_get_contents($pipes[1]);
                    $cliErr .= stream_get_contents($pipes[2]);
                    if (!$status['running']) {
                        $finalExit = $status['exitcode'];
                        break;
                    }
                    usleep(200000);
                }
                $status = proc_get_status($proc);
                if ($status['running']) {
                    proc_terminate($proc, 9);
                    $finalExit = 137;
                }
                $cliOut .= stream_get_contents($pipes[1]);
                $cliErr .= stream_get_contents($pipes[2]);
                fclose($pipes[1]);
                fclose($pipes[2]);
                proc_close($proc);
                if ($finalExit === 0 && trim($cliOut) !== '') {
                    $stdout = $cliOut;
                    $stubReason = '';
                } elseif ($stubReason === '') {
                    $stubReason = 'CLI exit ' . $finalExit . ': ' . trim($cliErr);
                }
            }
        }

        // Tier 3 — pass-through: ship the raw fields. Brochure still
        // produces, just unpolished.
        if ($stdout === '') {
            $stubbed = true;
            if ($stubReason === '') $stubReason = 'no generator available';
            return array(
                'description'       => $ctx['description'],
                'learning_outcomes' => $ctx['outcomes'],
                'who_should_attend' => $ctx['who_attend'],
            );
        }

        // Claude sometimes wraps its JSON in a ```json fence even when
        // told not to — strip it before decoding.
        $clean = trim($stdout);
        $clean = preg_replace('/^```(?:json)?\s*/i', '', $clean);
        $clean = preg_replace('/```\s*$/', '', $clean);
        // Some replies still have leading prose; grab the first {...} block.
        if (preg_match('/\{.*\}/s', $clean, $m)) {
            $clean = $m[0];
        }
        $decoded = json_decode($clean, true);
        if (!is_array($decoded)) {
            // Parse failed — pass through raw data so the PDF still ships.
            $stubbed = true;
            $stubReason = 'AI output not parseable as JSON';
            return array(
                'description'       => $ctx['description'],
                'learning_outcomes' => $ctx['outcomes'],
                'who_should_attend' => $ctx['who_attend'],
            );
        }
        return array(
            'description'       => (string) ($decoded['description']       ?? ''),
            'learning_outcomes' => is_array($decoded['learning_outcomes'] ?? null)
                                    ? array_map('strval', $decoded['learning_outcomes'])
                                    : array(),
            'who_should_attend' => (string) ($decoded['who_should_attend'] ?? ''),
        );
    }

    /**
     * Per-page brochure header — logo on the left, provider name on the
     * right, thin brand-blue rule below the row. Rendered into a single
     * <table> because mPDF's flow inside SetHTMLHeader is finicky about
     * float/flex; tables are the supported layout primitive for headers.
     */
    protected function _buildBrochureHeader(array $ctx)
    {
        // Page-header band on continuation pages (page 2+). Keep the
        // consumer brand consistent with the storefront and sitemap.
        return '<table width="100%" cellpadding="0" cellspacing="0" '
             . 'style="border-bottom:0.5pt solid #2563eb;font-family:Helvetica,Arial,sans-serif;">'
             . '<tr>'
             .   '<td align="left" style="padding:0 0 2pt;'
             .     'font-size:9pt;color:#1e3a8a;letter-spacing:0.06em;'
             .     'text-transform:uppercase;font-weight:700;vertical-align:bottom;">Tertiary Courses</td>'
             . '</tr>'
             . '</table>';
    }

    /**
     * Per-page brochure footer — contact strip on the left, page number
     * on the right. {PAGENO} / {nbpg} are mPDF page-counter placeholders
     * resolved at render time.
     */
    protected function _buildBrochureFooter(array $ctx)
    {
        $phone = trim((string) ($ctx['store_phone'] ?? ''));
        $email = trim((string) ($ctx['store_email'] ?? ''));
        $bits = array();
        if ($phone !== '') $bits[] = htmlspecialchars($phone);
        if ($email !== '') $bits[] = htmlspecialchars($email);
        $contact = implode('   |   ', $bits);
        return '<table width="100%" cellpadding="0" cellspacing="0" '
             . 'style="border-top:0.4pt solid #cbd5e1;font-family:Helvetica,Arial,sans-serif;font-size:8.5pt;color:#94a3b8;">'
             . '<tr>'
             .   '<td width="70%" align="left"  style="padding:4pt 0 0;">' . $contact . '</td>'
             .   '<td width="30%" align="right" style="padding:4pt 0 0;">Page {PAGENO} of {nbpg}</td>'
             . '</tr>'
             . '</table>';
    }

    /**
     * Replace unicode chars that core (Type 1) PDF fonts can't render
     * with their nearest ASCII equivalents. Only invoked when we use
     * `useCoreFontsOnly => true` in mPDF — otherwise the multi-script
     * fonts handle them natively (at the cost of a 9 MB output).
     *
     * Anything still outside WinAnsi after this pass gets dropped by
     * mPDF, which prints "?" — that's a deliberate trade for the
     * 100× smaller artefact.
     */
    protected function _normaliseUnicodeForCore($s)
    {
        if ($s === '' || $s === null) return '';
        $map = array(
            "\xe2\x80\x94" => '--',  // em dash
            "\xe2\x80\x93" => '-',   // en dash
            "\xe2\x80\x98" => "'",   // left single quote
            "\xe2\x80\x99" => "'",   // right single quote / apostrophe
            "\xe2\x80\x9c" => '"',   // left double quote
            "\xe2\x80\x9d" => '"',   // right double quote
            "\xe2\x80\xa6" => '...', // ellipsis
            "\xe2\x80\xa2" => '*',   // bullet
            "\xc2\xa0"     => ' ',   // nbsp
            "\xe2\x86\x92" => '->',  // right arrow
            "\xe2\x86\x90" => '<-',  // left arrow
            "\xe2\x88\x92" => '-',   // minus
        );
        return strtr((string) $s, $map);
    }

    /**
     * Render brochure.phtml into a string, hand to mPDF, write to
     * media/courses/brochures/<safe-sku>.pdf. Returns the public URL
     * (with a cache-bust query string keyed off mtime so the storefront
     * picks up regenerations immediately).
     */
    protected function _renderBrochurePdf($product, array &$context)
    {
        // Brochure logo.
        // Embed via base64 data: URI — mPDF's SetHTMLHeader() context
        // is sandboxed and won't reliably read filesystem paths even
        // for files in the same container. The data URI ships the
        // bytes inline so mPDF can decode them directly.
        $logoBase  = Mage::getBaseDir() . DS . 'skin' . DS . 'frontend'
                   . DS . 'ultimo' . DS . 'default' . DS . 'images' . DS;
        $candidates = array(
            $logoBase . 'logo.png',
        );
        $context['logo_uri'] = '';
        foreach ($candidates as $logoFile) {
            if ($logoFile !== '' && is_readable($logoFile)) {
                $context['logo_uri'] = 'data:image/png;base64,'
                                     . base64_encode((string) file_get_contents($logoFile));
                break;
            }
        }

        // Render the template with extract() — flat partial, no Magento block.
        ob_start();
        $__tpl = Mage::getBaseDir('code')
            . '/local/MMD/RoleManager/etc/ai-brochure/brochure.phtml';
        if (!is_readable($__tpl)) {
            ob_end_clean();
            throw new Exception('Brochure template missing: ' . basename($__tpl));
        }
        // Escape fields the template echoes raw (title, sku, etc.).
        // Multi-line / HTML fields stay un-escaped because they intentionally
        // carry markup (outline_html, trainer_html, …).
        $renderCtx = $context;
        foreach (array('title', 'sku', 'price', 'price_gst', 'price_incl_gst',
                       'duration', 'duration_fmt', 'sessions', 'sessions_fmt',
                       'assessment_dur', 'skills_title', 'skills_code',
                       'level', 'store_name', 'store_phone', 'store_email') as $k) {
            $renderCtx[$k] = htmlspecialchars((string) ($renderCtx[$k] ?? ''));
        }
        extract($renderCtx, EXTR_SKIP);
        include $__tpl;
        $html = ob_get_clean();

        // Where to write — one file per (SKU, country). Multi-country
        // courses (E001 lives on all 5 sites) thus end up with up to
        // five brochure PDFs side-by-side:
        //   <SKU>-SG.pdf, <SKU>-MY.pdf, <SKU>-GH.pdf, …
        // Per-store CMS-block textareas point each storefront at its
        // own file.
        $sku       = (string) $product->getSku();
        $safeSku   = preg_replace('/[^A-Za-z0-9._-]/', '_', $sku !== '' ? $sku : ('product-' . $product->getId()));
        $cc        = $this->_brochureCountryCodeForWebsite($context['active_wid'] ?? 1);
        $filename  = $safeSku . '-' . $cc . '.pdf';
        // Output dir — same dual-owner concern as tempDir below. The
        // CLI smoke-test runs as root, Apache as www-data; both need to
        // be able to write the per-course PDF. Force 0777 on create AND
        // on every run so a previously-root-owned dir self-heals once
        // the controller fires.
        $brochureDir = Mage::getBaseDir('media') . DS . 'courses' . DS . 'brochures';
        $oldUmask = umask(0);
        if (!is_dir($brochureDir)) {
            @mkdir($brochureDir, 0777, true);
        }
        @chmod($brochureDir, 0777);
        umask($oldUmask);
        $absPath = $brochureDir . DS . $filename;

        // mPDF tempDir — keep it under var/ so it survives container
        // rebuilds. We create it 0777 (and umask 0) because the same dir
        // gets used by both CLI smoke-tests (root) and Apache (www-data),
        // and a 0775 dir made by root would fail "not writable" for the
        // www-data web request. mPDF appends its own `mpdf` subdir, so
        // the parent has to allow that mkdir from either user.
        $tempDir = Mage::getBaseDir('var') . DS . 'tmp' . DS . 'mpdf';
        $oldUmask = umask(0);
        if (!is_dir($tempDir)) {
            @mkdir($tempDir, 0777, true);
        }
        @chmod($tempDir, 0777);
        umask($oldUmask);

        // Use core (Type 1) fonts only — Helvetica/Times/Courier are
        // built into every PDF reader so no font embedding happens. This
        // takes the artefact from ~9 MB (full DejaVu subset, ~50s render)
        // down to ~30 KB (~1 s render). The trade-off is core fonts are
        // WinAnsi-only — em-dashes, curly quotes, ellipses etc. get
        // replaced via _normaliseUnicodeForCore() before WriteHTML.
        // Margins: compact, to fit the brochure on a single A4 page
        // where possible. `margin_header` / `margin_footer` set where
        // the band STARTS from the page edge; `margin_top` / `_bottom`
        // are where body content begins/ends. Trimmed from 26/22 to
        // 18/14 to give content more vertical room.
        $mpdf = new \Mpdf\Mpdf(array(
            'mode'             => 'c',
            'format'           => 'A4',
            'tempDir'          => $tempDir,
            'useCoreFontsOnly' => true,
            'default_font'     => 'helvetica',
            'margin_left'      => 12,
            'margin_right'     => 12,
            'margin_top'       => 16,
            'margin_bottom'    => 14,
            'margin_header'    => 6,
            'margin_footer'    => 6,
        ));
        $mpdf->SetTitle($this->_normaliseUnicodeForCore($context['title']) . ' - Course Brochure');
        $mpdf->SetAuthor($this->_normaliseUnicodeForCore($context['store_name']));

        // Per-page header band — logo on the left, provider name on the
        // right, thin brand-blue rule below. Renders on every page.
        $mpdf->SetHTMLHeader($this->_normaliseUnicodeForCore($this->_buildBrochureHeader($context)));
        // Per-page footer band — contact info on the left, page number
        // on the right, thin rule above.
        $mpdf->SetHTMLFooter($this->_normaliseUnicodeForCore($this->_buildBrochureFooter($context)));

        $mpdf->WriteHTML($this->_normaliseUnicodeForCore($html));
        $mpdf->Output($absPath, \Mpdf\Output\Destination::FILE);
        // Same dual-owner concern as the dir mkdir above: the CLI
        // smoke-test runs as root and a 0644 file it created earlier
        // would lock out Apache (www-data) on the next regenerate. Force
        // world-writable so either user can overwrite. The file is a
        // public artefact in media/ anyway — no auth/secret in it.
        @chmod($absPath, 0666);

        // Push the PDF to Google Drive (per-country folder). Failure
        // here is non-fatal — the local file + storefront link still
        // work; admin sees a "Drive upload skipped" note in the response
        // status. Result is plumbed back to the JS via $context.
        $context['drive_result'] = $this->_uploadBrochureToDrive(
            $absPath,
            $filename,
            $this->_brochureCountryCodeForWebsite($context['active_wid'] ?? 1)
        );

        // Build the brochure file URL against the CURRENT environment's
        // base media URL so admins can preview locally (localhost:8080)
        // before the deploy, and the saved URL in the CMS textarea
        // works in prod (country domain). The registration URL inside
        // the PDF — see _collectBrochureContext — uses hardcoded
        // production domains because that link is printed/distributed
        // to learners and must always land on the public storefront.
        $mediaBase = (string) Mage::getBaseUrl('media');
        $url = rtrim($mediaBase, '/')
             . '/courses/brochures/' . rawurlencode($filename)
             . '?v=' . (int) @filemtime($absPath);
        return $url;
    }

    /**
     * Deterministic SEO stub used when no Anthropic key is configured or
     * the upstream call fails (e.g. 429 rate limit on the OAuth token).
     * Pulls the course name + keywords from the supplied form inputs so
     * the output is tailored to *this* course rather than fully generic.
     * Output mirrors what Claude would return so _parseAiSeoSections can
     * read it unchanged.
     */
    protected function _buildAiSeoStub($mode, array $vals, $product)
    {
        $isWsq  = ($mode === 'wsq');
        $isWsqLike = $isWsq;

        $name = $isWsqLike
            ? trim($vals['course_title'] ?? '')
            : trim($vals['course_name']  ?? '');
        if ($name === '') $name = (string) $product->getName();
        if ($name === '') $name = 'Course';

        // Country supplied by the caller (already whitelisted in aiSeoAction).
        // Drives the brand suffix and geo-language.
        $country = trim((string) ($vals['country'] ?? '')) ?: 'Singapore';

        // ---------- Meta Title ----------
        // No truncation; Google trims SERP titles itself at ~60 chars and
        // word-boundary cuts are uglier than letting the browser tab show
        // the full name. Keep it human-readable.
        if ($isWsq) {
            $title = $name . ' | WSQ Course | Tertiary Courses ' . $country;
        } else {
            $title = $name . ' | Tertiary Courses ' . $country;
        }

        // ---------- Meta Keywords ----------
        // Pull tokens from the user's typed inputs (learning outcomes,
        // topics, highlights). Strip any leading "LO1:", "T2:", "L3:"-
        // style outline prefixes (one or two letters + digits + colon).
        $kwSource = trim(($vals['learning_outcomes'] ?? '') . ' '
                       . ($vals['topics']            ?? '') . ' '
                       . ($vals['key_topics']        ?? '') . ' '
                       . ($vals['course_highlights'] ?? ''));
        $kwSource = preg_replace('/\b[a-zA-Z]{1,3}\d+\s*:?/i', '', $kwSource);
        $kwSource = preg_replace('/[^a-zA-Z0-9 \-]+/', ' ', $kwSource);
        $words = preg_split('/\s+/', strtolower($kwSource));
        $stop  = array('the','a','an','and','or','of','to','in','for','on',
                       'with','by','at','from','as','is','are','be','will',
                       'this','that','these','those','its','their','can',
                       'has','have','had','was','were','they','them','it',
                       'using','use','used','learn','learners','learner',
                       'participants','including','various','about','also',
                       'such','than','then','only','more','most','other',
                       'each','etc','via','wsq');
        $picked = array();
        foreach ($words as $w) {
            $w = trim($w);
            if (strlen($w) < 4) continue;
            if (in_array($w, $stop, true)) continue;
            if (!preg_match('/^[a-z][a-z0-9\-]+$/', $w)) continue;
            $picked[$w] = true;
            if (count($picked) >= 8) break;
        }
        $topicWords = array_keys($picked);

        // Build keyword list — variety: course name itself + a couple
        // topic-tail phrases + Singapore intent terms. Dedupe
        // case-insensitively so "WSQ" doesn't repeat as "wsq". Pick the
        // first content word (skip "WSQ -" prefix) and preserve all-caps
        // acronyms like "AI", "SQL", "AWS" rather than ucfirst-ing them
        // into "Ai" / "Sql" / "Aws".
        // Strip any leading "WSQ ", "WSQ - ", "WSQ: ", "WSQ – " so we
        // pick the meaningful first word ("Python", not "WSQ").
        $titleWords = preg_split('/\s+/', trim(preg_replace('/^WSQ\s*[-:–]?\s*/i', '', $name)));
        $firstWord  = $titleWords[0] ?? $name;
        if (!preg_match('/^[A-Z]{2,}$/', $firstWord)) {
            $firstWord = ucfirst(strtolower($firstWord));
        }
        $kws = array();
        if ($isWsq) {
            $kws[] = 'WSQ ' . $firstWord . ' course ' . $country;
        }
        $kws[] = $firstWord . ' training ' . $country;
        foreach ($topicWords as $w) $kws[] = ucfirst($w);
        if ($isWsq) {
            $kws[] = 'SkillsFuture credit eligible';
            $kws[] = 'WSQ funded course';
        } else {
            $kws[] = 'professional training course';
        }
        $seen = array();
        $deduped = array();
        foreach ($kws as $k) {
            $key = strtolower(trim($k));
            if ($key === '' || isset($seen[$key])) continue;
            $seen[$key] = true;
            $deduped[] = $k;
        }
        $keywords = implode(', ', array_slice($deduped, 0, 10));

        // ---------- Meta Description ----------
        // Phrase varies by mode and references 1–2 topic words for
        // specificity. Capped at 240 chars (Google snippets ~155 desktop,
        // we keep slack for funding line).
        $topicTail = '';
        if (count($topicWords) >= 2) {
            $topicTail = ' Covers ' . $topicWords[0] . ', ' . $topicWords[1] . '.';
        } elseif (count($topicWords) === 1) {
            $topicTail = ' Covers ' . $topicWords[0] . '.';
        }
        if ($isWsq) {
            $desc = 'Learn ' . $name . ' through this WSQ-certified course in ' . $country . '.' . $topicTail . ' Up to 70% WSQ funding subsidy available.';
        } else {
            $desc = 'Master ' . $name . ' with hands-on training in ' . $country . '.' . $topicTail . ' Practical skills for working professionals.';
        }
        if (strlen($desc) > 240) $desc = substr($desc, 0, 237) . '...';

        return "**SEO Meta Title:** " . $title . "\n\n"
             . "**SEO Meta Keywords:** " . $keywords . "\n\n"
             . "**SEO Meta Description:** " . $desc . "\n";
    }

    /**
     * Parse the WSQ/Non-WSQ markdown output from Claude into a flat map
     * keyed by lowercased label slug. Mirrors course-helper's
     * ui_helpers.split_sections() heuristic — splits on lines like
     * "1. **SEO Meta Title:** ..." or "**Label:** ..." and collapses
     * "SEO " prefix + Singapore suffix variants so meta_title resolves
     * for both skills.
     */
    protected function _parseAiSeoSections($md)
    {
        $out = array();
        $pattern = '/^\s*(?:\d+\.\s*)?\*\*([^*]+?)\*\*:?\s*(.*)$/mu';
        if (!preg_match_all($pattern, $md, $matches, PREG_OFFSET_CAPTURE)) {
            return $out;
        }
        $count = count($matches[0]);
        for ($i = 0; $i < $count; $i++) {
            $rawLabel = strtolower(trim($matches[1][$i][0]));
            // Claude returns "**SEO Meta Title:**" with the colon INSIDE
            // the asterisks, so it lands inside our captured label. Strip
            // it (along with any stray punctuation) before slugifying,
            // otherwise the key becomes "meta_title:" and the caller's
            // `$sections['meta_title']` lookup misses.
            $rawLabel = rtrim($rawLabel, " :.\t");
            $rawLabel = preg_replace('/^seo\s+/', '', $rawLabel);
            // "Meta Title for Singapore" collapses to "meta_title" — SG is
            // the default scope so callers can keep using $sections['meta_title']
            // unconditionally. Other countries keep the "for <country>"
            // suffix and slugify to "meta_title_for_malaysia" etc.
            $rawLabel = preg_replace('/\s+for\s+singapore$/', '', $rawLabel);
            // Strip parens-wrapped country variants like "Meta Title (Default)"
            // -> "meta_title", and country-specific meta labels to share the same downstream
            // key shape regardless of which prompt produced the output.
            if (preg_match('/^(.*?)\s*\(([^)]+)\)\s*$/u', $rawLabel, $pm)) {
                $base = trim($pm[1]);
                $var  = strtolower(trim($pm[2]));
                if ($var === 'default' || $var === 'singapore') {
                    $rawLabel = $base;
                } else {
                    $rawLabel = $base . ' for ' . $var;
                }
            }
            $label    = preg_replace('/\s+/', '_', trim($rawLabel));

            $start = $matches[2][$i][1];
            $end   = ($i + 1 < $count)
                ? $matches[0][$i + 1][1]
                : strlen($md);
            $value = trim(substr($md, $start, $end - $start));
            // Strip bullet markers so keywords/description aren't littered
            // with leading "- ".
            $value = preg_replace('/^[\-\*]\s+/m', '', $value);
            // Strip the trailing horizontal rule Claude likes to add
            // between sections.
            $value = preg_replace('/^-{3,}\s*$/m', '', $value);
            $out[$label] = trim($value);
        }
        return $out;
    }

    protected function _isAllowed()
    {
        // Course / class / enrolment / attendance management. Trainers
        // legitimately use addSession, attendance lookups, etc.; learners
        // and marketing-only users have no business here.
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(array(
            'training_provider', 'admin', 'developer', 'trainer',
        ));
    }

    /**
     * Bulk-renumber the SORT positions of every product's "Course Date"
     * custom-option in date order, in steps of 10.
     *
     * Scope:
     *   - scope=store   : products visible on the website that owns the
     *                     given store_id (catalog_product_website join)
     *   - scope=global  : every product, regardless of store
     *
     * "Course Date" option = any catalog_product_option whose admin-scope
     * (store_id=0) title OR description equals "course date"
     * (case-insensitive). Matches the same heuristic used by the per-row
     * "Delete Past Dates" feature.
     *
     * Returns JSON { success, scope, products_processed, values_renumbered,
     *                products_skipped_no_dates }.
     */
    public function bulkRenumberAction()
    {
        $resp = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $req     = $this->getRequest();
            $scope   = (string) $req->getParam('scope');
            if (!in_array($scope, array('store', 'global'), true)) {
                throw new Exception('scope must be "store" or "global"');
            }
            $storeId = (int) $req->getParam('store_id');

            $resource = Mage::getSingleton('core/resource');
            $r        = $resource->getConnection('core_read');
            $w        = $resource->getConnection('core_write');
            $tOpt     = $resource->getTableName('catalog/product_option');
            $tTitle   = $resource->getTableName('catalog/product_option_title');
            $tVal     = $resource->getTableName('catalog/product_option_type_value');

            // 1. Find every option_id whose admin-scope title is "Course Date".
            //    description column lives in the custom_options_option_description
            //    table (added by MMD_CustomOptions); join LEFT so missing-row
            //    products still match on title.
            $tDesc = 'custom_options_option_description';
            $sql = "SELECT o.option_id, o.product_id
                    FROM {$tOpt} o
                    JOIN {$tTitle} t ON t.option_id = o.option_id AND t.store_id = 0
                    LEFT JOIN {$tDesc} d ON d.option_id = o.option_id
                    WHERE LOWER(TRIM(t.title)) = 'course date'
                       OR LOWER(TRIM(COALESCE(d.description, ''))) = 'course date'";

            $params = array();
            if ($scope === 'store') {
                if ($storeId <= 0) throw new Exception('store_id required for scope=store');
                $websiteId = (int) Mage::app()->getStore($storeId)->getWebsiteId();
                $sql .= " AND o.product_id IN (SELECT product_id FROM " .
                        $resource->getTableName('catalog/product_website') .
                        " WHERE website_id = ?)";
                $params[] = $websiteId;
            }

            $optionRows = $r->fetchAll($sql, $params);

            $productsSeen      = array();
            $productsProcessed = 0;
            $productsSkipped   = 0;
            $valuesRenumbered  = 0;

            foreach ($optionRows as $row) {
                $optionId = (int) $row['option_id'];
                $pid      = (int) $row['product_id'];
                $vals = $r->fetchAll(
                    "SELECT option_type_id, reg_course
                     FROM {$tVal}
                     WHERE option_id = ?",
                    array($optionId)
                );
                if (empty($vals)) continue;

                // Parse reg_course (m/d/y, e.g. "5/29/26") into timestamps.
                // Rows with blank / unparseable dates are pushed to the end and
                // keep their existing sort_order untouched.
                $dated   = array();
                foreach ($vals as $v) {
                    $raw = (string) $v['reg_course'];
                    if ($raw === '') continue;
                    $dt = DateTime::createFromFormat('n/j/y', $raw);
                    if (!($dt instanceof DateTime)) continue;
                    $dated[] = array(
                        'id' => (int) $v['option_type_id'],
                        'ts' => (int) $dt->getTimestamp(),
                    );
                }
                if (empty($dated)) { $productsSkipped++; continue; }
                usort($dated, function($a, $b){
                    if ($a['ts'] === $b['ts']) return $a['id'] - $b['id'];
                    return $a['ts'] - $b['ts'];
                });

                $sort = 10;
                foreach ($dated as $item) {
                    $w->update(
                        $tVal,
                        array('sort_order' => $sort),
                        array('option_type_id = ?' => $item['id'])
                    );
                    $sort += 10;
                    $valuesRenumbered++;
                }
                if (!isset($productsSeen[$pid])) {
                    $productsSeen[$pid] = true;
                    $productsProcessed++;
                }
            }

            Mage::app()->cleanCache();

            Mage::log(sprintf(
                'bulkRenumber scope=%s storeId=%d optionRows=%d productsProcessed=%d productsSkippedNoDates=%d valuesRenumbered=%d',
                $scope, $storeId, count($optionRows), $productsProcessed, $productsSkipped, $valuesRenumbered
            ), null, 'mmd_schedule_save.log', true);

            $resp = array(
                'success'                   => true,
                'scope'                     => $scope,
                'store_id'                  => $storeId,
                'products_processed'        => $productsProcessed,
                'products_skipped_no_dates' => $productsSkipped,
                'values_renumbered'         => $valuesRenumbered,
            );
        } catch (Exception $e) {
            $resp['message'] = $e->getMessage();
        }
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($resp));
    }

    /**
     * AJAX: send a trainer invitation for a class run.
     *
     * POST params:
     *   run_id               (int, required)
     *   trainer_name         (string, optional — admin override to invite a specific trainer)
     *
     * Returns JSON { success, message, trainer_name?, trainer_email? }
     */
    /**
     * Toggle invitation_paused or invitation_replies_blocked on a course run.
     *
     * POST params:
     *   run_id   (int, required)
     *   flag     (string: invitation_paused | invitation_replies_blocked)
     *   value    (0 | 1)
     *
     * Returns JSON { success, message, value }
     */
    public function updateInvitationFlagsAction()
    {
        $result = array('success' => false, 'message' => 'An error occurred.');
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $this->_validateFormKey();

            $runId = (int)    $this->getRequest()->getParam('run_id');
            $flag  = (string) $this->getRequest()->getParam('flag');
            $value = (int)    $this->getRequest()->getParam('value');

            if (!$runId) {
                throw new Exception('run_id is required');
            }
            $allowed = array('invitation_paused', 'invitation_replies_blocked');
            if (!in_array($flag, $allowed, true)) {
                throw new Exception('Invalid flag');
            }

            $resource = Mage::getSingleton('core/resource');
            $write    = $resource->getConnection('core_write');
            $write->update(
                $resource->getTableName('course_runs'),
                array($flag => $value ? 1 : 0),
                array('run_id = ?' => $runId)
            );

            $result = array('success' => true, 'message' => 'Updated.', 'value' => $value ? 1 : 0);
        } catch (Exception $e) {
            $result = array('success' => false, 'message' => $e->getMessage());
        }
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($result));
    }

    /**
     * Master toggle for the automated trainer-invitation cron sweep.
     *
     * Stored in core_config_data at mmd/trainer_invitation/auto_enabled.
     * Absent/0 = disabled (fail-safe default — the cron self-skips). Manual
     * "Send Invitation" actions are NOT affected by this flag.
     *
     * Restricted to administrative roles (Admin / Super Admin / Developer) —
     * trainers must not flip the global automation switch.
     *
     * POST params: value (0 | 1)
     * Returns JSON { success, message, value }
     */
    public function setAutoInvitationEnabledAction()
    {
        $result = array('success' => false, 'message' => 'An error occurred.');
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $this->_validateFormKey();

            if (!Mage::helper('mmd_rolemanager')->isRoleAllowed(array('admin', 'training_provider', 'developer'))) {
                throw new Exception('Not authorized to change this setting.');
            }

            $value = (int) $this->getRequest()->getParam('value') ? 1 : 0;

            Mage::getConfig()->saveConfig('mmd/trainer_invitation/auto_enabled', $value, 'default', 0);
            Mage::getConfig()->reinit();

            $result = array(
                'success' => true,
                'message' => $value ? 'Automated invitations enabled.' : 'Automated invitations disabled.',
                'value'   => $value,
            );
        } catch (Exception $e) {
            $result = array('success' => false, 'message' => $e->getMessage());
        }
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($result));
    }

    /**
     * Set the auto-invite look-ahead window (days before class start that the
     * sweep considers). Stored in mmd/trainer_invitation/window_days; the cron
     * reads it (falls back to 30 when unset). Clamped to 1..365.
     */
    public function setInvitationWindowAction()
    {
        $result = array('success' => false, 'message' => 'An error occurred.');
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $this->_validateFormKey();
            if (!Mage::helper('mmd_rolemanager')->isRoleAllowed(array('admin', 'training_provider', 'developer'))) {
                throw new Exception('Not authorized to change this setting.');
            }
            $days = (int) $this->getRequest()->getParam('days');
            if ($days < 1)   $days = 1;
            if ($days > 365) $days = 365;

            Mage::getConfig()->saveConfig('mmd/trainer_invitation/window_days', $days, 'default', 0);
            Mage::getConfig()->reinit();

            $result = array('success' => true, 'message' => 'Invitation window set to ' . $days . ' days.', 'days' => $days);
        } catch (Exception $e) {
            $result = array('success' => false, 'message' => $e->getMessage());
        }
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($result));
    }

    public function sendTrainerInvitationAction()
    {
        $result = array('success' => false, 'message' => 'An error occurred.');
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $this->_validateFormKey();

            $runId        = (int)    $this->getRequest()->getParam('run_id');
            $trainerName  = (string) $this->getRequest()->getParam('trainer_name', '');
            if (!$runId) {
                throw new Exception('run_id is required');
            }

            /** @var MMD_RoleManager_Model_TrainerInvitationService $svc */
            $svc    = Mage::getModel('mmd_rolemanager/trainerInvitationService');
            $result = $svc->sendNextInvitation($runId, $trainerName);

        } catch (Exception $e) {
            $result = array('success' => false, 'message' => $e->getMessage());
        }
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($result));
    }
}
