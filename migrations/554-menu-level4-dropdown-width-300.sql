-- Narrow the level-4+ CLASSIC dropdowns in the Adult Courses menu to 300px.
--
-- After 552/553 made level>=4 render as CLASSIC vertical lists (one item per
-- line), the old mega-era widths are far too wide: Data Management and
-- Programming were 800px, plus a 900px and three 600px, stretching an almost
-- empty panel across most of the viewport. Most level-4 categories were already
-- 300px, which is the right width for a single-column list — this migration
-- makes the rest match.
--
-- Sets umm_dd_width='300px' for every category at level>=4 inside the Adult
-- Courses subtree. Scoped by subtree path resolved from the level-2 category
-- NAME (ids differ per site) so no other top-level menu is touched — we are
-- rolling the menu work out in phases, Adult Courses first.
--
-- umm_dd_width (attribute_code umm_dd_width, entity_type_id 3) is a VARCHAR the
-- UltraMegamenu block emits as an INLINE style="width:NNNpx" on the flyout <ul>.
-- Because it is inline, CSS cannot override it without !important — the value
-- must be fixed in the DATA, which is what this does.
--
-- EAV (store 0 + per-store overrides) + flat mirror per store, information_schema
-- guarded (SG=1, MY=2, GH=3). Idempotent. After deploy, reindex
-- catalog_category_flat + flush block_html/FPC (Redis) so the menu re-renders.
-- See skill megamenu-structure.

SET @a_ddwidth := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'umm_dd_width');

SET @adult_path := (SELECT c.path FROM catalog_category_entity c
  JOIN catalog_category_entity_varchar nv ON nv.entity_id=c.entity_id AND nv.store_id=0
    AND nv.attribute_id=(SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name')
  WHERE nv.value='Adult Courses' AND c.level=2 LIMIT 1);
SET @adult_like := CONCAT(@adult_path, '/%');

-- 1) EAV: set level>=4 dropdown width to 300px inside Adult Courses.
UPDATE catalog_category_entity_varchar cv
JOIN catalog_category_entity e ON e.entity_id = cv.entity_id
SET cv.value = '300px'
WHERE cv.attribute_id = @a_ddwidth AND cv.store_id = 0
  AND e.level >= 4 AND e.path LIKE @adult_like AND @adult_path IS NOT NULL;

UPDATE catalog_category_entity_varchar cv
JOIN catalog_category_entity e ON e.entity_id = cv.entity_id
SET cv.value = '300px'
WHERE cv.attribute_id = @a_ddwidth AND cv.store_id <> 0
  AND e.level >= 4 AND e.path LIKE @adult_like AND @adult_path IS NOT NULL;

-- 2) Flat mirror per live store, guarded so a missing flat table is a no-op.
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  CONCAT("UPDATE catalog_category_flat_store_1 SET umm_dd_width='300px' WHERE level>=4 AND path LIKE ", QUOTE(@adult_like)), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  CONCAT("UPDATE catalog_category_flat_store_2 SET umm_dd_width='300px' WHERE level>=4 AND path LIKE ", QUOTE(@adult_like)), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  CONCAT("UPDATE catalog_category_flat_store_3 SET umm_dd_width='300px' WHERE level>=4 AND path LIKE ", QUOTE(@adult_like)), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
