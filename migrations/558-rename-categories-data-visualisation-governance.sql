-- Rename three menu categories:
--   "Data Visualisation and Dashboard" -> "Data Visualisation"
--   "Data Governance & Protection"     -> "Data Governance"
--   "Google Cloud Platform"            -> "Google Cloud"   (under Cloud)
--
-- The Google Cloud match is deliberately EXACT: sibling categories
-- "Google Cloud Practice Exams" and "Google Cloud Certification Prep" exist and
-- must not be touched, so never loosen this to a LIKE 'Google Cloud%'.
--
-- Name only. url_keys stay 'data-visualisation-courses' and
-- 'data-governance-protection-courses' so category URLs, existing links and SEO
-- are unchanged (no rewrite churn, no 301 needed).
--
-- Matched by the CURRENT NAME rather than a hardcoded id so it lands on the
-- right row on every site (ids differ per instance) and is a no-op once renamed.
-- Updates store 0 and any per-store override, then mirrors into each
-- catalog_category_flat_store_N present on this instance (SG=1, MY=2, GH=3),
-- information_schema-guarded so a missing flat table is a no-op — the storefront
-- reads flat and there is no reindex hook at deploy.
-- Idempotent. After deploy, reindex catalog_category_flat + flush block_html/FPC.

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');

UPDATE catalog_category_entity_varchar
SET value = 'Data Visualisation'
WHERE attribute_id = @a_name AND value = 'Data Visualisation and Dashboard';

UPDATE catalog_category_entity_varchar
SET value = 'Data Governance'
WHERE attribute_id = @a_name AND value = 'Data Governance & Protection';

UPDATE catalog_category_entity_varchar
SET value = 'Google Cloud'
WHERE attribute_id = @a_name AND value = 'Google Cloud Platform';

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  "UPDATE catalog_category_flat_store_1 SET name='Data Visualisation' WHERE name='Data Visualisation and Dashboard'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  "UPDATE catalog_category_flat_store_1 SET name='Data Governance' WHERE name='Data Governance & Protection'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  "UPDATE catalog_category_flat_store_1 SET name='Google Cloud' WHERE name='Google Cloud Platform'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  "UPDATE catalog_category_flat_store_2 SET name='Data Visualisation' WHERE name='Data Visualisation and Dashboard'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  "UPDATE catalog_category_flat_store_2 SET name='Data Governance' WHERE name='Data Governance & Protection'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  "UPDATE catalog_category_flat_store_2 SET name='Google Cloud' WHERE name='Google Cloud Platform'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  "UPDATE catalog_category_flat_store_3 SET name='Data Visualisation' WHERE name='Data Visualisation and Dashboard'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  "UPDATE catalog_category_flat_store_3 SET name='Data Governance' WHERE name='Data Governance & Protection'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  "UPDATE catalog_category_flat_store_3 SET name='Google Cloud' WHERE name='Google Cloud Platform'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
