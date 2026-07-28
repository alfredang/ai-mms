<?php
/**
 * Compact override of the Search Terms grid. Replaces the stock multi-line
 * Store column (website / group / store-view stacked) with a single-line
 * Branch column ("Singapore", "Malaysia", ...) so each search term renders
 * on one row. Filters by the global Store View bar's ?store=N (universal
 * pattern — see backend-design skill, "Filtering contract").
 */
class MMD_Adminhtml_Block_Catalog_Search_Grid
    extends Mage_Adminhtml_Block_Catalog_Search_Grid
{
    public function __construct()
    {
        parent::__construct();
        // Latest terms first. updated_at is bumped every time the term is
        // searched, so this surfaces both newly-created and recently-reused
        // terms (stock default was query_id ASC — oldest first).
        $this->setDefaultSort('updated_at');
        $this->setDefaultDir('desc');

        // The stock grid persists the last-used sort in the admin session
        // (saveParametersInSession), and admin sessions here effectively
        // never expire — so a sort saved before this default existed keeps
        // overriding it forever. On a plain page load (no explicit ?sort=)
        // drop the remembered sort so latest-first always applies; a column
        // header click still sorts normally via its request param.
        if (!Mage::app()->getRequest()->getParam($this->getVarNameSort())) {
            $session = Mage::getSingleton('adminhtml/session');
            $session->unsetData($this->getId() . $this->getVarNameSort());
            $session->unsetData($this->getId() . $this->getVarNameDir());
        }
    }

    protected function _prepareCollection()
    {
        $collection = Mage::getModel('catalogsearch/query')->getResourceCollection();
        $this->setCollection($collection);
        return Mage_Adminhtml_Block_Widget_Grid::_prepareCollection();
    }

    protected function _beforeLoadCollection()
    {
        parent::_beforeLoadCollection();
        $storeId = (int) $this->getRequest()->getParam('store', 0);
        if ($storeId > 0 && $this->getCollection()) {
            $this->getCollection()->addStoreFilter($storeId);
        }

        // Free-text search via ?q= — driven by the custom search input
        // injected into .dcf-mag-bar (see catalog_search block in
        // sidebar-nav-v2.js). Matches against query_text, synonym_for
        // and redirect so a single search reaches every column the user
        // can scan visually. Wildcards both ends so partial matches
        // ("photo" hits "photoshop") work.
        $q = trim((string) $this->getRequest()->getParam('q', ''));
        if ($q !== '' && $this->getCollection()) {
            $like = '%' . $q . '%';
            // OpenMage / Magento 1 OR-filter syntax: parallel arrays —
            // first arg is the list of column names, second arg is the
            // matching list of condition specs. Generates
            // `WHERE (query_text LIKE ? OR synonym_for LIKE ? OR redirect LIKE ?)`.
            $this->getCollection()->addFieldToFilter(
                array('query_text', 'synonym_for', 'redirect'),
                array(
                    array('like' => $like),
                    array('like' => $like),
                    array('like' => $like),
                )
            );
        }
        return $this;
    }

    protected function _prepareColumns()
    {
        parent::_prepareColumns();

        if ($this->getColumn('store_id')) {
            $this->removeColumn('store_id');
        }

        if (!Mage::app()->isSingleStoreMode()) {
            // Branch column is informational only — the page is already scoped
            // by the global Store View bar (?store=N), so a per-column Branch
            // filter is redundant. 'filter' => false drops it from the Filters
            // panel while keeping the column visible in the grid.
            $this->addColumnAfter('store_id', array(
                'header'   => Mage::helper('catalog')->__('Branch'),
                'index'    => 'store_id',
                'renderer' => 'MMD_Adminhtml_Block_Widget_Grid_Column_Renderer_Branch',
                'sortable' => false,
                'filter'   => false,
            ), 'search_query');
        }

        // Drop the "Display in Suggested Terms" filter field (low signal). Its
        // filter block is built at column construction (setGrid → getFilter),
        // so a post-hoc setData('filter', false) is ignored — the column must
        // be rebuilt with 'filter' => false. Column stays visible in the grid;
        // only its filter input is removed.
        if ($this->getColumn('display_in_terms')) {
            $this->removeColumn('display_in_terms');
            $this->addColumnAfter('display_in_terms', array(
                'header'  => Mage::helper('catalog')->__('Display in Suggested Terms'),
                'index'   => 'display_in_terms',
                'type'    => 'options',
                'width'   => '100px',
                'options' => array(
                    '1' => Mage::helper('catalog')->__('Yes'),
                    '0' => Mage::helper('catalog')->__('No'),
                ),
                'align'   => 'left',
                'filter'  => false,
            ), 'redirect');
        }

        // Surface the sort key for the "latest first" default order. The
        // timestamp is stored in UTC (MySQL CURRENT_TIMESTAMP) — 'gmtoffset'
        // converts it to the admin locale timezone for display.
        $this->addColumnAfter('updated_at', array(
            'header'    => Mage::helper('catalog')->__('Last Searched'),
            'index'     => 'updated_at',
            'type'      => 'datetime',
            'gmtoffset' => true,
            'width'     => '160px',
            'filter'    => false,
        ), 'display_in_terms');

        // parent::_prepareColumns() ran sortColumnsByOrder() BEFORE our
        // addColumnAfter() calls above registered their order, so the
        // re-added columns would otherwise render appended at the end
        // (Branch after the Action column, etc). Re-sort now so Branch
        // sits after Search Query and Display-in-Suggested-Terms after
        // Redirect, with Action last.
        $this->sortColumnsByOrder();

        return $this;
    }

    /**
     * Stamp every Edit link with `?back=<urlencoded current listing URL>`.
     * The edit page injects that value into the save form as a hidden
     * input (see sidebar-nav-v2.js → "catalog_search edit page" block),
     * and MMD_Adminhtml_Catalog_SearchController::saveAction redirects
     * to it after the save.
     *
     * Why not use the admin session: it's shared across tabs, so
     * opening a second tab with a different ?store= overwrites the
     * stash and steers a save in the first tab to the wrong store
     * view. The per-request form-field round-trip is immune.
     */
    public function getRowUrl($row)
    {
        $back = (string) Mage::app()->getRequest()->getRequestUri();
        return $this->getUrl('*/*/edit', array(
            'id'     => $row->getId(),
            '_query' => array('back' => $back),
        ));
    }
}
