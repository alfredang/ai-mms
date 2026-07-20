-- Rename the top-level menu category "Exam Prep" -> "Certification Exam Prep".
--
-- This is the level-2 root of the Exam Prep mega-menu (49 children, each already
-- named "<Vendor> Certification Exam Prep"), so the new name reads consistently
-- with its own dropdown.
--
-- Name only. url_key is untouched, so the category keeps its existing URL —
-- no rewrite churn, no 301 needed, and MMD_FlatCategoryUrl's /<url_key>.html
-- rule is unaffected. Deliberately NO url_key/url_path writes.
--
-- Matched on the exact current name and scoped to level = 2 so the 49 child
-- categories (all of which contain the words "Certification Exam Prep") cannot
-- be caught. Resolved by name rather than a hardcoded id so it lands on every
-- site; a no-op once renamed.
-- Mirrored into catalog_category_flat_store_{1,2,3} behind information_schema
-- guards. After deploy: reindex catalog_category_flat, flush block_html/FPC.

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');

SET @ep := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id = e.entity_id
    AND v.attribute_id = @a_name AND v.store_id = 0
  WHERE TRIM(v.value) = 'Exam Prep' AND e.level = 2 LIMIT 1) r);

UPDATE catalog_category_entity_varchar
SET value = 'Certification Exam Prep'
WHERE attribute_id = @a_name AND entity_id = @ep AND @ep IS NOT NULL;

SET @flat := " SET name = 'Certification Exam Prep' WHERE entity_id = @ep AND @ep IS NOT NULL";

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0, CONCAT('UPDATE catalog_category_flat_store_1', @flat), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0, CONCAT('UPDATE catalog_category_flat_store_2', @flat), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0, CONCAT('UPDATE catalog_category_flat_store_3', @flat), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
