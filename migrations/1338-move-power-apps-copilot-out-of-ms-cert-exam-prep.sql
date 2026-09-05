-- 1338: Move "WSQ - Create Intelligent Power Apps and Power Automate Workflows
-- with Copilot" (TGS-2023036648) out of Microsoft Certification Exam Prep and
-- keep it in Microsoft Copilot Series.
--
-- Verified on SG prod 2026-09-05:
--   * It is ALREADY a direct member of microsoft-copilot-series (357, position
--     4, inside the WSQ block) — so the "add" half is only a per-instance safety
--     net (INSERT IGNORE + curated-aware renumber), a no-op on SG.
--   * It is a direct member of microsoft-certifications-exams (135) AND of its
--     child instructor-led-microsoft-exam-prep (358). 135 is an anchor parent,
--     so deleting only the 135 row would let the course resurface on the
--     Microsoft Certification Exam Prep page via anchor inheritance from 358 at
--     the next reindex. The removal therefore covers the WHOLE 135 subtree.
--   * Its row on the grandparent certification-exam-prep-courses (182) is
--     anchor-only (index row, no base row). After the subtree removal the course
--     is reachable through NO other category under 182, so that index row is
--     dropped too (a full reindex would drop it anyway).
--
-- Business-key lookups only (url_key + SKU). Partner-safe: the TGS- SKU does
-- not exist on MY/GH, so every statement is a clean no-op there. Idempotent.

SET @sku := 'TGS-2023036648';
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = @sku LIMIT 1);
SET @a_pname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_ukey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @src := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id = 0 AND attribute_id = @a_ukey AND value = 'microsoft-certifications-exams' LIMIT 1);
SET @src_path := (SELECT path FROM catalog_category_entity WHERE entity_id = @src);
SET @gp := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id = 0 AND attribute_id = @a_ukey AND value = 'certification-exam-prep-courses' LIMIT 1);
SET @gp_path := (SELECT path FROM catalog_category_entity WHERE entity_id = @gp);
SET @dst := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id = 0 AND attribute_id = @a_ukey AND value = 'microsoft-copilot-series' LIMIT 1);

-- 1. Remove from Microsoft Certification Exam Prep and its whole subtree -------
DROP TEMPORARY TABLE IF EXISTS tmp_1338_src_tree;
CREATE TEMPORARY TABLE tmp_1338_src_tree (category_id INT PRIMARY KEY);
INSERT IGNORE INTO tmp_1338_src_tree (category_id)
SELECT entity_id FROM catalog_category_entity
WHERE @src IS NOT NULL AND (entity_id = @src OR path LIKE CONCAT(@src_path, '/%'));

DELETE cp FROM catalog_category_product cp
JOIN tmp_1338_src_tree t ON t.category_id = cp.category_id
WHERE cp.product_id = @pid AND @pid IS NOT NULL;

DELETE i FROM catalog_category_product_index i
JOIN tmp_1338_src_tree t ON t.category_id = i.category_id
WHERE i.product_id = @pid AND @pid IS NOT NULL;

-- 2. Drop the anchor-only row on the grandparent, only if the course is no
--    longer reachable through ANY category under it (materialised first: MySQL
--    1093 forbids reading the table being deleted from).
DROP TEMPORARY TABLE IF EXISTS tmp_1338_still_under_gp;
CREATE TEMPORARY TABLE tmp_1338_still_under_gp (product_id INT PRIMARY KEY);
INSERT IGNORE INTO tmp_1338_still_under_gp (product_id)
SELECT cp.product_id
FROM catalog_category_product cp
JOIN catalog_category_entity c ON c.entity_id = cp.category_id
WHERE @gp IS NOT NULL AND cp.product_id = @pid
  AND (c.entity_id = @gp OR c.path LIKE CONCAT(@gp_path, '/%'));

DELETE i FROM catalog_category_product_index i
WHERE i.category_id = @gp AND @gp IS NOT NULL
  AND i.product_id = @pid AND @pid IS NOT NULL
  AND i.product_id NOT IN (SELECT product_id FROM tmp_1338_still_under_gp);

DROP TEMPORARY TABLE IF EXISTS tmp_1338_still_under_gp;
DROP TEMPORARY TABLE IF EXISTS tmp_1338_src_tree;

-- 3. Safety net: make sure it is in Microsoft Copilot Series, at the tail of
--    the WSQ block (never MAX(position)+1 across the category — that lands a
--    funded course under the C-block).
SET @tgs_max := (SELECT COALESCE(MAX(cp.position), 0) FROM catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id AND e.sku LIKE 'TGS-%'
  WHERE cp.category_id = @dst);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @dst, @pid, @tgs_max + 1 FROM DUAL
WHERE @dst IS NOT NULL AND @pid IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @dst, @pid, @tgs_max + 1, 1, s.store_id, MAX(i.visibility)
FROM core_store s
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id = s.store_id
WHERE s.store_id > 0 AND @dst IS NOT NULL AND @pid IS NOT NULL
GROUP BY s.store_id;

-- 4. Renumber Microsoft Copilot Series densely: TGS- first keeping relative
--    order, then non-TGS keeping their existing (curated) order.
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
    WHERE i.category_id = @dst AND @dst IS NOT NULL
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
    WHERE p.category_id = @dst AND @dst IS NOT NULL
    ORDER BY
      p.category_id ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN 0 WHEN e.sku LIKE 'C%' THEN 1 ELSE 2 END ASC,
      p.position ASC,
      p.product_id ASC
  ) sorted
) ranked ON ranked.category_id = cp.category_id AND ranked.product_id = cp.product_id
SET cp.position = ranked.new_pos;
