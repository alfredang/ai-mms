-- Re-apply the canonical category ordering rule (WSQ first, non-WSQ alphabetical,
-- partner/other last) across EVERY category on this instance.
--
-- Verbatim copy of 545's two UPDATE statements. Shipped as a NEW file because
-- the schema_migrations ledger tracks by filename: 545 is already applied on
-- every prod instance and would never re-run, so an edit to it is a no-op there
-- (see memory feedback_edited_shared_migrations_never_rerun_on_prod).
--
-- Why now: the order is DATA-DERIVED. Courses added, renamed, or recategorised
-- since 545 ran never got renumbered, so they kept their stale/appended
-- positions. Observed 2026-07-18 on SG /leadership-training-courses.html, which
-- listed: WSQ, "Coaching and Mentoring" (non-WSQ), WSQ, ... — a non-WSQ course
-- above a WSQ course, violating the hard rule.
--
-- From this migration on, the MMD_RoleManager daily category-ordering cron
-- re-applies the same rule every night, so drift self-heals and future one-off
-- reorder migrations should not be needed.
--
-- Partner-safe (no SKU list; the TGS-/C/M prefix convention holds on every
-- site). Touches listing ORDER only — no product data. Idempotent.

SET @a_pname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');

-- 1) Renumber the storefront-facing index directly, per category AND per store.
--    Written directly (NOT via a JOIN to catalog_category_product) so that
--    anchor-inherited rows — which have no base row — are covered too.
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
SET idx.position = ranked.new_pos;

-- 2) Renumber the base table (store 0 name key) so the admin view matches.
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
SET cp.position = ranked.new_pos;
