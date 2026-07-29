<?php
class MMD_Enhancedsalesgrid_Block_Sales_Order extends Mage_Adminhtml_Block_Sales_Order
{
    public function __construct()
    {
        parent::__construct();

        $this->_blockGroup = 'enhancedsalesgrid';
        // Rendered as the .dcf-mag-bar title (with the auto-injected
        // page-title icon) on the index route; other sales_order* routes
        // still hide the bar span via CSS (dark-theme.css, the
        // body[...sales_order] .dcf-mag-bar > span:first-child rule).
        $this->_headerText = Mage::helper('sales')->__('Total Registrations');
        $this->_addButtonLabel = Mage::helper('sales')->__('Create New Registration');
    }

    /**
     * Inject a compact toolbar — Search input + Reset + Filters toggle —
     * and relocate it via JS into the grid's existing header strip (the
     * gray bar that shows the "Total Registrations" title + "New
     * Registration"). One consolidated row, no separate cards above the
     * grid. The registration counts live in the KPI cards above.
     *
     * Branch pills are no longer rendered here — the global MMD_Branchscope
     * store_switcher block (injected via branchscope.xml's <default> handle)
     * provides them, reading ?store=N. Filtering is wired in
     * MMD_Enhancedsalesgrid_Model_Observer::salesOrderGridCollectionLoadBefore.
     */
    public function getGridHtml()
    {
        $req     = $this->getRequest();
        $baseUrl = $this->getUrl('*/*/index');
        $q       = (string) $req->getParam('q', '');

        /** @var MMD_Branchscope_Helper_Data $branch */
        $branch    = Mage::helper('branchscope');
        $activeStoreId = (int) $branch->getActiveStoreId();

        // Registration KPIs for the current store (no other filters).
        // created_at is stored in UTC; day boundaries are computed in the
        // admin timezone (Asia/Singapore) so "Today" flips at local midnight.
        $tz = new DateTimeZone(Mage::getStoreConfig('general/locale/timezone') ?: 'UTC');
        $utc = new DateTimeZone('UTC');
        $todayStart = new DateTime('now', $tz);
        $todayStart->setTime(0, 0, 0);
        $weekStart = clone $todayStart;
        $weekStart->modify('-6 days'); // last 7 days = today + 6 preceding days

        $read  = Mage::getSingleton('core/resource')->getConnection('core_read');
        $select = $read->select()->from(
            Mage::getSingleton('core/resource')->getTableName('sales/order_grid'),
            array(
                'total' => 'COUNT(*)',
                'last7' => new Zend_Db_Expr('SUM(created_at >= '
                    . $read->quote($weekStart->setTimezone($utc)->format('Y-m-d H:i:s')) . ')'),
                'today' => new Zend_Db_Expr('SUM(created_at >= '
                    . $read->quote($todayStart->setTimezone($utc)->format('Y-m-d H:i:s')) . ')'),
            )
        );
        if ($activeStoreId > 0) {
            $select->where('store_id = ?', $activeStoreId);
        }
        $kpi   = $read->fetchRow($select);
        $total = (int) $kpi['total'];

        $searchIcon = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" '
                    . 'stroke="currentColor" stroke-width="2">'
                    . '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>';

        // KPI cards — same .trn-kpi-* component as Manage Courses / Learners /
        // Trainers (admin-dashboard.css, loaded globally). Rendered before the
        // grid wrapper, so wrapMmdGridInCard() inserts the grid card below them.
        $html  = '<div class="trn-kpi-grid">';
        $html .= '<div class="trn-kpi-card"><div class="trn-kpi-num blue">' . number_format($total)
              .  '</div><div class="trn-kpi-lbl">' . Mage::helper('sales')->__('Total Registrations') . '</div></div>';
        $html .= '<div class="trn-kpi-card"><div class="trn-kpi-num green">' . number_format((int) $kpi['last7'])
              .  '</div><div class="trn-kpi-lbl">' . Mage::helper('sales')->__('Registrations — Last 7 Days') . '</div></div>';
        $html .= '<div class="trn-kpi-card"><div class="trn-kpi-num pink">' . number_format((int) $kpi['today'])
              .  '</div><div class="trn-kpi-lbl">' . Mage::helper('sales')->__('Registrations Today') . '</div></div>';
        $html .= '</div>';

        // Build the consolidated toolbar in a hidden staging container.
        // A small inline script then moves it into the grid's page-header
        // strip so "Registrations" + "New Registration" share the row
        // with Total + Search + Filters.
        $html .= '<div class="mmd-reg-staging" style="display:none;">';
        $html .= '<form method="get" action="' . $baseUrl . '" class="mmd-reg-search-form">';
        $html .= '<input type="hidden" name="store" value="' . (int) $activeStoreId . '" />';
        $html .= '<div class="mmd-reg-search-input-wrap">' . $searchIcon
              .  '<input type="text" name="q" class="mmd-reg-search-input" '
              .  'placeholder="' . Mage::helper('sales')->__('Search Reg #, learner name, email, or course') . '" '
              .  'value="' . $this->escapeHtml($q) . '" autocomplete="off" />'
              .  '</div>';
        $html .= '<a class="mmd-reg-reset" href="' . $baseUrl . '?store=' . (int) $activeStoreId . '">'
              .  Mage::helper('sales')->__('Reset') . '</a>';
        $html .= '<span class="mmd-reg-filter-slot"></span>';
        $html .= '</form>';
        $html .= '</div>';

        // Relocate the staged toolbar + the auto-injected filter toggle
        // into the .dcf-mag-bar that wrapAdminGridInCard() in
        // sidebar-nav-v2.js builds around the grid. The bar appears
        // AFTER our inline script runs (the wrap happens at DOM-ready),
        // so we keep observing the body until both exist, then move
        // the toolbar in between the title span (hidden via CSS) and
        // the form buttons (Add New / New Registration). Always
        // continue observing — don't disconnect on the first success
        // because the filter toggle is injected by buildFilterPanels()
        // even later than wrapAdminGridInCard().
        $html .= '<script>'
              .  '(function(){'
              .  '  function relocate(){'
              .  '    var staging = document.querySelector(".mmd-reg-staging");'
              .  '    if (!staging) return;'
              .  '    var bar = document.querySelector(".dcf-mag-bar");'
              .  '    if (!bar) return;'
              .  '    var toolbar = bar.querySelector(".mmd-reg-toolbar");'
              .  '    if (!toolbar) {'
              .  '      toolbar = document.createElement("div");'
              .  '      toolbar.className = "mmd-reg-toolbar";'
              .  '      while (staging.firstChild) toolbar.appendChild(staging.firstChild);'
              .  '      var actions = bar.querySelector(".mmd-auto-card-actions");'
              .  '      if (actions) {'
              .  '        bar.insertBefore(toolbar, actions);'
              .  '      } else {'
              .  '        bar.appendChild(toolbar);'
              .  '      }'
              .  '    }'
              .  '    var slot = toolbar.querySelector(".mmd-reg-filter-slot");'
              .  '    var toggle = document.querySelector(".advanced-filter-toggle");'
              .  '    if (slot && toggle && toggle.parentNode !== slot) slot.appendChild(toggle);'
              .  '  }'
              .  '  relocate();'
              .  '  var obs = new MutationObserver(function(){ relocate(); });'
              .  '  obs.observe(document.body, {childList:true, subtree:true});'
              .  '  setTimeout(function(){ obs.disconnect(); }, 15000);'
              .  '})();'
              .  '</script>';

        return $html . parent::getGridHtml();
    }
}
