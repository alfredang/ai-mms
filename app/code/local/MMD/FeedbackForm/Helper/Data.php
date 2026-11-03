<?php
class MMD_FeedbackForm_Helper_Data extends Mage_Core_Helper_Abstract
{
    const AUTOFILL_COURSE_TITLE = 'course_title';
    const AUTOFILL_COURSE_CODE  = 'course_code';
    const AUTOFILL_START_DATE   = 'start_date';
    const AUTOFILL_END_DATE     = 'end_date';
    const AUTOFILL_TRAINER_NAME = 'trainer_name';
    const AUTOFILL_CLASS_ID     = 'class_id';   // human run label, e.g. C000046

    public function getFieldTypes()
    {
        return array(
            'text'        => 'Short Text',
            'textarea'    => 'Long Text',
            'email'       => 'Email',
            'date'        => 'Date',
            'select'      => 'Dropdown',
            'rating1to5'  => '1–5 Star Rating',
        );
    }

    public function getAutofillOptions()
    {
        return array(
            ''             => '— None —',
            'course_title' => 'Course Title',
            'course_code'  => 'Course Code',
            'class_id'     => 'Course Run ID',
            'trainer_name' => 'Trainer Name',
            'start_date'   => 'Start Date',
            'end_date'     => 'End Date',
        );
    }

    public function getDefaultTemplate()
    {
        return array(
            'title'    => 'Course Feedback Form',
            'sections' => array(
                array(
                    'id'     => 's1',
                    'title'  => 'Your Details',
                    'fields' => array(
                        array('id'=>'f1','label'=>'Course Title',     'type'=>'text',  'autofill'=>'course_title', 'readonly'=>true,  'required'=>false,'options'=>''),
                        array('id'=>'f2','label'=>'Course Code',      'type'=>'text',  'autofill'=>'course_code',  'readonly'=>true,  'required'=>false,'options'=>''),
                        array('id'=>'f11','label'=>'Course Run ID',   'type'=>'text',  'autofill'=>'class_id',     'readonly'=>true,  'required'=>false,'options'=>''),
                        array('id'=>'f3','label'=>'Trainer',          'type'=>'text',  'autofill'=>'trainer_name', 'readonly'=>true,  'required'=>false,'options'=>''),
                        array('id'=>'f4','label'=>'Your Full Name',   'type'=>'text',  'autofill'=>'',             'readonly'=>false, 'required'=>true, 'options'=>''),
                        array('id'=>'f5','label'=>'Class Start Date', 'type'=>'date',  'autofill'=>'start_date',   'readonly'=>true,  'required'=>false,'options'=>''),
                        array('id'=>'f6','label'=>'Class End Date',   'type'=>'date',  'autofill'=>'end_date',     'readonly'=>true,  'required'=>false,'options'=>''),
                    ),
                ),
                array(
                    'id'     => 's2',
                    'title'  => 'Course Evaluation',
                    'fields' => array(
                        array('id'=>'f7','label'=>'Overall, how would you rate the course meeting the learning objectives?', 'type'=>'rating1to5','autofill'=>'','readonly'=>false,'required'=>true, 'options'=>''),
                        array('id'=>'f8','label'=>'Overall, how would you rate the trainer\'s knowledge in this subject matter?',  'type'=>'rating1to5','autofill'=>'','readonly'=>false,'required'=>true, 'options'=>''),
                        array('id'=>'f9','label'=>'Overall, how would you rate the training environment?', 'type'=>'rating1to5','autofill'=>'','readonly'=>false,'required'=>true, 'options'=>''),
                        array('id'=>'f10','label'=>'Additional comments (optional)', 'type'=>'textarea','autofill'=>'','readonly'=>false,'required'=>false,'options'=>''),
                    ),
                ),
            ),
        );
    }

    /**
     * Load the single active template, or seed it from defaults if none exists.
     */
    public function getOrCreateTemplate()
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $tbl      = $resource->getTableName('mmd_feedback_form_template');

        $row = $read->fetchRow("SELECT * FROM `$tbl` WHERE is_active = 1 ORDER BY template_id ASC LIMIT 1");
        if ($row) {
            $row['sections'] = json_decode($row['sections'], true) ?: array();
            $row['sections'] = $this->_ensureClassIdField($row['sections']);
            return $row;
        }

        // Seed default.
        $default = $this->getDefaultTemplate();
        $write   = $resource->getConnection('core_write');
        $write->insert($tbl, array(
            'title'    => $default['title'],
            'sections' => json_encode($default['sections']),
            'is_active'=> 1,
        ));
        $default['template_id'] = (int) $write->lastInsertId();
        return $default;
    }

    /**
     * Templates saved before 2026-07-29 predate the Course Run ID field.
     * Inject it (read-time, not persisted) right after the Course Code
     * field so every rendered form carries the run label — the field is
     * readonly/autofill, so the submit parser skips it either way.
     */
    protected function _ensureClassIdField(array $sections)
    {
        foreach ($sections as $section) {
            foreach ((array) (isset($section['fields']) ? $section['fields'] : array()) as $field) {
                if (isset($field['autofill']) && $field['autofill'] === self::AUTOFILL_CLASS_ID) {
                    return $sections; // already present
                }
            }
        }
        $runField = array('id'=>'f11','label'=>'Course Run ID','type'=>'text','autofill'=>self::AUTOFILL_CLASS_ID,'readonly'=>true,'required'=>false,'options'=>'');
        foreach ($sections as $si => $section) {
            foreach ((array) (isset($section['fields']) ? $section['fields'] : array()) as $fi => $field) {
                if (isset($field['autofill']) && $field['autofill'] === self::AUTOFILL_COURSE_CODE) {
                    array_splice($sections[$si]['fields'], $fi + 1, 0, array($runField));
                    return $sections;
                }
            }
        }
        if (isset($sections[0]['fields'])) {
            $sections[0]['fields'][] = $runField; // no Course Code field — append
        }
        return $sections;
    }

    /**
     * A class run with the context the form autofills (course title, trainer,
     * dates). Null when the run does not exist. Shared by the public web form
     * (RespondController) and the native learner apps (MMD_MobileApi).
     */
    public function loadRun($runId)
    {
        $resource  = Mage::getSingleton('core/resource');
        $read      = $resource->getConnection('core_read');
        $runsTbl   = $resource->getTableName('course_runs');
        $pVarchar  = $resource->getTableName('catalog_product_entity_varchar');
        $eavAttr   = $resource->getTableName('eav_attribute');
        $eavType   = $resource->getTableName('eav_entity_type');
        $eavOptVal = $resource->getTableName('eav_attribute_option_value');
        $auTbl     = $resource->getTableName('admin_user');

        $nameAttrId = (int)$read->fetchOne(
            "SELECT a.attribute_id FROM `$eavAttr` a
               JOIN `$eavType` t ON t.entity_type_id = a.entity_type_id
              WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'name'"
        );

        return $read->fetchRow(
            "SELECT cr.run_id, cr.class_id, cr.course_sku, cr.product_id,
                    cr.course_start_date,
                    -- Single-day classes leave course_end_date NULL.
                    COALESCE(cr.course_end_date, cr.course_start_date) AS course_end_date,
                    cr.trainer_option_id, cr.trainer_user_id,
                    COALESCE(pn.value, cr.course_sku) AS course_title,
                    -- Phase 2: account-confirmed trainer wins, EAV is the fallback.
                    COALESCE(
                        NULLIF(TRIM(CONCAT(COALESCE(au.firstname,''),' ',COALESCE(au.lastname,''))), ''),
                        tov.value, ''
                    ) AS trainer_name
               FROM `$runsTbl` cr
               LEFT JOIN `$pVarchar` pn
                    ON pn.entity_id = cr.product_id AND pn.store_id = 0
                   AND pn.attribute_id = $nameAttrId
               LEFT JOIN `$auTbl` au
                    ON au.user_id = cr.trainer_user_id
               LEFT JOIN `$eavOptVal` tov
                    ON tov.option_id = cr.trainer_option_id AND tov.store_id = 0
              WHERE cr.run_id = ?",
            array((int)$runId)
        ) ?: null;
    }

    /** Values the template's autofill fields take for a run (see loadRun). */
    public function contextForRun(array $run)
    {
        return array(
            'course_title' => (string)$run['course_title'],
            'course_code'  => (string)$run['course_sku'],
            'class_id'     => (string)$run['class_id'],
            'trainer_name' => (string)$run['trainer_name'],
            'start_date'   => $run['course_start_date'] ? date('Y-m-d', strtotime($run['course_start_date'])) : '',
            'end_date'     => $run['course_end_date']   ? date('Y-m-d', strtotime($run['course_end_date']))   : '',
        );
    }

    /**
     * Save one survey response as a Magento product review — the single
     * feedback store — and link it to the run for the daily digest.
     *
     * @param array $run      row from loadRun()
     * @param array $template getOrCreateTemplate()
     * @param array $answers  field id (f4, f7 …) => value
     * @return int review_id
     */
    public function saveSubmission(array $run, array $template, array $answers)
    {
        // Derive learner name, comment, and the three 1–5 star ratings by
        // scanning the template field definitions — this maps field IDs
        // (f4, f7 …) back to their semantic purpose. The rating fields map
        // positionally onto the Magento rating codes:
        //   1st rating1to5 → rating_id 1 (course meets expectation)
        //   2nd rating1to5 → rating_id 2 (trainer knowledgeable)
        //   3rd rating1to5 → rating_id 5 (training environment)
        $ratingIds   = array(1, 2, 5);
        $starValues  = array();   // rating_id => value 1..5
        $learnerName = '';
        $comment     = '';
        foreach ($template['sections'] as $section) {
            foreach ($section['fields'] as $field) {
                if (!empty($field['autofill']) || !empty($field['readonly'])) continue;
                $fid = $field['id'];
                $val = isset($answers[$fid]) ? trim((string)$answers[$fid]) : '';
                if ($learnerName === '' && $field['type'] === 'text' && !empty($field['required'])) $learnerName = $val;
                if ($comment === '' && $field['type'] === 'textarea' && $val !== '')                $comment = $val;
                if ($field['type'] === 'rating1to5' && !empty($ratingIds)) {
                    $ratingId = array_shift($ratingIds);
                    $star     = max(1, min(5, (int)$val ?: 5));
                    $starValues[$ratingId] = $star;
                }
            }
        }

        $productId = (int)$run['product_id'];
        $runId     = (int)$run['run_id'];
        $storeId   = (int)Mage::app()->getStore()->getId();
        $average   = $starValues ? round(array_sum($starValues) / count($starValues), 1) : 5.0;

        /** @var Mage_Review_Model_Review $review */
        $review = Mage::getModel('review/review');
        $review->setEntityPkValue($productId)
               ->setStatusId(Mage_Review_Model_Review::STATUS_APPROVED)
               ->setTitle('Average Rating: ' . number_format($average, 1) . '/5')
               ->setDetail($comment !== '' ? $comment : 'N/A')
               ->setEntityId($review->getEntityIdByCode(Mage_Review_Model_Review::ENTITY_PRODUCT_CODE))
               ->setStoreId($storeId)
               ->setStores(array($storeId))
               ->setNickname($learnerName)
               ->save();

        // One vote per rating dimension: resolve the option row for the
        // chosen star value, then record + aggregate.
        $resource  = Mage::getSingleton('core/resource');
        $read      = $resource->getConnection('core_read');
        $optionTbl = $resource->getTableName('rating_option');
        foreach ($starValues as $ratingId => $star) {
            $optionId = (int)$read->fetchOne(
                "SELECT option_id FROM `$optionTbl` WHERE rating_id = ? AND value = ?",
                array($ratingId, $star)
            );
            if (!$optionId) continue;
            Mage::getModel('rating/rating')
                ->setRatingId($ratingId)
                ->setReviewId($review->getId())
                ->addOptionVote($optionId, $productId);
        }
        $review->aggregate();

        // Remember the class so the daily digest can consolidate per class.
        $resource->getConnection('core_write')->query(
            'INSERT IGNORE INTO `' . $resource->getTableName('mmd_feedback_review_run') . '` (review_id, run_id) VALUES (?, ?)',
            array((int)$review->getId(), $runId)
        );
        return (int)$review->getId();
    }
}
