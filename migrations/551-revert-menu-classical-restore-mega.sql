-- REVERT migration 549-menu-classical-below-toplevel.sql. That migration flipped
-- umm_dd_type Mega('1') -> Classic('2') for every category at level>=3, which
-- made the mega-menu COLUMN HEADERS (level-3: Infocomm Technology, Digital
-- Marketing, Business & Soft Skills, Autodesk, WSQ IT & Security) render as bare
-- headers with NONE of their sub-categories showing. Restore the previous
-- structure so all sub-categories show in the mega dropdown again: flip those
-- level>=3 classic rows back to Mega ('1').
--
-- Scope = exactly what 549 changed: umm_dd_type='2' AND level>=3, at store 0 and
-- any per-store override, mirrored into each catalog_category_flat_store_N that
-- exists (SG=1, MY=2, GH=3), information_schema-guarded so a missing flat table
-- is a no-op. Level-based + value-based only (no id/SKU list) — same rule on
-- every partner site. Idempotent. After deploy, reindex catalog_category_flat +
-- flush block_html/FPC (Redis) so the menu re-renders.
--
-- NOTE: 549's ledger row stays (its file is unchanged); this NEW migration is
-- the corrective delta, per feedback_edited_shared_migrations_never_rerun_on_prod.

SET @a_ddtype := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'umm_dd_type');

-- 1) EAV (authoritative): flip level>=3 classic -> mega at store 0.
UPDATE catalog_category_entity_varchar cv
JOIN catalog_category_entity e ON e.entity_id = cv.entity_id
SET cv.value = '1'
WHERE cv.attribute_id = @a_ddtype AND cv.store_id = 0 AND cv.value = '2' AND e.level >= 3;

-- Also revert any per-store override rows.
UPDATE catalog_category_entity_varchar cv
JOIN catalog_category_entity e ON e.entity_id = cv.entity_id
SET cv.value = '1'
WHERE cv.attribute_id = @a_ddtype AND cv.store_id <> 0 AND cv.value = '2' AND e.level >= 3;

-- 2) Flat mirror per live store, guarded so a missing flat table is a no-op.
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  "UPDATE catalog_category_flat_store_1 SET umm_dd_type='1' WHERE level>=3 AND umm_dd_type='2'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  "UPDATE catalog_category_flat_store_2 SET umm_dd_type='1' WHERE level>=3 AND umm_dd_type='2'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  "UPDATE catalog_category_flat_store_3 SET umm_dd_type='1' WHERE level>=3 AND umm_dd_type='2'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
