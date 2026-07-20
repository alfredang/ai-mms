-- RPA consolidation.
--   1. Rename "RPA, API & Automation" -> "RPA".
--   2. Move "REST API" out to Web Development (it is not RPA).
--   3. Backfill every course from the remaining children into the RPA parent.
--   4. Disable those now-redundant children (RPA, Google Apps Script, Selenium).
--
-- ORDER MATTERS: the backfill (3) MUST run before the disable (4), otherwise a
-- course that lives only in a child becomes unreachable. Audit before writing
-- this found exactly that risk, so the backfill is unconditional and idempotent
-- (INSERT IGNORE against the UNIQUE (category_id, product_id) key).
--
-- The child named "RPA" (219) is disabled, not deleted, and the parent (202) is
-- renamed to "RPA" — so the menu keeps a single "RPA" entry holding every
-- Power Automate / UiPath / Google Apps Script / Selenium course.
--
-- URL IMPACT:
--   * The parent rename touches the NAME only — url_key is untouched, so the
--     parent keeps its existing URL. No 301 needed.
--   * The REST API move is a reparent only. MMD_FlatCategoryUrl resolves every
--     category at /<url_key>.html regardless of parent, so REST API keeps
--     rest-api-training-courses.html unchanged. No 301, and deliberately NO
--     url_key/url_path writes here.
--   * The three DISABLED children DO lose their pages, so 301s to the RPA
--     parent are added in core_url_rewrite (see the redirect block below).
--
-- Resolved by NAME rather than hardcoded ids so it lands on every site.
-- Idempotent throughout. Mirrored into catalog_category_flat_store_{1,2,3}
-- behind information_schema guards.
-- After deploy: reindex catalog_category_flat + catalog_url, flush block_html/FPC.

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @a_active := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_active');
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_menu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'include_in_menu');

SET @rpa := (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id = e.entity_id
    AND v.attribute_id = @a_name AND v.store_id = 0
  WHERE TRIM(v.value) IN ('RPA, API & Automation','RPA') AND e.level = 4 LIMIT 1);

SET @webdev := (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id = e.entity_id
    AND v.attribute_id = @a_name AND v.store_id = 0
  WHERE TRIM(v.value) = 'Web Development' AND e.level = 4 LIMIT 1);

SET @c_restapi := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id = e.entity_id
    AND v.attribute_id = @a_name AND v.store_id = 0
  WHERE TRIM(v.value) = 'REST API' AND e.parent_id = @rpa LIMIT 1) r);

-- (1) Rename the parent. Name only; url_key untouched.
UPDATE catalog_category_entity_varchar
SET value = 'RPA'
WHERE attribute_id = @a_name AND store_id = 0 AND entity_id = @rpa;

-- (2) Move REST API to Web Development. parent_id/path/level only.
UPDATE catalog_category_entity
SET parent_id = @webdev,
    path      = CONCAT((SELECT p FROM (SELECT path p FROM catalog_category_entity WHERE entity_id = @webdev) x), '/', entity_id),
    level     = (SELECT l FROM (SELECT level l FROM catalog_category_entity WHERE entity_id = @webdev) y) + 1
WHERE entity_id = @c_restapi;

-- (3) Backfill child courses into the RPA parent BEFORE disabling the children.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @rpa, cp.product_id, 0
FROM catalog_category_product cp
JOIN catalog_category_entity c ON c.entity_id = cp.category_id
WHERE c.parent_id = @rpa AND c.entity_id <> @c_restapi;

-- (4) Disable the redundant children. Per the category-ordering skill a disable
-- must set BOTH is_active = 0 AND include_in_menu = 0, or the item keeps
-- rendering in the mega-menu even though its page 404s.
UPDATE catalog_category_entity_int i
JOIN catalog_category_entity c ON c.entity_id = i.entity_id
SET i.value = 0
WHERE i.attribute_id IN (@a_active, @a_menu)
  AND c.parent_id = @rpa
  AND c.entity_id <> @c_restapi;

INSERT IGNORE INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, c.entity_id, 0
FROM catalog_category_entity c
CROSS JOIN (SELECT @a_active AS attribute_id UNION ALL SELECT @a_menu) a
WHERE c.parent_id = @rpa AND c.entity_id <> @c_restapi;

-- Keep children_count honest on both parents after the REST API move.
UPDATE catalog_category_entity SET children_count = (SELECT COUNT(*) FROM (SELECT entity_id FROM catalog_category_entity WHERE parent_id = @rpa) a)    WHERE entity_id = @rpa;
UPDATE catalog_category_entity SET children_count = (SELECT COUNT(*) FROM (SELECT entity_id FROM catalog_category_entity WHERE parent_id = @webdev) b) WHERE entity_id = @webdev;

-- 301s for the disabled children -> the RPA parent, so their indexed URLs
-- do not dead-end. request_path is each child's own flat url_key.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id,
       CONCAT('mmd_rpa_disabled_', c.entity_id, '_', s.store_id),
       CONCAT(kv.value, '.html'),
       CONCAT(pk.value, '.html'),
       0, 'RP', 'RPA consolidation: disabled child -> RPA parent'
FROM catalog_category_entity c
JOIN catalog_category_entity_varchar kv ON kv.entity_id = c.entity_id AND kv.attribute_id = @a_urlkey AND kv.store_id = 0
JOIN catalog_category_entity_varchar pk ON pk.entity_id = @rpa        AND pk.attribute_id = @a_urlkey AND pk.store_id = 0
JOIN core_store s ON s.store_id > 0
WHERE c.parent_id = @rpa AND c.entity_id <> @c_restapi
  AND kv.value IS NOT NULL AND pk.value IS NOT NULL
  AND kv.value <> pk.value;

SET @flat_name  := " SET name = 'RPA' WHERE entity_id = @rpa";
SET @flat_move  := " SET parent_id = @webdev, path = CONCAT((SELECT p FROM (SELECT path p FROM catalog_category_entity WHERE entity_id = @webdev) x), '/', entity_id), level = (SELECT l FROM (SELECT level l FROM catalog_category_entity WHERE entity_id = @webdev) y) + 1 WHERE entity_id = @c_restapi";
SET @flat_off   := " SET is_active = 0, include_in_menu = 0 WHERE parent_id = @rpa AND entity_id <> @c_restapi";

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0, CONCAT('UPDATE catalog_category_flat_store_1', @flat_name), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0, CONCAT('UPDATE catalog_category_flat_store_1', @flat_move), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0, CONCAT('UPDATE catalog_category_flat_store_1', @flat_off), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0, CONCAT('UPDATE catalog_category_flat_store_2', @flat_name), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0, CONCAT('UPDATE catalog_category_flat_store_2', @flat_move), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0, CONCAT('UPDATE catalog_category_flat_store_2', @flat_off), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0, CONCAT('UPDATE catalog_category_flat_store_3', @flat_name), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0, CONCAT('UPDATE catalog_category_flat_store_3', @flat_move), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0, CONCAT('UPDATE catalog_category_flat_store_3', @flat_off), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
