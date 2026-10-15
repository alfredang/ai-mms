<?php
/**
 * Manage Class Schedule → Schedule Distribution.
 *
 * Read-only report: how ACTIVE courses are spread over the schedule
 * templates per duration series (A = 1 day … E = 5 days), how often each
 * template actually runs (future "Course Date" values), and a set of
 * rebalancing recommendations. Nothing here writes — every suggested move
 * is applied by an operator through the normal template switch.
 */
class MMD_Adminhtml_Block_Customoptions_Distribution extends Mage_Adminhtml_Block_Template
{
    /** Window used to measure how often a template runs. */
    const RUN_WINDOW_DAYS = 90;
    /** Window used to measure course demand (registrations). */
    const DEMAND_MONTHS = 12;
    /** Cap on suggested moves per duration series. */
    const MAX_MOVES_PER_SERIES = 8;

    protected $_report;

    public function getTypeFilter()
    {
        $t = (string) $this->getRequest()->getParam('type', '');
        return isset($this->getTypeOptions()[$t]) ? $t : '';
    }

    public function getTypeOptions()
    {
        return MMD_Adminhtml_Block_Customoptions_Options_Grid::getScheduleTypeOptions();
    }

    public function getLetters()
    {
        $opts = MMD_Adminhtml_Block_Customoptions_Options_Grid::getDurationOptions();
        unset($opts['X']);
        return $opts;
    }

    public function getReport()
    {
        if ($this->_report === null) {
            $this->_report = $this->_buildReport();
        }
        return $this->_report;
    }

    protected function _buildReport()
    {
        $res  = Mage::getSingleton('core/resource');
        $read = $res->getConnection('core_read');
        $type = $this->getTypeFilter();
        $generator = Mage::getModel('mmd/schedule_generator');

        // ── Templates ──
        $select = $read->select()
            ->from(array('g' => $res->getTableName('customoptions/group')), array(
                'group_id', 'title', 'is_active', 'hash_options',
                'schedule_type' => new Zend_Db_Expr(MMD_Adminhtml_Block_Customoptions_Options_Grid::scheduleTypeSql('g.title')),
                'letter'        => new Zend_Db_Expr(MMD_Adminhtml_Block_Customoptions_Options_Grid::durationCodeSql('g.title')),
            ));
        $templates = array();
        foreach ($read->fetchAll($select) as $row) {
            if ($row['letter'] === 'X' || ($type !== '' && $row['schedule_type'] !== $type)) {
                continue;
            }
            preg_match('/(?:^|[^A-Za-z])([A-E][0-9]{2})/', $row['title'], $m);
            $code = $m[1];
            $templates[(int) $row['group_id']] = array(
                'id'        => (int) $row['group_id'],
                'title'     => $row['title'],
                'code'      => $code,
                'label'     => ($row['schedule_type'] === 'wsq' ? 'WSQ-' : '') . $code,
                'type'      => $row['schedule_type'],
                'letter'    => $row['letter'],
                'is_active' => (int) $row['is_active'] === 1,
                // Regular week slots (01–20) only; special ones (A21/B21 hydroponics)
                // are reported but never used as rebalancing targets.
                'balanceable' => (int) $row['is_active'] === 1 && (int) substr($code, 1) <= 20
                    && $generator->isKnownCode($code),
                'runs'      => $this->_countUpcomingRuns($row['hash_options']),
                'courses'   => array(),
                'demand'    => 0,
            );
        }

        if ($templates) {
            // ── Active courses on those templates ──
            $statusAttrId = (int) Mage::getSingleton('eav/config')
                ->getAttribute(Mage_Catalog_Model_Product::ENTITY, 'status')->getId();
            $links = $read->fetchAll($read->select()->distinct()
                ->from(array('r' => $res->getTableName('customoptions/relation')), array('group_id', 'product_id'))
                ->join(array('st' => $res->getTableName('catalog/product') . '_int'),
                    'st.entity_id = r.product_id AND st.store_id = 0 AND st.value = 1 AND st.attribute_id = ' . $statusAttrId, array())
                ->join(array('e' => $res->getTableName('catalog/product')), 'e.entity_id = r.product_id', array('sku'))
                ->where('r.group_id IN (?)', array_keys($templates)));

            $productIds = array_unique(array_map('intval', array_column($links, 'product_id')));
            $demand = $productIds ? $this->_loadDemand($productIds) : array();
            $names  = $productIds ? $this->_loadNames($productIds) : array();

            foreach ($links as $l) {
                $pid = (int) $l['product_id'];
                $d   = isset($demand[$pid]) ? $demand[$pid] : 0;
                $templates[(int) $l['group_id']]['courses'][$pid] = array(
                    'id' => $pid, 'sku' => trim($l['sku']),
                    'name' => isset($names[$pid]) ? $names[$pid] : '', 'demand' => $d,
                );
                $templates[(int) $l['group_id']]['demand'] += $d;
            }
        }

        uasort($templates, function ($a, $b) {
            return strcmp($a['code'], $b['code']) ?: strcmp($b['type'], $a['type']);
        });

        // ── Series (A–E) roll-up ──
        $series = array();
        foreach ($this->getLetters() as $letter => $label) {
            $series[$letter] = array('letter' => $letter, 'label' => $label, 'schedules' => 0,
                'courses' => 0, 'demand' => 0, 'runs' => 0, 'templates' => array());
        }
        foreach ($templates as $t) {
            $s =& $series[$t['letter']];
            $s['templates'][] = $t;
            if ($t['is_active']) {
                $s['schedules']++;
            }
            $s['courses'] += count($t['courses']);
            $s['demand']  += $t['demand'];
            $s['runs']    += $t['runs'];
            unset($s);
        }
        foreach ($series as &$s) {
            $s['ratio'] = $s['schedules'] ? $s['courses'] / $s['schedules'] : 0;
        }
        unset($s);

        return array(
            'series'          => $series,
            'templates'       => $templates,
            'moves'           => $this->_suggestMoves($series),
            'recommendations' => $this->_recommend($series, $templates),
        );
    }

    /**
     * Greedy rebalance inside each WSQ series: repeatedly move one course from
     * the fullest balanceable template to the emptiest one until their course
     * counts differ by at most 1. The course picked is the one whose move best
     * evens out the two templates' registration volume, among courses at or
     * below the source template's average demand (high-demand courses stay
     * on the slot their learners already know).
     *
     * Non-WSQ templates are never moved here: a C-prefix course with a
     * same-day WSQ twin must sit on the twin's template code (CLAUDE.md hard
     * rule), so the WSQ side is rebalanced and the twins follow.
     */
    protected function _suggestMoves(array $series)
    {
        $moves = array();
        foreach ($series as $letter => $s) {
            $pool = array();
            foreach ($s['templates'] as $t) {
                if ($t['type'] === 'wsq' && $t['balanceable']) {
                    $pool[$t['id']] = $t;
                }
            }
            if (count($pool) < 2) {
                continue;
            }
            $n = 0;
            while ($n < self::MAX_MOVES_PER_SERIES) {
                uasort($pool, function ($a, $b) {
                    return count($b['courses']) - count($a['courses']) ?: $b['demand'] - $a['demand'];
                });
                $hi = reset($pool);
                $lo = end($pool);
                if (count($hi['courses']) - count($lo['courses']) <= 1) {
                    break;
                }
                $best = null;
                $avgDemand = $hi['demand'] / count($hi['courses']);
                foreach ($hi['courses'] as $c) {
                    if ($c['demand'] > $avgDemand) {
                        continue;
                    }
                    $gap = abs(($hi['demand'] - $c['demand']) - ($lo['demand'] + $c['demand']));
                    if ($best === null || $gap < $best[0]) {
                        $best = array($gap, $c);
                    }
                }
                $c = $best[1];
                $moves[] = array(
                    'letter' => $letter, 'course' => $c,
                    'from' => $hi['label'], 'from_count' => count($hi['courses']),
                    'to'   => $lo['label'], 'to_count'   => count($lo['courses']),
                );
                unset($pool[$hi['id']]['courses'][$c['id']]);
                $pool[$hi['id']]['demand'] -= $c['demand'];
                $pool[$lo['id']]['courses'][$c['id']] = $c;
                $pool[$lo['id']]['demand'] += $c['demand'];
                $n++;
            }
        }
        return $moves;
    }

    protected function _recommend(array $series, array $templates)
    {
        $out = array();

        // 1. Series-level load: courses per schedule far above the others.
        $ratios = array_filter(array_column($series, 'ratio', 'letter'));
        if (count($ratios) > 1) {
            $avg = array_sum($ratios) / count($ratios);
            foreach ($ratios as $letter => $r) {
                if ($r > $avg * 1.5) {
                    $out[] = array('kind' => 'Load',
                        'text' => sprintf('%s carries %.1f active courses per schedule vs %.1f on average across series. '
                            . 'Expect trainer/room clashes in its week slots — spread its courses evenly (moves below) before adding more courses to this series.',
                            $series[$letter]['label'], $r, $avg));
                }
            }
        }

        foreach ($templates as $t) {
            if (!$t['is_active']) {
                continue;
            }
            $n = count($t['courses']);
            // 2. Courses on a template that has nothing to sell.
            if ($n > 0 && $t['runs'] === 0) {
                $out[] = array('kind' => 'Frequency',
                    'text' => sprintf('%s has %d active course(s) but no Course Dates in the next %d days — run Bulk Generate Schedules for it.',
                        $t['title'], $n, self::RUN_WINDOW_DAYS));
            }
            // 3. Free capacity.
            if ($n === 0 && $t['balanceable']) {
                $out[] = array('kind' => 'Capacity',
                    'text' => sprintf('%s is active with no active courses — a free week slot to move courses into.', $t['title']));
            }
        }

        // 4. High-demand courses on rarely-running templates.
        $all = array();
        foreach ($templates as $t) {
            foreach ($t['courses'] as $c) {
                $all[] = $c + array('template' => $t);
            }
        }
        usort($all, function ($a, $b) { return $b['demand'] - $a['demand']; });
        foreach (array_slice($all, 0, 15) as $c) {
            $runs = $c['template']['runs'];
            if ($c['demand'] >= 10 && $runs > 0 && $runs < 3) {
                $out[] = array('kind' => 'Frequency',
                    'text' => sprintf('%s %s — %d registrations in %d months but %s runs only %d time(s) in the next %d days. '
                        . 'Consider more dates on its template.',
                        $c['sku'], $c['name'], $c['demand'], self::DEMAND_MONTHS, $c['template']['label'], $runs, self::RUN_WINDOW_DAYS));
            }
        }

        // 5. Courses nobody registers for still occupy slots.
        $idle = 0;
        foreach ($all as $c) {
            $idle += $c['demand'] === 0 ? 1 : 0;
        }
        if ($idle) {
            $out[] = array('kind' => 'Demand',
                'text' => sprintf('%d active course(s) had no registrations in the last %d months. Move these first when rebalancing '
                    . '(no learners affected), and review whether they should stay enabled.', $idle, self::DEMAND_MONTHS));
        }

        return $out;
    }

    /** Future "Course Date" values within the run window, from the template's own options. */
    protected function _countUpcomingRuns($hash)
    {
        $opts = $hash ? @unserialize($hash) : false;
        if (!is_array($opts)) {
            return 0;
        }
        $from = strtotime('today');
        $to   = strtotime('+' . self::RUN_WINDOW_DAYS . ' days', $from);
        $n = 0;
        foreach ($opts as $opt) {
            if (empty($opt['title']) || strcasecmp(trim($opt['title']), 'course date') !== 0 || empty($opt['values'])) {
                continue;
            }
            foreach ($opt['values'] as $v) {
                if (!empty($v['is_delete']) || empty($v['reg_course'])) {
                    continue;
                }
                $d  = DateTime::createFromFormat('!m/d/y', trim($v['reg_course']));
                $ts = $d ? $d->getTimestamp() : false;
                if ($ts !== false && $ts >= $from && $ts < $to) {
                    $n++;
                }
            }
        }
        return $n;
    }

    /** Registrations (qty ordered) per course over the demand window, cancelled orders excluded. */
    protected function _loadDemand(array $productIds)
    {
        $res  = Mage::getSingleton('core/resource');
        $read = $res->getConnection('core_read');
        $select = $read->select()
            ->from(array('i' => $res->getTableName('sales/order_item')), array('product_id', 'qty' => 'SUM(i.qty_ordered)'))
            ->join(array('o' => $res->getTableName('sales/order')), 'o.entity_id = i.order_id', array())
            ->where('i.parent_item_id IS NULL')
            ->where('o.state <> ?', Mage_Sales_Model_Order::STATE_CANCELED)
            ->where('o.created_at >= ?', gmdate('Y-m-d H:i:s', strtotime('-' . self::DEMAND_MONTHS . ' months')))
            ->where('i.product_id IN (?)', $productIds)
            ->group('i.product_id');
        return array_map('intval', $read->fetchPairs($select));
    }

    protected function _loadNames(array $productIds)
    {
        $res  = Mage::getSingleton('core/resource');
        $read = $res->getConnection('core_read');
        $attrId = (int) Mage::getSingleton('eav/config')
            ->getAttribute(Mage_Catalog_Model_Product::ENTITY, 'name')->getId();
        return $read->fetchPairs($read->select()
            ->from($res->getTableName('catalog/product') . '_varchar', array('entity_id', 'value'))
            ->where('attribute_id = ?', $attrId)
            ->where('store_id = 0')
            ->where('entity_id IN (?)', $productIds));
    }
}
