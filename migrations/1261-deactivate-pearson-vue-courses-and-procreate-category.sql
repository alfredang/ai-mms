-- 1261: Deactivate the four non-WSQ Pearson VUE Certified IT Specialist
-- courses (status = 2) and three category pages:
--   C184  - pearson-vue-certified-it-specialist-network-security
--   C815  - pearson-vue-certified-it-specialist-networking
--   C920  - pearson-vue-certified-it-specialist-cybersecurity
--   C1814 - pearson-vue-certified-it-specialist-cloud-computing
--
-- Categories deactivated (is_active = 0, include_in_menu = 0 at store 0):
--   435 pearson-vue-it-specialists        - holds exactly these 4 courses -> empty
--   402 person-vue-it-specialist-exam-prep - child of 435, same 4 courses -> empty
--   422 procreate-digital-art-courses     - deactivated on explicit request; its
--       remaining course keeps its other category memberships and stays live.
--
-- The WSQ Pearson VUE courses (TGS- SKUs, wsq-pearson-* URLs) are NOT touched —
-- they were already repurposed into AI courses and 301 to live pages.
--
-- Search redirects pointing at any of the seven killed URLs are cleared
-- (632 pattern) so those terms fall back to normal catalog search instead of
-- dead-ending on a 404. Redirects to the live wsq-* targets are left alone.
--
-- Course-disable pattern as migrations 833-842 / 1253 / 1254: default-scope
-- status row + flip per-store overrides. Category pattern as 1253.
-- A catalog reindex + cache flush after apply makes the changes visible.
--
-- SG-guarded; partner no-op. Idempotent.

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
-- 1) Disable the four courses.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, e.entity_id, 2
FROM catalog_product_entity e
WHERE e.sku IN ('C184', 'C815', 'C920', 'C1814')
  AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
SET i.value = 2
WHERE i.attribute_id = @status_attr
  AND e.sku IN ('C184', 'C815', 'C920', 'C1814')
  AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 2) Deactivate the three categories (resolved by url_key; ids differ per site).
-- ---------------------------------------------------------------------------

SET @cat_pv := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'pearson-vue-it-specialists' LIMIT 1
);
SET @cat_pvchild := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'person-vue-it-specialist-exam-prep' LIMIT 1
);
SET @cat_procreate := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'procreate-digital-art-courses' LIMIT 1
);

-- Drop per-store overrides so the store-0 disable wins everywhere.
DELETE FROM catalog_category_entity_int
WHERE entity_id IN (@cat_pv, @cat_pvchild, @cat_procreate)
  AND attribute_id IN (@a_cactive, @a_cmenu)
  AND store_id <> 0
  AND @is_sg > 0;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cactive, 0, c.entity_id, 0
FROM catalog_category_entity c
WHERE c.entity_id IN (@cat_pv, @cat_pvchild, @cat_procreate)
  AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmenu, 0, c.entity_id, 0
FROM catalog_category_entity c
WHERE c.entity_id IN (@cat_pv, @cat_pvchild, @cat_procreate)
  AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flat mirror (store 1), guarded; 'DO 0' no-op where the table is absent.
SET @has_flat := (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'catalog_category_flat_store_1'
);

SET @sql := IF(@has_flat > 0 AND @is_sg > 0,
  'UPDATE catalog_category_flat_store_1 SET is_active = 0, include_in_menu = 0
   WHERE entity_id IN (@cat_pv, @cat_pvchild, @cat_procreate)',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;

-- ---------------------------------------------------------------------------
-- 3) Clear search redirects that point at the killed pages (632 pattern).
-- ---------------------------------------------------------------------------

UPDATE catalogsearch_query
SET redirect = NULL
WHERE @is_sg > 0
  AND (
    redirect LIKE '%/pearson-vue-certified-it-specialist-network-security.html%'
    OR redirect LIKE '%/pearson-vue-certified-it-specialist-networking.html%'
    OR redirect LIKE '%/pearson-vue-certified-it-specialist-cybersecurity.html%'
    OR redirect LIKE '%/pearson-vue-certified-it-specialist-cloud-computing.html%'
    OR redirect LIKE '%/pearson-vue-it-specialists.html%'
    OR redirect LIKE '%/person-vue-it-specialist-exam-prep.html%'
    OR redirect LIKE '%/procreate-digital-art-courses.html%'
  );
