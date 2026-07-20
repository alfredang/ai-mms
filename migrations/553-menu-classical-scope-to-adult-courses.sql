-- Scope the level-4+ CLASSIC dropdown rule to the "Adult Courses" subtree ONLY.
--
-- 552 applied Mega->Classic at level>=4 across the WHOLE tree, which also changed
-- 6 categories in other top-level menus (Enquiries: Pearson Vue Exams, Regional
-- Franchisee; Exam Prep: Microsoft Certification Exam Prep, Azure Certification;
-- WSQ Courses: WSQ Generative AI Courses, WSQ Graphics Design & Media Courses).
-- Only the Adult Courses menu was meant to change. This migration reverts those
-- out-of-scope rows back to Mega ('1'), leaving the Adult Courses subtree classic.
--
-- Adult Courses is the level-2 category whose path is '1/2/3'; its subtree is
-- matched by path LIKE '1/2/3/%'. Resolved by NAME so it stays correct if ids
-- differ on a partner site. Everything OUTSIDE that subtree at level>=4 that is
-- currently Classic is restored to Mega.
--
-- Net result across the tree:
--   Adult Courses  level 3 -> MEGA, level 4+ -> CLASSIC
--   Other menus    unchanged from their pre-552 state
--
-- EAV (store 0 + per-store overrides) + flat mirror per store, information_schema
-- guarded (SG=1, MY=2, GH=3). Idempotent. After deploy, reindex
-- catalog_category_flat + flush block_html/FPC (Redis) so the menu re-renders.
-- See skill megamenu-structure.

SET @a_ddtype := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'umm_dd_type');

-- Adult Courses subtree path prefix, resolved by name (level 2).
SET @adult_path := (SELECT c.path FROM catalog_category_entity c
  JOIN catalog_category_entity_varchar nv ON nv.entity_id=c.entity_id AND nv.store_id=0
    AND nv.attribute_id=(SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name')
  WHERE nv.value='Adult Courses' AND c.level=2 LIMIT 1);
SET @adult_like := CONCAT(@adult_path, '/%');

-- 1) EAV: revert level>=4 classic rows OUTSIDE the Adult Courses subtree to mega.
UPDATE catalog_category_entity_varchar cv
JOIN catalog_category_entity e ON e.entity_id = cv.entity_id
SET cv.value = '1'
WHERE cv.attribute_id = @a_ddtype AND cv.store_id = 0 AND cv.value = '2'
  AND e.level >= 4 AND e.path NOT LIKE @adult_like AND @adult_path IS NOT NULL;

UPDATE catalog_category_entity_varchar cv
JOIN catalog_category_entity e ON e.entity_id = cv.entity_id
SET cv.value = '1'
WHERE cv.attribute_id = @a_ddtype AND cv.store_id <> 0 AND cv.value = '2'
  AND e.level >= 4 AND e.path NOT LIKE @adult_like AND @adult_path IS NOT NULL;

-- 2) Flat mirror per live store, guarded so a missing flat table is a no-op.
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  CONCAT("UPDATE catalog_category_flat_store_1 SET umm_dd_type='1' WHERE level>=4 AND umm_dd_type='2' AND path NOT LIKE ", QUOTE(@adult_like)), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  CONCAT("UPDATE catalog_category_flat_store_2 SET umm_dd_type='1' WHERE level>=4 AND umm_dd_type='2' AND path NOT LIKE ", QUOTE(@adult_like)), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  CONCAT("UPDATE catalog_category_flat_store_3 SET umm_dd_type='1' WHERE level>=4 AND umm_dd_type='2' AND path NOT LIKE ", QUOTE(@adult_like)), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
