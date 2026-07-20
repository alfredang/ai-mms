-- Rename the category "Java & Scala" -> "Java" (category 75, level 5, under
-- Adult Courses > Infocomm Technology > Programming).
--
-- Name only. url_key stays 'java-programming-courses' so the category URL,
-- existing links and SEO are unchanged (no rewrite churn, no 301 needed).
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
SET value = 'Java'
WHERE attribute_id = @a_name AND value = 'Java & Scala';

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  "UPDATE catalog_category_flat_store_1 SET name='Java' WHERE name='Java & Scala'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  "UPDATE catalog_category_flat_store_2 SET name='Java' WHERE name='Java & Scala'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  "UPDATE catalog_category_flat_store_3 SET name='Java' WHERE name='Java & Scala'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
