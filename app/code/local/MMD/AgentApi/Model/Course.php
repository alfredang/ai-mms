<?php
/**
 * Capability: update course info.
 *
 *   op: update  { sku, fields: { <allowlisted>: value, ... } }
 *
 * Default-deny field allowlist - anything not listed (notably `name`, `sku`,
 * and every GST/tax/funding field) is refused with forbidden_field. Saves at
 * admin (default) scope; on a single-store site that is the effective value.
 */
class MMD_AgentApi_Model_Course extends MMD_AgentApi_Model_Abstract
{
    /** Editable fields -> product attribute code (category_ids handled specially). */
    protected $_allow = array(
        'description'      => 'description',
        'short_description'=> 'short_description',
        'price'            => 'price',
        'special_price'    => 'special_price',
        'meta_title'       => 'meta_title',
        'meta_description' => 'meta_description',
        'status'           => 'status',
        'url_key'          => 'url_key',
        'category_ids'     => 'category_ids',
    );

    public function preview($op, array $body)
    {
        if ($op !== 'update') {
            $this->_err('validation_error', 'Unsupported op "' . $op . '" for api_course.', 400);
        }
        $sku    = $this->_require($body, 'sku');
        $fields = isset($body['fields']) && is_array($body['fields']) ? $body['fields'] : array();
        if (!$fields) {
            $this->_err('validation_error', 'Provide at least one field to update in "fields".', 400);
        }

        $product = $this->_loadAdmin($sku);
        $diff = array();
        $normalized = array();
        $current = array();

        foreach ($fields as $key => $value) {
            if (!isset($this->_allow[$key])) {
                $this->_err('forbidden_field',
                    'Field "' . $key . '" cannot be changed via the agent API (name, sku, GST/funding and unknown fields are blocked).', 422);
            }
            list($new, $old, $display) = $this->_normalize($key, $value, $product);
            $normalized[$key] = $new;
            $current[$key]    = $old;
            if ((string) json_encode($new) !== (string) json_encode($old)) {
                $diff[] = array('field' => $key, 'from' => $display['from'], 'to' => $display['to']);
            }
        }

        if (!$diff) {
            $this->_err('validation_error', 'No changes - the supplied values already match the course.', 400);
        }

        $summary = $this->_summary($product, $diff);
        return array(
            'target'        => $sku,
            'diff'          => $diff,
            'human_summary' => $summary,
            'warnings'      => array(),
            'token_payload' => array('sku' => $sku, 'new' => $normalized, 'current' => $current),
        );
    }

    public function commit($op, array $body, array $preview)
    {
        $sku = $preview['target'];
        $new = $preview['token_payload']['new'];
        $id  = Mage::getModel('catalog/product')->getIdBySku($sku);
        if (!$id) {
            $this->_err('not_found', 'No course with sku=' . $sku . '.', 404);
        }

        // Split scalar attributes from the category assignment. We deliberately
        // avoid a full $product->save(): run outside adminhtml it trips a PHP 8
        // foreach(null) warning in core (Mage_Eav_Model_Entity_Abstract::1141)
        // which the error handler promotes to a fatal. Targeted resource writes
        // update only what changed and are safe from a front controller.
        $scalars = array();
        $catIds  = null;
        foreach ($new as $key => $value) {
            if ($key === 'category_ids') {
                $catIds = $value;
            } else {
                $scalars[$this->_allow[$key]] = $value;
            }
        }

        $reindexed = array();
        if ($scalars) {
            Mage::getSingleton('catalog/product_action')->updateAttributes(array($id), $scalars, 0);
            $reindexed[] = 'product_attributes';
        }
        if ($catIds !== null) {
            $this->_assignCategories($id, $catIds);
            $reindexed[] = 'category_products';
        }

        return array(
            'target'    => $sku,
            'reindexed' => $reindexed,
            'after'     => $new,
        );
    }

    /**
     * Set the product's category membership to exactly $categoryIds via the
     * category_product link table (add missing, drop removed) and flag the
     * category/product index for reindex - a targeted alternative to the full
     * product save that _saveCategories() would normally piggyback on.
     */
    protected function _assignCategories($productId, array $categoryIds)
    {
        $resource = Mage::getSingleton('core/resource');
        $write    = $resource->getConnection('core_write');
        $table    = $resource->getTableName('catalog/category_product');

        $existing = array_map('intval', $write->fetchCol(
            $write->select()->from($table, 'category_id')->where('product_id = ?', (int) $productId)
        ));
        $desired  = array_values(array_unique(array_map('intval', $categoryIds)));
        $toAdd    = array_diff($desired, $existing);
        $toRemove = array_diff($existing, $desired);

        if ($toRemove) {
            $write->delete($table, array(
                'product_id = ?'     => (int) $productId,
                'category_id IN (?)' => array_values($toRemove),
            ));
        }
        foreach ($toAdd as $catId) {
            $write->insert($table, array(
                'category_id' => (int) $catId,
                'product_id'  => (int) $productId,
                'position'    => 0,
            ));
        }
        Mage::getSingleton('index/indexer')->getProcessByCode('catalog_category_product')
            ->changeStatus(Mage_Index_Model_Process::STATUS_REQUIRE_REINDEX);
    }

    /** Load at admin (default) scope so writes land on the global value. */
    protected function _loadAdmin($sku)
    {
        $id = Mage::getModel('catalog/product')->getIdBySku($sku);
        if (!$id) {
            $this->_err('not_found', 'No course with sku=' . $sku . '.', 404);
        }
        return Mage::getModel('catalog/product')->setStoreId(0)->load($id);
    }

    /**
     * Normalise one field -> [newValue, currentValue, {from,to} display].
     */
    protected function _normalize($key, $value, $product)
    {
        switch ($key) {
            case 'status':
                $new = $this->_statusInt($value);
                $old = (int) $product->getStatus();
                return array($new, $old, array('from' => $this->_statusLabel($old), 'to' => $this->_statusLabel($new)));
            case 'price':
            case 'special_price':
                $new = round((float) $value, 2);
                $old = $product->getData($key) === null ? null : round((float) $product->getData($key), 2);
                return array($new, $old, array('from' => $old, 'to' => $new));
            case 'category_ids':
                $new = array_values(array_unique(array_map('intval', (array) $value)));
                sort($new);
                $old = array_values(array_map('intval', (array) $product->getCategoryIds()));
                sort($old);
                return array($new, $old, array('from' => $old, 'to' => $new));
            default:
                $new = (string) $value;
                $old = (string) $product->getData($this->_allow[$key]);
                return array($new, $old, array('from' => $this->_truncate($old), 'to' => $this->_truncate($new)));
        }
    }

    protected function _statusInt($value)
    {
        $v = strtolower(trim((string) $value));
        if ($v === 'enabled' || $v === 'enable' || $v === '1') {
            return Mage_Catalog_Model_Product_Status::STATUS_ENABLED;
        }
        if ($v === 'disabled' || $v === 'disable' || $v === '2') {
            return Mage_Catalog_Model_Product_Status::STATUS_DISABLED;
        }
        $this->_err('validation_error', 'status must be "enabled" or "disabled".', 400);
    }

    protected function _statusLabel($int)
    {
        return ((int) $int === Mage_Catalog_Model_Product_Status::STATUS_ENABLED) ? 'enabled' : 'disabled';
    }

    protected function _truncate($s, $len = 60)
    {
        $s = (string) $s;
        return strlen($s) > $len ? substr($s, 0, $len) . '...' : $s;
    }

    protected function _summary($product, array $diff)
    {
        $parts = array();
        foreach ($diff as $d) {
            $from = is_array($d['from']) ? json_encode($d['from']) : $d['from'];
            $to   = is_array($d['to'])   ? json_encode($d['to'])   : $d['to'];
            $parts[] = $d['field'] . ': ' . ($from === '' ? '(empty)' : $from) . ' -> ' . ($to === '' ? '(empty)' : $to);
        }
        return 'Course ' . $product->getSku() . ' (' . $product->getName() . '): ' . implode('; ', $parts) . '.';
    }
}
