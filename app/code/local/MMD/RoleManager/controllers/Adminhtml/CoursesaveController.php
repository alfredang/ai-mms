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
            if (($v = $req->getParam('course_description')) !== null) $product->setData('short_description', $v);
            if (($v = $req->getParam('who_should_attend')) !== null) $product->setData('whoshouldattend', $v);
            if (($v = $req->getParam('prerequisite'))      !== null) $product->setData('prerequisite', $v);

            // Course Information fields (back the storefront rightData tab):
            // sessions (text), level (select option_id), additional_note (textarea).
            if (($v = $req->getParam('sessions'))        !== null) $product->setData('sessions',        $v === '' ? null : $v);
            if (($v = $req->getParam('level'))           !== null) $product->setData('level',           $v === '' ? null : (int)$v);
            if (($v = $req->getParam('additional_note')) !== null) $product->setData('additional_note', $v);

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
                'lesson_plan_url', 'learner_guide_url',
                'learner_slides_url', 'trainer_slides_url',
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
            $trainerOp = (int)         $req->getParam('trainer_option_id');
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

            // Persist all the form fields to course_runs.
            $runRow = array(
                'product_id'        => $productId,
                'course_sku'        => $sku,
                'trainer_option_id' => $trainerOp > 0 ? $trainerOp : null,
                'reg_open_date'     => preg_match('/^\d{4}-\d{2}-\d{2}$/', $regOpen)   ? $regOpen   : null,
                'reg_close_date'    => preg_match('/^\d{4}-\d{2}-\d{2}$/', $regClose)  ? $regClose  : null,
                'course_start_date' => preg_match('/^\d{4}-\d{2}-\d{2}$/', $startDate) ? $startDate : null,
                'course_end_date'   => preg_match('/^\d{4}-\d{2}-\d{2}$/', $endDate)   ? $endDate   : null,
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
            );
            $write->insert($resource->getTableName('course_runs'), $runRow);
            $result['run_id'] = (int) $write->lastInsertId();

            // Append the trainer option_id to the `trainers` multiselect.
            // Stored as a comma-separated string in catalog_product_entity_text
            // for attribute_id = trainers attribute. Append, dedupe, save.
            if ($trainerOp > 0) {
                $trainersAttrId = (int) $read->fetchOne(
                    "SELECT attribute_id FROM eav_attribute WHERE attribute_code='trainers' AND entity_type_id=4"
                );
                if (!$trainersAttrId) throw new Exception('Trainers attribute not configured');
                $existing = (string) $read->fetchOne(
                    "SELECT value FROM {$eavTx} WHERE entity_id=? AND attribute_id=? AND store_id=0 LIMIT 1",
                    array($productId, $trainersAttrId)
                );
                $opts = $existing !== '' ? array_filter(array_map('intval', explode(',', $existing))) : array();
                if (!in_array($trainerOp, $opts, true)) {
                    $opts[] = $trainerOp;
                    $newCsv = implode(',', $opts);
                    if ($existing !== '') {
                        $write->update($eavTx,
                            array('value' => $newCsv),
                            array('entity_id = ?' => $productId, 'attribute_id = ?' => $trainersAttrId, 'store_id = ?' => 0)
                        );
                    } else {
                        $write->insert($eavTx, array(
                            'entity_type_id' => 4,
                            'attribute_id'   => $trainersAttrId,
                            'store_id'       => 0,
                            'entity_id'      => $productId,
                            'value'          => $newCsv,
                        ));
                    }
                    $result['trainer_added'] = true;
                } else {
                    $result['trainer_added'] = false; // already assigned
                }
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
            $result['message'] = 'Class scheduled. The assigned trainer can now see it under "My Assigned Classes".';
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
     * List learners attached to a product. Union of sales_flat_order
     * customers (historical purchases) and course_run_enrolments rows
     * (admin-driven enrolments via the Assign Learners panel).
     */
    public function loadLearnersAction()
    {
        $result = array('success' => false, 'learners' => array());
        try {
            $productId = (int) $this->getRequest()->getParam('product_id');
            if (!$productId) throw new Exception('product_id required');

            $resource = Mage::getSingleton('core/resource');
            $read     = $resource->getConnection('core_read');
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

            // Resolve the latest run for the product so the enrolment
            // attaches to the upcoming class instance, not the product
            // generally — keeps per-run counting honest.
            $runId = $read->fetchOne(
                "SELECT MAX(run_id) FROM " . $resource->getTableName('course_runs') . " WHERE product_id=?",
                array($productId)
            );
            $runId = $runId ? (int) $runId : null;

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
            $email     = strtolower(trim((string) $req->getParam('learner_email')));
            if (!$productId || $email === '') throw new Exception('product_id + learner_email required');

            $resource = Mage::getSingleton('core/resource');
            $write    = $resource->getConnection('core_write');
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
