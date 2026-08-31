-- 1295: Populate the two renamed categories with every funded (TGS-) course
-- from their source series pages, pinned in the series page order.
--
--   WSQ AI Security Courses    (284) <- ai-security-series      (8 courses)
--   WSQ AI Vibe Coding Courses (425) <- ai-vibe-coding-series   (22 courses)
--
-- Source of truth is catalog_category_product_index at store 1, i.e. what a
-- visitor actually SEES on the series page, not just catalog_category_product.
-- For these two series the two agree (8 and 22); the AI Applications series
-- differs because of anchor inheritance and is handled in 1297.
--
-- TGS- covers WSQ, CASL and IBF alike — the SKU prefix is the only test, so
-- both categories end up all-TGS and the funded-first rule cannot be violated.
--
-- Existing membership is REPLACED, not merged: 284 previously held the AI
-- Ethics and Governance set and 425 the old Programming & Vibe Coding set, and
-- leaving those rows would mix retired topics into the renamed page. The pins
-- are copied from the series' own positions so both pages read in the same
-- order as the series page they came from.
--
-- Business-key lookups only. Idempotent.

SET @uk := (SELECT attribute_id FROM eav_attribute
            WHERE entity_type_id = 3 AND attribute_code = 'url_key' LIMIT 1);

-- New slug first (1294 renames them), old slug as fallback so this file cannot
-- silently no-op if applied before 1294 or re-run out of order.
SET @c_sec  := COALESCE(
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk AND value='wsq-ai-security-courses' LIMIT 1),
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk AND value='wsq-ai-ethics-and-governance-courses' LIMIT 1));
SET @c_vibe := COALESCE(
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk AND value='wsq-ai-vibe-coding-courses' LIMIT 1),
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk
     AND value='wsq-programming-vibe-coding-courses-tertiary-courses-singapore' LIMIT 1));
SET @s_sec  := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id=0 AND attribute_id=@uk AND value='ai-security-series' LIMIT 1);
SET @s_vibe := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id=0 AND attribute_id=@uk AND value='ai-vibe-coding-series' LIMIT 1);

-- Snapshot the funded membership of both series (index at store 1).
DROP TEMPORARY TABLE IF EXISTS tmp_src;
CREATE TEMPORARY TABLE tmp_src (
  dest_id INT, product_id INT, pos INT,
  PRIMARY KEY (dest_id, product_id)
);

INSERT IGNORE INTO tmp_src (dest_id, product_id, pos)
SELECT @c_sec, i.product_id, i.position
FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @s_sec AND i.store_id = 1 AND p.sku LIKE 'TGS-%'
  AND @c_sec IS NOT NULL AND @s_sec IS NOT NULL;

INSERT IGNORE INTO tmp_src (dest_id, product_id, pos)
SELECT @c_vibe, i.product_id, i.position
FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @s_vibe AND i.store_id = 1 AND p.sku LIKE 'TGS-%'
  AND @c_vibe IS NOT NULL AND @s_vibe IS NOT NULL;

-- Replace the old topic membership on both destinations.
DELETE FROM catalog_category_product
WHERE category_id IN (@c_sec, @c_vibe) AND @c_sec IS NOT NULL AND @c_vibe IS NOT NULL;
DELETE FROM catalog_category_product_index
WHERE category_id IN (@c_sec, @c_vibe) AND @c_sec IS NOT NULL AND @c_vibe IS NOT NULL;

INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT t.dest_id, t.product_id, t.pos FROM tmp_src t
ON DUPLICATE KEY UPDATE position = VALUES(position);

INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT t.dest_id, t.product_id, t.pos, 1, s.store_id, MAX(i.visibility)
FROM tmp_src t
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = t.product_id AND i.store_id = s.store_id
GROUP BY t.dest_id, t.product_id, s.store_id, t.pos
ON DUPLICATE KEY UPDATE position = VALUES(position);
