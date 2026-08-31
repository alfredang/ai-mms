-- 1297: Populate the two new categories with every funded (TGS-) course from
-- their source series pages, pinned in the series page order.
--
--   WSQ Multi AI Agents Courses (234) <- multi-agents-series     ( 7 courses)
--   WSQ AI Applications Courses (383) <- ai-applications-series  (26 courses)
--
-- Source of truth is catalog_category_product_index at store 1 — what a visitor
-- actually SEES on the series page. This matters for AI Applications: the
-- ai-applications-series category holds only 10 TGS- rows of its own, but the
-- live page renders 26 because it is an anchor with 12 child subcategories and
-- inherits their products. Reading catalog_category_product alone would have
-- silently dropped 16 courses the owner can see on that page.
--
-- (multi-agents-series has no such gap: 7 by either measure.)
--
-- TGS- covers WSQ, CASL and IBF alike, so both destinations stay all-TGS and
-- the funded-first rule cannot be violated.
--
-- Business-key lookups only. Idempotent.

SET @uk := (SELECT attribute_id FROM eav_attribute
            WHERE entity_type_id = 3 AND attribute_code = 'url_key' LIMIT 1);

-- Resolve by the NEW slug (1296 has renamed them by now), falling back to the
-- OLD slug so this file is correct even if it is ever applied before 1296 or
-- re-run out of order. Without the fallback both lookups return NULL and every
-- insert below silently matches zero rows, leaving both pages empty.
SET @c_multi := COALESCE(
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk AND value='wsq-multi-ai-agents-courses' LIMIT 1),
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk AND value='autodesk-navisworks-training' LIMIT 1));
SET @c_apps  := COALESCE(
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk AND value='wsq-ai-applications-courses' LIMIT 1),
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk AND value='microsoft-access-training' LIMIT 1));
SET @s_multi := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id=0 AND attribute_id=@uk AND value='multi-agents-series' LIMIT 1);
SET @s_apps  := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id=0 AND attribute_id=@uk AND value='ai-applications-series' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS tmp_src2;
CREATE TEMPORARY TABLE tmp_src2 (
  dest_id INT, product_id INT, pos INT,
  PRIMARY KEY (dest_id, product_id)
);

INSERT IGNORE INTO tmp_src2 (dest_id, product_id, pos)
SELECT @c_multi, i.product_id, i.position
FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @s_multi AND i.store_id = 1 AND p.sku LIKE 'TGS-%'
  AND @c_multi IS NOT NULL AND @s_multi IS NOT NULL;

INSERT IGNORE INTO tmp_src2 (dest_id, product_id, pos)
SELECT @c_apps, i.product_id, i.position
FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @s_apps AND i.store_id = 1 AND p.sku LIKE 'TGS-%'
  AND @c_apps IS NOT NULL AND @s_apps IS NOT NULL;

DELETE FROM catalog_category_product
WHERE category_id IN (@c_multi, @c_apps) AND @c_multi IS NOT NULL AND @c_apps IS NOT NULL;
DELETE FROM catalog_category_product_index
WHERE category_id IN (@c_multi, @c_apps) AND @c_multi IS NOT NULL AND @c_apps IS NOT NULL;

INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT t.dest_id, t.product_id, t.pos FROM tmp_src2 t
ON DUPLICATE KEY UPDATE position = VALUES(position);

INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT t.dest_id, t.product_id, t.pos, 1, s.store_id, MAX(i.visibility)
FROM tmp_src2 t
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = t.product_id AND i.store_id = s.store_id
GROUP BY t.dest_id, t.product_id, s.store_id, t.pos
ON DUPLICATE KEY UPDATE position = VALUES(position);
