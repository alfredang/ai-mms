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

            $indexRows = $write->query($this->_indexSql())->rowCount();
            $baseRows  = $write->query($this->_baseSql())->rowCount();

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
     * Renumber the storefront-facing index, per (category_id, store_id).
     *
     * @return string
     */
    protected function _indexSql()
    {
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
      CASE WHEN e.sku LIKE 'TGS-%' THEN NULL ELSE nv.value END ASC,
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
    protected function _baseSql()
    {
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
      CASE WHEN e.sku LIKE 'TGS-%' THEN NULL ELSE nv.value END ASC,
      p.product_id ASC
  ) sorted
) ranked ON ranked.category_id = cp.category_id AND ranked.product_id = cp.product_id
SET cp.position = ranked.new_pos";
    }
}
