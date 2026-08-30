<?php
/**
 * Daily category-ordering sweep — wired from config.xml <crontab>.
 *
 * Enforces the hard storefront listing rule in EVERY category, on every
 * instance (SG + franchise partners):
 *   1. WSQ courses first          — SKU TGS-%, existing relative order kept
 *   2. non-WSQ courses next       — SKU C%, ALPHABETICAL by product name
 *   3. everything else last       — partner M-prefix / other
 *
 * Why a cron and not just a migration: the order is DATA-DERIVED. Adding,
 * renaming, disabling or re-categorising a course does not reorder its
 * category, and a migration only runs once per instance — so the catalog
 * drifts out of order between deploys. Observed 2026-07-18 on SG
 * /leadership-training-courses.html, where a non-WSQ course ("Coaching and
 * Mentoring") had drifted above a WSQ course. This sweep makes that
 * self-healing within a day instead of needing a fresh reorder migration
 * every time the catalog changes.
 *
 * The SQL is intentionally identical to migrations/601 (itself a copy of the
 * canonical 545) — one rule, one expression, two delivery mechanisms. If the
 * rule ever changes, change BOTH.
 *
 * Writes catalog_category_product_index.position (what the storefront listing
 * actually reads, per store) and catalog_category_product.position (the
 * admin-facing source of truth). The index is renumbered DIRECTLY rather than
 * via a join to the base table, so anchor-inherited rows — which have no base
 * row — are covered; joining was the 539/542 bug that stranded WSQ courses at
 * stale positions like 20015 and sorted them to the bottom.
 *
 * Touches listing ORDER only — never product data. Idempotent: a run over an
 * already-correct catalog rewrites the same positions and changes nothing.
 * Read-mostly for the storefront; no frontend code path runs this.
 */
class MMD_RoleManager_Model_Cron_CategoryOrdering
{
    const LOG_FILE = 'category_ordering.log';

    /** Flip to 0 in core_config_data to disable the sweep without a deploy. */
    const CONFIG_ENABLED = 'mmd/category_ordering/enabled';

    /**
     * Comma-separated category url_keys whose non-WSQ order is CURATED and
     * must not be re-alphabetised (WSQ-first is still enforced). Set in
     * core_config_data so a curated order can be granted/revoked without a
     * deploy; seeded by migrations/1199.
     */
    const CONFIG_CURATED = 'mmd/category_ordering/curated_url_keys';

    /**
     * Cron entry point.
     */
    public function run()
    {
        // Fail-safe kill switch. Absent = ON (the rule is a hard requirement,
        // so the safe default is "enforced"); set to '0' to suspend.
        $enabled = Mage::getStoreConfig(self::CONFIG_ENABLED);
        if ($enabled !== null && $enabled !== '' && !(int) $enabled) {
            return;
        }

        $write = Mage::getSingleton('core/resource')->getConnection('core_write');
        $start = microtime(true);

        try {
            $write->query('SET @a_pname := (SELECT attribute_id FROM eav_attribute '
                . "WHERE entity_type_id = 4 AND attribute_code = 'name')");

            $curated = $this->_curatedCategoryIds($write);

            $indexRows = $write->query($this->_indexSql($curated))->rowCount();
            $baseRows  = $write->query($this->_baseSql($curated))->rowCount();

            $msg = sprintf(
                'MMD category ordering: reordered %d index row(s), %d base row(s) in %.1fs',
                $indexRows,
                $baseRows,
                microtime(true) - $start
            );
            Mage::log($msg, Zend_Log::INFO, self::LOG_FILE);
        } catch (Exception $e) {
            // error_log lands in `docker logs` even when Mage::log is broken
            // (see memory feedback_mage_log_dead_allowed_extensions).
            error_log('MMD CATEGORY ORDERING FAILED: ' . $e->getMessage());
            Mage::log('MMD category ordering FAILED: ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
        }
    }

    /**
     * Resolve the curated url_keys to category ids on THIS instance.
     *
     * Returns [] when unset/empty or when no url_key matches (partner DBs
     * have their own category ids and may not carry these categories), in
     * which case the sweep behaves exactly as before.
     *
     * @param  Varien_Db_Adapter_Interface $write
     * @return int[]
     */
    protected function _curatedCategoryIds($write)
    {
        // Read core_config_data DIRECTLY, not via Mage::getStoreConfig(): the
        // config cache is populated at app init, so a migration that seeds
        // this row is invisible to the cron until a cache flush. A daily job
        // must not depend on someone having flushed.
        $raw = (string) $write->fetchOne(
            $write->select()
                ->from('core_config_data', array('value'))
                ->where('path = ?', self::CONFIG_CURATED)
                ->order(array('scope_id ASC'))
                ->limit(1)
        );
        if (trim($raw) === '') {
            return array();
        }

        $keys = array_filter(array_map('trim', explode(',', $raw)));
        if (!$keys) {
            return array();
        }

        $select = $write->select()
            ->from(array('v' => 'catalog_category_entity_varchar'), array('entity_id'))
            ->join(array('a' => 'eav_attribute'), 'a.attribute_id = v.attribute_id', array())
            ->where('a.entity_type_id = ?', 3)
            ->where('a.attribute_code = ?', 'url_key')
            ->where('v.store_id = ?', 0)
            ->where('v.value IN (?)', $keys);

        return array_map('intval', $write->fetchCol($select));
    }

    /**
     * SQL fragment that keeps a curated category's non-WSQ rows in their
     * existing position order instead of re-alphabetising them.
     *
     * Empty string when nothing is curated, so the generated SQL — and its
     * plan — is byte-identical to the pre-exemption sweep.
     *
     * @param  int[]  $curated
     * @param  string $posCol  qualified position column for this query
     * @return string
     */
    protected function _curatedOrderExpr(array $curated, $posCol)
    {
        if (!$curated) {
            return '';
        }

        list($catCol, $skuCol) = $posCol === 'i.position'
            ? array('i.category_id', 'e.sku')
            : array('p.category_id', 'e.sku');

        return sprintf(
            "      CASE WHEN %s IN (%s) AND %s NOT LIKE 'TGS-%%' THEN %s END ASC,\n",
            $catCol,
            implode(',', $curated),
            $skuCol,
            $posCol
        );
    }

    /**
     * Renumber the storefront-facing index, per (category_id, store_id).
     *
     * @param  int[] $curated
     * @return string
     */
    protected function _indexSql(array $curated = array())
    {
        $curatedExpr = $this->_curatedOrderExpr($curated, 'i.position');

        return "
UPDATE catalog_category_product_index idx
JOIN (
  SELECT category_id, store_id, product_id,
    (@rn := IF(@grp = CONCAT(category_id, '-', store_id), @rn + 1, 1)) AS new_pos,
    (@grp := CONCAT(category_id, '-', store_id)) AS grp_set
  FROM (
    SELECT i.category_id, i.store_id, i.product_id
    FROM catalog_category_product_index i
    JOIN catalog_product_entity e ON e.entity_id = i.product_id
    LEFT JOIN catalog_product_entity_varchar nv
      ON nv.entity_id = e.entity_id AND nv.attribute_id = @a_pname AND nv.store_id = 0
    CROSS JOIN (SELECT @rn := 0, @grp := NULL) init
    ORDER BY
      i.category_id ASC,
      i.store_id ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN 0 WHEN e.sku LIKE 'C%' THEN 1 ELSE 2 END ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN i.position END ASC,
{$curatedExpr}      CASE WHEN e.sku LIKE 'TGS-%' THEN NULL ELSE nv.value END ASC,
      i.product_id ASC
  ) sorted
) ranked
  ON ranked.category_id = idx.category_id
 AND ranked.store_id  = idx.store_id
 AND ranked.product_id = idx.product_id
SET idx.position = ranked.new_pos";
    }

    /**
     * Renumber the base table so the admin view matches the storefront.
     *
     * @return string
     */
    protected function _baseSql(array $curated = array())
    {
        $curatedExpr = $this->_curatedOrderExpr($curated, 'p.position');

        return "
UPDATE catalog_category_product cp
JOIN (
  SELECT category_id, product_id,
    (@rn2 := IF(@cat2 = category_id, @rn2 + 1, 1)) AS new_pos,
    (@cat2 := category_id) AS cat_set
  FROM (
    SELECT p.category_id, p.product_id
    FROM catalog_category_product p
    JOIN catalog_product_entity e ON e.entity_id = p.product_id
    LEFT JOIN catalog_product_entity_varchar nv
      ON nv.entity_id = e.entity_id AND nv.attribute_id = @a_pname AND nv.store_id = 0
    CROSS JOIN (SELECT @rn2 := 0, @cat2 := NULL) init
    ORDER BY
      p.category_id ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN 0 WHEN e.sku LIKE 'C%' THEN 1 ELSE 2 END ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN p.position END ASC,
{$curatedExpr}      CASE WHEN e.sku LIKE 'TGS-%' THEN NULL ELSE nv.value END ASC,
      p.product_id ASC
  ) sorted
) ranked ON ranked.category_id = cp.category_id AND ranked.product_id = cp.product_id
SET cp.position = ranked.new_pos";
    }
}
