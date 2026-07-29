<?php
/**
 * Base capability model. Each capability (schedule/course/content/ops) extends
 * this and implements preview() + commit():
 *
 *   preview($op, $body): array   -> ['target','diff','human_summary','warnings','token_payload']
 *   commit($op, $body, $preview): array -> ['target','reindexed','after','extra'?]
 *
 * preview() MUST be deterministic against live data: its token_payload is
 * hashed into the change_token and recomputed on commit to detect intervening
 * edits. Never mutate anything in preview().
 */
abstract class MMD_AgentApi_Model_Abstract
{
    /** One store per site; SG = 1. Matches the existing read APIs. */
    const STORE_ID = 1;

    abstract public function preview($op, array $body);

    abstract public function commit($op, array $body, array $preview);

    /** Throw a typed API error. */
    protected function _err($code, $message, $http = 400)
    {
        throw new MMD_AgentApi_Model_Exception($code, $message, $http);
    }

    /** Required string param or validation_error. */
    protected function _require(array $body, $key)
    {
        $v = isset($body[$key]) ? trim((string) $body[$key]) : '';
        if ($v === '') {
            $this->_err('validation_error', 'Missing required field "' . $key . '".', 400);
        }
        return $v;
    }

    protected function _opt(array $body, $key, $default = null)
    {
        return array_key_exists($key, $body) && $body[$key] !== '' ? $body[$key] : $default;
    }

    /** Load a course (product) by SKU at the SG store, or not_found. */
    protected function _loadProductBySku($sku)
    {
        $id = Mage::getModel('catalog/product')->getIdBySku($sku);
        if (!$id) {
            $this->_err('not_found', 'No course with sku=' . $sku . ' on this site.', 404);
        }
        return Mage::getModel('catalog/product')->setStoreId(self::STORE_ID)->load($id);
    }

    /** Load a course_runs row by class_id (C######) or not_found. */
    protected function _loadRunByClassId($classId)
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $table    = $resource->getTableName('course_runs');
        $row = $read->fetchRow(
            "SELECT * FROM `{$table}` WHERE class_id = ? LIMIT 1",
            array($classId)
        );
        if (!$row) {
            $this->_err('not_found', 'No class with class_id=' . $classId . '.', 404);
        }
        return $row;
    }

    /** Count learners enrolled on a run. */
    protected function _enrolmentCount($runId)
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $table    = $resource->getTableName('course_run_enrolments');
        return (int) $read->fetchOne(
            "SELECT COUNT(*) FROM `{$table}` WHERE run_id = ?",
            array((int) $runId)
        );
    }
}
