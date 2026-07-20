-- Rename "Operating Systems" -> "Linux" and disable its children (Linux, Windows).
--
-- The level-4 parent (76) absorbs its children: the child named "Linux" (174) is
-- disabled and the PARENT takes the name "Linux", so the menu keeps a single
-- "Linux" entry holding every course.
--
-- ORDER MATTERS: the backfill runs BEFORE the disable. Audit found two courses
-- (C1162 / M961 "CompTIA Linux+ Training") that sit in the Linux child but NOT
-- in the parent — disabling first would have stranded them. The backfill is
-- unconditional and idempotent (INSERT IGNORE on the UNIQUE (category_id,
-- product_id) key), so it also covers any equivalent gap on a partner site.
--
-- URL IMPACT:
--   * The parent rename touches the NAME only — url_key untouched, so the parent
--     keeps its existing URL. No 301 needed, and deliberately NO url_key writes
--     (MMD_FlatCategoryUrl keeps every category at /<url_key>.html).
--   * The two DISABLED children lose their pages, so 301s to the parent are
--     added in core_url_rewrite below.
--
-- Per the category-ordering skill, a disable sets BOTH is_active = 0 AND
-- include_in_menu = 0, or the item keeps rendering in the mega-menu while its
-- page 404s.
--
-- Resolved by NAME rather than hardcoded ids so it lands on every site.
-- Idempotent. Mirrored into catalog_category_flat_store_{1,2,3} behind
-- information_schema guards.
-- After deploy: reindex catalog_category_flat + catalog_url, flush block_html/FPC.

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @a_active := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_active');
SET @a_menu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'include_in_menu');
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @os := (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id = e.entity_id
    AND v.attribute_id = @a_name AND v.store_id = 0
  WHERE TRIM(v.value) IN ('Operating Systems','Linux') AND e.level = 4 LIMIT 1);

-- (1) Backfill child courses into the parent BEFORE disabling the children.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @os, cp.product_id, 0
FROM catalog_category_product cp
JOIN catalog_category_entity c ON c.entity_id = cp.category_id
WHERE c.parent_id = @os;

-- (2) 301s for the children -> the parent, captured BEFORE the rename so the
-- child url_keys are still resolvable. request_path is each child's flat url_key.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id,
       CONCAT('mmd_os_disabled_', c.entity_id, '_', s.store_id),
       CONCAT(kv.value, '.html'),
       CONCAT(pk.value, '.html'),
       0, 'RP', 'Operating Systems -> Linux: disabled child -> parent'
FROM catalog_category_entity c
JOIN catalog_category_entity_varchar kv ON kv.entity_id = c.entity_id AND kv.attribute_id = @a_urlkey AND kv.store_id = 0
JOIN catalog_category_entity_varchar pk ON pk.entity_id = @os        AND pk.attribute_id = @a_urlkey AND pk.store_id = 0
JOIN core_store s ON s.store_id > 0
WHERE c.parent_id = @os
  AND kv.value IS NOT NULL AND pk.value IS NOT NULL
  AND kv.value <> pk.value;

-- (3) Rename the parent. Name only; url_key untouched.
UPDATE catalog_category_entity_varchar
SET value = 'Linux'
WHERE attribute_id = @a_name AND store_id = 0 AND entity_id = @os;

-- (4) Disable the children (is_active AND include_in_menu).
UPDATE catalog_category_entity_int i
JOIN catalog_category_entity c ON c.entity_id = i.entity_id
SET i.value = 0
WHERE i.attribute_id IN (@a_active, @a_menu) AND c.parent_id = @os;

INSERT IGNORE INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, c.entity_id, 0
FROM catalog_category_entity c
CROSS JOIN (SELECT @a_active AS attribute_id UNION ALL SELECT @a_menu) a
WHERE c.parent_id = @os;

SET @flat_name := " SET name = 'Linux' WHERE entity_id = @os";
SET @flat_off  := " SET is_active = 0, include_in_menu = 0 WHERE parent_id = @os";

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0, CONCAT('UPDATE catalog_category_flat_store_1', @flat_name), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0, CONCAT('UPDATE catalog_category_flat_store_1', @flat_off), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0, CONCAT('UPDATE catalog_category_flat_store_2', @flat_name), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0, CONCAT('UPDATE catalog_category_flat_store_2', @flat_off), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0, CONCAT('UPDATE catalog_category_flat_store_3', @flat_name), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0, CONCAT('UPDATE catalog_category_flat_store_3', @flat_off), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
