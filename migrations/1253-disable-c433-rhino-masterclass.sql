-- 1253: Disable the retired course C433 "Rhino Masterclass" (status = 2).
--
-- Same pattern as migrations 833-842: set the default-scope (store_id 0)
-- status to Disabled and flip any per-store override rows too — an Enabled
-- override keeps the course live on that store even when store 0 says
-- Disabled.
--
-- C433 is the ONLY product in the "Rhino" category (146), which is currently
-- active and in the menu. Disabling the course would leave an empty category
-- page reachable from the nav, so 146 is deactivated and hidden from the menu
-- as well — the same treatment the category-ordering skill prescribes for a
-- category with no storefront products. Its parent trees (3D Modeling, Media
-- & Design, Software Training) keep their other courses and are untouched.
--
-- The category's ancestors' children_count is left alone: deactivating is not
-- a tree move, and Magento counts children structurally, not by visibility.
--
-- A catalog reindex + cache flush after apply makes both changes visible.
--
-- SG-guarded; C-prefix SKU is SG-only (partner no-op). Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @status_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status');
SET @a_curlkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_cactive   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_active');
SET @a_cmenu     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'include_in_menu');

-- ---------------------------------------------------------------------------
-- 1) Disable the course.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2
FROM catalog_product_entity e
WHERE e.sku = 'C433' AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE i.attribute_id = @status_attr
  AND e.sku = 'C433'
  AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 2) Deactivate the now-empty "Rhino" category and drop it from the menu.
-- ---------------------------------------------------------------------------

SET @rhino := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'rhino-trainings' LIMIT 1
);

-- Fall back to the category id if that url_key differs on this instance.
SET @rhino := IF(@rhino IS NULL,
  (SELECT cp.category_id
   FROM catalog_category_product cp
   JOIN catalog_product_entity p ON p.entity_id = cp.product_id
   WHERE p.sku = 'C433' AND cp.category_id = 146 LIMIT 1),
  @rhino);

DELETE FROM catalog_category_entity_int
WHERE entity_id = @rhino
  AND attribute_id IN (@a_cactive, @a_cmenu)
  AND store_id <> 0
  AND @rhino IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cactive, 0, @rhino, 0
FROM dual WHERE @rhino IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmenu, 0, @rhino, 0
FROM dual WHERE @rhino IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flat mirror (store 1), guarded; 'DO 0' no-op.
SET @has_flat := (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'catalog_category_flat_store_1'
);

SET @sql := IF(@has_flat > 0 AND @rhino IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET is_active = 0, include_in_menu = 0 WHERE entity_id = @rhino',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;
