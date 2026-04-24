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

            // Optional: assign a trainer to the new session
            $trainerOptId = (int) $req->getParam('trainer_option_id');
            if ($trainerOptId > 0) {
                $trainerName = (string) $read->fetchOne(
                    "SELECT value FROM eav_attribute_option_value WHERE option_id = ? AND store_id = 0",
                    array($trainerOptId)
                );
                $write->insert('course_session_trainers', array(
                    'option_type_id'    => $optionTypeId,
                    'trainer_option_id' => $trainerOptId,
                    'trainer_name'      => $trainerName,
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
            // Also remove trainer mapping for this session
            $write->delete('course_session_trainers', array('option_type_id = ?' => $optionTypeId));
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
