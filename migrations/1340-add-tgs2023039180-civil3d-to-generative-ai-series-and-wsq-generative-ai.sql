-- 1340: Add "WSQ - Generative AI Design for Civil 3D" (TGS-2023039180) to
--
--   * generative-ai-series      (433 on SG) — MIXED: TGS- block at 1..14, then
--                                a C-prefix block at 15..36. The new course goes
--                                at the tail of the TGS block, and the category
--                                is renumbered densely (TGS- first, keeping
--                                relative order; C- keeps its existing order).
--                                Never MAX(position)+1 here — that lands a funded
--                                course under the C-block.
--   * wsq-generative-ai-courses (379 on SG) — all-TGS (18 rows), so appending at
--                                MAX(position)+1 is safe. Its parent WSQ AI
--                                Courses (325) inherits it via anchor at reindex.
--
-- Verified on SG prod 2026-09-06: product_id 1449, a member of neither category
-- (no base row, no index row).
--
-- Business-key lookups only (url_key + SKU). Partner-safe: the TGS- SKU does
-- not exist on MY/GH, so every statement is a clean no-op there. Idempotent.

SET @sku := 'TGS-2023039180';
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = @sku LIMIT 1);
SET @a_ukey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @series := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id = 0 AND attribute_id = @a_ukey AND value = 'generative-ai-series' LIMIT 1);
SET @wsq := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id = 0 AND attribute_id = @a_ukey AND value = 'wsq-generative-ai-courses' LIMIT 1);

-- 1. Generative AI Series: insert at the tail of the TGS- block ----------------
SET @tgs_max := (SELECT COALESCE(MAX(cp.position), 0) FROM catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id AND e.sku LIKE 'TGS-%'
  WHERE cp.category_id = @series);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @series, @pid, @tgs_max + 1 FROM DUAL
WHERE @series IS NOT NULL AND @pid IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @series, @pid, @tgs_max + 1, 1, s.store_id, MAX(i.visibility)
FROM core_store s
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id = s.store_id
WHERE s.store_id > 0 AND @series IS NOT NULL AND @pid IS NOT NULL
GROUP BY s.store_id;

-- 2. Renumber Generative AI Series densely: TGS- first keeping relative order,
--    then non-TGS keeping their existing order (same as 1338 step 4).
UPDATE catalog_category_product_index idx
JOIN (
  SELECT category_id, store_id, product_id,
    (@rn := IF(@grp = CONCAT(category_id, '-', store_id), @rn + 1, 1)) AS new_pos,
    (@grp := CONCAT(category_id, '-', store_id)) AS grp_set
  FROM (
    SELECT i.category_id, i.store_id, i.product_id
    FROM catalog_category_product_index i
    JOIN catalog_product_entity e ON e.entity_id = i.product_id
    CROSS JOIN (SELECT @rn := 0, @grp := NULL) init
    WHERE i.category_id = @series AND @series IS NOT NULL
    ORDER BY
      i.category_id ASC,
      i.store_id ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN 0 WHEN e.sku LIKE 'C%' THEN 1 ELSE 2 END ASC,
      i.position ASC,
      i.product_id ASC
  ) sorted
) ranked
  ON ranked.category_id = idx.category_id
 AND ranked.store_id  = idx.store_id
 AND ranked.product_id = idx.product_id
SET idx.position = ranked.new_pos;

UPDATE catalog_category_product cp
JOIN (
  SELECT category_id, product_id,
    (@rn2 := IF(@cat2 = category_id, @rn2 + 1, 1)) AS new_pos,
    (@cat2 := category_id) AS cat_set
  FROM (
    SELECT p.category_id, p.product_id
    FROM catalog_category_product p
    JOIN catalog_product_entity e ON e.entity_id = p.product_id
    CROSS JOIN (SELECT @rn2 := 0, @cat2 := NULL) init
    WHERE p.category_id = @series AND @series IS NOT NULL
    ORDER BY
      p.category_id ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN 0 WHEN e.sku LIKE 'C%' THEN 1 ELSE 2 END ASC,
      p.position ASC,
      p.product_id ASC
  ) sorted
) ranked ON ranked.category_id = cp.category_id AND ranked.product_id = cp.product_id
SET cp.position = ranked.new_pos;

-- 3. WSQ Generative AI Courses: all-TGS, append at MAX(position)+1 -------------
SET @wsq_max := (SELECT COALESCE(MAX(position), 0) FROM catalog_category_product WHERE category_id = @wsq);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @wsq, @pid, @wsq_max + 1 FROM DUAL
WHERE @wsq IS NOT NULL AND @pid IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @wsq, @pid, @wsq_max + 1, 1, s.store_id, MAX(i.visibility)
FROM core_store s
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id = s.store_id
WHERE s.store_id > 0 AND @wsq IS NOT NULL AND @pid IS NOT NULL
GROUP BY s.store_id;
