-- Move "Python" to the top of the Programming menu dropdown.
--
-- Current order (position): C/C++/C# 1, Java 2, PHP & MYSQL 3, Python 4,
-- R 5, Swift 6, VBA 7.
-- New order: Python 1, C/C++/C# 2, Java 3, PHP & MYSQL 4, rest unchanged.
--
-- Position only — no name, url_key or parent change, so URLs and SEO are
-- untouched. Resolved by NAME under the parent named 'Programming' rather than
-- hardcoded ids so it lands correctly on every site (ids differ per instance).
-- Note the stored names carry a trailing space ('Python ', 'R ') — matched with
-- TRIM() so the migration is not defeated by that.
--
-- Idempotent: re-running sets the same absolute positions.
-- The storefront menu reads the flat tables, so positions are mirrored into each
-- catalog_category_flat_store_N present on this instance (SG=1, MY=2, GH=3),
-- information_schema-guarded so a missing flat table is a no-op.
-- After deploy, reindex catalog_category_flat + flush block_html/FPC.

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');

SET @parent := (
  SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v
    ON v.entity_id = e.entity_id AND v.attribute_id = @a_name AND v.store_id = 0
  WHERE TRIM(v.value) = 'Programming'
  LIMIT 1
);

UPDATE catalog_category_entity c
JOIN catalog_category_entity_varchar v
  ON v.entity_id = c.entity_id AND v.attribute_id = @a_name AND v.store_id = 0
SET c.position = CASE TRIM(v.value)
    WHEN 'Python'      THEN 1
    WHEN 'C/C++/C#'    THEN 2
    WHEN 'Java'        THEN 3
    WHEN 'PHP & MYSQL' THEN 4
  END
WHERE c.parent_id = @parent
  AND TRIM(v.value) IN ('Python', 'C/C++/C#', 'Java', 'PHP & MYSQL');

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  "UPDATE catalog_category_flat_store_1 SET position = CASE TRIM(name) WHEN 'Python' THEN 1 WHEN 'C/C++/C#' THEN 2 WHEN 'Java' THEN 3 WHEN 'PHP & MYSQL' THEN 4 END WHERE parent_id = @parent AND TRIM(name) IN ('Python','C/C++/C#','Java','PHP & MYSQL')", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  "UPDATE catalog_category_flat_store_2 SET position = CASE TRIM(name) WHEN 'Python' THEN 1 WHEN 'C/C++/C#' THEN 2 WHEN 'Java' THEN 3 WHEN 'PHP & MYSQL' THEN 4 END WHERE parent_id = @parent AND TRIM(name) IN ('Python','C/C++/C#','Java','PHP & MYSQL')", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  "UPDATE catalog_category_flat_store_3 SET position = CASE TRIM(name) WHEN 'Python' THEN 1 WHEN 'C/C++/C#' THEN 2 WHEN 'Java' THEN 3 WHEN 'PHP & MYSQL' THEN 4 END WHERE parent_id = @parent AND TRIM(name) IN ('Python','C/C++/C#','Java','PHP & MYSQL')", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
