-- 1698: "WSQ - AI for Life Science and Bioinformatics" (TGS-2024049780) leaves
-- the Programming category page and is listed under AI Applications Series and
-- BioInformatics.
--
-- Requested 2026-10-02. On SG prod it already shows on both target pages, so
-- the change is mainly the removal; the INSERT IGNOREs make sure both target
-- listings hold a DIRECT row (not just anchor inheritance). Programming is an
-- anchor category, so the course is removed from it AND every subcategory
-- under it, or it would keep surfacing there by inheritance.
--
-- New rows sit above the C- block (MIN-1) -- WSQ-first rule; the nightly
-- CategoryOrdering sweep compacts positions.
-- Resolved by SKU + url_key: clean no-op on MY/GH (no TGS- course). Idempotent.

SET @p    := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024049780' LIMIT 1);
SET @a_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @prog := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE attribute_id = @a_uk AND store_id = 0 AND value = 'programming-courses' LIMIT 1);
SET @prog_path := (SELECT path FROM catalog_category_entity WHERE entity_id = @prog);

-- ------------------------------------------- out of Programming (+ children)
DELETE cp FROM catalog_category_product cp
  JOIN catalog_category_entity c ON c.entity_id = cp.category_id
 WHERE @p IS NOT NULL AND @prog IS NOT NULL AND cp.product_id = @p
   AND (c.entity_id = @prog OR c.path LIKE CONCAT(@prog_path, '/%'));

DELETE i FROM catalog_category_product_index i
  JOIN catalog_category_entity c ON c.entity_id = i.category_id
 WHERE @p IS NOT NULL AND @prog IS NOT NULL AND i.product_id = @p
   AND (c.entity_id = @prog OR c.path LIKE CONCAT(@prog_path, '/%'));

-- ------------------------------ into AI Applications Series + BioInformatics
DROP TEMPORARY TABLE IF EXISTS tmp_lsb_cats;
CREATE TEMPORARY TABLE tmp_lsb_cats (category_id INT UNSIGNED PRIMARY KEY);
INSERT IGNORE INTO tmp_lsb_cats
SELECT entity_id FROM catalog_category_entity_varchar
 WHERE @p IS NOT NULL AND attribute_id = @a_uk AND store_id = 0
   AND value IN ('ai-applications-series', 'bioinformatics-courses');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT t.category_id, @p,
       (SELECT IFNULL(MIN(cp.position), 1) - 1 FROM catalog_category_product cp WHERE cp.category_id = t.category_id)
  FROM tmp_lsb_cats t;

INSERT INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT t.category_id, @p, IFNULL(MIN(i.position), 1) - 1, 1, 1, 4
  FROM tmp_lsb_cats t
  LEFT JOIN catalog_category_product_index i ON i.category_id = t.category_id AND i.store_id = 1 AND i.product_id <> @p
 WHERE EXISTS (SELECT 1 FROM core_store WHERE store_id = 1)
   AND EXISTS (SELECT 1 FROM catalog_product_website WHERE product_id = @p AND website_id = 1)
 GROUP BY t.category_id
ON DUPLICATE KEY UPDATE is_parent = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_lsb_cats;
