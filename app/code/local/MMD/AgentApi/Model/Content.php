<?php
/**
 * Capability: marketing / content updates.
 *
 *   op: update_copy  { sku, fields: { description|short_description|meta_title|meta_description } }
 *   op: set_badges   { sku, badges: [ "WSQ", "UTAP", ... ] }   (canonical 9 only)
 *   op: set_cms_section  - surfaced but not yet implemented (needs the per-course
 *                          CMS-section mechanism; returns not_implemented).
 *
 * Product reviews are created through the separate existing review API
 * (POST /kael_review_api.php), not here.
 */
class MMD_AgentApi_Model_Content extends MMD_AgentApi_Model_Abstract
{
    protected $_copyFields = array('description', 'short_description', 'meta_title', 'meta_description');

    public function preview($op, array $body)
    {
        switch ($op) {
            case 'update_copy': return $this->_previewCopy($body);
            case 'set_badges':  return $this->_previewBadges($body);
            case 'set_cms_section':
                $this->_err('not_implemented', 'set_cms_section is not implemented yet.', 501);
            default:
                $this->_err('validation_error', 'Unsupported op "' . $op . '" for api_content.', 400);
        }
    }

    public function commit($op, array $body, array $preview)
    {
        if ($op === 'update_copy') {
            $sku = $preview['target'];
            $id  = Mage::getModel('catalog/product')->getIdBySku($sku);
            if (!$id) {
                $this->_err('not_found', 'No course with sku=' . $sku . '.', 404);
            }
            // Targeted attribute write at default scope. Avoids the full
            // $product->save(), which trips a PHP 8 foreach(null) in core when
            // run outside adminhtml (Mage_Eav_Model_Entity_Abstract::1141).
            Mage::getSingleton('catalog/product_action')
                ->updateAttributes(array($id), $preview['token_payload']['new'], 0);
            return array('target' => $sku, 'reindexed' => array('product_attributes'),
                'after' => $preview['token_payload']['new']);
        }
        // set_badges
        $product = $this->_loadProductBySku($preview['target']);
        Mage::helper('mmd_courseimage')->syncProductTags($product, $preview['token_payload']['badges']);
        return array('target' => $preview['target'], 'reindexed' => array('tags'),
            'after' => array('badges' => $preview['token_payload']['badges']),
            'extra' => array('note' => 'Storefront chips updated. Run api_ops regenerate_image to refresh the cover image.'));
    }

    /* ---- update_copy ---- */

    protected function _previewCopy(array $body)
    {
        $sku    = $this->_require($body, 'sku');
        $fields = isset($body['fields']) && is_array($body['fields']) ? $body['fields'] : array();
        if (!$fields) {
            $this->_err('validation_error', 'Provide at least one copy field in "fields".', 400);
        }
        $product = $this->_loadAdmin($sku);
        $diff = array(); $new = array(); $cur = array();
        foreach ($fields as $key => $value) {
            if (!in_array($key, $this->_copyFields, true)) {
                $this->_err('forbidden_field', 'Field "' . $key . '" is not an editable copy field.', 422);
            }
            $val = (string) $value;
            $old = (string) $product->getData($key);
            $new[$key] = $val; $cur[$key] = $old;
            if ($val !== $old) {
                $diff[] = array('field' => $key, 'from' => $this->_truncate($old), 'to' => $this->_truncate($val));
            }
        }
        if (!$diff) {
            $this->_err('validation_error', 'No changes - the supplied copy already matches.', 400);
        }
        return array(
            'target'        => $sku,
            'diff'          => $diff,
            'human_summary' => 'Course ' . $product->getSku() . ' (' . $product->getName() . '): update '
                                . implode(', ', array_column($diff, 'field')) . '.',
            'warnings'      => array(),
            'token_payload' => array('sku' => $sku, 'new' => $new, 'current' => $cur),
        );
    }

    /* ---- set_badges ---- */

    protected function _previewBadges(array $body)
    {
        $sku = $this->_require($body, 'sku');
        if (!isset($body['badges']) || !is_array($body['badges'])) {
            $this->_err('validation_error', 'Provide "badges" as an array of canonical badge names.', 400);
        }
        $allowed = Mage::helper('mmd_courseimage')->getAllBadges();
        $desired = array();
        foreach ($body['badges'] as $b) {
            $b = trim((string) $b);
            if ($b === '') { continue; }
            if (!in_array($b, $allowed, true)) {
                $this->_err('validation_error', 'Unknown badge "' . $b . '". Allowed: ' . implode(', ', $allowed) . '.', 400);
            }
            if (!in_array($b, $desired, true)) { $desired[] = $b; }
        }
        $product = $this->_loadProductBySku($sku);
        $current = Mage::helper('mmd_courseimage')->getProductBadges($product);

        $curSort = $current; sort($curSort);
        $newSort = $desired; sort($newSort);
        if ($curSort === $newSort) {
            $this->_err('validation_error', 'No change - the course already has exactly those badges.', 400);
        }
        return array(
            'target'        => $sku,
            'diff'          => array(array('field' => 'badges', 'from' => $current, 'to' => $desired)),
            'human_summary' => 'Course ' . $product->getSku() . ' (' . $product->getName() . ') badges: ['
                                . implode(', ', $current) . '] -> [' . implode(', ', $desired) . '].',
            'warnings'      => array(),
            'token_payload' => array('sku' => $sku, 'badges' => $desired, 'current' => $curSort),
        );
    }

    protected function _loadAdmin($sku)
    {
        $id = Mage::getModel('catalog/product')->getIdBySku($sku);
        if (!$id) {
            $this->_err('not_found', 'No course with sku=' . $sku . '.', 404);
        }
        return Mage::getModel('catalog/product')->setStoreId(0)->load($id);
    }

    protected function _truncate($s, $len = 60)
    {
        $s = (string) $s;
        return strlen($s) > $len ? substr($s, 0, $len) . '...' : $s;
    }
}
