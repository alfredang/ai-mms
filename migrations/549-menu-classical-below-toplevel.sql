-- Mega-menu: convert every NESTED dropdown (category level >= 3) from
-- "Mega drop-down" (umm_dd_type=1) to "Classic" (umm_dd_type=2), while KEEPING
-- the top-level bar items (level 2 — COURSES/Software Training/WSQ Courses/etc.)
-- as mega panels. So the top COURSES panel stays a multi-column mega grid, but
-- each column category and everything beneath it (e.g. Infocomm Technology ->
-- Data Management -> Data Engineering) opens as a plain vertical classical
-- dropdown instead of a nested mega sub-grid.
--
-- umm_dd_type values: 0=None(inherit) 1=Mega 2=Classic 3=Simple
-- (Infortis_UltraMegamenu_Block_Navigation::DDTYPE_*). Only categories that are
-- currently Mega (value='1') at level>=3 are flipped; level-2 mega items and
-- inherit(0)/classic(2) items are left untouched.
--
-- umm_dd_type is a VARCHAR category attribute stored in
-- catalog_category_entity_varchar (store_id 0 is authoritative on every live
-- site; verified no store-scope overrides shadow the level>=3 mega items). The
-- storefront reads the flat category tables (flat categories are enabled), so
-- the new value must ALSO be mirrored into each catalog_category_flat_store_N
-- that exists on this instance — there is no PHP reindex hook at deploy. The
-- flat updates are guarded by information_schema so they no-op on sites that
-- don't have that store's flat table (SG has store 1; MY 2; GH 3).
--
-- Level-based + value-based only (no category-id / SKU list) so the SAME rule
-- applies coherently on every partner site. Idempotent: re-running finds no
-- remaining level>=3 mega rows and is a no-op. After deploy, reindex
-- catalog_category_flat + flush block_html/FPC (Redis) so the menu re-renders.

SET @a_ddtype := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'umm_dd_type');

-- 1) EAV (authoritative): flip level>=3 mega -> classic at store 0.
UPDATE catalog_category_entity_varchar cv
JOIN catalog_category_entity e ON e.entity_id = cv.entity_id
SET cv.value = '2'
WHERE cv.attribute_id = @a_ddtype AND cv.store_id = 0 AND cv.value = '1' AND e.level >= 3;

-- Also flip any per-store override rows that are level>=3 mega, so no store
-- scope shadows the classic value.
UPDATE catalog_category_entity_varchar cv
JOIN catalog_category_entity e ON e.entity_id = cv.entity_id
SET cv.value = '2'
WHERE cv.attribute_id = @a_ddtype AND cv.store_id <> 0 AND cv.value = '1' AND e.level >= 3;

-- 2) Flat mirror per live store (1=SG, 2=MY, 3=GH). Guarded so a missing flat
--    table is a no-op on that site.
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  "UPDATE catalog_category_flat_store_1 SET umm_dd_type='2' WHERE level>=3 AND umm_dd_type='1'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  "UPDATE catalog_category_flat_store_2 SET umm_dd_type='2' WHERE level>=3 AND umm_dd_type='1'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  "UPDATE catalog_category_flat_store_3 SET umm_dd_type='2' WHERE level>=3 AND umm_dd_type='1'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
