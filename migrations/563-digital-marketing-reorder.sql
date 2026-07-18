-- Reorder the Digital Marketing dropdown (level 4 children of 'Digital Marketing').
--
-- Before: PPC 1, SEO 2, Social Media 3, Email 4, Video 5, Content 6, Analytics 7.
-- After:  SEO 1, Content 2, Social Media 3, Email 4, Video 5, PPC 6, Analytics 7.
--
-- Position only — no name, url_key or parent change, so URLs and SEO untouched.
-- Resolved by NAME under the parent named 'Digital Marketing' rather than
-- hardcoded ids so it lands correctly on every site (ids differ per instance).
-- TRIM()-ed defensively: sibling categories elsewhere in this catalog carry
-- trailing spaces in their stored names.
--
-- Idempotent: re-running sets the same absolute positions.
-- Mirrored into each catalog_category_flat_store_N present on this instance
-- (SG=1, MY=2, GH=3), information_schema-guarded.
-- After deploy, reindex catalog_category_flat + flush block_html/FPC.

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');

SET @parent := (
  SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v
    ON v.entity_id = e.entity_id AND v.attribute_id = @a_name AND v.store_id = 0
  WHERE TRIM(v.value) = 'Digital Marketing'
  LIMIT 1
);

UPDATE catalog_category_entity c
JOIN catalog_category_entity_varchar v
  ON v.entity_id = c.entity_id AND v.attribute_id = @a_name AND v.store_id = 0
SET c.position = CASE TRIM(v.value)
    WHEN 'SEO'                    THEN 1
    WHEN 'Content Marketing'      THEN 2
    WHEN 'Social Media Marketing' THEN 3
    WHEN 'Email Marketing'        THEN 4
    WHEN 'Video Marketing'        THEN 5
    WHEN 'PPC Marketing'          THEN 6
    WHEN 'Marketing Analytics'    THEN 7
  END
WHERE c.parent_id = @parent
  AND TRIM(v.value) IN ('SEO','Content Marketing','Social Media Marketing',
                        'Email Marketing','Video Marketing','PPC Marketing',
                        'Marketing Analytics');

SET @order_sql := "SET position = CASE TRIM(name) WHEN 'SEO' THEN 1 WHEN 'Content Marketing' THEN 2 WHEN 'Social Media Marketing' THEN 3 WHEN 'Email Marketing' THEN 4 WHEN 'Video Marketing' THEN 5 WHEN 'PPC Marketing' THEN 6 WHEN 'Marketing Analytics' THEN 7 END WHERE parent_id = @parent AND TRIM(name) IN ('SEO','Content Marketing','Social Media Marketing','Email Marketing','Video Marketing','PPC Marketing','Marketing Analytics')";

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  CONCAT('UPDATE catalog_category_flat_store_1 ', @order_sql), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  CONCAT('UPDATE catalog_category_flat_store_2 ', @order_sql), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  CONCAT('UPDATE catalog_category_flat_store_3 ', @order_sql), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
