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
            $dashboardUrl = Mage::helper('adminhtml')->getUrl('adminhtml/dashboard');

            if ($continueEdit) {
                $editUrl = Mage::helper('adminhtml')->getUrl('adminhtml/dashboard', array(
                    'course_id' => $courseId,
                    'mode' => 'editing',
                ));
                $this->_redirectUrl($editUrl);
            } else {
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
