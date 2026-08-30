-- 1239: Rename C138 "AI Vibe Coding with Python Fundamentals" to
-- "AI Vibe Coding for Python", with a new url_key + 301 and a freshly
-- rendered branded R2 cover.
--
-- SKU stays C138. Content, price, duration and category memberships are
-- unchanged — name, slug, meta_title and cover only.
--
-- Redirect handling: the old slug is 'ai-vibe-coding-with-python', which is
-- already the TARGET of ~60 historical Magento rewrites from this course's
-- earlier names (python-3-essential-training, wsq-python-intermediate-level-
-- course, and so on). Those all point at the bare old slug, so a single 301
-- from 'ai-vibe-coding-with-python.html' keeps every one of them resolving —
-- in two hops for the ancient ones, one hop for the current slug.
--
-- The 301 uses a SLUG-derived id_path ('custom/ai-vibe-coding-with-python-301'),
-- not 'custom/c138-301': a second rename of the same SKU would collide with
-- the SKU-derived form and INSERT IGNORE would silently skip it, leaving the
-- previous slug 404ing. See feedback_second_rename_reuses_301_id_path.
--
-- SG-guarded; C-prefix SKU and this url_key are SG-only (partner no-op).
-- Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_pname   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_purlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_pmetat  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_pcimg   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

SET @e138 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C138' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Name, slug, meta_title, cover.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e138, 'AI Vibe Coding for Python'
FROM dual WHERE @e138 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e138 AND attribute_id = @a_pname AND store_id <> 0
  AND @e138 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e138, 'ai-vibe-coding-for-python'
FROM dual WHERE @e138 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e138 AND attribute_id = @a_purlkey AND store_id <> 0
  AND @e138 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e138, 'AI Vibe Coding for Python | Tertiary Courses Singapore'
FROM dual WHERE @e138 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e138, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C138-20260830-121027.png'
FROM dual WHERE @e138 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2) 301 the old slug, seat the new system rewrite.
-- ---------------------------------------------------------------------------

DELETE FROM core_url_rewrite
WHERE request_path = 'ai-vibe-coding-with-python.html'
  AND store_id = 1
  AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/ai-vibe-coding-with-python-301',
       'ai-vibe-coding-with-python.html', 'ai-vibe-coding-for-python.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e138) AND store_id = 1
  AND request_path <> 'ai-vibe-coding-for-python.html'
  AND @e138 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e138), 'ai-vibe-coding-for-python.html',
       CONCAT('catalog/product/view/id/', @e138), 1, @e138
FROM dual WHERE @e138 IS NOT NULL AND @is_sg > 0;
