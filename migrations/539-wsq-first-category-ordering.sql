-- Enforce WSQ-first ordering in every category listing: WSQ (TGS- SKU) courses
-- list first, then non-WSQ (C- SKU), then everything else (M-prefix / other).
-- Relative order WITHIN each group is preserved by existing position, EXCEPT
-- the two Microsoft Certification Exam Prep categories (135, 358) where the
-- non-WSQ (C-) courses are ordered ALPHABETICALLY by course name (their names
-- start with the exam code, e.g. AB-100, AI-103, AZ-104 ... — so this reads as
-- exam-code order). WSQ courses in 135/358 keep their existing relative order.
--
-- Positions are renumbered to a dense 1..N sequence per category and the change
-- is mirrored into catalog_category_product_index (the table the storefront
-- actually sorts by) for every store_id present on THIS instance — there is no
-- PHP reindex hook at deploy, so the index must be written directly (see
-- feedback_flat_catalog_reindex). Idempotent: re-running yields the same order.
--
-- Universal + partner-safe: the TGS/C/M prefix convention holds on every site,
-- and M-prefix (partner-only) SKUs naturally sort last (grp=2). No SKU list, so
-- nothing partner-specific is overwritten. WSQ (TGS-) product DATA is untouched;
-- only listing order changes.
--
-- The category name attribute id (store 0) used to detect 135/358's alpha rule
-- is resolved via the product name attribute for the alpha sort key.

SET @a_pname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');

-- 1) Renumber catalog_category_product.position with WSQ-first (+ alpha for 135/358).
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
      -- WSQ + non-special non-WSQ + other: keep existing relative order.
      CASE WHEN p.category_id IN (135, 358) AND e.sku LIKE 'C%' THEN NULL ELSE p.position END ASC,
      -- Microsoft cert categories: non-WSQ ordered alphabetically by name.
      CASE WHEN p.category_id IN (135, 358) AND e.sku LIKE 'C%' THEN nv.value END ASC,
      p.position ASC,
      p.product_id ASC
  ) sorted
) ranked ON ranked.category_id = cp.category_id AND ranked.product_id = cp.product_id
SET cp.position = ranked.new_pos;

-- 2) Mirror the new positions into the storefront-facing index for every store
--    on this instance (SG=1; MY adds 2; GH adds 3 — whatever exists here).
UPDATE catalog_category_product_index idx
JOIN catalog_category_product cp
  ON cp.category_id = idx.category_id AND cp.product_id = idx.product_id
SET idx.position = cp.position;
