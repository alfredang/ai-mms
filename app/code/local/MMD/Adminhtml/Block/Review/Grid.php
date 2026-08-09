<?php
/**
 * Reviews & Ratings grid override.
 *
 * Reorders the columns and joins per-rating scores into the collection so
 * each rating question shows as its own column (1–5). Action column stays
 * `type => action` so it picks up the global MMD icon-button renderer.
 */
class MMD_Adminhtml_Block_Review_Grid extends Mage_Adminhtml_Block_Review_Grid
{
    /** @var array<int,string>|null cached rating_id => short label */
    protected $_ratings;

    /**
     * @return array<int,string>
     */
    protected function _getRatings()
    {
        if ($this->_ratings === null) {
            $this->_ratings = array();
            $collection = Mage::getModel('rating/rating')->getResourceCollection()
                ->setOrder('position', 'ASC');
            foreach ($collection as $rating) {
                $this->_ratings[(int) $rating->getId()] = $this->_shortRatingLabel(
                    $rating->getRatingCode(),
                    (int) $rating->getId()
                );
            }
        }
        return $this->_ratings;
    }

    /**
     * Heuristic: turn a long rating question into a 1–2 word column header.
     * Falls back to "Q{id}" when no keyword is found.
     */
    protected function _shortRatingLabel($code, $id)
    {
        $c = strtolower((string) $code);
        $map = array(
            'expect'   => 'Expectation',
            'trainer'  => 'Trainer',
            'knowledge'=> 'Trainer',
            'environment' => 'Environment',
            'venue'    => 'Venue',
            'material' => 'Material',
            'content'  => 'Content',
            'overall'  => 'Overall',
            'recommend'=> 'Recommend',
            'pace'     => 'Pace',
            'support'  => 'Support',
        );
        foreach ($map as $needle => $label) {
            if (strpos($c, $needle) !== false) {
                return $label;
            }
        }
        return 'Q' . $id;
    }

    protected function _prepareCollection()
    {
        parent::_prepareCollection();

        try {
            $this->_injectRatingValues();
        } catch (Exception $e) {
            Mage::logException($e);
        }
        return $this;
    }

    /**
     * Two jobs, both of which must happen BEFORE load():
     *
     * 1. Wire the Store View bar's ?store=N to actually filter the grid.
     *    Stock Mage_Adminhtml_Block_Review_Grid only joins store data for
     *    display (addStoreData) and never filters by ?store=. The grid's
     *    collection runs _applyStoresFilterToSelect during _beforeLoad, so
     *    the store id must be set before load() is called from
     *    Mage_Adminhtml_Block_Widget_Grid::_prepareCollection. This hook
     *    fires between filter setup and load().
     *
     * 2. Pull `review.is_featured` into the select so the Featured column can
     *    display, sort and filter. Unlike the per-rating values (separate
     *    table, stripped by the EAV collection's _loadEntities), is_featured
     *    is a real column on `rt` — the collection's own select — so adding
     *    it to the column list survives the load and filters work for free.
     */
    protected function _beforeLoadCollection()
    {
        parent::_beforeLoadCollection();

        $storeId = (int) $this->getRequest()->getParam('store', 0);
        if ($storeId > 0 && $this->getCollection()) {
            $this->getCollection()->addStoreFilter($storeId);
        }

        if ($this->getCollection()) {
            try {
                $this->getCollection()->getSelect()->columns('rt.is_featured');
            } catch (Exception $e) {
                Mage::logException($e);
            }
        }

        return $this;
    }

    protected function _injectRatingValues()
    {
        // The EAV product collection strips ad-hoc joined columns during
        // _loadEntities → setData, so a plain joinLeft() doesn't survive.
        // Instead, iterate the (already paginated/filtered) collection
        // and inject rating values per review in a single follow-up query.
        $collection = $this->getCollection();
        if (!$collection) {
            return;
        }
        if (method_exists($collection, 'isLoaded') && !$collection->isLoaded()) {
            $collection->load();
        }

        $reviewIds = array();
        foreach ($collection as $item) {
            $rid = (int) $item->getReviewId();
            if ($rid > 0) {
                $reviewIds[] = $rid;
            }
        }
        if (!$reviewIds) {
            return;
        }

        $ratingIds = array_keys($this->_getRatings());
        if (!$ratingIds) {
            return;
        }

        $conn = $collection->getConnection();
        $rows = $conn->fetchAll(
            $conn->select()
                ->from(
                    $collection->getTable('rating/rating_option_vote'),
                    array('review_id', 'rating_id', 'value')
                )
                ->where('review_id IN (?)', $reviewIds)
                ->where('rating_id IN (?)', $ratingIds)
        );
        $byReview = array();
        foreach ($rows as $r) {
            $byReview[(int) $r['review_id']]['rating_' . (int) $r['rating_id']] = (int) $r['value'];
        }
        foreach ($collection as $item) {
            $rid = (int) $item->getReviewId();
            if (isset($byReview[$rid])) {
                foreach ($byReview[$rid] as $k => $v) {
                    $item->setData($k, $v);
                }
            }
        }
    }

    protected function _prepareColumns()
    {
        parent::_prepareColumns();

        try {
            $this->_customiseColumns();
        } catch (Exception $e) {
            Mage::logException($e);
        }
        return $this;
    }

    protected function _customiseColumns()
    {
        // Rename existing columns
        if ($this->getColumn('title')) {
            $this->getColumn('title')->setHeader(Mage::helper('review')->__('Review Summary'));
        }
        if ($this->getColumn('name')) {
            $this->getColumn('name')->setHeader(Mage::helper('review')->__('Course Title'));
        }
        if ($this->getColumn('sku')) {
            $this->getColumn('sku')
                ->setHeader(Mage::helper('review')->__('Course Code'))
                ->setAlign('left');
        }
        if ($this->getColumn('visible_in')) {
            $this->getColumn('visible_in')
                ->setHeader(Mage::helper('review')->__('Branch'))
                ->setType('')
                ->setData('renderer', 'mmd/widget_grid_column_renderer_branch');
        }

        // Drop the 'Review' (detail) column — not in the requested order.
        if ($this->getColumn('detail')) {
            $this->removeColumn('detail');
        }

        // Featured flag — drives the storefront testimonials strip + page.
        // filter_condition_callback is REQUIRED: this grid runs on an EAV
        // product collection, whose addFieldToFilter() resolves the field as a
        // product attribute and throws "Invalid attribute name: is_featured".
        // The callback applies the condition straight to the select instead.
        $this->addColumn('is_featured', array(
            'header'   => Mage::helper('review')->__('Featured'),
            'align'    => 'center',
            'width'    => '80px',
            'index'    => 'is_featured',
            'type'     => 'options',
            'options'  => array(
                1 => Mage::helper('review')->__('Featured'),
                0 => Mage::helper('review')->__('No'),
            ),
            'renderer' => 'mmd/widget_grid_column_renderer_featured',
            'filter_condition_callback' => array($this, 'filterFeatured'),
        ));

        // Add a column per rating question.
        foreach ($this->_getRatings() as $ratingId => $label) {
            $code = 'rating_' . $ratingId;
            $this->addColumn($code, array(
                'header'    => $label,
                'align'     => 'center',
                'width'     => '60px',
                'index'     => $code,
                'type'      => 'number',
                'sortable'  => false,
                'filter'    => false,
            ));
        }

        // Reorder. Mage_Adminhtml_Block_Widget_Grid::sortColumnsByOrder uses
        // setColumnsOrder(after, target) — i.e. place `target` after `after`.
        $order = array(
            'review_id',
            'created_at',
            'nickname',
            'name',         // Course Title
            'sku',          // Course Code
            'title',        // Review Summary
        );
        foreach (array_keys($this->_getRatings()) as $ratingId) {
            $order[] = 'rating_' . $ratingId;
        }
        $order[] = 'visible_in';
        $order[] = 'type';
        $order[] = 'status';
        $order[] = 'is_featured';
        $order[] = 'action';

        // Re-sequence the _columns array in the desired order; anything
        // unlisted (e.g. mass-action checkbox) is appended afterwards.
        $sorted = array();
        foreach ($order as $col) {
            if (isset($this->_columns[$col])) {
                $sorted[$col] = $this->_columns[$col];
            }
        }
        foreach ($this->_columns as $id => $col) {
            if (!isset($sorted[$id])) {
                $sorted[$id] = $col;
            }
        }
        $this->_columns = $sorted;
        if ($sorted) {
            end($sorted);
            $this->_lastColumnId = key($sorted);
        }
    }

    /**
     * Filter callback for the Featured column — see the addColumn() note.
     *
     * @param Varien_Data_Collection_Db                $collection
     * @param Mage_Adminhtml_Block_Widget_Grid_Column  $column
     * @return $this
     */
    public function filterFeatured($collection, $column)
    {
        $value = $column->getFilter()->getValue();
        // '' / null means "no filter"; 0 is a legitimate value, so compare
        // against null explicitly rather than using empty().
        if ($value === null || $value === '') {
            return $this;
        }
        $collection->getSelect()->where('rt.is_featured = ?', (int) $value);
        return $this;
    }

    /**
     * Add the featured mass actions. Editing 22k reviews one at a time isn't
     * a workflow, so featuring is primarily a bulk operation from the grid.
     */
    protected function _prepareMassaction()
    {
        parent::_prepareMassaction();

        try {
            $this->getMassactionBlock()->addItem('mmd_feature', array(
                'label' => Mage::helper('review')->__('Mark as Featured'),
                'url'   => $this->getUrl('adminhtml/featured/massFeatured'),
            ));
            $this->getMassactionBlock()->addItem('mmd_unfeature', array(
                'label' => Mage::helper('review')->__('Remove from Featured'),
                'url'   => $this->getUrl('adminhtml/featured/massUnfeatured'),
            ));
        } catch (Exception $e) {
            Mage::logException($e);
        }

        return $this;
    }
}
