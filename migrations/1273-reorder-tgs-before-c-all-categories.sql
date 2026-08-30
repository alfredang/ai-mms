-- 1273: Re-apply the canonical listing order in EVERY category —
-- WSQ / CASL / IBF (TGS- SKU) courses ALWAYS before non-WSQ (C- SKU), then
-- everything else (M-prefix / partner) last.
--
-- Verbatim copy of migration 545's two UPDATE statements. 545 is the canonical
-- rule and is already applied everywhere, and the ledger tracks by FILENAME, so
-- an edited/re-run 545 would never execute again on prod — a fresh numbered
-- copy is the supported way to re-apply it (see the category-ordering skill).
--
-- Why now: migration 1269 appended "CASL - AI for eCommerce" (TGS-2026064474)
-- to AI for Retail at the next free position, which placed a TGS- course BELOW
-- the C-prefix "AI for Retail" (C398). Appending at MAX(position)+1 is only
-- safe in an all-TGS category; wherever a category also holds C- courses the
-- new row must be re-sorted into the TGS block. This re-applies the rule
-- catalog-wide so no other category is left in that state.
--
-- Ordering within each (category_id, store_id):
--   1. TGS- (WSQ / CASL / IBF) first, KEEPING their existing relative order —
--      so every curated pin shipped in 1264-1272 survives untouched.
--   2. C- (non-WSQ) next, alphabetical by product name.
--   3. Everything else (M-prefix / partner) last.
--
-- Renumbers the INDEX directly so anchor-inherited rows (which have no base
-- catalog_category_product row) are covered too, then the base table for the
-- admin view. Partner-safe (prefix convention only, no SKU list). Idempotent.
--
-- CURATED-ORDER SAFETY: categories listed in
-- mmd/category_ordering/curated_url_keys carry a hand-curated NON-WSQ order
-- (Masterclasses before certifications, etc). 545's alphabetical pass would
-- flatten those — the documented failure that produced 22 "reapply-curated-
-- orders" migrations. This copy therefore EXCLUDES allowlisted categories from
-- both renumbers. That is safe for the reported bug: a TGS- row sitting below a
-- C- row is fixed for every NON-curated category here, and the three affected
-- categories are handled explicitly in the final block below, which moves ONLY
-- the offending TGS- rows above the C-block and leaves the curated C order
-- untouched.

SET @a_pname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');

-- Categories with a curated non-WSQ order — excluded from the renumbers below.
DROP TEMPORARY TABLE IF EXISTS tmp_curated_cats;
CREATE TEMPORARY TABLE tmp_curated_cats (category_id INT PRIMARY KEY);
INSERT IGNORE INTO tmp_curated_cats (category_id)
SELECT v.entity_id
FROM catalog_category_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id
 AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
WHERE v.store_id = 0
  AND FIND_IN_SET(v.value, (
    SELECT value FROM (SELECT value FROM core_config_data
      WHERE path = 'mmd/category_ordering/curated_url_keys'
        AND scope = 'default' AND scope_id = 0 LIMIT 1) cfg
  )) > 0;

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
    WHERE i.category_id NOT IN (SELECT category_id FROM tmp_curated_cats)
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
    WHERE p.category_id NOT IN (SELECT category_id FROM tmp_curated_cats)
    ORDER BY
      p.category_id ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN 0 WHEN e.sku LIKE 'C%' THEN 1 ELSE 2 END ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN p.position END ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN NULL ELSE nv.value END ASC,
      p.product_id ASC
  ) sorted
) ranked ON ranked.category_id = cp.category_id AND ranked.product_id = cp.product_id
SET cp.position = ranked.new_pos;

-- Curated categories: fix ONLY the WSQ-first violation, keep the curated
-- C-order. Any TGS- row sitting at/below the first C- row is lifted above the
-- whole C-block by giving it a position below the current minimum; relative
-- order among those lifted rows is preserved.
UPDATE catalog_category_product_index idx
JOIN (
  SELECT i.category_id, i.store_id, i.product_id,
         (SELECT MIN(i3.position) FROM catalog_category_product_index i3
           WHERE i3.category_id = i.category_id AND i3.store_id = i.store_id) AS min_pos,
         i.position AS old_pos
  FROM catalog_category_product_index i
  JOIN catalog_product_entity e ON e.entity_id = i.product_id
  JOIN tmp_curated_cats t ON t.category_id = i.category_id
  WHERE e.sku LIKE 'TGS-%'
    AND i.position > (
      SELECT MIN(i2.position) FROM catalog_category_product_index i2
      JOIN catalog_product_entity e2 ON e2.entity_id = i2.product_id
      WHERE i2.category_id = i.category_id AND i2.store_id = i.store_id
        AND e2.sku LIKE 'C%'
    )
) bad
  ON bad.category_id = idx.category_id
 AND bad.store_id   = idx.store_id
 AND bad.product_id = idx.product_id
SET idx.position = bad.min_pos - 1;

UPDATE catalog_category_product cp
JOIN (
  SELECT p.category_id, p.product_id,
         (SELECT MIN(p3.position) FROM catalog_category_product p3
           WHERE p3.category_id = p.category_id) AS min_pos
  FROM catalog_category_product p
  JOIN catalog_product_entity e ON e.entity_id = p.product_id
  JOIN tmp_curated_cats t ON t.category_id = p.category_id
  WHERE e.sku LIKE 'TGS-%'
    AND p.position > (
      SELECT MIN(p2.position) FROM catalog_category_product p2
      JOIN catalog_product_entity e2 ON e2.entity_id = p2.product_id
      WHERE p2.category_id = p.category_id AND e2.sku LIKE 'C%'
    )
) bad ON bad.category_id = cp.category_id AND bad.product_id = cp.product_id
SET cp.position = bad.min_pos - 1;

DROP TEMPORARY TABLE IF EXISTS tmp_curated_cats;
