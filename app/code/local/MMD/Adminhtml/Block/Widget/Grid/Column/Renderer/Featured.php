<?php
/**
 * Renders the All Reviews "Featured" flag as a status pill.
 *
 * Reuses the existing `.grid-severity-notice` class so the badge inherits the
 * global §19 pill treatment in dark-theme.css (tinted fill + ring, 999px
 * radius) rather than introducing a one-off badge style. Unfeatured rows show
 * a muted dash — a "No" pill on 22k rows would be pure visual noise.
 */
class MMD_Adminhtml_Block_Widget_Grid_Column_Renderer_Featured
    extends Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract
{
    public function render(Varien_Object $row)
    {
        $value = (int) $row->getData($this->getColumn()->getIndex());
        if ($value !== 1) {
            return '<span style="color:#6b7a90;">&ndash;</span>';
        }
        return '<span class="grid-severity-notice"><span>'
            . Mage::helper('review')->__('Featured')
            . '</span></span>';
    }
}
