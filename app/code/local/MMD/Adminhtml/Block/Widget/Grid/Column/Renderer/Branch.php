<?php
/**
 * Renders a grid column of store-ids as a compact, comma-separated list of
 * branch (= website) names — e.g. "Singapore, Malaysia". Strips the
 * website/store-group/store-view hierarchy that the stock Store renderer
 * emits, since in this LMS each website maps 1:1 to a country branch.
 */
class MMD_Adminhtml_Block_Widget_Grid_Column_Renderer_Branch
    extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract
{
    public function render(Varien_Object $row)
    {
        $stores = $row->getData($this->getColumn()->getIndex());
        if (empty($stores)) {
            return '';
        }
        if (!is_array($stores)) {
            $stores = array($stores);
        }
        if (in_array(0, $stores) && count($stores) === 1) {
            return Mage::helper('adminhtml')->__('All Branches');
        }

        $names = array();
        foreach ($stores as $storeId) {
            if ((int) $storeId === 0) {
                continue;
            }
            $store = Mage::app()->getStore($storeId);
            if (!$store || !$store->getId()) {
                continue;
            }
            // Store view name → "Singapore Store View"; strip the suffix so
            // the grid shows the country/branch label only.
            $label = preg_replace('/\s*Store View\s*$/i', '', $store->getName());
            $names[$label] = $label;
        }
        if (!$names) {
            return '';
        }
        return Mage::helper('core')->escapeHtml(implode(', ', $names));
    }
}
