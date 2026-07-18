-- Move "3D Printing" from Media & Design to Robotics & IoT, and set the
-- Robotics & IoT child order.
--
-- Before: Media & Design > 3D Printing (path 1/2/3/69/93, level 4)
--         Robotics & IoT: IoT 1, ROS 2, Raspberry Pi 3, Arduino 4
-- After:  Robotics & IoT > 3D Printing (path 1/2/3/56/93, level 4)
--         Robotics & IoT: IoT 1, ROS 2, Arduino 3, Raspberry Pi 4, 3D Printing 5
--
-- URL IMPACT: NONE. MMD_FlatCategoryUrl forces every category to resolve at
-- /<url_key>.html regardless of its parent, so 3D Printing stays at
-- 3d-printing-training-courses.html across the move — no rewrite churn, no 301,
-- no SEO change. Do NOT add url_key/url_path edits here.
--
-- Both source and target parents are level 3, so the moved node stays at
-- level 4 and no descendant re-pathing is required (children_count = 0).
-- Its 6 product assignments in catalog_category_product are untouched.
--
-- Resolved by NAME rather than hardcoded ids so it lands correctly on every
-- site. Idempotent: the reparent is a no-op once applied, and the positions are
-- absolute. Note ROS is stored as 'ROS' (not 'Robot Operating System (ROS)').
--
-- Mirrored into each catalog_category_flat_store_N present on this instance
-- (SG=1, MY=2, GH=3), information_schema-guarded. The flat tables carry
-- parent_id/path/level/position, so all four are updated there too.
-- After deploy, reindex catalog_category_flat + catalog_url + flush block_html/FPC.

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');

SET @src := (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id = e.entity_id
    AND v.attribute_id = @a_name AND v.store_id = 0
  WHERE TRIM(v.value) = 'Media & Design' LIMIT 1);

SET @dst := (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id = e.entity_id
    AND v.attribute_id = @a_name AND v.store_id = 0
  WHERE TRIM(v.value) = 'Robotics & IoT' LIMIT 1);

SET @node := (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id = e.entity_id
    AND v.attribute_id = @a_name AND v.store_id = 0
  WHERE TRIM(v.value) = '3D Printing' AND e.parent_id = @src LIMIT 1);

-- Reparent (no-op on re-run: @node is NULL once it no longer sits under @src).
UPDATE catalog_category_entity
SET parent_id = @dst,
    path      = CONCAT((SELECT path FROM (SELECT path FROM catalog_category_entity WHERE entity_id = @dst) x), '/', entity_id),
    level     = (SELECT level FROM (SELECT level FROM catalog_category_entity WHERE entity_id = @dst) y) + 1
WHERE entity_id = @node;

-- Keep both parents' children_count honest.
UPDATE catalog_category_entity SET children_count = (SELECT COUNT(*) FROM (SELECT entity_id FROM catalog_category_entity WHERE parent_id = @src) a) WHERE entity_id = @src;
UPDATE catalog_category_entity SET children_count = (SELECT COUNT(*) FROM (SELECT entity_id FROM catalog_category_entity WHERE parent_id = @dst) b) WHERE entity_id = @dst;

-- Order the Robotics & IoT children.
UPDATE catalog_category_entity c
JOIN catalog_category_entity_varchar v
  ON v.entity_id = c.entity_id AND v.attribute_id = @a_name AND v.store_id = 0
SET c.position = CASE TRIM(v.value)
    WHEN 'Internet of Things (IoT)' THEN 1
    WHEN 'ROS'                      THEN 2
    WHEN 'Arduino'                  THEN 3
    WHEN 'Raspberry Pi'             THEN 4
    WHEN '3D Printing'              THEN 5
  END
WHERE c.parent_id = @dst
  AND TRIM(v.value) IN ('Internet of Things (IoT)','ROS','Arduino','Raspberry Pi','3D Printing');

SET @flat_move  := " SET parent_id = @dst, path = CONCAT((SELECT p FROM (SELECT path p FROM catalog_category_entity WHERE entity_id = @dst) x), '/', entity_id), level = (SELECT l FROM (SELECT level l FROM catalog_category_entity WHERE entity_id = @dst) y) + 1 WHERE entity_id = @node";
SET @flat_order := " SET position = CASE TRIM(name) WHEN 'Internet of Things (IoT)' THEN 1 WHEN 'ROS' THEN 2 WHEN 'Arduino' THEN 3 WHEN 'Raspberry Pi' THEN 4 WHEN '3D Printing' THEN 5 END WHERE parent_id = @dst AND TRIM(name) IN ('Internet of Things (IoT)','ROS','Arduino','Raspberry Pi','3D Printing')";

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  CONCAT('UPDATE catalog_category_flat_store_1', @flat_move), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  CONCAT('UPDATE catalog_category_flat_store_1', @flat_order), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  CONCAT('UPDATE catalog_category_flat_store_2', @flat_move), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  CONCAT('UPDATE catalog_category_flat_store_2', @flat_order), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  CONCAT('UPDATE catalog_category_flat_store_3', @flat_move), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  CONCAT('UPDATE catalog_category_flat_store_3', @flat_order), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
