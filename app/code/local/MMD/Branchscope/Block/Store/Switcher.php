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

        // Country instances (MMS_MODE=country) only have one store view
        // configured — the Store View bar is meaningless and confusing there.
        if (getenv('MMS_MODE') === 'country') {
            return '';
        }

        // Roles that don't get a branch switcher:
        //  - learner / trainer: scoped to their own registration country.
        // Everyone else (developer, marketing, admin, super-admin) sees
        // the bar on store-scoped pages. NOTE: 'training_provider' is
        // the internal role code for Super Admin (see RoleManager
        // Helper/Data.php).
        $_activeRole = '';
        try {
            $_activeRole = (string) Mage::helper('mmd_rolemanager')->getActiveRoleCode();
            if (in_array($_activeRole, array('learner', 'trainer'), true)) {
                return '';
            }
        } catch (Exception $e) { /* role helper unavailable — render normally */ }
          catch (Error $e)     { /* same */ }

        // Branchscope rewrites adminhtml/store_switcher globally, so every
        // inline <block type="adminhtml/store_switcher" /> in catalog.xml /
        // sales.xml / report.xml / newsletter.xml / admin.xml ALSO ends up
        // as a MMD_Branchscope_Block_Store_Switcher and would render a
        // second pill bar + "Editing for/Viewing" notice on the same page.
        // The global instance ('mmd.branch.pills.global' from branchscope.xml)
        // is the single source of truth — every other instance renders empty.
        // Programmatic callers that read getStoreId() / getStores() off the
        // block keep working; only _toHtml() goes silent.
        if ($this->getNameInLayout() !== 'mmd.branch.pills.global') {
            return '';
        }

        /** @var MMD_Branchscope_Helper_Data $helper */
        $helper = Mage::helper('branchscope');

        // INVARIANT: the Store View bar + the "Viewing / Editing for"
        // header notice render on EVERY adminhtml page for the four
        // operator roles — developer, marketing, admin, super-admin
        // (internal code 'training_provider'). These users see the same
        // top chrome on Reports / Tax / Newsletter Templates / any
        // custom module, regardless of whether the underlying grid
        // actually filters by ?store=. Learner and trainer were already
        // excluded above.
        //
        // Detection-failure safety: if the role helper returned empty
        // (session not yet seeded, role row missing, helper exception),
        // default to TRUE so the bar stays visible rather than silently
        // disappearing. Hiding the bar is worse than showing it on a
        // page that may not filter — operators rely on it as the
        // "which country am I working in" anchor.
        $operatorRoles = array('developer', 'marketing', 'admin', 'training_provider');
        $isFullAdmin   = ($_activeRole === '')
            || in_array($_activeRole, $operatorRoles, true);

        // The block is injected into the <default> layout handle so it
        // would otherwise render on every adminhtml page. Suppress on
        // non-store-scoped routes (Permissions, System → Cache, etc.).
        // Blocks placed explicitly by core layout XML (Catalog product
        // grid's nested store_switcher) still render — those callers
        // already opted in by including the block in their layout.
        if (!$isFullAdmin
            && $this->getNameInLayout() === 'mmd.branch.pills.global'
            && !$helper->isStoreScopedRoute()) {
            return '';
        }

        // Manage Categories (catalog_category): catalog is shared across
        // all countries, the per-store category tree fetch already keys
        // off the native store switcher, and the extra pill row on top
        // of the tree was creating visual noise. Suppress for non-admin
        // roles (admins keep it as a global navigation aid).
        //
        // Manage Courses (?panel=courses) USED to be suppressed here
        // because the panel rendered its own inline country-pill strip.
        // That inline strip has been retired — the global Store View bar
        // is now the canonical selector for the course list too — so we
        // let it render here.
        if ($this->getNameInLayout() === 'mmd.branch.pills.global') {
            $_req = Mage::app()->getRequest();
            // Edit Course / Editing Course page renders its own inline
            // Store View bar (template/dashboard/index.phtml — preserves
            // course_id / mode / dev_back across switches). Suppress the
            // global bar here to avoid two stacked switchers.
            if ($_req->getRouteName() === 'adminhtml'
                && $_req->getControllerName() === 'dashboard'
                && $_req->getParam('course_id')
                && in_array((string) $_req->getParam('mode'), array('edit', 'editing'), true)) {
                return '';
            }
            // New product page: the ?store=X pill URL blanks the creation
            // form because Magento can't scope a not-yet-saved product to a
            // store view. Suppress pills here to prevent that breakage.
            if ($_req->getRouteName() === 'adminhtml'
                && $_req->getControllerName() === 'catalog_product'
                && $_req->getActionName() === 'new') {
                return '';
            }
            if (!$isFullAdmin
                && $_req->getRouteName() === 'adminhtml'
                && $_req->getControllerName() === 'catalog_category') {
                return '';
            }
        }

        // Same markup as Edit Course's inline Store View bar
        // (template/dashboard/index.phtml, .dcf-store-switcher) — same
        // class names so the page CSS (now hoisted to admin-dashboard.css)
        // styles both identically. Active storefront pills: SG / NG.
        // Admin store (id=0, "All") is excluded.
        $activeId = (int) $helper->getActiveStoreId();
        $options  = $helper->getCountryStorePillOptions();

        $pills = '';
        $activeName = '';
        $activeCode = '';
        foreach ($options as $opt) {
            $url   = $helper->buildPillUrl($opt['id']);
            $isAct = ((int) $opt['id'] === $activeId);
            if ($isAct) {
                $activeName = $opt['name'];
                $activeCode = $opt['code'];
            }
            $pills .= '<a class="dcf-store-tab' . ($isAct ? ' is-active' : '') . '"'
                   .  ' href="' . $this->escapeHtml($url) . '"'
                   .  ' role="tab" aria-selected="' . ($isAct ? 'true' : 'false') . '"'
                   .  ' data-store-id="' . (int) $opt['id'] . '"'
                   .  ' title="Switch to ' . $this->escapeHtml($opt['name']) . ' store view">'
                   .  '<span class="dcf-store-tab-flag">' . $this->escapeHtml($opt['code']) . '</span>'
                   .  '<span class="dcf-store-tab-name">' . $this->escapeHtml($opt['name']) . '</span>'
                   .  '</a>';
        }

        // Right-side "Viewing: <Country> XX" / "Editing: <Country> XX" pill
        // (formerly a second ribbon under the bar). Label flips to "Editing"
        // on record-edit / record-new pages so the band stays honest about
        // which mode the operator is in. Replaces the old "Scope" hint.
        $req       = Mage::app()->getRequest();
        $actionN   = strtolower((string) $req->getActionName());
        $editActs  = array('edit', 'new', 'save', 'editpost', 'newpost');
        $isEditing = in_array($actionN, $editActs, true)
            || $req->getParam('course_id')
            || in_array((string) $req->getParam('mode'), array('edit', 'editing'), true);
        $label     = $isEditing ? 'Editing:' : 'Viewing:';

        $activePill = '';
        if ($activeName !== '') {
            $activePill = '<span class="dcf-active-store-pill"'
                . ' title="Store-view-scoped fields on this page apply to this country. Switch via the Store View tabs.">'
                . '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">'
                . '<circle cx="12" cy="12" r="10"/><path d="M2 12h20"/>'
                . '<path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>'
                . $this->escapeHtml($label) . ' <strong>' . $this->escapeHtml($activeName) . '</strong>'
                . '<span class="dcf-active-store-code">' . $this->escapeHtml($activeCode) . '</span>'
                . '</span>';
        }

        $bar = '<div class="dcf-store-switcher mmd-branchscope-pills"'
            . ' role="tablist" aria-label="Store view">'
            . '<span class="dcf-store-switcher-label">Store View:</span>'
            . $pills
            . $activePill
            . '</div>';

        return $bar;
    }
}
