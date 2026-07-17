-- Extend WSQ-first ordering (migration 539) to sort NON-WSQ courses alphabetically
-- in EVERY category, not just the two Microsoft Cert categories (135, 358).
--
-- Ordering rule per category:
--   1. WSQ (TGS- SKU) courses first  — existing relative order preserved (grp 0)
--   2. non-WSQ (C- SKU) courses next — ordered ALPHABETICALLY by course name (grp 1)
--   3. everything else (M-prefix / other) — existing relative order preserved (grp 2)
--
-- Only the non-WSQ (C-) group's order changes vs 539. WSQ product order and the
-- partner-only M-prefix order are untouched (relative position preserved), so this
-- stays partner-safe: no SKU list, and M-prefix SKUs never get reordered.
--
-- Positions renumbered to a dense 1..N sequence per category, then mirrored into
-- catalog_category_product_index (the storefront-facing table) for every store_id
-- on THIS instance — no PHP reindex hook at deploy (see feedback_flat_catalog_reindex).
-- Idempotent: re-running yields the same order.

SET @a_pname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');

-- 1) Renumber catalog_category_product.position: WSQ first, then non-WSQ alpha, then other.
UPDATE catalog_category_product cp
JOIN (
  SELECT product_id, category_id,
    (@rn := IF(@cat = category_id, @rn + 1, 1)) AS new_pos,
    (@cat := category_id) AS cat_set
  FROM (
    SELECT p.product_id, p.category_id
    FROM catalog_category_product p
    JOIN catalog_product_entity e ON e.entity_id = p.product_id
    LEFT JOIN catalog_product_entity_varchar nv
      ON nv.entity_id = e.entity_id AND nv.attribute_id = @a_pname AND nv.store_id = 0
    CROSS JOIN (SELECT @rn := 0, @cat := NULL) init
    ORDER BY
      p.category_id ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN 0 WHEN e.sku LIKE 'C%' THEN 1 ELSE 2 END ASC,
      -- non-WSQ (C-) courses: alphabetical by name. WSQ + other: keep existing order.
      CASE WHEN e.sku LIKE 'C%' THEN nv.value END ASC,
      p.position ASC,
      p.product_id ASC
  ) sorted
) ranked ON ranked.category_id = cp.category_id AND ranked.product_id = cp.product_id
SET cp.position = ranked.new_pos;

-- 2) Mirror the new positions into the storefront-facing index for every store on this instance.
UPDATE catalog_category_product_index idx
JOIN catalog_category_product cp
  ON cp.category_id = idx.category_id AND cp.product_id = idx.product_id
SET idx.position = cp.position;
