-- 1223: Convert C28 "AI Vibe Coding for PHP and MySQL" into
-- "AI Agent Security", and move it from the AI Vibe Coding Series to the
-- AI Security Series.
--
-- SKU stays C28. New name, new url_key with a 301 from the old one, freshly
-- rendered branded R2 cover, new meta. The course details ("What's This
-- Course About" = short_description, "What You'll Learn" = description) are
-- copied at store 0 from the requested donor,
-- TGS-2025060473 "WSQ - AI Security for Autonomous AI Agents".
--
-- It also leaves the Programming / PHP & MYSQL trees, which no longer
-- describe the course (same treatment as the C811/C903 conversions). It
-- keeps All Courses (3), Infocomm Technology (55) and AI Courses (252).
--
-- Placed first in the AI Security Series non-WSQ block, ahead of the related
-- "AI Security and Governance for AI Agents"; that category carries a
-- curated non-WSQ order, so the whole block is re-pinned here. Positions
-- stay in the 101+ band, after every WSQ/CASL/IBF course.
--
-- NOTE: the donor is a 8h WSQ course and C28 is 15h; only the descriptive
-- copy is copied, never duration, price or funding attributes.
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

SET @e28   := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C28' LIMIT 1);
SET @donor := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025060473' LIMIT 1);

SET @vibe := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-vibe-coding-series' LIMIT 1);
SET @security := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-security-series' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Name, slug, meta, cover.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e28, 'AI Agent Security'
FROM dual WHERE @e28 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e28 AND attribute_id = @a_pname AND store_id <> 0
  AND @e28 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e28, 'ai-agent-security'
FROM dual WHERE @e28 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e28 AND attribute_id = @a_purlkey AND store_id <> 0
  AND @e28 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e28, 'AI Agent Security | Tertiary Courses Singapore'
FROM dual WHERE @e28 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e28, 'Secure AI agents end to end - threat models, prompt injection and tool abuse, identity and permissions, monitoring and incident response for autonomous agents.'
FROM dual WHERE @e28 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e28, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C28-20260830-075321.png'
FROM dual WHERE @e28 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2) Copy the course details from the donor course at store 0.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e28, d.value
FROM (SELECT value FROM catalog_product_entity_text
      WHERE entity_id = @donor AND store_id = 0 AND attribute_id = @a_psdesc LIMIT 1) d
WHERE @e28 IS NOT NULL AND @donor IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e28, d.value
FROM (SELECT value FROM catalog_product_entity_text
      WHERE entity_id = @donor AND store_id = 0 AND attribute_id = @a_pdesc LIMIT 1) d
WHERE @e28 IS NOT NULL AND @donor IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e28 AND attribute_id IN (@a_pdesc, @a_psdesc) AND store_id <> 0
  AND @e28 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 3) 301 the old URL, seat the new system rewrite.
-- ---------------------------------------------------------------------------

DELETE FROM core_url_rewrite
WHERE request_path = 'ai-vibe-coding-for-php-and-mysql.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c28-301', 'ai-vibe-coding-for-php-and-mysql.html', 'ai-agent-security.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e28) AND store_id = 1
  AND request_path <> 'ai-agent-security.html'
  AND @e28 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e28), 'ai-agent-security.html',
       CONCAT('catalog/product/view/id/', @e28), 1, @e28
FROM dual WHERE @e28 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 4) Leave the AI Vibe Coding Series and the Programming / PHP trees.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
WHERE cp.product_id = @e28
  AND cp.category_id IN (@vibe, 31, 34)
  AND @e28 IS NOT NULL AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
WHERE i.product_id = @e28
  AND i.category_id IN (@vibe, 31, 34)
  AND @e28 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 5) Join the AI Security Series, first in its non-WSQ block.
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @security, p.entity_id, 101
FROM catalog_product_entity p
WHERE @security IS NOT NULL AND @is_sg > 0
  AND p.sku = 'C28';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @security, p.entity_id, 101, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @security IS NOT NULL AND @is_sg > 0
  AND p.sku = 'C28'
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C28'   THEN 101
  WHEN 'C1440' THEN 102
  WHEN 'C434'  THEN 103
  WHEN 'C1750' THEN 104
END
WHERE cp.category_id = @security
  AND p.sku IN ('C28', 'C1440', 'C434', 'C1750');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C28'   THEN 101
  WHEN 'C1440' THEN 102
  WHEN 'C434'  THEN 103
  WHEN 'C1750' THEN 104
END
WHERE i.category_id = @security
  AND p.sku IN ('C28', 'C1440', 'C434', 'C1750');
