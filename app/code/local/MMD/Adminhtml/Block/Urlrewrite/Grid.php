<?php
/**
 * URL Rewrite admin grid override.
 *
 * The stock grid sorts by `url_rewrite_id ASC` and paginates 20 at a time.
 * On a 130K+ row table that means an ops user always lands on the oldest
 * rewrites (least relevant — anything actionable is a recent custom rewrite)
 * and has to click through ~6500 pages of system rewrites to reach them.
 *
 * Two low-risk changes:
 *   1. Default sort = url_rewrite_id DESC  → newest first; same PK index,
 *      same query speed.
 *   2. Default page size = 50              → fewer page-flips on a big
 *      table (Magento's default is 20). 50 rows fits one screen scroll
 *      and roughly halves the total number of round-trips needed when
 *      scanning a range of recent IDs.
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
        $this->setDefaultLimit(50);
    }
}
