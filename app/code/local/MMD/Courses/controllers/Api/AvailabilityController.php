<?php

/**
 * TMS -> Magento availability sink.
 *
 * POST /courses/api_availability
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
        $visibilityChanged = 0;
        $unmatched = array();

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
            $product = Mage::getModel('catalog/product')->setStoreId(0)->load($productId);
            $currentVisibility = (int) $product->getVisibility();
            $originalVisibility = $existing && $existing['original_visibility'] !== null
                ? (int) $existing['original_visibility']
                : null;

            $targetVisibility = null;
            if ($status !== 'active' && $currentVisibility !== Mage_Catalog_Model_Product_Visibility::VISIBILITY_NOT_VISIBLE) {
                if ($originalVisibility === null) {
                    $originalVisibility = $currentVisibility;
                }
                $targetVisibility = Mage_Catalog_Model_Product_Visibility::VISIBILITY_NOT_VISIBLE;
            } elseif ($status === 'active'
                && $originalVisibility !== null
                && $currentVisibility === Mage_Catalog_Model_Product_Visibility::VISIBILITY_NOT_VISIBLE) {
                $targetVisibility = $originalVisibility;
                $originalVisibility = null;
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
                'original_visibility' => $originalVisibility,
            );
            $write->insertOnDuplicate($table, $data, array(
                'course_code', 'ssg_course_code', 'availability_status',
                'availability_reason', 'support_from', 'support_to',
                'has_future_run', 'checked_at', 'original_visibility',
            ));

            if ($targetVisibility !== null && $targetVisibility !== $currentVisibility) {
                Mage::getSingleton('catalog/product_action')->updateAttributes(
                    array($productId),
                    array('visibility' => $targetVisibility),
                    0
                );
                $visibilityChanged++;
            }
            Mage::app()->cleanCache(array(Mage_Catalog_Model_Product::CACHE_TAG . '_' . $productId));
            $matched++;
        }

        return $this->_json(200, array(
            'success' => true,
            'matched' => $matched,
            'visibility_changed' => $visibilityChanged,
            'unmatched' => array_slice($unmatched, 0, 50),
        ));
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
