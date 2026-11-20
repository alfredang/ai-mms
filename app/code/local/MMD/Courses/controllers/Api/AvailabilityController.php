<?php

/**
 * TMS -> Magento availability sink.
 *
 * POST /courses/api_availability
 *
 * Stores what TMS read from SSG (information only: it never hides a course or
 * closes its registration) and answers with `runs_needed`: every enabled course
 * SSG has no future run for. TMS then publishes those courses' website schedule
 * (/courses/api_schedule) to TPGateway, so SSG tallies with the storefront.
 * Header: X-API-Key (same integration key as /courses/api_schedule)
 */
class MMD_Courses_Api_AvailabilityController extends Mage_Core_Controller_Front_Action
{
    const CONFIG_PATH_API_KEY = 'courses/general/wsq_schedule_api_key';

    public function indexAction()
    {
        if (!$this->getRequest()->isPost()) {
            return $this->_json(405, array('success' => false, 'error' => 'method_not_allowed'));
        }

        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if ($expected === '') {
            return $this->_json(503, array('success' => false, 'error' => 'api_disabled'));
        }
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, array('success' => false, 'error' => 'unauthorized'));
        }

        try {
            $payload = Mage::helper('core')->jsonDecode($this->getRequest()->getRawBody());
        } catch (Exception $e) {
            return $this->_json(400, array('success' => false, 'error' => 'invalid_json'));
        }
        if (!is_array($payload) || !isset($payload['courses']) || !is_array($payload['courses'])) {
            return $this->_json(400, array('success' => false, 'error' => 'courses_array_required'));
        }

        $allowed = array('active', 'renewal_processing', 'expired', 'no_public_run', 'rejected', 'no_support', 'unknown');
        $resource = Mage::getSingleton('core/resource');
        $write = $resource->getConnection('core_write');
        $table = $resource->getTableName('mmd_course_availability');
        $matched = 0;
        $visibilityChanged = 0; // always 0: kept in the response for the TMS client
        $changes = array();
        $unmatched = array();
        // Enabled courses SSG has no future run for. Registration stays open; TMS is
        // asked (in the response) to publish their website schedule to TPGateway.
        $runsNeeded = array();

        foreach ($payload['courses'] as $course) {
            $courseCode = trim((string) (isset($course['course_code']) ? $course['course_code'] : ''));
            $ssgCourseCode = trim((string) (isset($course['ssg_course_code']) ? $course['ssg_course_code'] : $courseCode));
            $status = trim((string) (isset($course['status']) ? $course['status'] : ''));
            if (stripos($courseCode, 'TGS-') !== 0 || !in_array($status, $allowed, true)) {
                continue;
            }

            $productId = (int) Mage::getModel('catalog/product')->getIdBySku($courseCode);
            $matchedCourseCode = $courseCode;
            if (!$productId && stripos($ssgCourseCode, 'TGS-') === 0) {
                $productId = (int) Mage::getModel('catalog/product')->getIdBySku($ssgCourseCode);
                $matchedCourseCode = $ssgCourseCode;
            }
            if (!$productId) {
                $unmatched[] = $courseCode;
                continue;
            }

            $existing = $write->fetchRow(
                $write->select()->from($table)->where('product_id = ?', $productId)->limit(1)
            );
            // Read-only load (title + status for the response).
            $product = Mage::getModel('catalog/product')->setStoreId(0)->load($productId);

            // HARD RULE (2026-11-20): this sync cannot edit, hide or disable a course.
            // It has no write to the catalogue at all: the SSG status is stored for
            // information only, and a status change is emailed to the approver
            // (MMD_Courses_Helper_Changenotice). Any change to a course is made by a
            // person. Guardrail: .claude/hooks/course-change-guard.py.
            $oldStatus = $existing ? (string) $existing['availability_status'] : '';
            if ($oldStatus !== $status && !($oldStatus === '' && $status === 'active')) {
                $changes[] = array(
                    'product_id' => $productId,
                    'sku' => $matchedCourseCode,
                    'old' => $oldStatus,
                    'new' => $status,
                    'reason' => trim((string) (isset($course['reason']) ? $course['reason'] : '')),
                    'support_to' => (string) $this->_dateOrNull(isset($course['support_to']) ? $course['support_to'] : null),
                );
            }

            $checkedAt = !empty($course['checked_at']) && strtotime($course['checked_at'])
                ? gmdate('Y-m-d H:i:s', strtotime($course['checked_at']))
                : gmdate('Y-m-d H:i:s');
            $data = array(
                'product_id' => $productId,
                'course_code' => $matchedCourseCode,
                'ssg_course_code' => substr($ssgCourseCode, 0, 64),
                'availability_status' => $status,
                'availability_reason' => substr(trim((string) (isset($course['reason']) ? $course['reason'] : '')), 0, 255),
                'support_from' => $this->_dateOrNull(isset($course['support_from']) ? $course['support_from'] : null),
                'support_to' => $this->_dateOrNull(isset($course['support_to']) ? $course['support_to'] : null),
                'has_future_run' => !empty($course['has_future_run']) ? 1 : 0,
                'checked_at' => $checkedAt,
                'original_visibility' => null,
            );
            $write->insertOnDuplicate($table, $data, array(
                'course_code', 'ssg_course_code', 'availability_status',
                'availability_reason', 'support_from', 'support_to',
                'has_future_run', 'checked_at', 'original_visibility',
            ));

            Mage::app()->cleanCache(array(Mage_Catalog_Model_Product::CACHE_TAG . '_' . $productId));
            $matched++;

            if ($status === 'no_public_run'
                && empty($course['has_future_run'])
                && (int) $product->getStatus() === Mage_Catalog_Model_Product_Status::STATUS_ENABLED
            ) {
                $runsNeeded[] = array(
                    'course_code' => $matchedCourseCode,
                    'ssg_course_code' => $ssgCourseCode,
                    'course_title' => (string) $product->getName(),
                );
            }
        }

        $notified = $this->_notifyApprover($changes);

        return $this->_json(200, array(
            'success' => true,
            'matched' => $matched,
            'visibility_changed' => $visibilityChanged,
            'status_changes' => count($changes),
            'approver_notified' => $notified,
            'unmatched' => array_slice($unmatched, 0, 50),
            'runs_needed' => $runsNeeded,
        ));
    }

    /** Email the approver about status changes. A mail failure never fails the sync. */
    private function _notifyApprover(array $changes)
    {
        if (!$changes) {
            return false;
        }
        try {
            $res = Mage::getSingleton('core/resource');
            $read = $res->getConnection('core_read');
            $store = Mage::app()->getDefaultStoreView();
            $nameAttr = (int) Mage::getSingleton('eav/config')->getAttribute('catalog_product', 'name')->getId();
            foreach ($changes as &$c) {
                $c['name'] = (string) $read->fetchOne(
                    'SELECT value FROM ' . $res->getTableName('catalog/product') . '_varchar'
                    . ' WHERE entity_id = ? AND attribute_id = ? AND store_id = 0',
                    array($c['product_id'], $nameAttr)
                );
                $path = (string) $read->fetchOne(
                    'SELECT request_path FROM ' . $res->getTableName('core/url_rewrite')
                    . ' WHERE product_id = ? AND store_id = ? AND is_system = 1 AND category_id IS NULL',
                    array($c['product_id'], (int) $store->getId())
                );
                $c['url'] = $store->getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB) . $path;
            }
            unset($c);
            return (bool) Mage::helper('courses/changenotice')->notify($changes);
        } catch (Throwable $e) {
            Mage::log('availability change notice failed: ' . $e->getMessage(), Zend_Log::ERR);
            return false;
        }
    }

    private function _dateOrNull($value)
    {
        $value = trim((string) $value);
        return preg_match('/^\d{4}-\d{2}-\d{2}$/', $value) ? $value : null;
    }

    private function _json($status, array $body)
    {
        $this->getResponse()
            ->setHttpResponseCode($status)
            ->setHeader('Content-Type', 'application/json; charset=utf-8', true)
            ->setBody(Mage::helper('core')->jsonEncode($body));
        return $this;
    }
}
