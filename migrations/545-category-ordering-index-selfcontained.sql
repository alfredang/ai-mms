-- Fix category listing order so WSQ (TGS-) courses ALWAYS list first in EVERY
-- category — including WSQ courses that are assigned to a category only by ANCHOR
-- INHERITANCE (a child-category product surfacing in a parent anchor category).
--
-- Bug in 542/539: those migrations renumbered catalog_category_product.position
-- then mirrored it into catalog_category_product_index via
--   UPDATE index idx JOIN catalog_category_product cp ON (category_id, product_id)
-- That INNER JOIN skips index rows with NO base catalog_category_product row —
-- exactly the anchor-inherited WSQ courses — leaving them at stale positions
-- (e.g. 20015/20016), which sorts them to the BOTTOM. Symptom: on
-- cyber-security page 2, non-WSQ "SC-100 ..." appeared above WSQ "CompTIA CySA+".
--
-- This migration renumbers catalog_category_product_index DIRECTLY (self-
-- contained — no dependency on the base table), per (category_id, store_id):
--   1. WSQ (TGS- SKU) first
--   2. non-WSQ (C- SKU) next, ALPHABETICAL by course name
--   3. everything else (M-prefix / other), alphabetical
-- It also renumbers the base catalog_category_product.position the same way so
-- the admin view matches. The storefront reads the index, so the index write is
-- what fixes the visible order.
--
-- Partner-safe (no SKU list; TGS/C/M convention holds everywhere; M sorts last).
-- Idempotent: re-running yields the same order. This is the canonical ordering
-- migration going forward — copy THIS file (not 539/542) for future reorders.

SET @a_pname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');

-- 1) Renumber the storefront-facing index directly, per category AND per store.
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
      CASE WHEN e.sku LIKE 'TGS-%' THEN i.position END ASC,   -- WSQ keep relative order
      CASE WHEN e.sku LIKE 'TGS-%' THEN NULL ELSE nv.value END ASC,  -- non-WSQ alphabetical
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
