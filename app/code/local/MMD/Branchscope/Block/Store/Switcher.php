<?php
/**
 * Rewrites Magento's native admin store-switcher dropdown as a horizontal
 * pill strip. Every adminhtml page that already includes the switcher in
 * its layout XML (catalog, sales, customer, cms, etc.) now gets pills
 * instead — no per-page wiring needed.
 *
 * Public API (getStoreId / getStores / getWebsites / etc.) is inherited
 * unchanged so any external caller that probes the block keeps working.
 * Only _toHtml() is overridden.
 */
class MMD_Branchscope_Block_Store_Switcher extends Mage_Adminhtml_Block_Store_Switcher
{
    /**
     * Render the pill strip in place of the native <select> dropdown.
     *
     * @return string
     */
    protected function _toHtml()
    {
        if (Mage::app()->isSingleStoreMode()) {
            return '';
        }

        // Roles that don't get a branch switcher:
        //  - learner / trainer: scoped to their own registration country.
        //  - developer: course catalog is shared across all countries
        //    (one product = all branches), so a per-country pill is noise.
        //  - marketing: campaigns and newsletter content are authored
        //    cross-country; the operator doesn't pick a branch here.
        // Other roles (admin, training_provider, super admin) still see
        // the pills.
        try {
            $_activeRole = Mage::helper('mmd_rolemanager')->getActiveRoleCode();
            if (in_array($_activeRole, array('learner', 'trainer', 'developer', 'marketing'), true)) {
                return '';
            }
        } catch (Exception $e) { /* role helper unavailable — render normally */ }
          catch (Error $e)     { /* same */ }

        /** @var MMD_Branchscope_Helper_Data $helper */
        $helper = Mage::helper('branchscope');

        // The block is injected into the <default> layout handle so it
        // would otherwise render on every adminhtml page. Suppress on
        // non-store-scoped routes (Permissions, System → Cache, etc.).
        // Blocks placed explicitly by core layout XML (Catalog product
        // grid's nested store_switcher) still render — those callers
        // already opted in by including the block in their layout.
        if ($this->getNameInLayout() === 'mmd.branch.pills.global'
            && !$helper->isStoreScopedRoute()) {
            return '';
        }

        $activeId = $helper->getActiveStoreId();
        $options  = $helper->getStorePillOptions();

        $pills = '';
        foreach ($options as $opt) {
            $url    = $helper->buildPillUrl($opt['id']);
            $active = ((int) $opt['id'] === (int) $activeId) ? ' active' : '';
            $pills .= '<a href="' . $this->escapeHtml($url) . '"'
                   .  ' class="dev-country-btn' . $active . '"'
                   .  ' data-store-id="' . (int) $opt['id'] . '">'
                   .  $this->escapeHtml($opt['name'])
                   .  '</a>';
        }

        return '<div class="dev-country-tabs mmd-branchscope-pills">' . $pills . '</div>';
    }
}
