<?php
/**
 * Franchise statistics export — served by every instance from its OWN DB; the
 * SG Franchise Admin control center pulls it daily from the MY/GH partner
 * domains (see MMD_RoleManager_Model_FranchiseStatsService).
 *
 * GET /courses/api_franchise_stats?dataset=classes|orders&since=YYYY-MM-DD&page=1&page_size=500
 *   Header: X-API-Key: <mmd/course_sync/api_key>  (same key as course sync)
 *
 * Datasets (see MMD_Courses_Model_FranchiseStats for the exact fields):
 *   classes — every class (course_runs row with a class_id) ending on/after
 *             `since`: run ID, course, dates, trainer, status, enrolled /
 *             attended learners, certificates issued.
 *   orders  — every course registration line of a non-cancelled order placed
 *             on/after `since`: order no, date, status, course, class date,
 *             learners, amount, currency. No learner identity is exported.
 * Read-only: never mutates any table. No numeric entity IDs are exported.
 */
class MMD_Courses_Api_Franchise_StatsController extends Mage_Core_Controller_Front_Action
{
    const CONFIG_API_KEY  = 'mmd/course_sync/api_key';
    const DEFAULT_PAGE_SZ = 500;
    const MAX_PAGE_SZ     = 1000;

    public function indexAction()
    {
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_API_KEY));
        if ($expected === '') {
            return $this->_json(503, array('success' => false, 'error' => 'API key not configured (mmd/course_sync/api_key).'));
        }
        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, array('success' => false, 'error' => 'Invalid or missing X-API-Key.'));
        }

        $dataset = strtolower(trim((string) $this->getRequest()->getParam('dataset', 'classes')));
        if (!in_array($dataset, array('classes', 'orders'), true)) {
            return $this->_json(400, array('success' => false, 'error' => 'dataset must be classes or orders.'));
        }
        $page   = max(1, (int) $this->getRequest()->getParam('page', 1));
        $pgSize = min(self::MAX_PAGE_SZ, max(1, (int) $this->getRequest()->getParam('page_size', self::DEFAULT_PAGE_SZ)));
        $since  = trim((string) $this->getRequest()->getParam('since', ''));
        if ($since === '' || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $since)) {
            $since = date('Y-m-d', strtotime('-12 months'));
        }

        try {
            /** @var MMD_Courses_Model_FranchiseStats $stats */
            $stats = Mage::getModel('courses/franchiseStats');
            $total = $dataset === 'classes' ? $stats->classesTotal($since) : $stats->ordersTotal($since);
            $rows  = $dataset === 'classes' ? $stats->classes($since, $page, $pgSize) : $stats->orders($since, $page, $pgSize);
            $this->_json(200, array(
                'success'     => true,
                'dataset'     => $dataset,
                'since'       => $since,
                'page'        => $page,
                'page_size'   => $pgSize,
                'total'       => $total,
                'total_pages' => max(1, (int) ceil($total / $pgSize)),
                'rows'        => $rows,
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
