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

        // Per-rating columns are best-effort: if anything in the
        // join/inject path throws (missing rating tables in a fresh DB,
        // schema drift, oddly-shaped data), the grid itself must still
        // render. Log and bail.
        try {
            $this->_injectRatingValues();
        } catch (Exception $e) {
            Mage::logException($e);
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
}
