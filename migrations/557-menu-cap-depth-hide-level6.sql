-- Cap the Adult Courses menu at 4 displayed tiers: hide the deepest tier so no
-- further flyout opens off a level-5 item.
--
-- Menu tier map (Adult Courses counted as tier 1):
--   Magento level 2 = tier 1  ADULT COURSES
--   Magento level 3 = tier 2  Infocomm Technology
--   Magento level 4 = tier 3  Data Management
--   Magento level 5 = tier 4  Data Engineering        <- deepest tier we SHOW
--   Magento level 6 = tier 5  Microsoft Fabric, ...   <- HIDDEN by this migration
--
-- Sets include_in_menu=0 for every category at level>=6 inside the Adult Courses
-- subtree (6 categories: Microsoft Fabric, Apache, Elastic Search, ...). Data
-- Engineering then renders as a plain leaf with no caret / no extra panel.
--
-- This hides them from the NAVIGATION ONLY. is_active is untouched, so the
-- category pages stay live and reachable by URL, keep their products, and remain
-- in sitemaps/search — nothing is deleted or disabled.
--
-- Scoped by subtree path resolved from the level-2 category NAME (ids differ per
-- site) so no other top-level menu is touched — menu work is rolling out in
-- phases, Adult Courses first. Inserts the include_in_menu row when a category
-- has none (the attribute defaults to 1 when the row is absent).
--
-- EAV (store 0 + per-store overrides) + flat mirror per store, information_schema
-- guarded (SG=1, MY=2, GH=3). Idempotent. After deploy, reindex
-- catalog_category_flat + flush block_html/FPC (Redis). See skill
-- megamenu-structure.

SET @a_menu := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'include_in_menu');

SET @adult_path := (SELECT c.path FROM catalog_category_entity c
  JOIN catalog_category_entity_varchar nv ON nv.entity_id=c.entity_id AND nv.store_id=0
    AND nv.attribute_id=(SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name')
  WHERE nv.value='Adult Courses' AND c.level=2 LIMIT 1);
SET @adult_like := CONCAT(@adult_path, '/%');

-- 1) EAV: existing rows -> 0.
UPDATE catalog_category_entity_int ci
JOIN catalog_category_entity e ON e.entity_id = ci.entity_id
SET ci.value = 0
WHERE ci.attribute_id = @a_menu AND ci.store_id = 0
  AND e.level >= 6 AND e.path LIKE @adult_like AND @adult_path IS NOT NULL;

UPDATE catalog_category_entity_int ci
JOIN catalog_category_entity e ON e.entity_id = ci.entity_id
SET ci.value = 0
WHERE ci.attribute_id = @a_menu AND ci.store_id <> 0
  AND e.level >= 6 AND e.path LIKE @adult_like AND @adult_path IS NOT NULL;

-- 2) EAV: insert a 0 row where the category never had one (absent defaults to 1).
INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_menu, 0, e.entity_id, 0
FROM catalog_category_entity e
WHERE e.level >= 6 AND e.path LIKE @adult_like AND @adult_path IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM catalog_category_entity_int ci
    WHERE ci.entity_id = e.entity_id AND ci.store_id = 0 AND ci.attribute_id = @a_menu);

-- 3) Flat mirror per live store, guarded so a missing flat table is a no-op.
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  CONCAT("UPDATE catalog_category_flat_store_1 SET include_in_menu=0 WHERE level>=6 AND path LIKE ", QUOTE(@adult_like)), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  CONCAT("UPDATE catalog_category_flat_store_2 SET include_in_menu=0 WHERE level>=6 AND path LIKE ", QUOTE(@adult_like)), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  CONCAT("UPDATE catalog_category_flat_store_3 SET include_in_menu=0 WHERE level>=6 AND path LIKE ", QUOTE(@adult_like)), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
