-- 1255: Rename C820 "AI for HR" to "AI for HR Management", with a new
-- url_key + 301 and a freshly rendered branded R2 cover.
--
-- SKU stays C820. Content, price, duration and category memberships are
-- unchanged — name, slug, meta_title and cover only.
--
-- The old slug 'ai-for-hr' is NOT the AI for HR CATEGORY's url_key (that is
-- 'ai-for-hr-courses', chosen in 1204 precisely because this product owned
-- 'ai-for-hr.html'). Freeing the product slug does not affect the category
-- page; the 301 below keeps the old product URL working.
--
-- The 301 uses a slug-derived id_path so a future rename cannot silently
-- collide (see feedback_second_rename_reuses_301_id_path).
--
-- SG-guarded; C-prefix SKU is SG-only (partner no-op). Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_pname   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_purlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_pmetat  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_pcimg   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

SET @e820 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C820' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Name, slug, meta_title, cover.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e820, 'AI for HR Management'
FROM dual WHERE @e820 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e820 AND attribute_id = @a_pname AND store_id <> 0
  AND @e820 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e820, 'ai-for-hr-management'
FROM dual WHERE @e820 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e820 AND attribute_id = @a_purlkey AND store_id <> 0
  AND @e820 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e820, 'AI for HR Management | Tertiary Courses Singapore'
FROM dual WHERE @e820 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e820, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C820-20260830-133403.png'
FROM dual WHERE @e820 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2) 301 the old slug, seat the new system rewrite.
-- ---------------------------------------------------------------------------

DELETE FROM core_url_rewrite
WHERE request_path = 'ai-for-hr.html'
  AND store_id = 1
  AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/ai-for-hr-301',
       'ai-for-hr.html', 'ai-for-hr-management.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e820) AND store_id = 1
  AND request_path <> 'ai-for-hr-management.html'
  AND @e820 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e820), 'ai-for-hr-management.html',
       CONCAT('catalog/product/view/id/', @e820), 1, @e820
FROM dual WHERE @e820 IS NOT NULL AND @is_sg > 0;
