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

            // Basic fields
            if (($v = $req->getParam('course_name'))  !== null && $v !== '') $product->setName($v);
            if (($v = $req->getParam('course_code'))  !== null && $v !== '') $product->setSku($v);
            if (($v = $req->getParam('image_url'))    !== null)              $product->setData('course_image_url', $v);
            if (($v = $req->getParam('brochure_url')) !== null)              $product->setData('course_brochure_url', $v);
            if (($v = $req->getParam('duration'))     !== null && $v !== '') $product->setData('duration', $v);
            if (($v = $req->getParam('training_hours')) !== null && $v !== '') $product->setData('duration', $v);
            if (($v = $req->getParam('price'))        !== null && $v !== '') $product->setPrice((float)$v);
            if (($v = $req->getParam('funding_validity')) !== null && $v !== '') {
                $product->setData('news_to_date', $v);
            }

            // Trainer multiselect (primary source)
            $trainerIdsChanged = false;
            if (($v = $req->getParam('trainer_ids')) !== null) {
                $ids = array_filter(array_map('intval', explode(',', $v)));
                $product->setData('trainers', implode(',', $ids));
                $trainerIdsChanged = true;
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
            }
            if (($v = $req->getParam('learning_outcomes')) !== null) $product->setData('description', $v);
            if (($v = $req->getParam('who_should_attend')) !== null) $product->setData('whoshouldattend', $v);
            if (($v = $req->getParam('prerequisite'))      !== null) $product->setData('prerequisite', $v);

            // SEO
            if (($v = $req->getParam('meta_title'))        !== null) $product->setMetaTitle($v);
            if (($v = $req->getParam('meta_description'))  !== null) $product->setMetaDescription($v);
            if (($v = $req->getParam('meta_keyword'))      !== null) $product->setMetaKeyword($v);

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

            // === Prices tab ===
            if (($v = $req->getParam('prices_price'))        !== null && $v !== '') $product->setData('price', (float)$v);
            if (($v = $req->getParam('prices_special_price')) !== null) $product->setData('special_price',     $v === '' ? null : (float)$v);
            if (($v = $req->getParam('prices_special_from_date')) !== null) $product->setData('special_from_date', $v ?: null);
            if (($v = $req->getParam('prices_special_to_date'))   !== null) $product->setData('special_to_date',   $v ?: null);
            if (($v = $req->getParam('prices_cost'))         !== null) $product->setData('cost',          $v === '' ? null : (float)$v);
            if (($v = $req->getParam('prices_msrp'))         !== null) $product->setData('msrp',          $v === '' ? null : (float)$v);
            if (($v = $req->getParam('prices_msrp_enabled')) !== null) $product->setData('msrp_enabled',  $v);
            if (($v = $req->getParam('prices_msrp_display_actual_price_type')) !== null) $product->setData('msrp_display_actual_price_type', $v);

            // === Trainer Details tab — Trainer Profile rich text ===
            if (($v = $req->getParam('trainer_profile')) !== null) $product->setData('trainerprofile', $v);

            // === Recurring Profile ===
            if (($v = $req->getParam('recurring_profile_enabled')) !== null) $product->setData('is_recurring', (int)$v);

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

            // === Group Price (Prices tab) ===
            if ($req->getParam('_group_price_loaded')) {
                $_gpRaw = (array) $req->getParam('group_price', array());
                $_gpClean = array();
                foreach ($_gpRaw as $_row) {
                    if (!is_array($_row)) continue;
                    $_gpClean[] = array(
                        'website_id' => (int) (isset($_row['website_id']) ? $_row['website_id'] : 0),
                        'cust_group' => (int) (isset($_row['cust_group']) ? $_row['cust_group'] : 0),
                        'price'      => (float) (isset($_row['price']) ? $_row['price'] : 0),
                    );
                }
                $product->setGroupPrice($_gpClean);
            }

            // === Tier Price (Prices tab) ===
            if ($req->getParam('_tier_price_loaded')) {
                $_tpRaw = (array) $req->getParam('tier_price', array());
                $_tpClean = array();
                foreach ($_tpRaw as $_row) {
                    if (!is_array($_row)) continue;
                    $_tpClean[] = array(
                        'website_id' => (int) (isset($_row['website_id']) ? $_row['website_id'] : 0),
                        'cust_group' => (int) (isset($_row['cust_group']) ? $_row['cust_group'] : 0),
                        'price_qty'  => (int) (isset($_row['price_qty']) ? max(1, (int)$_row['price_qty']) : 1),
                        'price'      => (float) (isset($_row['price']) ? $_row['price'] : 0),
                    );
                }
                $product->setTierPrice($_tpClean);
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
                foreach ($_valueMap as $_vid => $_fields) {
                    $_vid = (int) $_vid;
                    if ($_vid <= 0 || !in_array($_vid, $_remainingValueIds, true)) continue;
                    $_title = isset($_fields['title']) ? trim((string) $_fields['title']) : null;
                    $_priceRaw = isset($_fields['price']) ? trim((string) $_fields['price']) : null;
                    $_sort  = isset($_fields['sort'])  ? (int) $_fields['sort']  : null;

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

                        $_write->insert($_optTypeTable, array(
                            'option_id'  => $_optId,
                            'sku'        => '',
                            'sort_order' => $_sort,
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

                Mage::app()->cleanCache();
            }

            // Save courseware URLs into the dedicated course_courseware table (upsert by product_id).
            // Only runs if the form actually submitted any courseware_* field.
            $_cwFields = array(
                'lesson_plan_url', 'learner_guide_url', 'facilitator_guide_url',
                'assessment_plan_url', 'learner_slides_url', 'trainer_slides_url',
                'courseware_link', 'brochure_link',
                'assessment_record_link', 'assessment_summary_url',
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

            // Force-save the multiselect trainers attribute directly to catalog_product_entity_text
            // in case Magento's normal save didn't persist it correctly for multiselects
            if ($trainerIdsChanged) {
                $product->getResource()->saveAttribute($product, 'trainers');
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
            Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
            $dashboardUrl = Mage::helper('adminhtml')->getUrl('adminhtml/dashboard');
            $this->_redirectUrl($dashboardUrl);
        }
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

    protected function _isAllowed()
    {
        // Course / class / enrolment / attendance management. Trainers
        // legitimately use addSession, attendance lookups, etc.; learners
        // and marketing-only users have no business here.
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(array(
            'training_provider', 'admin', 'developer', 'trainer',
        ));
    }
}
