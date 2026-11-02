<?php
/**
 * Read-only API: who is assigned to which class.
 *
 * GET /courses/api_trainer_classes?trainer_email=<email>             → that trainer's upcoming assigned classes
 * GET /courses/api_trainer_classes?course_sku=<sku>[&date=YYYY-MM-DD] → the course's classes (on that date, else upcoming)
 * GET /courses/api_trainer_classes?course_sku=<sku>&date=...&trainer_email=<email>
 *                                                                     → the course's classes, each flagged
 *                                                                       assigned_to_trainer for that trainer
 * ...&include_learners=1                                              → each class also lists its learners
 *                                                                       (name + email; bot key only)
 *
 * Auth: X-API-Key (the bot key or the trainer-reminders key, as /courses/api_trainers).
 *
 * "Assigned" uses the same definition as the trainer's My Assigned Classes
 * panel: course_runs.trainer_user_id is the trainer's account, or (legacy) the
 * run's trainer_option_id is the trainer's EAV option. Built for the Kael
 * trainer-support agent to verify a class before/after
 * POST /agent/api_classes op=assign_trainer. Never mutates anything.
 */
class MMD_Courses_Api_Trainer_ClassesController extends Mage_Core_Controller_Front_Action
{
    const CONFIG_PATH_API_KEY         = 'courses/general/wsq_schedule_api_key';
    const CONFIG_PATH_TRAINER_API_KEY = 'courses/general/trainer_reminders_api_key';
    const MAX_ROWS                    = 100;

    public function indexAction()
    {
        $keyBot     = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        $keyTrainer = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_TRAINER_API_KEY));
        if ($keyBot === '' && $keyTrainer === '') {
            return $this->_json(503, array('success' => false, 'error' => 'api_disabled', 'message' => 'No API keys configured.'));
        }
        $provided = trim((string) $this->getRequest()->getHeader('X-API-Key'));
        if (!(($keyBot !== '' && hash_equals($keyBot, $provided)) || ($keyTrainer !== '' && hash_equals($keyTrainer, $provided)))) {
            return $this->_json(401, array('success' => false, 'error' => 'unauthorized', 'message' => 'Invalid or missing X-API-Key.'));
        }

        // Learner names/emails go only to the bot key (the admin agent), never to the trainer-reminders key.
        $withLearners = (bool) $this->getRequest()->getParam('include_learners', false);
        if ($withLearners && !($keyBot !== '' && hash_equals($keyBot, $provided))) {
            return $this->_json(403, array('success' => false, 'error' => 'forbidden',
                'message' => 'include_learners needs the agent API key.'));
        }
        $email = strtolower(trim((string) $this->getRequest()->getParam('trainer_email', '')));
        $sku   = trim((string) $this->getRequest()->getParam('course_sku', ''));
        $date  = trim((string) $this->getRequest()->getParam('date', ''));
        if ($email === '' && $sku === '') {
            return $this->_json(400, array('success' => false, 'error' => 'validation_error',
                'message' => 'Pass trainer_email, course_sku, or both.'));
        }
        if ($date !== '' && !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            return $this->_json(400, array('success' => false, 'error' => 'validation_error',
                'message' => 'date must be YYYY-MM-DD.'));
        }

        try {
            $read    = Mage::getSingleton('core/resource')->getConnection('core_read');
            $product = null;
            if ($sku !== '') {
                $product = $read->fetchRow(
                    "SELECT entity_id, TRIM(sku) AS sku FROM catalog_product_entity WHERE TRIM(sku) = ? LIMIT 1", array($sku));
                if (!$product) {
                    return $this->_json(404, array('success' => false, 'error' => 'not_found',
                        'message' => 'No course with course_sku=' . $sku . ' on this site.'));
                }
            }
            $trainer = $email !== '' ? $this->_trainer($read, $email, $product) : null;

            $where = array(); $binds = array();
            if ($product) {
                $where[] = 'cr.product_id = ?';
                $binds[] = (int) $product['entity_id'];
            } else {
                // Trainer-only mode: just the classes assigned to them.
                $match = array();
                if ($trainer['user_id']) { $match[] = 'cr.trainer_user_id = ' . (int) $trainer['user_id']; }
                if ($trainer['_option_ids']) { $match[] = 'cr.trainer_option_id IN (' . implode(',', $trainer['_option_ids']) . ')'; }
                $where[] = $match ? '(' . implode(' OR ', $match) . ')' : '0';
            }
            if ($date !== '') {
                $where[] = 'cr.course_start_date <= ? AND COALESCE(cr.course_end_date, cr.course_start_date) >= ?';
                $binds[] = $date; $binds[] = $date;
            } else {
                $where[] = 'COALESCE(cr.course_end_date, cr.course_start_date) >= CURDATE()';
            }

            $runs = $read->fetchAll(
                "SELECT cr.*, TRIM(p.sku) AS live_sku,
                        (SELECT v.value FROM catalog_product_entity_varchar v
                          WHERE v.entity_id = cr.product_id AND v.store_id IN (0, 1) AND v.attribute_id =
                                (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name')
                          ORDER BY v.store_id DESC LIMIT 1) AS course_title,
                        (SELECT COUNT(*) FROM course_run_enrolments e WHERE e.run_id = cr.run_id) AS learners_enrolled
                   FROM course_runs cr
                   JOIN catalog_product_entity p ON p.entity_id = cr.product_id
                  WHERE cr.class_id IS NOT NULL AND " . implode(' AND ', $where) . "
                  ORDER BY cr.course_start_date ASC, cr.run_id ASC
                  LIMIT " . self::MAX_ROWS,
                $binds
            );

            $classes = array();
            foreach ($runs as $r) {
                $row = $this->_classRow($read, $r, $trainer);
                if ($withLearners) {
                    $row['learners'] = $read->fetchAll(
                        "SELECT TRIM(COALESCE(learner_name, '')) AS name, LOWER(TRIM(learner_email)) AS email
                           FROM course_run_enrolments WHERE run_id = ? ORDER BY learner_name, learner_email",
                        array((int) $r['run_id']));
                }
                $classes[] = $row;
            }
            if ($trainer) { unset($trainer['_option_ids']); }

            return $this->_json(200, array(
                'success'      => true,
                'last_updated' => gmdate('c'),
                'filters'      => array('trainer_email' => $email ?: null, 'course_sku' => $product ? $product['sku'] : null,
                                        'date' => $date ?: null, 'window' => $date !== '' ? 'classes running on date' : 'upcoming (ends today or later)'),
                'trainer'      => $trainer,
                'count'        => count($classes),
                'classes'      => $classes,
            ));
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, array('success' => false, 'error' => 'internal_error', 'message' => $e->getMessage()));
        }
    }

    /** The trainer's MMS account state, plus their legacy EAV option ids for matching. */
    private function _trainer($read, $email, $product)
    {
        $u = $read->fetchRow(
            "SELECT user_id, email, is_active, TRIM(CONCAT(COALESCE(firstname,''),' ',COALESCE(lastname,''))) AS name
               FROM admin_user WHERE LOWER(TRIM(email)) = ? LIMIT 1", array($email));
        $uid = $u ? (int) $u['user_id'] : 0;
        $optIds = array_values(array_filter(array_map('intval', $read->fetchCol(
            "SELECT relation_id FROM courses_trainers WHERE LOWER(TRIM(email)) = ? AND relation_id > 0", array($email)))));

        $out = array(
            'email'            => $email,
            'mms_account'      => $uid > 0,
            'user_id'          => $uid ?: null,
            'name'             => $u ? ($u['name'] ?: $u['email']) : null,
            'login_active'     => $u ? (int) $u['is_active'] === 1 : false,
            'has_trainer_role' => $uid > 0 && (bool) $read->fetchOne(
                "SELECT 1 FROM mmd_user_role_map WHERE user_id = ? AND role_code = 'trainer' LIMIT 1", array($uid)),
            '_option_ids'      => $optIds,
        );
        if ($product) {
            // The course's approved trainer pool (Edit Course → Trainers). Informational:
            // assign_trainer does not require it.
            $out['in_course_trainer_pool'] = $uid > 0 && (bool) $read->fetchOne(
                "SELECT 1 FROM mmd_product_trainer WHERE product_id = ? AND user_id = ? LIMIT 1",
                array((int) $product['entity_id'], $uid));
        }
        return $out;
    }

    private function _classRow($read, array $r, $trainer)
    {
        $assigned = Mage::helper('mmd_rolemanager/trainer')->resolveRunTrainer($r);
        $inv = $read->fetchRow(
            "SELECT trainer_name, trainer_email, status, sent_at, responded_at
               FROM course_run_trainer_invitations WHERE run_id = ? ORDER BY id DESC LIMIT 1", array((int) $r['run_id']));
        $row = array(
            'class_id'          => (string) $r['class_id'],
            'course_sku'        => (string) $r['live_sku'],
            'course_title'      => (string) $r['course_title'],
            'start_date'        => $r['course_start_date'] ?: null,
            'end_date'          => $r['course_end_date'] ?: $r['course_start_date'],
            'start_time'        => $r['course_start_time'] ? substr($r['course_start_time'], 0, 5) : null,
            'end_time'          => $r['course_end_time'] ? substr($r['course_end_time'], 0, 5) : null,
            'mode'              => (int) $r['mode_of_training'] === 2 ? 'Virtual' : 'Physical Classroom',
            'virtual_link'      => isset($r['virtual_link']) && $r['virtual_link'] !== '' ? $r['virtual_link'] : null,
            'google_calendar_event' => !empty($r['gcal_event_id']),
            'learners_enrolled' => (int) $r['learners_enrolled'],
            'trainer'           => $assigned ? array('name' => $assigned['name'], 'email' => $assigned['email'] ?: null,
                                                     'source' => $assigned['source']) : null,
            'latest_invitation' => $inv ?: null,
        );
        if ($trainer) {
            // Account pointer wins over the legacy option, as in resolveRunTrainer.
            $row['assigned_to_trainer'] = (int) $r['trainer_user_id']
                ? (int) $r['trainer_user_id'] === (int) $trainer['user_id']
                : ((int) $r['trainer_option_id'] && in_array((int) $r['trainer_option_id'], $trainer['_option_ids'], true));
        }
        $row['next_step'] = $assigned
            ? null
            : 'No trainer assigned. Use POST /agent/api_classes op=assign_trainer with class_id=' . $r['class_id'] . ' (preview, confirm, commit).';
        return $row;
    }

    private function _json($status, array $body)
    {
        $this->getResponse()
            ->setHttpResponseCode($status)
            ->setHeader('Content-Type', 'application/json; charset=utf-8', true)
            ->setHeader('Cache-Control', 'no-store', true)
            ->setBody(json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        return $this;
    }
}
