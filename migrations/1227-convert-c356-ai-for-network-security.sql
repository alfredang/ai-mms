-- 1227: Convert C356 "AI Vibe Coding for Java" into "AI for Network
-- Security", and move it from the AI Vibe Coding Series to the AI Security
-- Series.
--
-- SKU stays C356. New name, new url_key with a 301 from the old one, freshly
-- rendered branded R2 cover, new meta. The course details ("What's This
-- Course About" = short_description, "What You'll Learn" = description) are
-- copied at store 0 from the requested donor TGS-2024051414
-- "WSQ - AI for Network Security" — descriptive copy only, never duration,
-- price or funding attributes.
--
-- It also leaves the Programming / Java trees, which no longer describe the
-- course (same treatment as the C28/C811/C903 conversions). It keeps All
-- Courses (3), Infocomm Technology (55) and AI Courses (252).
--
-- Placed in the AI Security Series curated non-WSQ block after
-- "AI for Cyber Security", so the two "AI for ... Security" courses sit
-- together; the whole block is re-pinned (1225 order plus this course) so no
-- member is left unpinned to drift. Positions stay in the 101+ band, after
-- every WSQ/CASL/IBF course.
--
-- Its funding_and_grant block, created by 1226 with the AI Vibe Coding Series
-- target, is repointed at the AI Security Series target
-- (WSQ - AI Security for Autonomous AI Agents, verified 200) to match the
-- course's new home. Content-only UPDATE — never a cms/block model save.
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

SET @e356  := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C356' LIMIT 1);
SET @donor := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024051414' LIMIT 1);

SET @vibe := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-vibe-coding-series' LIMIT 1);
SET @security := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-security-series' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Name, slug, meta, cover.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e356, 'AI for Network Security'
FROM dual WHERE @e356 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e356 AND attribute_id = @a_pname AND store_id <> 0
  AND @e356 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e356, 'ai-for-network-security'
FROM dual WHERE @e356 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e356 AND attribute_id = @a_purlkey AND store_id <> 0
  AND @e356 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e356, 'AI for Network Security | Tertiary Courses Singapore'
FROM dual WHERE @e356 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e356, 'Apply AI to network security - anomaly and intrusion detection, traffic analysis, automated threat response and AI-assisted network defence.'
FROM dual WHERE @e356 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e356, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C356-20260830-080542.png'
FROM dual WHERE @e356 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2) Copy the course details from the donor course at store 0.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e356, d.value
FROM (SELECT value FROM catalog_product_entity_text
      WHERE entity_id = @donor AND store_id = 0 AND attribute_id = @a_psdesc LIMIT 1) d
WHERE @e356 IS NOT NULL AND @donor IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e356, d.value
FROM (SELECT value FROM catalog_product_entity_text
      WHERE entity_id = @donor AND store_id = 0 AND attribute_id = @a_pdesc LIMIT 1) d
WHERE @e356 IS NOT NULL AND @donor IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e356 AND attribute_id IN (@a_pdesc, @a_psdesc) AND store_id <> 0
  AND @e356 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 3) 301 the old URL, seat the new system rewrite.
-- ---------------------------------------------------------------------------

DELETE FROM core_url_rewrite
WHERE request_path = 'ai-vibe-coding-for-java.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c356-301', 'ai-vibe-coding-for-java.html', 'ai-for-network-security.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e356) AND store_id = 1
  AND request_path <> 'ai-for-network-security.html'
  AND @e356 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e356), 'ai-for-network-security.html',
       CONCAT('catalog/product/view/id/', @e356), 1, @e356
FROM dual WHERE @e356 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 4) Leave the AI Vibe Coding Series and the Programming / Java trees.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
WHERE cp.product_id = @e356
  AND cp.category_id IN (@vibe, 31, 75)
  AND @e356 IS NOT NULL AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
WHERE i.product_id = @e356
  AND i.category_id IN (@vibe, 31, 75)
  AND @e356 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 5) Join the AI Security Series and re-pin its curated non-WSQ block.
--    Order: AI for Cyber Security, AI for Network Security,
--           AI Security and Governance, AI Agent Security, CompTIA SecAI+.
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @security, p.entity_id, 102
FROM catalog_product_entity p
WHERE @security IS NOT NULL AND @is_sg > 0
  AND p.sku = 'C356';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @security, p.entity_id, 102, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @security IS NOT NULL AND @is_sg > 0
  AND p.sku = 'C356'
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C434'  THEN 101
  WHEN 'C356'  THEN 102
  WHEN 'C1440' THEN 103
  WHEN 'C28'   THEN 104
  WHEN 'C1750' THEN 105
END
WHERE cp.category_id = @security
  AND p.sku IN ('C434', 'C356', 'C1440', 'C28', 'C1750');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C434'  THEN 101
  WHEN 'C356'  THEN 102
  WHEN 'C1440' THEN 103
  WHEN 'C28'   THEN 104
  WHEN 'C1750' THEN 105
END
WHERE i.category_id = @security
  AND p.sku IN ('C434', 'C356', 'C1440', 'C28', 'C1750');

-- ---------------------------------------------------------------------------
-- 6) Repoint its funding card at the AI Security Series target.
-- ---------------------------------------------------------------------------

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-ai-for-network-security.html" title="WSQ - AI for Network Security">WSQ - AI for Network Security</a></span></p>'
WHERE identifier = 'course_C356_funding_and_grant'
  AND @is_sg > 0;
