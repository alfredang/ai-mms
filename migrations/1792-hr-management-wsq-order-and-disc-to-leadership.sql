-- 1792: HR Management ('human-resource-management-courses') — pin the WSQ order
-- and move the DISC course to Leadership ('leadership-training-courses').
--
-- Requested order for HR Management:
--   1  TGS-2026066579  CASL - Managing Human Resource Management System (HRMS)
--   2  TGS-2024045795  WSQ - Microsoft Copilot for HR
--   3  TGS-2024051421  WSQ - Microsoft Copilot for HR Recruitment
-- followed by the non-WSQ block, alphabetical as the nightly sweep keeps it:
--   4  C431            AI for Career Coaching
--   5  C820            Microsoft Copilot for HR
--
-- REMOVED from HR Management:
--   TGS-2024051250  WSQ - Mastering the Art & Science of Working with People &
--                   Teams using DISC AsiaPlus
-- On SG prod (2026-10-06) it is already a direct member of Leadership
-- (base + index, position 2, right after Impactful Leadership Framework), so the
-- Leadership insert below is only a safety net for a DB that differs.
-- HR Management has no child categories, so the delete is not undone by anchor
-- inheritance. The parent Business & Soft Skills (68) keeps its own direct row.
--
-- Positions are positive 1..N (negative pins don't survive the daily reindex);
-- the page sorts by the global default 'position'. Index rows are updated
-- alongside base rows so no Category Products reindex is needed.
-- Business-key lookups; no-ops on sites without these SKUs or categories.
-- Idempotent.

SET @hr := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='human-resource-management-courses' LIMIT 1);
SET @ld := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='leadership-training-courses' LIMIT 1);
SET @disc := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024051250' LIMIT 1);

-- 1. DISC: off HR Management, onto Leadership (safety net) -------------------

DELETE FROM catalog_category_product WHERE category_id=@hr AND product_id=@disc;
DELETE FROM catalog_category_product_index WHERE category_id=@hr AND product_id=@disc;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @ld, @disc, 2 FROM DUAL WHERE @ld IS NOT NULL AND @disc IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @ld, @disc, 2, 1, s.store_id, COALESCE(vis.value, 4)
FROM core_store s
LEFT JOIN catalog_product_entity_int vis ON vis.entity_id=@disc AND vis.store_id=0
  AND vis.attribute_id=(SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='visibility')
WHERE s.store_id > 0 AND @ld IS NOT NULL AND @disc IS NOT NULL;

-- 2. HR Management order ------------------------------------------------------

DROP TEMPORARY TABLE IF EXISTS tmp_hr_order;
CREATE TEMPORARY TABLE tmp_hr_order (sku VARCHAR(64) PRIMARY KEY, pos INT);
INSERT INTO tmp_hr_order (sku, pos) VALUES
  ('TGS-2026066579', 1),
  ('TGS-2024045795', 2),
  ('TGS-2024051421', 3),
  ('C431', 4),
  ('C820', 5);

UPDATE catalog_category_product cp
JOIN catalog_product_entity e ON e.entity_id=cp.product_id
JOIN tmp_hr_order o ON o.sku=TRIM(e.sku)
SET cp.position=o.pos
WHERE cp.category_id=@hr;

UPDATE catalog_category_product_index i
JOIN catalog_product_entity e ON e.entity_id=i.product_id
JOIN tmp_hr_order o ON o.sku=TRIM(e.sku)
SET i.position=o.pos
WHERE i.category_id=@hr;

DROP TEMPORARY TABLE IF EXISTS tmp_hr_order;
