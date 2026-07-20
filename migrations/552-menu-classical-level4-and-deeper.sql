-- Mega-menu: make NESTED FLYOUTS classical, keeping the mega COLUMNS intact.
-- Flip umm_dd_type Mega('1') -> Classic('2') for categories at level >= 4 only.
--
-- Level map for this menu:
--   level 2 = top bar panels (ADULT COURSES / Software Training / WSQ / ...) — MEGA
--   level 3 = columns inside the panel (Infocomm Technology, Media & Design,
--             Robotics & IoT, Digital Marketing, ...)                        — MEGA (must stay)
--   level 4 = column items (Data Management, Programming, Cyber Security, ...) — CLASSIC
--   level 5+ = their children (Data Engineering, Data Quality, ...)           — CLASSIC
--
-- This is the CORRECTED version of 549-menu-classical-below-toplevel.sql, which
-- used level>=3 and therefore turned the level-3 COLUMN HEADERS classic — making
-- Infocomm Technology / Digital Marketing / Business & Soft Skills render as bare
-- headers with NONE of their children showing. 551 reverted that. This migration
-- applies the intended change at the right depth: a level-4 item (e.g. Data
-- Management) opens as a plain vertical classical dropdown instead of a nested
-- multi-column mega grid with empty columns.
--
-- umm_dd_type values: 0=None(inherit) 1=Mega 2=Classic 3=Simple
-- (Infortis_UltraMegamenu_Block_Navigation::DDTYPE_*). Only currently-Mega ('1')
-- rows at level>=4 are flipped; inherit(0) rows are left alone so nothing that
-- renders correctly today is disturbed.
--
-- umm_dd_type is a VARCHAR category attribute; store_id 0 is authoritative and
-- the storefront reads the FLAT tables, so the value is mirrored into each
-- catalog_category_flat_store_N present on this instance (SG=1, MY=2, GH=3),
-- information_schema-guarded so a missing flat table is a no-op. Level-based +
-- value-based only (no id/SKU list) so the same rule applies on every partner
-- site. Idempotent. After deploy, reindex catalog_category_flat + flush
-- block_html/FPC (Redis) so the menu re-renders.

SET @a_ddtype := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'umm_dd_type');

-- 1) EAV (authoritative): level>=4 mega -> classic at store 0.
UPDATE catalog_category_entity_varchar cv
JOIN catalog_category_entity e ON e.entity_id = cv.entity_id
SET cv.value = '2'
WHERE cv.attribute_id = @a_ddtype AND cv.store_id = 0 AND cv.value = '1' AND e.level >= 4;

-- Also flip any per-store override rows so no store scope shadows the value.
UPDATE catalog_category_entity_varchar cv
JOIN catalog_category_entity e ON e.entity_id = cv.entity_id
SET cv.value = '2'
WHERE cv.attribute_id = @a_ddtype AND cv.store_id <> 0 AND cv.value = '1' AND e.level >= 4;

-- 2) Flat mirror per live store, guarded so a missing flat table is a no-op.
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  "UPDATE catalog_category_flat_store_1 SET umm_dd_type='2' WHERE level>=4 AND umm_dd_type='1'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  "UPDATE catalog_category_flat_store_2 SET umm_dd_type='2' WHERE level>=4 AND umm_dd_type='1'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  "UPDATE catalog_category_flat_store_3 SET umm_dd_type='2' WHERE level>=4 AND umm_dd_type='1'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
