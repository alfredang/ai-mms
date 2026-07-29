<?php
/**
 * Completed-classes export endpoint — served by every instance from its OWN
 * DB; the SG Super Admin pulls it weekly from the MY/GH partner domains.
 *
 * GET /courses/api_completed_classes?page=1&page_size=200[&since=YYYY-MM-DD]
 *   Header: X-API-Key: <mmd/course_sync/api_key>  (same key as course sync)
 *
 * A class is exported when it is CONFIRMED (a trainer is assigned) and
 * COMPLETED (course_end_date, or start date for one-day runs, is before
 * today). Per-class fields:
 *   class_code        — course_runs.class_id (e.g. C000017)
 *   course_title      — catalog product name (admin scope)
 *   course_code       — course_runs.course_sku
 *   start_date / end_date
 *   trainer_name      — admin_user firstname+lastname via trainer_user_id
 *   learners_attended — mmd_course_run_attendance rows with is_present=1
 *
 * Read-only: never mutates any table. No numeric IDs are exported.
 */
class MMD_Courses_Api_Completed_ClassesController extends Mage_Core_Controller_Front_Action
{
    const CONFIG_API_KEY  = 'mmd/course_sync/api_key';
    const DEFAULT_PAGE_SZ = 200;
    const MAX_PAGE_SZ     = 500;

    public function indexAction()
    {
        // Auth — same X-API-Key contract as /courses/api_sync_export
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_API_KEY));
        if ($expected === '') {
            return $this->_json(503, array('success' => false, 'error' => 'API key not configured (mmd/course_sync/api_key).'));
        }
        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, array('success' => false, 'error' => 'Invalid or missing X-API-Key.'));
        }

        $page   = max(1, (int) $this->getRequest()->getParam('page', 1));
        $pgSize = min(self::MAX_PAGE_SZ, max(1, (int) $this->getRequest()->getParam('page_size', self::DEFAULT_PAGE_SZ)));
        $since  = trim((string) $this->getRequest()->getParam('since', ''));
        $sinceSql = '';
        $binds    = array();
        if ($since !== '' && preg_match('/^\d{4}-\d{2}-\d{2}$/', $since)) {
            $sinceSql = ' AND COALESCE(r.course_end_date, r.course_start_date) >= ?';
            $binds[]  = $since;
        }

        try {
            $resource = Mage::getSingleton('core/resource');
            $read     = $resource->getConnection('core_read');

            // Product name attribute (admin scope) for the course title join.
            $nameAttrId = (int) $read->fetchOne(
                "SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name' LIMIT 1"
            );

            $where = "r.class_id IS NOT NULL
                  AND (r.trainer_user_id IS NOT NULL OR r.trainer_option_id IS NOT NULL)
                  AND COALESCE(r.course_end_date, r.course_start_date) IS NOT NULL
                  AND COALESCE(r.course_end_date, r.course_start_date) < CURDATE()"
                . $sinceSql;

            $total = (int) $read->fetchOne(
                "SELECT COUNT(*) FROM course_runs r WHERE $where",
                $binds
            );
            $totalPages = max(1, (int) ceil($total / $pgSize));
            $offset     = ($page - 1) * $pgSize;

            $rows = $read->fetchAll(
                "SELECT r.class_id AS class_code,
                        COALESCE(pv.value, '') AS course_title,
                        r.course_sku AS course_code,
                        r.course_start_date AS start_date,
                        COALESCE(r.course_end_date, r.course_start_date) AS end_date,
                        TRIM(CONCAT(COALESCE(u.firstname,''), ' ', COALESCE(u.lastname,''))) AS trainer_name,
                        (SELECT COUNT(DISTINCT a.learner_email) FROM mmd_course_run_attendance a
                          WHERE a.run_id = r.run_id AND a.is_present = 1) AS learners_attended
                   FROM course_runs r
              LEFT JOIN admin_user u ON u.user_id = r.trainer_user_id
              LEFT JOIN catalog_product_entity_varchar pv
                     ON pv.entity_id = r.product_id AND pv.attribute_id = $nameAttrId AND pv.store_id = 0
                  WHERE $where
               ORDER BY COALESCE(r.course_end_date, r.course_start_date) DESC, r.class_id DESC
                  LIMIT $pgSize OFFSET $offset",
                $binds
            );

            $this->_json(200, array(
                'success'     => true,
                'page'        => $page,
                'page_size'   => $pgSize,
                'total'       => $total,
                'total_pages' => $totalPages,
                'classes'     => $rows,
            ));
        } catch (Exception $e) {
            Mage::logException($e);
            $this->_json(500, array('success' => false, 'error' => $e->getMessage()));
        }
    }

    private function _json($code, array $data)
    {
        $this->getResponse()
            ->setHttpResponseCode($code)
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($data));
    }
}
