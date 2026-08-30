-- 1240: Convert C169 "AI Vibe Coding with C" into "Generative AI for
-- Interviewing", and move it from the AI Vibe Coding Series to AI for HR.
--
-- SKU stays C169. New name, new url_key with a 301 from the old one, freshly
-- rendered branded R2 cover, new meta. The course details ("What's This
-- Course About" = short_description, "What You'll Learn" = description) are
-- copied at store 0 from the requested donor TGS-2024051421
-- "WSQ - Generative AI for Interviewing" — descriptive copy only, never
-- duration, price or funding attributes.
--
-- It also leaves the Programming / C-C++-C# trees, which no longer describe
-- the course (same treatment as the C28/C356/C811/C903 conversions). It keeps
-- All Courses (3), Infocomm Technology (55) and AI Courses (252).
--
-- AI for HR already carries the WSQ version of this course (TGS-2024051421,
-- pinned at 2 by 1235); that stays, and the non-WSQ C169 joins the non-WSQ
-- block below it. The block is re-pinned with every member covered so none
-- drifts above it (see feedback_curated_leftovers_must_be_pinned_not_parked).
--
-- The 301 uses a slug-derived id_path so a future rename cannot silently
-- collide with it (see feedback_second_rename_reuses_301_id_path).
--
-- SG-guarded; C-prefix SKU and these url_keys are SG-only (partner no-op).
-- Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_pname   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_purlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_pmetat  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_pmetad  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_pdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_psdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_pcimg   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @e169  := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C169' LIMIT 1);
SET @donor := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024051421' LIMIT 1);

SET @vibe := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-vibe-coding-series' LIMIT 1);
SET @hr := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-hr-courses' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Name, slug, meta, cover.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e169, 'Generative AI for Interviewing'
FROM dual WHERE @e169 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e169 AND attribute_id = @a_pname AND store_id <> 0
  AND @e169 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e169, 'generative-ai-for-interviewing'
FROM dual WHERE @e169 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e169 AND attribute_id = @a_purlkey AND store_id <> 0
  AND @e169 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e169, 'Generative AI for Interviewing | Tertiary Courses Singapore'
FROM dual WHERE @e169 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e169, 'Use generative AI across the interview process - structured question design, candidate evaluation, interview preparation and fair, consistent hiring decisions.'
FROM dual WHERE @e169 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e169, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C169-20260830-121257.png'
FROM dual WHERE @e169 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2) Copy the course details from the donor at store 0.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e169, d.value
FROM (SELECT value FROM catalog_product_entity_text
      WHERE entity_id = @donor AND store_id = 0 AND attribute_id = @a_psdesc LIMIT 1) d
WHERE @e169 IS NOT NULL AND @donor IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e169, d.value
FROM (SELECT value FROM catalog_product_entity_text
      WHERE entity_id = @donor AND store_id = 0 AND attribute_id = @a_pdesc LIMIT 1) d
WHERE @e169 IS NOT NULL AND @donor IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e169 AND attribute_id IN (@a_pdesc, @a_psdesc) AND store_id <> 0
  AND @e169 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 3) 301 the old slug, seat the new system rewrite.
-- ---------------------------------------------------------------------------

DELETE FROM core_url_rewrite
WHERE request_path = 'ai-vibe-coding-with-c.html'
  AND store_id = 1
  AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/ai-vibe-coding-with-c-301',
       'ai-vibe-coding-with-c.html', 'generative-ai-for-interviewing.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e169) AND store_id = 1
  AND request_path <> 'generative-ai-for-interviewing.html'
  AND @e169 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e169), 'generative-ai-for-interviewing.html',
       CONCAT('catalog/product/view/id/', @e169), 1, @e169
FROM dual WHERE @e169 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 4) Leave the AI Vibe Coding Series and the Programming / C trees.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
WHERE cp.product_id = @e169
  AND cp.category_id IN (@vibe, 31, 80)
  AND @e169 IS NOT NULL AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
WHERE i.product_id = @e169
  AND i.category_id IN (@vibe, 31, 80)
  AND @e169 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 5) Join AI for HR, first in its non-WSQ block.
--    WSQ pair stays at 1..2; non-WSQ becomes C169, C811, C903, C820.
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @hr, p.entity_id, 101
FROM catalog_product_entity p
WHERE @hr IS NOT NULL AND @is_sg > 0
  AND p.sku = 'C169';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @hr, p.entity_id, 101, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @hr IS NOT NULL AND @is_sg > 0
  AND p.sku = 'C169'
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C169' THEN 101
  WHEN 'C811' THEN 102
  WHEN 'C903' THEN 103
  WHEN 'C820' THEN 104
END
WHERE cp.category_id = @hr
  AND p.sku IN ('C169', 'C811', 'C903', 'C820');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C169' THEN 101
  WHEN 'C811' THEN 102
  WHEN 'C903' THEN 103
  WHEN 'C820' THEN 104
END
WHERE i.category_id = @hr
  AND p.sku IN ('C169', 'C811', 'C903', 'C820');
