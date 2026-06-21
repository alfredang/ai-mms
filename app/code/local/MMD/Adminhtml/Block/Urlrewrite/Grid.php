<?php
/**
 * URL Rewrite admin grid override.
 *
 * The stock grid sorts by `url_rewrite_id ASC` and paginates 20 at a time.
 * On a 50K+ row table that means an ops user always lands on the oldest
 * (auto-generated, least relevant) rewrites and has to click through
 * hundreds of pages to reach anything actionable.
 *
 * Profiling locally showed the cost is dominated by PHP per-row column
 * rendering in Mage_Adminhtml_Block_Widget_Grid::_toHtml() — roughly
 * 5ms × N rows. SQL load + getStoresStructure are negligible. So the
 * effective lever is page size, not query tuning.
 *
 * Changes:
 *   1. Default sort = url_rewrite_id DESC  → newest first; same PK index,
 *      same query speed.
 *   2. Default page size = 25              → renders in ~1-2s on prod
 *      (vs ~13s at 200/page). Pairs with the CSS rule in
 *      admin-dashboard.css that hides the "200" option in the page-size
 *      dropdown on this route — keeps the worst case off the table.
 *
 * Wired via config.xml:
 *   <adminhtml><rewrite><urlrewrite_grid>MMD_Adminhtml_Block_Urlrewrite_Grid…
 */
class MMD_Adminhtml_Block_Urlrewrite_Grid extends Mage_Adminhtml_Block_Urlrewrite_Grid
{
    public function __construct()
    {
        parent::__construct();
        $this->setDefaultDir('DESC');
        $this->setDefaultLimit(25);
    }
}
