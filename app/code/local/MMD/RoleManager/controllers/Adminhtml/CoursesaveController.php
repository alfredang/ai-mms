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

            $product->save();

            // Save courseware URLs into the dedicated course_courseware table (upsert by product_id).
            // Only runs if the form actually submitted any courseware_* field.
            $_cwFields = array(
                'lesson_plan_url', 'learner_guide_url', 'facilitator_guide_url',
                'assessment_plan_url', 'learner_slides_url', 'trainer_slides_url',
                'courseware_link', 'brochure_link', 'skillsfuture_link',
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

    /**
     * Add a Course Date session to a product.
     * Creates the "Course Date" drop_down custom option if it doesn't exist,
     * then appends a new option type value (title = session label, e.g. "27 April 2026 (Mon)").
     * POST: course_id, session_date (YYYY-MM-DD), session_label (optional override)
     * Returns JSON { success: bool, message?, option_type_id? }
     */
    public function addSessionAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $req = $this->getRequest();
            $courseId = (int) $req->getParam('course_id');
            $dateIn   = trim((string) $req->getParam('session_date'));
            $label    = trim((string) $req->getParam('session_label'));
            $price    = $req->getParam('session_price');
            if (!$courseId || $dateIn === '') {
                throw new Exception('course_id and session_date are required');
            }
            $ts = strtotime($dateIn);
            if (!$ts) {
                throw new Exception('Invalid date: ' . $dateIn);
            }
            if ($label === '') {
                // Default: "27 April 2026 (Mon)"
                $label = date('j F Y', $ts) . ' (' . date('D', $ts) . ')';
            }
            $product = Mage::getModel('catalog/product')->load($courseId);
            if (!$product->getId()) {
                throw new Exception('Course not found');
            }
            $resource = Mage::getSingleton('core/resource');
            $read  = $resource->getConnection('core_read');
            $write = $resource->getConnection('core_write');
            $optTable      = $resource->getTableName('catalog/product_option');
            $optTitleTable = $resource->getTableName('catalog/product_option_title');
            $optTypeTable  = $resource->getTableName('catalog/product_option_type_value');
            $optTypeTitle  = $resource->getTableName('catalog/product_option_type_title');
            $optTypePrice  = $resource->getTableName('catalog/product_option_type_price');

            // Find existing "Course Date" option for this product
            $optionId = (int) $read->fetchOne(
                "SELECT o.option_id FROM {$optTable} o
                 JOIN {$optTitleTable} ot ON ot.option_id = o.option_id AND ot.store_id = 0
                 WHERE o.product_id = ? AND ot.title = 'Course Date' LIMIT 1",
                array($courseId)
            );

            if (!$optionId) {
                // Create the "Course Date" drop_down option
                $write->insert($optTable, array(
                    'product_id'   => $courseId,
                    'type'         => 'drop_down',
                    'is_require'   => 1,
                    'sort_order'   => 0,
                ));
                $optionId = (int) $write->lastInsertId();
                $write->insert($optTitleTable, array(
                    'option_id' => $optionId,
                    'store_id'  => 0,
                    'title'     => 'Course Date',
                ));
            }

            // Append option type value
            $write->insert($optTypeTable, array(
                'option_id'  => $optionId,
                'sku'        => '',
                'sort_order' => 0,
            ));
            $optionTypeId = (int) $write->lastInsertId();
            $write->insert($optTypeTitle, array(
                'option_type_id' => $optionTypeId,
                'store_id'       => 0,
                'title'          => $label,
            ));
            if ($price !== null && $price !== '') {
                $write->insert($optTypePrice, array(
                    'option_type_id' => $optionTypeId,
                    'store_id'       => 0,
                    'price'          => (float) $price,
                    'price_type'     => 'fixed',
                ));
            }

            Mage::app()->cleanCache();
            $result['success']        = true;
            $result['option_type_id'] = $optionTypeId;
            $result['label']          = $label;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Delete a Course Date session (single option_type_id).
     * POST: course_id, option_type_id
     */
    public function deleteSessionAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $req = $this->getRequest();
            $courseId     = (int) $req->getParam('course_id');
            $optionTypeId = (int) $req->getParam('option_type_id');
            if (!$courseId || !$optionTypeId) {
                throw new Exception('course_id and option_type_id are required');
            }
            $resource = Mage::getSingleton('core/resource');
            $read  = $resource->getConnection('core_read');
            $write = $resource->getConnection('core_write');
            $optTypeTable = $resource->getTableName('catalog/product_option_type_value');
            $optTable     = $resource->getTableName('catalog/product_option');

            // Verify the option_type belongs to this product (safety check)
            $ok = $read->fetchOne(
                "SELECT 1 FROM {$optTypeTable} ov
                 JOIN {$optTable} o ON o.option_id = ov.option_id
                 WHERE ov.option_type_id = ? AND o.product_id = ?",
                array($optionTypeId, $courseId)
            );
            if (!$ok) {
                throw new Exception('Session not found for this course');
            }
            // Deleting from catalog/product_option_type_value cascades to _title and _price via FK
            $write->delete($optTypeTable, array('option_type_id = ?' => $optionTypeId));
            Mage::app()->cleanCache();
            $result['success'] = true;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Assign (or clear) a trainer for an existing session.
     * POST: course_id, option_type_id, trainer_option_id (0 to clear)
     */
    public function assignSessionTrainerAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $req = $this->getRequest();
            $courseId     = (int) $req->getParam('course_id');
            $optionTypeId = (int) $req->getParam('option_type_id');
            $trainerOptId = (int) $req->getParam('trainer_option_id');
            if (!$courseId || !$optionTypeId) {
                throw new Exception('course_id and option_type_id are required');
            }
            $resource = Mage::getSingleton('core/resource');
            $read  = $resource->getConnection('core_read');
            $write = $resource->getConnection('core_write');

            // Verify session belongs to course
            $belongs = $read->fetchOne(
                "SELECT 1 FROM catalog_product_option_type_value ov
                 JOIN catalog_product_option o ON o.option_id = ov.option_id
                 WHERE ov.option_type_id = ? AND o.product_id = ?",
                array($optionTypeId, $courseId)
            );
            if (!$belongs) {
                throw new Exception('Session not found for this course');
            }

            if ($trainerOptId <= 0) {
                // Clear assignment
                $write->delete('course_session_trainers', array('option_type_id = ?' => $optionTypeId));
                $result['success'] = true;
                $result['trainer_name'] = '';
            } else {
                $trainerName = (string) $read->fetchOne(
                    "SELECT value FROM eav_attribute_option_value WHERE option_id = ? AND store_id = 0",
                    array($trainerOptId)
                );
                // Upsert
                $existing = $read->fetchOne(
                    "SELECT id FROM course_session_trainers WHERE option_type_id = ?",
                    array($optionTypeId)
                );
                if ($existing) {
                    $write->update('course_session_trainers',
                        array('trainer_option_id' => $trainerOptId, 'trainer_name' => $trainerName),
                        array('id = ?' => (int)$existing)
                    );
                } else {
                    $write->insert('course_session_trainers', array(
                        'option_type_id'    => $optionTypeId,
                        'trainer_option_id' => $trainerOptId,
                        'trainer_name'      => $trainerName,
                    ));
                }
                $result['success']      = true;
                $result['trainer_name'] = $trainerName;
            }
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Create New Class handler — TPG Management → Course Run → Create New Class.
     *
     * Treats "a new class" as a new scheduled run of an existing course:
     *   1. Resolves the template course by entity_id (from the dropdown) or SKU (typed value).
     *   2. Adds a "Course Date" custom option value using the form's start/end dates.
     *   3. Resolves the trainer input (name / email / NRIC — NRIC will never match but
     *      name & email will) to an existing trainer option_id on attribute 170.
     *   4. Appends that trainer to the product's `trainers` multiselect (dedup).
     *   5. Inserts a row into `course_session_trainers` so the trainer is bound to the
     *      new session specifically (same mechanism the trainer dashboard already reads).
     *
     * Net effect: the trainer whose admin account matches (by email or name) the entered
     * trainer now sees this course on their Trainer dashboard under "Upcoming".
     */
    public function createClassAction()
    {
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $req = $this->getRequest();

            $courseEntityId = (int) $req->getParam('course_entity_id');
            $courseRef      = trim((string) $req->getParam('course_ref'));
            $startDate      = trim((string) $req->getParam('course_start_date'));
            $endDate        = trim((string) $req->getParam('course_end_date'));
            $trainerLookup  = trim((string) $req->getParam('trainer_lookup'));

            if (!$courseEntityId && $courseRef === '') {
                throw new Exception('Select a course from the dropdown or enter a Course Reference Number.');
            }
            if ($startDate === '' || $endDate === '') {
                throw new Exception('Course Start Date and Course End Date are required.');
            }

            $resource = Mage::getSingleton('core/resource');
            $read  = $resource->getConnection('core_read');
            $write = $resource->getConnection('core_write');

            // Resolve course — prefer entity_id, fall back to SKU lookup
            if (!$courseEntityId && $courseRef !== '') {
                $courseEntityId = (int) $read->fetchOne(
                    "SELECT entity_id FROM catalog_product_entity WHERE sku = ? LIMIT 1",
                    array($courseRef)
                );
                if (!$courseEntityId) {
                    throw new Exception('No existing course found with reference "' . $courseRef . '". Pick one from the dropdown.');
                }
            }

            $product = Mage::getModel('catalog/product')->load($courseEntityId);
            if (!$product->getId()) {
                throw new Exception('Course not found (entity_id ' . $courseEntityId . ').');
            }

            // Seed trainerprofile / trainers from DB so save() won't silently wipe them
            try {
                $tpAttrId = (int) $read->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='trainerprofile' AND entity_type_id=4");
                if ($tpAttrId) {
                    $tpExisting = $read->fetchOne(
                        "SELECT value FROM catalog_product_entity_text WHERE entity_id=? AND attribute_id=? AND value IS NOT NULL AND value != '' ORDER BY store_id LIMIT 1",
                        array($courseEntityId, $tpAttrId)
                    );
                    if ($tpExisting !== false && $tpExisting !== null) {
                        $product->setData('trainerprofile', $tpExisting);
                    }
                }
            } catch (Exception $e) {}

            $existingTrainersCsv = (string) $read->fetchOne(
                "SELECT value FROM catalog_product_entity_text WHERE entity_id=? AND attribute_id=170 AND value IS NOT NULL AND value != '' ORDER BY store_id LIMIT 1",
                array($courseEntityId)
            );

            // --- Step 2: Add Course Date session ---
            $startTs = strtotime($startDate);
            if (!$startTs) throw new Exception('Invalid start date: ' . $startDate);
            $endTs = strtotime($endDate);
            if (!$endTs) throw new Exception('Invalid end date: ' . $endDate);

            $label = date('j M Y', $startTs) . ' (' . date('D', $startTs) . ')';
            if (date('Ymd', $startTs) !== date('Ymd', $endTs)) {
                $label = date('j', $startTs) . '/' . date('j M Y', $endTs) . ' (' . date('D', $startTs) . '-' . date('D', $endTs) . ')';
            }

            $optTable      = $resource->getTableName('catalog/product_option');
            $optTitleTable = $resource->getTableName('catalog/product_option_title');
            $optTypeTable  = $resource->getTableName('catalog/product_option_type_value');
            $optTypeTitle  = $resource->getTableName('catalog/product_option_type_title');

            $optionId = (int) $read->fetchOne(
                "SELECT o.option_id FROM {$optTable} o
                 JOIN {$optTitleTable} ot ON ot.option_id = o.option_id AND ot.store_id = 0
                 WHERE o.product_id = ? AND ot.title = 'Course Date' LIMIT 1",
                array($courseEntityId)
            );
            if (!$optionId) {
                $write->insert($optTable, array(
                    'product_id' => $courseEntityId,
                    'type'       => 'drop_down',
                    'is_require' => 1,
                    'sort_order' => 0,
                ));
                $optionId = (int) $write->lastInsertId();
                $write->insert($optTitleTable, array(
                    'option_id' => $optionId,
                    'store_id'  => 0,
                    'title'     => 'Course Date',
                ));
            }
            $write->insert($optTypeTable, array(
                'option_id'  => $optionId,
                'sku'        => '',
                'sort_order' => 0,
            ));
            $newOptionTypeId = (int) $write->lastInsertId();
            $write->insert($optTypeTitle, array(
                'option_type_id' => $newOptionTypeId,
                'store_id'       => 0,
                'title'          => $label,
            ));

            // --- Step 3: Resolve trainer ---
            $trainerOptionId = 0;
            $trainerValueStr = '';
            if ($trainerLookup !== '') {
                // Try exact-match first, then LIKE
                $row = $read->fetchRow(
                    "SELECT eao.option_id, eaov.value
                     FROM eav_attribute_option eao
                     JOIN eav_attribute_option_value eaov ON eao.option_id = eaov.option_id AND eaov.store_id = 0
                     WHERE eao.attribute_id = 170 AND eaov.value = ?
                     LIMIT 1",
                    array($trainerLookup)
                );
                if (!$row) {
                    $row = $read->fetchRow(
                        "SELECT eao.option_id, eaov.value
                         FROM eav_attribute_option eao
                         JOIN eav_attribute_option_value eaov ON eao.option_id = eaov.option_id AND eaov.store_id = 0
                         WHERE eao.attribute_id = 170 AND eaov.value LIKE ?
                         ORDER BY LENGTH(eaov.value) ASC
                         LIMIT 1",
                        array('%' . $trainerLookup . '%')
                    );
                }
                if ($row) {
                    $trainerOptionId = (int) $row['option_id'];
                    $trainerValueStr = (string) $row['value'];
                }
            }

            // --- Step 4: Append trainer to product's trainers multiselect ---
            $trainerAdded = false;
            if ($trainerOptionId > 0) {
                $idsArr = array_filter(array_map('intval', explode(',', $existingTrainersCsv)));
                if (!in_array($trainerOptionId, $idsArr, true)) {
                    $idsArr[] = $trainerOptionId;
                    $product->setData('trainers', implode(',', $idsArr));
                    $product->save();
                    $product->getResource()->saveAttribute($product, 'trainers');
                    $product->getResource()->saveAttribute($product, 'trainerprofile');
                    $trainerAdded = true;
                }

                // --- Step 5: Link session ↔ trainer (the trainer dashboard reads this) ---
                try {
                    $write->insert('course_session_trainers', array(
                        'option_type_id'    => $newOptionTypeId,
                        'trainer_option_id' => $trainerOptionId,
                        'trainer_name'      => $trainerValueStr,
                    ));
                } catch (Exception $e) {
                    // Table may not exist in some envs — ignore silently
                }
            }

            // Register this course in course_run_registry so the Trainer / Learner
            // dashboards can render a per-course sequential Course Run ID
            // (SG-100000, SG-100001, ...). Idempotent — a course that's already
            // registered keeps its existing seq.
            $courseRunSeq = null;
            try {
                $existingSeq = $read->fetchOne(
                    "SELECT run_seq FROM course_run_registry WHERE product_id = ?",
                    array($courseEntityId)
                );
                if ($existingSeq === false || $existingSeq === null) {
                    $productWebsiteId = (int) $read->fetchOne(
                        "SELECT website_id FROM catalog_product_website WHERE product_id = ? ORDER BY website_id ASC LIMIT 1",
                        array($courseEntityId)
                    ) ?: 1;
                    $nextSeq = (int) $read->fetchOne(
                        "SELECT COALESCE(MAX(run_seq), -1) + 1 FROM course_run_registry WHERE website_id = ?",
                        array($productWebsiteId)
                    );
                    $write->insert('course_run_registry', array(
                        'product_id' => $courseEntityId,
                        'website_id' => $productWebsiteId,
                        'run_seq'    => $nextSeq,
                    ));
                    $courseRunSeq = $nextSeq;
                } else {
                    $courseRunSeq = (int) $existingSeq;
                }
            } catch (Exception $e) {
                // course_run_registry migration not yet applied — skip, dashboard
                // will fall back to entity_id-based numbering.
            }

            Mage::app()->cleanCache();

            $msg = 'Class created for "' . $product->getSku() . '" on ' . $label . '.';
            if ($trainerOptionId > 0) {
                $msg .= ' Trainer "' . $trainerValueStr . '" assigned' . ($trainerAdded ? '' : ' (already linked)') . '.';
            } elseif ($trainerLookup !== '') {
                $msg .= ' (No existing trainer matched "' . $trainerLookup . '" — class saved without trainer.)';
            }
            Mage::getSingleton('adminhtml/session')->addSuccess($msg);

            $this->_redirectUrl(Mage::helper('adminhtml')->getUrl('adminhtml/dashboard', array('tpg_page' => 'create_class')));
            return;
        } catch (Exception $e) {
            Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
            $this->_redirectUrl(Mage::helper('adminhtml')->getUrl('adminhtml/dashboard', array('tpg_page' => 'create_class')));
        }
    }

    /**
     * Enroll Learners handler — TPG Management → Enrolment → Enroll Learners.
     *
     * The Learner dashboard reads enrolled courses from sales_flat_order +
     * sales_flat_order_item, matched on customer_email. To make an enrollment
     * show up for a learner we insert those two rows directly (we don't need
     * a real Magento checkout — we're an admin-only management tool).
     *
     * POST params:
     *   course_entity_id | course_ref (SKU fallback) — the course product
     *   course_run_id — stored on the order item (non-authoritative, for audit)
     *   learner_email (required) — key used by the learner dashboard
     *   learner_fullname, learner_nric, learner_dob, learner_phone — stored on order
     *   sponsorship_type — INDIVIDUAL / EMPLOYER (stored in a remote_ip-style note)
     */
    public function enrollLearnerAction()
    {
        try {
            if (!$this->getRequest()->isPost()) {
                throw new Exception('POST required');
            }
            $req = $this->getRequest();

            $courseEntityId = (int) $req->getParam('course_entity_id');
            $courseRef      = trim((string) $req->getParam('course_ref'));
            $runId          = trim((string) $req->getParam('course_run_id'));
            $email          = strtolower(trim((string) $req->getParam('learner_email')));
            $fullName       = trim((string) $req->getParam('learner_fullname'));
            $nric           = trim((string) $req->getParam('learner_nric'));
            $sponsorship    = trim((string) $req->getParam('sponsorship_type')) ?: 'INDIVIDUAL';

            if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
                throw new Exception('A valid learner email is required.');
            }
            if (!$courseEntityId && $courseRef === '') {
                throw new Exception('Select a course from the dropdown or enter a Course Reference Number.');
            }

            $resource = Mage::getSingleton('core/resource');
            $read  = $resource->getConnection('core_read');
            $write = $resource->getConnection('core_write');

            // Resolve course by entity_id, fall back to SKU
            if (!$courseEntityId && $courseRef !== '') {
                $courseEntityId = (int) $read->fetchOne(
                    "SELECT entity_id FROM catalog_product_entity WHERE sku = ? LIMIT 1",
                    array($courseRef)
                );
                if (!$courseEntityId) {
                    throw new Exception('No course found with reference "' . $courseRef . '". Pick one from the dropdown.');
                }
            }

            $product = Mage::getModel('catalog/product')->load($courseEntityId);
            if (!$product->getId()) {
                throw new Exception('Course not found (entity_id ' . $courseEntityId . ').');
            }

            // Split name
            $firstName = $fullName; $lastName = '';
            if (strpos($fullName, ' ') !== false) {
                $parts = explode(' ', $fullName, 2);
                $firstName = $parts[0];
                $lastName  = $parts[1];
            }
            if ($firstName === '') $firstName = 'Learner';

            // Dedup with auto-heal: if an enrolment already exists for (email, product),
            // check whether it was created by an older version of this controller that
            // produced a guest order (customer_id NULL) or an item without product_options.
            // Those orders are invisible to attendance/learner-dashboard queries, so we
            // delete and rewrite them. Well-formed existing rows are left alone.
            $existing = $read->fetchRow(
                "SELECT o.entity_id AS order_id, o.customer_id, oi.item_id, oi.product_options, o.increment_id
                 FROM sales_flat_order o
                 JOIN sales_flat_order_item oi ON oi.order_id = o.entity_id
                 WHERE LOWER(o.customer_email) = ? AND oi.product_id = ?
                 LIMIT 1",
                array($email, $courseEntityId)
            );
            if ($existing) {
                $brokenByOldCode = (empty($existing['customer_id']) || empty($existing['product_options']));
                // Only auto-heal orders created by our Enrol flow, never external
                // real-money orders. Our orders use the ENROL- increment_id prefix.
                $isOurEnrol = strpos((string)$existing['increment_id'], 'ENROL-') === 0;
                if ($brokenByOldCode && $isOurEnrol) {
                    $write->delete('sales_flat_order_item', array('item_id = ?' => (int)$existing['item_id']));
                    $write->delete('sales_flat_order',      array('entity_id = ?' => (int)$existing['order_id']));
                    // fall through to recreate the order below
                } else {
                    Mage::getSingleton('adminhtml/session')->addSuccess(
                        'Enrolment already exists for ' . $email . ' on ' . $product->getSku() . ' — no changes made.'
                    );
                    $this->_redirectUrl(Mage::helper('adminhtml')->getUrl('adminhtml/dashboard', array('tpg_page' => 'enroll_learners')));
                    return;
                }
            }

            // Resolve (or create) the Magento customer_entity for this learner so that
            // the order links to a real customer_id. Attendance, billing, and every
            // other downstream query joins on customer_id — a guest order with a
            // null customer_id will appear to have "no enrolled learners".
            $customerId = 0;
            try {
                $customer = Mage::getModel('customer/customer');
                $customer->setWebsiteId((int) Mage::app()->getStore()->getWebsiteId());
                $customer->loadByEmail($email);
                if (!$customer->getId()) {
                    // Fresh customer — use the default customer group and store
                    $customer->setEmail($email);
                    $customer->setFirstname($firstName ?: 'Learner');
                    $customer->setLastname($lastName ?: '');
                    $customer->setGroupId(1); // General group
                    // Set a random password — the learner can reset via email if needed
                    $customer->setPassword(substr(md5(uniqid((string)mt_rand(), true)), 0, 12));
                    $customer->setConfirmation(null);
                    $customer->save();
                }
                $customerId = (int) $customer->getId();
            } catch (Exception $e) {
                // Fall back to guest order if customer creation fails (e.g. race,
                // website constraint) — attendance will still miss this enrolment
                // but enrolment itself shouldn't block.
            }

            // Generate a unique increment_id
            $incrementId = 'ENROL-' . time() . '-' . substr(md5($email . '|' . $courseEntityId), 0, 6);

            $write->insert('sales_flat_order', array(
                'state'                => 'processing',
                'status'               => 'processing',
                'store_id'             => 1,
                'customer_id'          => $customerId ?: null,
                'customer_email'       => $email,
                'customer_firstname'   => $firstName,
                'customer_lastname'    => $lastName,
                'customer_is_guest'    => $customerId ? 0 : 1,
                'base_grand_total'     => 0,
                'grand_total'          => 0,
                'base_subtotal'        => 0,
                'subtotal'             => 0,
                'total_qty_ordered'    => 1,
                'total_item_count'     => 1,
                'base_currency_code'   => 'SGD',
                'order_currency_code'  => 'SGD',
                'store_currency_code'  => 'SGD',
                'increment_id'         => $incrementId,
                'protect_code'         => substr(md5(uniqid((string)mt_rand(), true)), 0, 20),
                // Stash non-standard enrolment metadata in the remote_ip column (harmless,
                // shows in admin order grid as a note). Keeps us from needing a schema change.
                'remote_ip'            => 'enrol:run=' . $runId . ';nric=' . $nric . ';sponsor=' . $sponsorship,
                'created_at'           => date('Y-m-d H:i:s'),
                'updated_at'           => date('Y-m-d H:i:s'),
            ));
            $orderId = (int) $write->lastInsertId();

            // Serialize product_options so AttendanceController::listAction can find this
            // enrolment for this specific session (it LIKE-matches option_value against
            // the picked option_type_id). Without this, a learner enrolled in the
            // 27 Apr session would incorrectly appear under every session of the course.
            $productOptionsSerialized = '';
            if ($runId !== '' && ctype_digit($runId)) {
                $parentOptionId = (int) $read->fetchOne(
                    "SELECT option_id FROM catalog_product_option_type_value WHERE option_type_id = ?",
                    array((int)$runId)
                );
                $sessionTitle = (string) $read->fetchOne(
                    "SELECT title FROM catalog_product_option_type_title WHERE option_type_id = ? AND store_id = 0",
                    array((int)$runId)
                );
                if ($parentOptionId && $sessionTitle !== '') {
                    $productOptionsSerialized = serialize(array(
                        'options' => array(
                            array(
                                'label'        => 'Course Date',
                                'value'        => $sessionTitle,
                                'print_value'  => $sessionTitle,
                                'option_id'    => $parentOptionId,
                                'option_type'  => 'drop_down',
                                'option_value' => (string)(int)$runId,
                            ),
                        ),
                    ));
                }
            }

            $write->insert('sales_flat_order_item', array(
                'order_id'        => $orderId,
                'store_id'        => 1,
                'created_at'      => date('Y-m-d H:i:s'),
                'updated_at'      => date('Y-m-d H:i:s'),
                'product_id'      => $courseEntityId,
                'product_type'    => 'simple',
                'sku'             => $product->getSku(),
                'name'            => $product->getName(),
                'qty_ordered'     => 1,
                'base_price'      => 0,
                'price'           => 0,
                'base_row_total'  => 0,
                'row_total'       => 0,
                'product_options' => $productOptionsSerialized,
            ));

            // Upsert learner_profile so next time this learner is picked,
            // the Trainee Information form auto-fills every field.
            try {
                $dobIn = trim((string) $req->getParam('learner_dob'));
                $dobSql = ($dobIn !== '' && strtotime($dobIn)) ? date('Y-m-d', strtotime($dobIn)) : null;
                $profileRow = array(
                    'email'            => $email,
                    'customer_id'      => $customerId ?: null,
                    'id_type'          => trim((string) $req->getParam('learner_id_type')) ?: 'NRIC',
                    'nric'             => $nric,
                    'full_name'        => $fullName,
                    'date_of_birth'    => $dobSql,
                    'country_code'     => trim((string) $req->getParam('learner_country_code')) ?: '+65',
                    'phone_number'     => trim((string) $req->getParam('learner_phone')),
                    'sponsorship_type' => $sponsorship,
                );
                $existingProfile = $read->fetchOne(
                    "SELECT id FROM learner_profile WHERE email = ? LIMIT 1",
                    array($email)
                );
                if ($existingProfile) {
                    // Only overwrite a field if the new submission actually has a non-empty value
                    // — preserves whatever the admin typed before.
                    $updateFields = array();
                    foreach ($profileRow as $k => $v) {
                        if ($k === 'email') continue;
                        if ($v !== null && $v !== '') $updateFields[$k] = $v;
                    }
                    if ($updateFields) {
                        $write->update('learner_profile', $updateFields, array('id = ?' => (int)$existingProfile));
                    }
                } else {
                    $write->insert('learner_profile', $profileRow);
                }
            } catch (Exception $e) {
                // learner_profile table may not exist yet (migration 024 not applied)
                // — enrolment itself already succeeded so don't fail the request.
            }

            Mage::app()->cleanCache();

            $msg = 'Enrolled ' . ($fullName !== '' ? $fullName . ' (' . $email . ')' : $email)
                 . ' in "' . $product->getSku() . ' — ' . $product->getName() . '". '
                 . 'Order ' . $incrementId . ' created. The learner will see this class on their dashboard.';
            Mage::getSingleton('adminhtml/session')->addSuccess($msg);
            $this->_redirectUrl(Mage::helper('adminhtml')->getUrl('adminhtml/dashboard', array('tpg_page' => 'enroll_learners')));
            return;
        } catch (Exception $e) {
            Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
            $this->_redirectUrl(Mage::helper('adminhtml')->getUrl('adminhtml/dashboard', array('tpg_page' => 'enroll_learners')));
        }
    }

    /**
     * AJAX search for existing learners (used by the Enroll Learners form's search box).
     * Searches both admin_user and customer_entity, dedupes by email,
     * returns up to 20 matches ranked by admin_user first then customer_entity.
     * GET params: q — name/email fragment (min 2 chars)
     */
    public function searchLearnersAction()
    {
        $results = array();
        try {
            $q = trim((string) $this->getRequest()->getParam('q'));
            if (strlen($q) < 2) { $this->_sendJson(array('results' => array())); return; }
            $like = '%' . $q . '%';

            $read = Mage::getSingleton('core/resource')->getConnection('core_read');

            // Preload all matching learner_profile rows once so we can enrich
            // each result with stored Trainee Particulars. Key by lowercase email.
            $profiles = array();
            try {
                $profileRows = $read->fetchAll(
                    "SELECT email, id_type, nric, full_name, date_of_birth, country_code, phone_number, sponsorship_type
                     FROM learner_profile
                     WHERE email LIKE ? OR full_name LIKE ?",
                    array($like, $like)
                );
                foreach ($profileRows as $pr) {
                    $profiles[strtolower($pr['email'])] = $pr;
                }
            } catch (Exception $e) {
                // learner_profile table may not exist yet — treat as empty.
            }

            // admin_user (the people who actually log in and see the Learner dashboard)
            $adminRows = $read->fetchAll(
                "SELECT email, firstname, lastname FROM admin_user
                 WHERE is_active = 1 AND (email LIKE ? OR CONCAT_WS(' ', firstname, lastname) LIKE ?)
                 ORDER BY firstname LIMIT 20",
                array($like, $like)
            );
            $seen = array();
            foreach ($adminRows as $r) {
                $email = strtolower($r['email']);
                if ($email === '' || isset($seen[$email])) continue;
                $seen[$email] = 1;
                $p = isset($profiles[$email]) ? $profiles[$email] : null;
                $results[] = array(
                    'email'            => $r['email'],
                    'fullname'         => ($p && $p['full_name'] !== '') ? $p['full_name'] : trim($r['firstname'] . ' ' . $r['lastname']),
                    'source'           => 'admin_user',
                    'id_type'          => $p ? $p['id_type']          : '',
                    'nric'             => $p ? $p['nric']             : '',
                    'date_of_birth'    => $p ? $p['date_of_birth']    : '',
                    'country_code'     => $p ? $p['country_code']     : '',
                    'phone_number'     => $p ? $p['phone_number']     : '',
                    'sponsorship_type' => $p ? $p['sponsorship_type'] : '',
                );
            }

            // customer_entity (Magento customers — much larger pool)
            if (count($results) < 20) {
                $limit = 20 - count($results);
                $fnAttr = (int) $read->fetchOne(
                    "SELECT attribute_id FROM eav_attribute WHERE attribute_code='firstname' AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='customer')"
                );
                $lnAttr = (int) $read->fetchOne(
                    "SELECT attribute_id FROM eav_attribute WHERE attribute_code='lastname'  AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='customer')"
                );
                $custRows = $read->fetchAll(
                    "SELECT c.entity_id, c.email,
                            (SELECT value FROM customer_entity_varchar WHERE entity_id=c.entity_id AND attribute_id=? LIMIT 1) AS firstname,
                            (SELECT value FROM customer_entity_varchar WHERE entity_id=c.entity_id AND attribute_id=? LIMIT 1) AS lastname
                     FROM customer_entity c
                     WHERE c.email LIKE ?
                     ORDER BY c.email LIMIT " . (int)$limit,
                    array($fnAttr, $lnAttr, $like)
                );
                foreach ($custRows as $r) {
                    $email = strtolower($r['email']);
                    if ($email === '' || isset($seen[$email])) continue;
                    $seen[$email] = 1;
                    $p = isset($profiles[$email]) ? $profiles[$email] : null;
                    $results[] = array(
                        'email'            => $r['email'],
                        'fullname'         => ($p && $p['full_name'] !== '') ? $p['full_name'] : trim(($r['firstname'] ?: '') . ' ' . ($r['lastname'] ?: '')),
                        'source'           => 'customer',
                        'id_type'          => $p ? $p['id_type']          : '',
                        'nric'             => $p ? $p['nric']             : '',
                        'date_of_birth'    => $p ? $p['date_of_birth']    : '',
                        'country_code'     => $p ? $p['country_code']     : '',
                        'phone_number'     => $p ? $p['phone_number']     : '',
                        'sponsorship_type' => $p ? $p['sponsorship_type'] : '',
                    );
                }
            }
        } catch (Exception $e) {
            // Return empty results silently
        }
        $this->_sendJson(array('results' => $results));
    }

    /**
     * Look up a Course Run by run_id and return SSG-style details.
     *
     * The real SSG service issues 7-digit course run IDs (e.g. 1089835)
     * which our local catalog doesn't have. To keep the page useful for
     * demo and for SKU-driven workflows, the lookup tries:
     *   1. our internal option_type_id (Magento custom-option session)
     *   2. course_run_registry.run_seq (the SG-100xxx sequence)
     *   3. deterministic hash into the SG product catalog so any numeric
     *      input returns a stable course (mimics the SSG demo data the
     *      AI-LMS-TMS reference shows).
     *
     * Returns rich SSG-shaped fields (vacancy, mode of training, dates,
     * venue, etc.) so the View Course Run page can render the same
     * detail layout as the SSG mockup.
     */
    public function runLookupAction()
    {
        $result = array('success' => false);
        try {
            $rawId = trim((string) $this->getRequest()->getParam('run_id'));
            $runId = (int) $rawId;
            if (!$runId) throw new Exception('Course Run ID is required');

            $read = Mage::getSingleton('core/resource')->getConnection('core_read');

            // Strategy 1: SSG-issued Course Run IDs explicitly registered in
            // tpg_run_id_map (the authoritative source — populated by admins
            // or seeded from SSG). Wins over everything else.
            $sourceProductId = 0;
            $resolvedVia = null;
            $mapTrainerOverride = null; // SSG-truth trainer attached to this run, if any
            try {
                $mapRow = $read->fetchRow(
                    "SELECT product_id, trainer_name, trainer_id_masked, trainer_email
                     FROM tpg_run_id_map WHERE ssg_run_id = ? LIMIT 1",
                    array($runId)
                );
                if ($mapRow && (int)$mapRow['product_id']) {
                    $sourceProductId = (int) $mapRow['product_id'];
                    $resolvedVia = 'tpg_run_id_map';
                    if (!empty($mapRow['trainer_name'])) {
                        $mapTrainerOverride = array(
                            'name'             => (string) $mapRow['trainer_name'],
                            'id_number_masked' => (string) ($mapRow['trainer_id_masked'] ?: '*****' . substr(strtoupper(md5($mapRow['trainer_name'])), 0, 3) . 'H'),
                            'email'            => (string) ($mapRow['trainer_email'] ?: 'trainer@gmail.com'),
                        );
                    }
                }
            } catch (Exception $e) { /* table or trainer columns not migrated yet */ }

            // Strategy 2: our local option_type_id (Magento custom-option session)
            $row = null;
            if (!$sourceProductId) {
                $row = $read->fetchRow(
                    "SELECT ov.option_type_id AS run_id, o.product_id, ott.title AS session_title,
                            e.sku AS course_code,
                            (SELECT value FROM catalog_product_entity_varchar v WHERE v.entity_id = e.entity_id AND v.attribute_id = 71 ORDER BY v.store_id LIMIT 1) AS course_name
                     FROM catalog_product_option_type_value ov
                     JOIN catalog_product_option o ON o.option_id = ov.option_id
                     JOIN catalog_product_option_type_title ott ON ott.option_type_id = ov.option_type_id AND ott.store_id = 0
                     JOIN catalog_product_entity e ON e.entity_id = o.product_id
                     WHERE ov.option_type_id = ?
                     LIMIT 1",
                    array($runId)
                );
                if ($row) { $sourceProductId = (int)$row['product_id']; $resolvedVia = 'option_type_id'; }
            }

            // Strategy 3: course_run_registry sequence label (SG-1000xx -> seq=xx)
            if (!$sourceProductId && $runId >= 100000 && $runId <= 999999) {
                $regRow = $read->fetchRow(
                    "SELECT product_id FROM course_run_registry WHERE website_id=1 AND run_seq=? LIMIT 1",
                    array($runId - 100000)
                );
                if ($regRow) { $sourceProductId = (int) $regRow['product_id']; $resolvedVia = 'course_run_registry'; }
            }

            // Strategy 4: deterministic hash into the SG catalog so any
            // numeric Course Run ID still produces a stable demo mapping.
            if (!$sourceProductId) {
                $sgIds = $read->fetchCol(
                    "SELECT product_id FROM catalog_product_website WHERE website_id=1 ORDER BY product_id"
                );
                if ($sgIds) {
                    $idx = $runId % count($sgIds);
                    $sourceProductId = (int) $sgIds[$idx];
                    $resolvedVia = 'hash_mapped';
                }
            }
            if (!$sourceProductId) throw new Exception('Could not resolve a course for ID ' . $runId);

            $product = $read->fetchRow(
                "SELECT e.entity_id, e.sku,
                        (SELECT value FROM catalog_product_entity_varchar v WHERE v.entity_id=e.entity_id AND v.attribute_id=71 ORDER BY v.store_id LIMIT 1) AS course_name
                 FROM catalog_product_entity e WHERE e.entity_id=? LIMIT 1",
                array($sourceProductId)
            );
            if (!$product) throw new Exception('Course product not found');

            // Course Run Label from registry (SG-100000 etc.)
            $reg = $read->fetchRow(
                "SELECT website_id, run_seq FROM course_run_registry WHERE product_id=? LIMIT 1",
                array($sourceProductId)
            );
            $courseRunLabel = null;
            if ($reg) {
                $prefixMap = array(1=>'SG',2=>'MY',3=>'GH',4=>'NG',5=>'BUT',6=>'IND',7=>'INF');
                $prefix = isset($prefixMap[(int)$reg['website_id']]) ? $prefixMap[(int)$reg['website_id']] : 'SG';
                $courseRunLabel = $prefix . '-' . str_pad((string)(100000 + (int)$reg['run_seq']), 6, '0', STR_PAD_LEFT);
            }

            // Pick a representative session title (earliest if any exist)
            $sessionTitle = $row ? $row['session_title'] : null;
            if (!$sessionTitle) {
                $sessionTitle = (string) $read->fetchOne(
                    "SELECT ott.title FROM catalog_product_option_type_value ov
                     JOIN catalog_product_option o ON o.option_id=ov.option_id
                     JOIN catalog_product_option_type_title ott ON ott.option_type_id=ov.option_type_id AND ott.store_id=0
                     WHERE o.product_id=? ORDER BY ov.sort_order ASC, ov.option_type_id DESC LIMIT 1",
                    array($sourceProductId)
                );
            }

            $enrolCount = (int) $read->fetchOne(
                "SELECT COUNT(DISTINCT o.entity_id) FROM sales_flat_order o
                 JOIN sales_flat_order_item oi ON oi.order_id=o.entity_id
                 WHERE oi.product_id=? AND o.state NOT IN ('canceled','closed')",
                array($sourceProductId)
            );

            // Vacancy: A=Available, L=Limited (>=20 enrolled), F=Fully Booked (>=25)
            if      ($enrolCount >= 25) $vacancy = 'F';
            elseif  ($enrolCount >= 20) $vacancy = 'L';
            else                         $vacancy = 'A';
            $vacancyLabel = array('A'=>'Available','L'=>'Limited','F'=>'Fully Booked');

            // Synthesize SSG-style course run details
            $modes = array('1' => 'Classroom Facilitated Training', '2' => 'Synchronous e-Learning',
                           '3' => 'Asynchronous e-Learning', '4' => 'Blended Learning');
            $modeKey = (string) (($runId % 4) + 1);

            // Try to extract real start/end from session_title (e.g. "27 Apr 2026 (Mon)")
            $startDate = $endDate = null;
            if ($sessionTitle && preg_match('#(\d{1,2})(?:/(\d{1,2}))?\s+([A-Za-z]{3,})\s+(\d{4})#', $sessionTitle, $m)) {
                $startTs = strtotime($m[1] . ' ' . $m[3] . ' ' . $m[4]);
                $endTs   = !empty($m[2]) ? strtotime($m[2] . ' ' . $m[3] . ' ' . $m[4]) : $startTs;
                if ($startTs) $startDate = date('Y-m-d', $startTs);
                if ($endTs)   $endDate   = date('Y-m-d', $endTs);
            }

            // Registration dates: opening 6 weeks before start, closing 1 day before
            $regOpenDate = $regCloseDate = null;
            if ($startDate) {
                $regOpenDate  = date('Y-m-d', strtotime($startDate . ' -6 weeks'));
                $regCloseDate = date('Y-m-d', strtotime($startDate . ' -1 day'));
            }

            // Assigned trainers: pull from BOTH the multiselect (structured) AND
            // the trainerprofile HTML (legacy textual). Dedupe by lowercased name
            // so the Assigned Trainer card lists every trainer this course is
            // really linked to, not just the first multiselect option.
            $trainerNames = array();      // dedup by lowercased name
            $assignedTrainers = array();  // ordered list rendered to UI

            // 1. Multiselect (attribute 170) — option_id values resolved to names
            $trainersCsv = (string) $read->fetchOne(
                "SELECT value FROM catalog_product_entity_text WHERE entity_id=? AND attribute_id=170 AND value IS NOT NULL AND value != '' ORDER BY store_id LIMIT 1",
                array($sourceProductId)
            );
            if ($trainersCsv !== '') {
                $ids = array_filter(array_map('intval', explode(',', $trainersCsv)));
                if ($ids) {
                    $rows = $read->fetchAll(
                        "SELECT eaov.value FROM eav_attribute_option_value eaov
                         WHERE eaov.option_id IN (" . implode(',', array_map('intval', $ids)) . ") AND eaov.store_id=0
                         ORDER BY eaov.value"
                    );
                    foreach ($rows as $r2) {
                        $name = trim((string)$r2['value']);
                        if ($name === '') continue;
                        $key = strtolower($name);
                        if (isset($trainerNames[$key])) continue;
                        $trainerNames[$key] = 1;
                        $assignedTrainers[] = $name;
                    }
                }
            }

            // 2. trainerprofile HTML — extract names from <strong>Name:</strong>
            //    blocks so courses with legacy-only assignments still surface.
            $tpAttrId = (int) $read->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='trainerprofile' AND entity_type_id=4");
            if ($tpAttrId) {
                $tpHtml = (string) $read->fetchOne(
                    "SELECT value FROM catalog_product_entity_text WHERE entity_id=? AND attribute_id=? AND value IS NOT NULL AND value != '' ORDER BY store_id LIMIT 1",
                    array($sourceProductId, $tpAttrId)
                );
                if ($tpHtml !== '' && preg_match_all('#<strong[^>]*>\s*([^<:]{2,80}?)\s*:?\s*</strong>#si', $tpHtml, $mm)) {
                    foreach ($mm[1] as $name) {
                        $name = html_entity_decode(trim($name));
                        if ($name === '' || stripos($name, 'http') !== false) continue;
                        if (preg_match('/^(course|module|topic|day|session|note|trainer profile|learning|outcome)/i', $name)) continue;
                        $key = strtolower($name);
                        if (isset($trainerNames[$key])) continue;
                        $trainerNames[$key] = 1;
                        $assignedTrainers[] = $name;
                    }
                }
            }

            // Build the list of trainer objects (name + masked NRIC + slug email).
            // The SSG-truth trainer from tpg_run_id_map (if present) goes FIRST
            // so the Assigned Trainer card shows the real run-level assignee.
            $assignedTrainerList = array();
            if ($mapTrainerOverride) $assignedTrainerList[] = $mapTrainerOverride;
            foreach ($assignedTrainers as $name) {
                if ($mapTrainerOverride && strcasecmp($name, $mapTrainerOverride['name']) === 0) continue;
                $clean = trim(preg_replace('/^(Dr\.?|Mr\.?|Mrs\.?|Ms\.?|Prof\.?)\s+/i', '', $name));
                $slug  = trim(preg_replace('/[^a-z0-9]+/', '', strtolower($clean)));
                $assignedTrainerList[] = array(
                    'name'             => $name,
                    'id_number_masked' => '*****' . substr(strtoupper(md5($name)), 0, 3) . 'H',
                    'email'            => ($slug ?: 'trainer') . '@gmail.com',
                );
            }
            $assignedTrainer = !empty($assignedTrainerList) ? $assignedTrainerList[0] : null;
            // Local trainer = catalog-level only (drops the SSG override to
            // show divergence between SSG-truth and our local data).
            $localTrainerList = array();
            foreach ($assignedTrainerList as $t) {
                if ($mapTrainerOverride && strcasecmp($t['name'], $mapTrainerOverride['name']) === 0) continue;
                $localTrainerList[] = $t;
            }
            $localTrainer = !empty($localTrainerList) ? $localTrainerList[0] : null;

            // Course admin email — admin user 1's email when present
            $courseAdminEmail = (string) $read->fetchOne(
                "SELECT email FROM admin_user WHERE is_active=1 ORDER BY user_id ASC LIMIT 1"
            ) ?: 'admin@tertiaryinfotech.com';

            // Digital attendance / QR
            $attendanceCode = 'RA' . str_pad((string)(($runId * 7) % 1000000), 6, '0', STR_PAD_LEFT);
            $qrLink = 'https://www.myskillsfuture.gov.sg/api/take-attendance/' . $attendanceCode;

            // Class status: Confirmed when there's a known session, else Pending
            $classStatus = $sessionTitle && $startDate ? 'Confirmed' : 'Pending';

            $result['success'] = true;
            $result['run']     = array(
                'run_id'                  => $runId,
                'product_id'              => $sourceProductId,
                'course_code'             => $product['sku'],
                'course_name'             => $product['course_name'] ?: '(No name)',
                'session_title'           => $sessionTitle ?: '—',
                'course_run_label'        => $courseRunLabel,
                'reference_number'        => $product['sku'],
                'vacancy'                 => $vacancy,
                'vacancy_label'           => $vacancyLabel[$vacancy],
                'mode_of_training'        => $modes[$modeKey],
                'mode_of_training_full'   => $modeKey . ' - ' . $modes[$modeKey],
                'start_date'              => $startDate,
                'end_date'                => $endDate,
                'registration_open_date'  => $regOpenDate,
                'registration_close_date' => $regCloseDate,
                'venue'                   => 'WOODS SQUARE, Blk 12, WOODS SQUARE, #07-85-87, S(737715)',
                'venue_room'              => 'Training Room',
                'training_partner'        => array('uen' => '201200696W', 'code' => '201200696W-01'),
                'organization_uen'        => '201200696W',
                'course_admin_email'      => $courseAdminEmail,
                'attendance_taken'        => 'Yes',
                'qr_code_link'            => $qrLink,
                'digital_attendance_id'   => $attendanceCode,
                'assigned_trainer'        => $assignedTrainer,
                'assigned_trainers'       => $assignedTrainerList,
                'local_trainer'           => $localTrainer,
                'local_trainers'          => $localTrainerList,
                'class_status'            => $classStatus,
                'enrolment_count'         => $enrolCount,
                'lookup_strategy'         => $resolvedVia ?: 'unknown',
            );
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * List all sessions of the course whose Course Run ID was looked up.
     * Uses the same lookup chain as runLookupAction so SSG-issued run IDs
     * (e.g. 1089835) resolve via tpg_run_id_map / course_run_registry /
     * hash mapping, not just the local option_type_id.
     */
    public function runSessionsLookupAction()
    {
        $result = array('success' => false);
        try {
            $runId = (int) $this->getRequest()->getParam('run_id');
            if (!$runId) throw new Exception('run_id is required');

            $read = Mage::getSingleton('core/resource')->getConnection('core_read');

            // Strategy 1: tpg_run_id_map (SSG-issued IDs we've registered)
            $productId = 0;
            try {
                $productId = (int) $read->fetchOne(
                    "SELECT product_id FROM tpg_run_id_map WHERE ssg_run_id = ? LIMIT 1",
                    array($runId)
                );
            } catch (Exception $e) {}

            // Strategy 2: local option_type_id (Magento custom-option session)
            if (!$productId) {
                $productId = (int) $read->fetchOne(
                    "SELECT o.product_id
                     FROM catalog_product_option_type_value ov
                     JOIN catalog_product_option o ON o.option_id = ov.option_id
                     WHERE ov.option_type_id = ? LIMIT 1",
                    array($runId)
                );
            }

            // Strategy 3: course_run_registry (SG-1000xx -> seq)
            if (!$productId && $runId >= 100000 && $runId <= 999999) {
                $productId = (int) $read->fetchOne(
                    "SELECT product_id FROM course_run_registry WHERE website_id=1 AND run_seq=? LIMIT 1",
                    array($runId - 100000)
                );
            }

            // Strategy 4: deterministic hash so any numeric ID still returns demo data
            if (!$productId) {
                $sgIds = $read->fetchCol(
                    "SELECT product_id FROM catalog_product_website WHERE website_id=1 ORDER BY product_id"
                );
                if ($sgIds) $productId = (int) $sgIds[$runId % count($sgIds)];
            }
            if (!$productId) throw new Exception('No course run found for ID ' . $runId);

            $course = $read->fetchRow(
                "SELECT e.entity_id, e.sku,
                        (SELECT value FROM catalog_product_entity_varchar v WHERE v.entity_id = e.entity_id AND v.attribute_id = 71 ORDER BY v.store_id LIMIT 1) AS course_name
                 FROM catalog_product_entity e WHERE e.entity_id = ? LIMIT 1",
                array($productId)
            );
            if (!$course) throw new Exception('Course product not found');

            $sessionsRaw = $read->fetchAll(
                "SELECT ov.option_type_id, ott.title
                 FROM catalog_product_option o
                 JOIN catalog_product_option_title ot ON ot.option_id = o.option_id AND ot.store_id = 0
                 JOIN catalog_product_option_type_value ov ON ov.option_id = o.option_id
                 JOIN catalog_product_option_type_title ott ON ott.option_type_id = ov.option_type_id AND ott.store_id = 0
                 WHERE o.product_id = ? AND (ot.title = 'Course Date' OR ot.title LIKE '%Date%')
                 ORDER BY ov.sort_order ASC, ov.option_type_id ASC",
                array((int)$course['entity_id'])
            );

            // Course run derived details (same shape as runLookup)
            $startTitle = $sessionsRaw ? $sessionsRaw[0]['title'] : '';
            $startDate = $endDate = null;
            if ($startTitle && preg_match('#(\d{1,2})(?:[-/](\d{1,2}))?\s+([A-Za-z]{3,})\s+(\d{4})#', $startTitle, $m)) {
                $sTs = strtotime($m[1] . ' ' . $m[3] . ' ' . $m[4]);
                $eTs = !empty($m[2]) ? strtotime($m[2] . ' ' . $m[3] . ' ' . $m[4]) : $sTs;
                if ($sTs) $startDate = date('Y-m-d', $sTs);
                if ($eTs) $endDate   = date('Y-m-d', $eTs);
            }

            $enrolCount = (int) $read->fetchOne(
                "SELECT COUNT(DISTINCT o.entity_id) FROM sales_flat_order o
                 JOIN sales_flat_order_item oi ON oi.order_id = o.entity_id
                 WHERE oi.product_id = ? AND o.state NOT IN ('canceled','closed')",
                array((int)$course['entity_id'])
            );

            $vacancy = $enrolCount >= 25 ? 'Fully Booked' : ($enrolCount >= 20 ? 'Limited' : 'Available');

            $courseAdminEmail = (string) $read->fetchOne(
                "SELECT email FROM admin_user WHERE is_active=1 ORDER BY user_id ASC LIMIT 1"
            ) ?: 'admin@tertiaryinfotech.com';

            // Build session rows with synthesized SSG-style fields
            $modesByKey = array('1'=>'Classroom','2'=>'Synchronous e-Learning','3'=>'Asynchronous e-Learning','4'=>'Blended Learning','8'=>'Assessment');
            $sessions = array();
            foreach ($sessionsRaw as $i => $s) {
                $title = $s['title'];
                $sDate = null; $startTime = null; $endTime = null;
                if (preg_match('#(\d{1,2})(?:[-/](\d{1,2}))?\s+([A-Za-z]{3,})\s+(\d{4})#', $title, $mm)) {
                    $ts = strtotime($mm[1] . ' ' . $mm[3] . ' ' . $mm[4]);
                    if ($ts) $sDate = date('Y-m-d', $ts);
                }
                // Alternate morning / afternoon timings; last one is Assessment 16:00-18:00
                $idx = $i + 1;
                $isLast = ($idx === count($sessionsRaw));
                $isMorning = ($idx % 2 === 1);
                if ($isLast && count($sessionsRaw) >= 3) {
                    $startTime = '16:00'; $endTime = '18:00'; $modeKey = '8';
                } elseif ($isMorning) {
                    $startTime = '09:15'; $endTime = '13:15'; $modeKey = '1';
                } else {
                    $startTime = '14:00'; $endTime = '18:00'; $modeKey = '1';
                }

                $attTaken = (int) $read->fetchOne(
                    "SELECT COUNT(*) FROM course_attendance WHERE option_type_id=?",
                    array((int)$s['option_type_id'])
                );

                $sessions[] = array(
                    'option_type_id'    => (int) $s['option_type_id'],
                    'session_id'        => $course['sku'] . '-' . $runId . '-S' . $idx,
                    'title'             => $title,
                    'date'              => $sDate,
                    'start_time'        => $startTime,
                    'end_time'          => $endTime,
                    'mode'              => $modesByKey[$modeKey],
                    'attendance_taken'  => $attTaken > 0,
                    'status'            => 'Active',
                );
            }

            $result['success'] = true;
            $result['run']     = array(
                'run_id'           => $runId,
                'product_id'       => (int) $course['entity_id'],
                'course_code'      => $course['sku'],
                'course_name'      => $course['course_name'] ?: '(No name)',
                'mode_of_training' => 'Classroom',
                'start_date'       => $startDate,
                'end_date'         => $endDate,
                'venue'            => 'Floor 07 · #85-87 · WOODS SQUARE',
                'vacancy'          => $vacancy,
                'admin_email'      => $courseAdminEmail,
                'registered'       => $enrolCount,
                'session_count'    => count($sessions),
                'active_count'     => count($sessions),
                'sessions'         => $sessions,
            );
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Course Session Attendance lookup. Resolves Course Code / Session ID /
     * Course Run ID into a session and returns its attendance roster.
     */
    public function sessionAttendanceLookupAction()
    {
        $result = array('success' => false);
        try {
            $uen        = trim((string) $this->getRequest()->getParam('uen'));
            $courseCode = trim((string) $this->getRequest()->getParam('course_code'));
            $sessionId  = trim((string) $this->getRequest()->getParam('session_id'));
            $runId      = (int) $this->getRequest()->getParam('run_id');

            $read = Mage::getSingleton('core/resource')->getConnection('core_read');

            // Resolve to an option_type_id (the canonical session id in our DB)
            $optionTypeId = 0;
            if ($runId > 0) {
                $optionTypeId = (int) $read->fetchOne(
                    "SELECT option_type_id FROM catalog_product_option_type_value WHERE option_type_id = ? LIMIT 1",
                    array($runId)
                );
            }
            // Session ID format like "TGS-2019503161-1289568-S1" — extract the
            // 1289568 part (or the trailing -SN if option_type_id is encoded there).
            if (!$optionTypeId && $sessionId !== '' && preg_match('/(\d{4,})/', $sessionId, $m)) {
                $optionTypeId = (int) $read->fetchOne(
                    "SELECT option_type_id FROM catalog_product_option_type_value WHERE option_type_id = ? LIMIT 1",
                    array((int)$m[1])
                );
            }
            if (!$optionTypeId && $courseCode !== '') {
                $optionTypeId = (int) $read->fetchOne(
                    "SELECT ov.option_type_id
                     FROM catalog_product_entity e
                     JOIN catalog_product_option o ON o.product_id = e.entity_id
                     JOIN catalog_product_option_type_value ov ON ov.option_id = o.option_id
                     WHERE e.sku = ?
                     ORDER BY ov.option_type_id ASC
                     LIMIT 1",
                    array($courseCode)
                );
            }
            if (!$optionTypeId) {
                throw new Exception('Could not resolve session — provide Course Run ID, Session ID, or Course Code.');
            }

            $session = $read->fetchRow(
                "SELECT ov.option_type_id, ott.title AS session_title,
                        e.sku AS course_code,
                        (SELECT value FROM catalog_product_entity_varchar v WHERE v.entity_id = e.entity_id AND v.attribute_id = 71 ORDER BY v.store_id LIMIT 1) AS course_name
                 FROM catalog_product_option_type_value ov
                 JOIN catalog_product_option o ON o.option_id = ov.option_id
                 JOIN catalog_product_option_type_title ott ON ott.option_type_id = ov.option_type_id AND ott.store_id = 0
                 JOIN catalog_product_entity e ON e.entity_id = o.product_id
                 WHERE ov.option_type_id = ?
                 LIMIT 1",
                array($optionTypeId)
            );

            $attendance = $read->fetchAll(
                "SELECT ca.customer_id, ca.status, ca.updated_at, c.email
                 FROM course_attendance ca
                 JOIN customer_entity c ON c.entity_id = ca.customer_id
                 WHERE ca.option_type_id = ?
                 ORDER BY ca.updated_at DESC",
                array($optionTypeId)
            );

            $result['success']    = true;
            $result['uen']        = $uen;
            $result['session']    = $session;
            $result['attendance'] = $attendance;
            $result['count']      = count($attendance);
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Check Attendance composite lookup. Given a Course Run ID returns:
     *   - run/course identity (so the page can display the SG-100xxx label)
     *   - the attendance roster on course_attendance for that run
     *   - the enrolments on sales_flat_order for the parent course
     * The page builds the Session Attendance / Class Enrolments / Manual
     * Attendance tables from this single payload.
     */
    public function checkAttendanceLookupAction()
    {
        $result = array('success' => false);
        try {
            $runId = (int) $this->getRequest()->getParam('run_id');
            if (!$runId) throw new Exception('run_id is required');

            $read = Mage::getSingleton('core/resource')->getConnection('core_read');

            $course = $read->fetchRow(
                "SELECT o.product_id, e.sku AS course_code,
                        ott.title AS session_title,
                        (SELECT value FROM catalog_product_entity_varchar v WHERE v.entity_id = e.entity_id AND v.attribute_id = 71 ORDER BY v.store_id LIMIT 1) AS course_name
                 FROM catalog_product_option_type_value ov
                 JOIN catalog_product_option o ON o.option_id = ov.option_id
                 JOIN catalog_product_option_type_title ott ON ott.option_type_id = ov.option_type_id AND ott.store_id = 0
                 JOIN catalog_product_entity e ON e.entity_id = o.product_id
                 WHERE ov.option_type_id = ?
                 LIMIT 1",
                array($runId)
            );
            if (!$course) throw new Exception('No course run found for ID ' . $runId);

            // Map run_id to its registry-assigned Course Run ID label, if registered
            $reg = $read->fetchRow(
                "SELECT website_id, run_seq FROM course_run_registry WHERE product_id = ? LIMIT 1",
                array((int)$course['product_id'])
            );
            $courseRunLabel = (string) $runId;
            if ($reg) {
                $prefixMap = array(1=>'SG',2=>'MY',3=>'GH',4=>'NG',5=>'BUT',6=>'IND',7=>'INF');
                $prefix = isset($prefixMap[(int)$reg['website_id']]) ? $prefixMap[(int)$reg['website_id']] : 'SG';
                $courseRunLabel = $prefix . '-' . str_pad((string)(100000 + (int)$reg['run_seq']), 6, '0', STR_PAD_LEFT);
            }

            $attendance = $read->fetchAll(
                "SELECT ca.customer_id, ca.status, ca.updated_at, c.email,
                        CONCAT(TRIM(COALESCE(fn.value,'')), ' ', TRIM(COALESCE(ln.value,''))) AS name
                 FROM course_attendance ca
                 JOIN customer_entity c ON c.entity_id = ca.customer_id
                 LEFT JOIN customer_entity_varchar fn ON fn.entity_id = c.entity_id AND fn.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code='firstname' AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='customer'))
                 LEFT JOIN customer_entity_varchar ln ON ln.entity_id = c.entity_id AND ln.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code='lastname'  AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='customer'))
                 WHERE ca.option_type_id = ?
                 ORDER BY ca.updated_at DESC",
                array($runId)
            );

            $enrolments = $read->fetchAll(
                "SELECT o.increment_id, o.created_at, o.customer_email AS email,
                        CONCAT(TRIM(COALESCE(o.customer_firstname,'')), ' ', TRIM(COALESCE(o.customer_lastname,''))) AS name
                 FROM sales_flat_order o
                 JOIN sales_flat_order_item oi ON oi.order_id = o.entity_id
                 WHERE oi.product_id = ?
                   AND o.state NOT IN ('canceled','closed')
                 ORDER BY o.created_at DESC",
                array((int)$course['product_id'])
            );

            $result['success']    = true;
            $result['run']        = array(
                'run_id'           => $runId,
                'product_id'       => (int) $course['product_id'],
                'course_code'      => $course['course_code'],
                'course_name'      => $course['course_name'] ?: '(No name)',
                'session_title'    => $course['session_title'],
                'course_run_label' => $courseRunLabel,
            );
            $result['attendance'] = $attendance;
            $result['enrolments'] = $enrolments;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Search Assessments — combined Course Run ID + Course Reference Number
     * lookup against course_attendance (treated as the assessment store for
     * now). Optional filters: enrolment number, trainee ID/NRIC.
     */
    public function searchAssessmentsAction()
    {
        $result = array('success' => false);
        try {
            $runId      = (int) $this->getRequest()->getParam('run_id');
            $courseRef  = trim((string) $this->getRequest()->getParam('course_ref'));
            $enrolRef   = trim((string) $this->getRequest()->getParam('enrol_ref'));
            $traineeId  = trim((string) $this->getRequest()->getParam('trainee_id'));
            if (!$runId)     throw new Exception('Course Run ID is required');
            if ($courseRef === '') throw new Exception('Course Reference Number is required');

            $read = Mage::getSingleton('core/resource')->getConnection('core_read');

            // Verify the run + course-ref pair is consistent (run_id belongs to a course
            // whose SKU == course_ref).
            $product = $read->fetchRow(
                "SELECT e.entity_id, e.sku
                 FROM catalog_product_option_type_value ov
                 JOIN catalog_product_option o ON o.option_id = ov.option_id
                 JOIN catalog_product_entity e ON e.entity_id = o.product_id
                 WHERE ov.option_type_id = ? AND e.sku = ?
                 LIMIT 1",
                array($runId, $courseRef)
            );
            if (!$product) {
                throw new Exception('No course matched the Course Run ID + Course Reference Number combination.');
            }

            $sql = "SELECT ca.customer_id, ca.status, ca.updated_at,
                           c.email,
                           CONCAT(TRIM(COALESCE(fn.value,'')), ' ', TRIM(COALESCE(ln.value,''))) AS name
                    FROM course_attendance ca
                    JOIN customer_entity c ON c.entity_id = ca.customer_id
                    LEFT JOIN customer_entity_varchar fn ON fn.entity_id = c.entity_id AND fn.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code='firstname' AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='customer'))
                    LEFT JOIN customer_entity_varchar ln ON ln.entity_id = c.entity_id AND ln.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code='lastname'  AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='customer'))
                    WHERE ca.option_type_id = ?";
            $params = array($runId);

            if ($enrolRef !== '') {
                // Match on the order's increment_id we set during enrollLearnerAction
                $sql .= " AND EXISTS (SELECT 1 FROM sales_flat_order o WHERE LOWER(o.customer_email) = LOWER(c.email) AND o.increment_id = ?)";
                $params[] = $enrolRef;
            }
            if ($traineeId !== '') {
                // We don't store NRIC directly — match by learner_profile.nric if available
                $sql .= " AND (EXISTS (SELECT 1 FROM learner_profile lp WHERE LOWER(lp.email) = LOWER(c.email) AND lp.nric = ?) OR LOWER(c.email) LIKE ?)";
                $params[] = $traineeId;
                $params[] = '%' . strtolower($traineeId) . '%';
            }
            $sql .= " ORDER BY ca.updated_at DESC LIMIT 200";

            $rows = $read->fetchAll($sql, $params);

            $result['success']  = true;
            $result['count']    = count($rows);
            $result['results']  = $rows;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * View Assessment — fetch a single assessment record by Assessment ID.
     * The ID format we recognise is ASM-{option_type_id}-{customer_id} (a
     * deterministic encoding of the underlying course_attendance row); a
     * permissive parse also accepts plain numeric IDs that match a
     * course_attendance.id directly.
     */
    public function viewAssessmentAction()
    {
        $result = array('success' => false);
        try {
            $rawId = trim((string) $this->getRequest()->getParam('id'));
            if ($rawId === '') throw new Exception('Assessment ID is required');

            $optionTypeId = 0;
            $customerId   = 0;
            $caId         = 0;

            if (preg_match('/^ASM-(\d+)-(\d+)$/i', $rawId, $m)) {
                $optionTypeId = (int) $m[1];
                $customerId   = (int) $m[2];
            } elseif (ctype_digit($rawId)) {
                $caId = (int) $rawId;
            } else {
                throw new Exception('Unrecognised Assessment ID format. Expected ASM-{run}-{learner} or numeric.');
            }

            $read = Mage::getSingleton('core/resource')->getConnection('core_read');

            if ($caId) {
                $row = $read->fetchRow(
                    "SELECT ca.id, ca.option_type_id, ca.customer_id, ca.status, ca.updated_at
                     FROM course_attendance ca
                     WHERE ca.id = ? LIMIT 1",
                    array($caId)
                );
            } else {
                $row = $read->fetchRow(
                    "SELECT ca.id, ca.option_type_id, ca.customer_id, ca.status, ca.updated_at
                     FROM course_attendance ca
                     WHERE ca.option_type_id = ? AND ca.customer_id = ? LIMIT 1",
                    array($optionTypeId, $customerId)
                );
            }
            if (!$row) throw new Exception('No assessment record found for ' . $rawId);

            $session = $read->fetchRow(
                "SELECT ott.title AS session_title,
                        e.entity_id AS product_id, e.sku AS course_code,
                        (SELECT value FROM catalog_product_entity_varchar v WHERE v.entity_id = e.entity_id AND v.attribute_id = 71 ORDER BY v.store_id LIMIT 1) AS course_name
                 FROM catalog_product_option_type_value ov
                 JOIN catalog_product_option o ON o.option_id = ov.option_id
                 JOIN catalog_product_option_type_title ott ON ott.option_type_id = ov.option_type_id AND ott.store_id = 0
                 JOIN catalog_product_entity e ON e.entity_id = o.product_id
                 WHERE ov.option_type_id = ? LIMIT 1",
                array((int)$row['option_type_id'])
            );

            $cust = $read->fetchRow(
                "SELECT c.email,
                        CONCAT(TRIM(COALESCE(fn.value,'')), ' ', TRIM(COALESCE(ln.value,''))) AS name
                 FROM customer_entity c
                 LEFT JOIN customer_entity_varchar fn ON fn.entity_id = c.entity_id AND fn.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code='firstname' AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='customer'))
                 LEFT JOIN customer_entity_varchar ln ON ln.entity_id = c.entity_id AND ln.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code='lastname'  AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='customer'))
                 WHERE c.entity_id = ? LIMIT 1",
                array((int)$row['customer_id'])
            );

            $result['success']    = true;
            $result['assessment'] = array(
                'id'             => 'ASM-' . (int)$row['option_type_id'] . '-' . (int)$row['customer_id'],
                'run_id'         => (int) $row['option_type_id'],
                'session_title'  => $session ? $session['session_title']  : '—',
                'course_code'    => $session ? $session['course_code']    : '—',
                'course_name'    => $session ? $session['course_name']    : '—',
                'trainee_name'   => $cust    ? $cust['name']              : '—',
                'trainee_email'  => $cust    ? $cust['email']             : '—',
                'status'         => $row['status'],
                'updated_at'     => $row['updated_at'],
            );
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Search Grant — returns grant-related details for a Course Run.
     * Combines run identity + Course Run Registry label + enrolment count
     * to produce a rough grant estimate (placeholder until real SSG data
     * source is wired up).
     */
    public function searchGrantAction()
    {
        $result = array('success' => false);
        try {
            $runId = (int) $this->getRequest()->getParam('run_id');
            if (!$runId) throw new Exception('Course Run ID is required');

            $read = Mage::getSingleton('core/resource')->getConnection('core_read');

            $row = $read->fetchRow(
                "SELECT ov.option_type_id AS run_id, o.product_id, ott.title AS session_title,
                        e.sku AS course_code,
                        (SELECT value FROM catalog_product_entity_varchar v WHERE v.entity_id = e.entity_id AND v.attribute_id = 71 ORDER BY v.store_id LIMIT 1) AS course_name
                 FROM catalog_product_option_type_value ov
                 JOIN catalog_product_option o ON o.option_id = ov.option_id
                 JOIN catalog_product_option_type_title ott ON ott.option_type_id = ov.option_type_id AND ott.store_id = 0
                 JOIN catalog_product_entity e ON e.entity_id = o.product_id
                 WHERE ov.option_type_id = ?
                 LIMIT 1",
                array($runId)
            );
            if (!$row) throw new Exception('No course run found for ID ' . $runId);

            $reg = $read->fetchRow(
                "SELECT website_id, run_seq FROM course_run_registry WHERE product_id = ? LIMIT 1",
                array((int)$row['product_id'])
            );
            $courseRunLabel = (string) $runId;
            if ($reg) {
                $prefixMap = array(1=>'SG',2=>'MY',3=>'GH',4=>'NG',5=>'BUT',6=>'IND',7=>'INF');
                $prefix = isset($prefixMap[(int)$reg['website_id']]) ? $prefixMap[(int)$reg['website_id']] : 'SG';
                $courseRunLabel = $prefix . '-' . str_pad((string)(100000 + (int)$reg['run_seq']), 6, '0', STR_PAD_LEFT);
            }

            $enrolCount = (int) $read->fetchOne(
                "SELECT COUNT(DISTINCT o.entity_id)
                 FROM sales_flat_order o
                 JOIN sales_flat_order_item oi ON oi.order_id = o.entity_id
                 WHERE oi.product_id = ? AND o.state NOT IN ('canceled','closed')",
                array((int)$row['product_id'])
            );

            // Placeholder grant numbers — replace with real SSG calculator data when wired
            $perLearner = 350;
            $total      = $perLearner * $enrolCount;

            $result['success'] = true;
            $result['grant']   = array(
                'run_id'                       => (int) $row['run_id'],
                'course_run_label'             => $courseRunLabel,
                'course_code'                  => $row['course_code'],
                'course_name'                  => $row['course_name'] ?: '(No name)',
                'session_title'                => $row['session_title'],
                'enrolment_count'              => $enrolCount,
                'estimated_grant_per_learner'  => 'SGD ' . number_format($perLearner, 2),
                'estimated_total_grant'        => 'SGD ' . number_format($total, 2),
                'status'                       => $enrolCount > 0 ? 'Eligible' : 'Pending Enrolment',
            );
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * View Grant Status by Grant ID. Format: GRN-{run_id}-{seq6} or plain
     * Course Run ID. Returns the same kind of detail as Search Grant plus
     * a synthesized status (Pending / Approved / Rejected — placeholder
     * until the real SSG grant store is wired up).
     */
    public function viewGrantStatusAction()
    {
        $result = array('success' => false);
        try {
            $raw = trim((string) $this->getRequest()->getParam('grant_id'));
            if ($raw === '') throw new Exception('Grant ID is required');

            $runId = 0;
            if (preg_match('/^GRN-(\d+)-(\d+)$/i', $raw, $m)) {
                $runId = (int) $m[1];
            } elseif (ctype_digit($raw)) {
                $runId = (int) $raw;
            } else {
                throw new Exception('Unrecognised Grant ID format. Expected GRN-{run}-{seq} or numeric.');
            }

            $read = Mage::getSingleton('core/resource')->getConnection('core_read');

            $row = $read->fetchRow(
                "SELECT ov.option_type_id AS run_id, o.product_id, ott.title AS session_title,
                        e.sku AS course_code,
                        (SELECT value FROM catalog_product_entity_varchar v WHERE v.entity_id = e.entity_id AND v.attribute_id = 71 ORDER BY v.store_id LIMIT 1) AS course_name
                 FROM catalog_product_option_type_value ov
                 JOIN catalog_product_option o ON o.option_id = ov.option_id
                 JOIN catalog_product_option_type_title ott ON ott.option_type_id = ov.option_type_id AND ott.store_id = 0
                 JOIN catalog_product_entity e ON e.entity_id = o.product_id
                 WHERE ov.option_type_id = ?
                 LIMIT 1",
                array($runId)
            );
            if (!$row) throw new Exception('No course run found for Grant ID ' . $raw);

            $reg = $read->fetchRow(
                "SELECT website_id, run_seq FROM course_run_registry WHERE product_id = ? LIMIT 1",
                array((int)$row['product_id'])
            );
            $courseRunLabel = (string) $runId;
            if ($reg) {
                $prefixMap = array(1=>'SG',2=>'MY',3=>'GH',4=>'NG',5=>'BUT',6=>'IND',7=>'INF');
                $prefix = isset($prefixMap[(int)$reg['website_id']]) ? $prefixMap[(int)$reg['website_id']] : 'SG';
                $courseRunLabel = $prefix . '-' . str_pad((string)(100000 + (int)$reg['run_seq']), 6, '0', STR_PAD_LEFT);
            }

            $enrolCount = (int) $read->fetchOne(
                "SELECT COUNT(DISTINCT o.entity_id)
                 FROM sales_flat_order o
                 JOIN sales_flat_order_item oi ON oi.order_id = o.entity_id
                 WHERE oi.product_id = ? AND o.state NOT IN ('canceled','closed')",
                array((int)$row['product_id'])
            );

            $perLearner = 350;
            $total      = $perLearner * $enrolCount;
            $status     = $enrolCount > 0 ? 'Approved' : 'Pending';

            // Synthetic Grant ID if caller passed plain run_id
            $grantId = (stripos($raw, 'GRN-') === 0)
                ? strtoupper($raw)
                : 'GRN-' . $runId . '-' . str_pad((string)$enrolCount, 6, '0', STR_PAD_LEFT);

            $result['success'] = true;
            $result['grant']   = array(
                'grant_id'         => $grantId,
                'run_id'           => $runId,
                'course_run_label' => $courseRunLabel,
                'course_code'      => $row['course_code'],
                'course_name'      => $row['course_name'] ?: '(No name)',
                'session_title'    => $row['session_title'],
                'enrolment_count'  => $enrolCount,
                'grant_amount'     => 'SGD ' . number_format($total, 2),
                'submitted_at'     => date('Y-m-d H:i:s'),
                'status'           => $status,
            );
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Get all course runs for a given Course Code (SKU). Returns each run's
     * option_type_id, registry-assigned Course Run label, session title,
     * enrolment count, and assigned trainer names.
     */
    public function searchCourseRunsAction()
    {
        $result = array('success' => false);
        try {
            $code = trim((string) $this->getRequest()->getParam('code'));
            if ($code === '') throw new Exception('Course Code is required');

            $read = Mage::getSingleton('core/resource')->getConnection('core_read');

            $product = $read->fetchRow(
                "SELECT e.entity_id, e.sku,
                        (SELECT value FROM catalog_product_entity_varchar v WHERE v.entity_id = e.entity_id AND v.attribute_id = 71 ORDER BY v.store_id LIMIT 1) AS course_name
                 FROM catalog_product_entity e
                 WHERE e.sku = ? LIMIT 1",
                array($code)
            );
            if (!$product) throw new Exception('No course found with code "' . $code . '"');

            // Registry label uses the same per-website mapping as the rest of TPG
            $reg = $read->fetchRow(
                "SELECT website_id, run_seq FROM course_run_registry WHERE product_id = ? LIMIT 1",
                array((int)$product['entity_id'])
            );
            $courseRunLabel = null;
            if ($reg) {
                $prefixMap = array(1=>'SG',2=>'MY',3=>'GH',4=>'NG',5=>'BUT',6=>'IND',7=>'INF');
                $prefix = isset($prefixMap[(int)$reg['website_id']]) ? $prefixMap[(int)$reg['website_id']] : 'SG';
                $courseRunLabel = $prefix . '-' . str_pad((string)(100000 + (int)$reg['run_seq']), 6, '0', STR_PAD_LEFT);
            }

            // Look up trainer multiselect option values for this product
            $trainersCsv = (string) $read->fetchOne(
                "SELECT value FROM catalog_product_entity_text WHERE entity_id=? AND attribute_id=170 AND value IS NOT NULL AND value != '' ORDER BY store_id LIMIT 1",
                array((int)$product['entity_id'])
            );
            $trainerNames = '—';
            if ($trainersCsv !== '') {
                $ids = array_filter(array_map('intval', explode(',', $trainersCsv)));
                if ($ids) {
                    $names = $read->fetchCol(
                        "SELECT eaov.value FROM eav_attribute_option_value eaov WHERE eaov.option_id IN (" . implode(',', array_map('intval', $ids)) . ") AND eaov.store_id=0"
                    );
                    if ($names) $trainerNames = implode(', ', $names);
                }
            }

            // List every Course Date session on this product
            $rows = $read->fetchAll(
                "SELECT ov.option_type_id, ott.title
                 FROM catalog_product_option o
                 JOIN catalog_product_option_title ot ON ot.option_id = o.option_id AND ot.store_id = 0
                 JOIN catalog_product_option_type_value ov ON ov.option_id = o.option_id
                 JOIN catalog_product_option_type_title ott ON ott.option_type_id = ov.option_type_id AND ott.store_id = 0
                 WHERE o.product_id = ? AND (ot.title = 'Course Date' OR ot.title LIKE '%Date%')
                 ORDER BY ov.sort_order ASC, ov.option_type_id ASC",
                array((int)$product['entity_id'])
            );

            $enrolCount = (int) $read->fetchOne(
                "SELECT COUNT(DISTINCT o.entity_id)
                 FROM sales_flat_order o
                 JOIN sales_flat_order_item oi ON oi.order_id = o.entity_id
                 WHERE oi.product_id = ? AND o.state NOT IN ('canceled','closed')",
                array((int)$product['entity_id'])
            );

            $runs = array();
            foreach ($rows as $r) {
                $runs[] = array(
                    'run_id'           => (int) $r['option_type_id'],
                    'course_run_label' => $courseRunLabel,
                    'session_title'    => $r['title'],
                    'enrolment_count'  => $enrolCount,
                    'trainer_names'    => $trainerNames,
                );
            }

            $result['success']     = true;
            $result['course_code'] = $product['sku'];
            $result['course_name'] = $product['course_name'] ?: '(No name)';
            $result['runs']        = $runs;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Edit Course Run — update the session title (and any other future
     * editable fields) for an existing run.
     * POST: run_id, session_title
     */
    public function editCourseRunAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $req = $this->getRequest();
            $runId = (int) $req->getParam('run_id');
            $title = trim((string) $req->getParam('session_title'));
            if (!$runId) throw new Exception('run_id is required');
            if ($title === '') throw new Exception('Session Title cannot be empty');

            $resource = Mage::getSingleton('core/resource');
            $read  = $resource->getConnection('core_read');
            $write = $resource->getConnection('core_write');

            $exists = (int) $read->fetchOne(
                "SELECT option_type_id FROM catalog_product_option_type_value WHERE option_type_id = ? LIMIT 1",
                array($runId)
            );
            if (!$exists) throw new Exception('Course run ' . $runId . ' not found');

            $updated = $write->update(
                'catalog_product_option_type_title',
                array('title' => $title),
                array('option_type_id = ?' => $runId, 'store_id = ?' => 0)
            );

            Mage::app()->cleanCache();
            $result['success'] = true;
            $result['updated'] = (int) $updated;
        } catch (Exception $e) {
            $result['message'] = $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Delete a Course Run. Requires both Course Reference Number (SKU)
     * and Course Run ID (option_type_id) to confirm intent. Removes the
     * Course Date option_type_value row (cascades to its title row), the
     * matching course_run_registry entry, and any course_session_trainers
     * binding. Existing course_attendance rows are preserved as audit.
     */
    public function deleteCourseRunAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) throw new Exception('POST required');
            $req = $this->getRequest();
            $ref   = trim((string) $req->getParam('course_ref'));
            $runId = (int) $req->getParam('run_id');
            if ($ref === '' || !$runId) throw new Exception('Both Course Reference Number and Course Run ID are required.');

            $resource = Mage::getSingleton('core/resource');
            $read  = $resource->getConnection('core_read');
            $write = $resource->getConnection('core_write');

            // Verify the (sku, run_id) pair belongs together
            $productId = (int) $read->fetchOne(
                "SELECT e.entity_id
                 FROM catalog_product_option_type_value ov
                 JOIN catalog_product_option o ON o.option_id = ov.option_id
                 JOIN catalog_product_entity e ON e.entity_id = o.product_id
                 WHERE ov.option_type_id = ? AND e.sku = ?
                 LIMIT 1",
                array($runId, $ref)
            );
            if (!$productId) {
                throw new Exception('Course run ' . $runId . ' does not belong to course ' . $ref . '.');
            }

            // Delete the option_type_title (title row) — and the option_type_value row
            $write->delete(
                'catalog_product_option_type_title',
                array('option_type_id = ?' => $runId)
            );
            $write->delete(
                'catalog_product_option_type_value',
                array('option_type_id = ?' => $runId)
            );

            // Drop session-trainer binding for this run, if any
            try {
                $write->delete(
                    'course_session_trainers',
                    array('option_type_id = ?' => $runId)
                );
            } catch (Exception $e) { /* table may not exist in some envs */ }

            // Drop the registry entry too — keeping it would leave an orphan SG-100xxx label
            try {
                $write->delete(
                    'course_run_registry',
                    array('product_id = ? AND run_seq IN (SELECT run_seq FROM (SELECT run_seq FROM course_run_registry WHERE product_id = ?) tmp)' => array($productId, $productId))
                );
            } catch (Exception $e) { /* registry may not exist in some envs */ }

            Mage::app()->cleanCache();
            $result['success']     = true;
            $result['deleted_run'] = $runId;
            $result['course_code'] = $ref;
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

    protected function _isAllowed()
    {
        return true;
    }
}
