<?php
/**
 * Capability: website / MMS operations.
 *
 *   op: reindex        { indexes: ["catalog_product_flat", ...] | "all" }
 *   op: flush_cache
 *   op: enable         { sku }
 *   op: disable        { sku }
 *   op: regenerate_image  - surfaced, not implemented (needs the CourseImage render entrypoint)
 *   op: run_class_formation - surfaced, not implemented (materialisation is cron-driven)
 *
 * These are deliberate, agent-invoked maintenance actions. reindex / flush are
 * heavy - the agent should confirm with the user first (the standard preview->
 * commit flow does this).
 */
class MMD_AgentApi_Model_Ops extends MMD_AgentApi_Model_Abstract
{
    protected $_indexWhitelist = array(
        'catalog_product_flat', 'catalog_category_flat', 'catalog_product_price',
        'catalog_url', 'catalog_product_attribute', 'catalog_category_product',
        'catalogsearch_fulltext', 'tag_summary',
    );

    public function preview($op, array $body)
    {
        switch ($op) {
            case 'reindex':     return $this->_previewReindex($body);
            case 'flush_cache': return $this->_previewFlush();
            case 'enable':      return $this->_previewStatus($body, true);
            case 'disable':     return $this->_previewStatus($body, false);
            case 'regenerate_image':
                $this->_err('not_implemented', 'regenerate_image is not implemented yet.', 501);
            case 'run_class_formation':
                $this->_err('not_implemented', 'run_class_formation is cron-driven and not exposed yet.', 501);
            default:
                $this->_err('validation_error', 'Unsupported op "' . $op . '" for api_ops.', 400);
        }
    }

    public function commit($op, array $body, array $preview)
    {
        switch ($op) {
            case 'reindex':     return $this->_commitReindex($preview);
            case 'flush_cache': return $this->_commitFlush();
            case 'enable':      return $this->_commitStatus($preview, true);
            case 'disable':     return $this->_commitStatus($preview, false);
            default:
                $this->_err('validation_error', 'Unsupported op "' . $op . '" for api_ops.', 400);
        }
    }

    /* ---- reindex ---- */

    protected function _previewReindex(array $body)
    {
        $raw = $this->_opt($body, 'indexes', 'all');
        if ($raw === 'all') {
            $codes = $this->_indexWhitelist;
        } else {
            $codes = array();
            foreach ((array) $raw as $c) {
                $c = trim((string) $c);
                if (!in_array($c, $this->_indexWhitelist, true)) {
                    $this->_err('validation_error', 'Unknown index "' . $c . '". Allowed: '
                        . implode(', ', $this->_indexWhitelist) . ', or "all".', 400);
                }
                $codes[] = $c;
            }
        }
        $codes = array_values(array_unique($codes));
        sort($codes);
        return array(
            'target'        => 'reindex',
            'diff'          => array(array('field' => 'indexes', 'from' => null, 'to' => $codes)),
            'human_summary' => 'Will reindex: ' . implode(', ', $codes) . '. This can be slow on a large catalogue.',
            'warnings'      => array('Reindexing is resource-intensive.'),
            'token_payload' => array('op' => 'reindex', 'indexes' => $codes),
        );
    }

    protected function _commitReindex(array $preview)
    {
        $codes   = $preview['token_payload']['indexes'];
        $indexer = Mage::getSingleton('index/indexer');
        $done = array();
        foreach ($codes as $code) {
            $process = $indexer->getProcessByCode($code);
            if ($process) {
                $process->reindexEverything();
                $done[] = $code;
            }
        }
        return array('target' => 'reindex', 'reindexed' => $done, 'after' => array('indexes' => $done));
    }

    /* ---- flush_cache ---- */

    protected function _previewFlush()
    {
        return array(
            'target'        => 'cache',
            'diff'          => array(array('field' => 'cache', 'from' => null, 'to' => 'flushed')),
            'human_summary' => 'Will flush all Magento caches on this site.',
            'warnings'      => array('The next few page loads will be slower while caches warm.'),
            'token_payload' => array('op' => 'flush_cache'),
        );
    }

    protected function _commitFlush()
    {
        Mage::app()->cleanCache();
        Mage::app()->getCacheInstance()->flush();
        return array('target' => 'cache', 'reindexed' => array(), 'after' => array('cache' => 'flushed'));
    }

    /* ---- enable / disable ---- */

    protected function _previewStatus(array $body, $enable)
    {
        $sku     = $this->_require($body, 'sku');
        $product = $this->_loadAdmin($sku);
        $cur     = (int) $product->getStatus();
        $target  = $enable ? Mage_Catalog_Model_Product_Status::STATUS_ENABLED
                           : Mage_Catalog_Model_Product_Status::STATUS_DISABLED;
        if ($cur === $target) {
            $this->_err('validation_error', 'Course is already ' . ($enable ? 'enabled' : 'disabled') . '.', 400);
        }
        return array(
            'target'        => $sku,
            'diff'          => array(array('field' => 'status',
                'from' => ($cur === 1 ? 'enabled' : 'disabled'), 'to' => ($enable ? 'enabled' : 'disabled'))),
            'human_summary' => 'Course ' . $sku . ' (' . $product->getName() . ') will be '
                                . ($enable ? 'ENABLED (shown on storefront)' : 'DISABLED (hidden from storefront)') . '.',
            'warnings'      => $enable ? array() : array('Disabling hides the course from the storefront.'),
            'token_payload' => array('sku' => $sku, 'status' => $target, 'current' => $cur),
        );
    }

    protected function _commitStatus(array $preview, $enable)
    {
        $sku = $preview['target'];
        $id  = Mage::getModel('catalog/product')->getIdBySku($sku);
        if (!$id) {
            $this->_err('not_found', 'No course with sku=' . $sku . '.', 404);
        }
        // Targeted status write at default scope - avoids the full
        // $product->save() PHP 8 foreach(null) fatal (see Course::commit).
        Mage::getSingleton('catalog/product_action')
            ->updateAttributes(array($id), array('status' => $preview['token_payload']['status']), 0);
        return array('target' => $sku, 'reindexed' => array('product_attributes'),
            'after' => array('status' => ($enable ? 'enabled' : 'disabled')));
    }

    protected function _loadAdmin($sku)
    {
        $id = Mage::getModel('catalog/product')->getIdBySku($sku);
        if (!$id) {
            $this->_err('not_found', 'No course with sku=' . $sku . '.', 404);
        }
        return Mage::getModel('catalog/product')->setStoreId(0)->load($id);
    }
}
