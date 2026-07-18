-- Disable the "Web Framework" category (child of Web Development).
--
-- NOTE this is an EXPLICIT disable, not the conditional empty-category form in
-- migrations/550. Web Framework is NOT empty — it carries 4 indexed products
-- (8 assignments, 7 enabled, incl. 3 WSQ TGS- courses). The user asked for it to
-- be removed from the menu anyway. Audit confirmed every one of those courses
-- also belongs to 7-13 other categories, so NOTHING is orphaned: they stay
-- listed and purchasable via their other paths. Its products are backfilled into
-- the Web Development parent first, so the courses remain reachable one level up.
--
-- Per the category-ordering skill a disable sets BOTH is_active = 0 AND
-- include_in_menu = 0, or the item keeps rendering in the mega-menu while its
-- page 404s.
--
-- URL IMPACT: the category page stops resolving, so a 301 to the Web Development
-- parent is added in core_url_rewrite. No url_key is written (MMD_FlatCategoryUrl
-- keeps every category at /<url_key>.html).
--
-- Resolved by url_key (partner-safe; ids differ per site). Idempotent.
-- Mirrored into catalog_category_flat_store_{1,2,3} behind information_schema guards.
-- After deploy: reindex catalog_category_flat + catalog_url, flush block_html/FPC.

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @a_active := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_active');
SET @a_menu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'include_in_menu');
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @wf := (SELECT uk.entity_id FROM catalog_category_entity_varchar uk
  WHERE uk.attribute_id = @a_urlkey AND uk.store_id = 0
    AND uk.value = 'web-framework-courses' LIMIT 1);

SET @webdev := (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id = e.entity_id
    AND v.attribute_id = @a_name AND v.store_id = 0
  WHERE TRIM(v.value) = 'Web Development' AND e.level = 4 LIMIT 1);

-- Backfill Web Framework's products into the parent BEFORE disabling.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @webdev, cp.product_id, 0
FROM catalog_category_product cp
WHERE cp.category_id = @wf AND @wf IS NOT NULL AND @webdev IS NOT NULL;

-- 301 -> Web Development parent.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id,
       CONCAT('mmd_wf_disabled_', @wf, '_', s.store_id),
       'web-framework-courses.html',
       CONCAT(pk.value, '.html'),
       0, 'RP', 'Web Framework disabled -> Web Development'
FROM core_store s
JOIN catalog_category_entity_varchar pk ON pk.entity_id = @webdev AND pk.attribute_id = @a_urlkey AND pk.store_id = 0
WHERE s.store_id > 0 AND @wf IS NOT NULL AND pk.value IS NOT NULL;

UPDATE catalog_category_entity_int SET value = 0
WHERE entity_id = @wf AND store_id = 0 AND attribute_id IN (@a_active, @a_menu) AND @wf IS NOT NULL;

INSERT IGNORE INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @wf, 0
FROM (SELECT @a_active AS attribute_id UNION ALL SELECT @a_menu) a
WHERE @wf IS NOT NULL;

SET @flat_off := " SET is_active = 0, include_in_menu = 0 WHERE entity_id = @wf";

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0, CONCAT('UPDATE catalog_category_flat_store_1', @flat_off), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0, CONCAT('UPDATE catalog_category_flat_store_2', @flat_off), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0, CONCAT('UPDATE catalog_category_flat_store_3', @flat_off), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
