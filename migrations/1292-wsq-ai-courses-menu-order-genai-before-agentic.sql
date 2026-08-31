-- 1292: Put "WSQ Generative AI Courses" BEFORE "WSQ Agentic AI Courses" in the
-- WSQ AI Courses dropdown (under WSQ Funded Courses).
--
-- Current children of WSQ AI Courses (325) and their positions:
--   1 WSQ Agentic AI Courses            (wsq-agentic-ai-courses)
--   2 WSQ Generative AI Courses         (wsq-generative-ai-courses)
--   3 WSQ Programming & VIbe Coding     (wsq-programming-vibe-coding-...)
--   4 WSQ AI Ethics and Governance      (wsq-ai-ethics-and-governance-courses)
--
-- Requested: Generative AI first, Agentic AI second. The other two keep their
-- places, so this is a straight swap of positions 1 and 2:
--   1 WSQ Generative AI Courses
--   2 WSQ Agentic AI Courses
--   3 WSQ Programming & VIbe Coding
--   4 WSQ AI Ethics and Governance
--
-- Positions are renumbered explicitly (not swapped in place) so the four
-- children keep DISTINCT positions — duplicate positions among siblings make
-- the sort non-deterministic and the mega-menu flyout render unreliably.
--
-- Written to catalog_category_entity.position (the column the menu sorts on)
-- and mirrored into every catalog_category_flat_store_N that exists on this
-- instance, each behind an information_schema guard — the storefront menu
-- reads flat, and a hardcoded flat table name would abort apply.php and 502
-- the whole site. Business-key (url_key) lookups only. Idempotent.

SET @uk := (SELECT attribute_id FROM eav_attribute
            WHERE entity_type_id = 3 AND attribute_code = 'url_key' LIMIT 1);

SET @c_gen := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id = 0 AND attribute_id = @uk AND value = 'wsq-generative-ai-courses' LIMIT 1);
SET @c_agt := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id = 0 AND attribute_id = @uk AND value = 'wsq-agentic-ai-courses' LIMIT 1);
SET @c_prg := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id = 0 AND attribute_id = @uk
    AND value = 'wsq-programming-vibe-coding-courses-tertiary-courses-singapore' LIMIT 1);
SET @c_eth := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id = 0 AND attribute_id = @uk AND value = 'wsq-ai-ethics-and-governance-courses' LIMIT 1);

UPDATE catalog_category_entity
SET position = CASE entity_id
      WHEN @c_gen THEN 1
      WHEN @c_agt THEN 2
      WHEN @c_prg THEN 3
      WHEN @c_eth THEN 4
      ELSE position END
WHERE entity_id IN (@c_gen, @c_agt, @c_prg, @c_eth);

-- Mirror into the per-store flat tables that exist here (guarded).
SET @sql := IF((SELECT COUNT(*) FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_1') > 0,
  'UPDATE catalog_category_flat_store_1 SET position = CASE entity_id
      WHEN @c_gen THEN 1 WHEN @c_agt THEN 2 WHEN @c_prg THEN 3 WHEN @c_eth THEN 4
      ELSE position END
    WHERE entity_id IN (@c_gen, @c_agt, @c_prg, @c_eth)',
  'DO 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := IF((SELECT COUNT(*) FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_2') > 0,
  'UPDATE catalog_category_flat_store_2 SET position = CASE entity_id
      WHEN @c_gen THEN 1 WHEN @c_agt THEN 2 WHEN @c_prg THEN 3 WHEN @c_eth THEN 4
      ELSE position END
    WHERE entity_id IN (@c_gen, @c_agt, @c_prg, @c_eth)',
  'DO 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := IF((SELECT COUNT(*) FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_3') > 0,
  'UPDATE catalog_category_flat_store_3 SET position = CASE entity_id
      WHEN @c_gen THEN 1 WHEN @c_agt THEN 2 WHEN @c_prg THEN 3 WHEN @c_eth THEN 4
      ELSE position END
    WHERE entity_id IN (@c_gen, @c_agt, @c_prg, @c_eth)',
  'DO 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := IF((SELECT COUNT(*) FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_4') > 0,
  'UPDATE catalog_category_flat_store_4 SET position = CASE entity_id
      WHEN @c_gen THEN 1 WHEN @c_agt THEN 2 WHEN @c_prg THEN 3 WHEN @c_eth THEN 4
      ELSE position END
    WHERE entity_id IN (@c_gen, @c_agt, @c_prg, @c_eth)',
  'DO 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := IF((SELECT COUNT(*) FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_5') > 0,
  'UPDATE catalog_category_flat_store_5 SET position = CASE entity_id
      WHEN @c_gen THEN 1 WHEN @c_agt THEN 2 WHEN @c_prg THEN 3 WHEN @c_eth THEN 4
      ELSE position END
    WHERE entity_id IN (@c_gen, @c_agt, @c_prg, @c_eth)',
  'DO 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := IF((SELECT COUNT(*) FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_6') > 0,
  'UPDATE catalog_category_flat_store_6 SET position = CASE entity_id
      WHEN @c_gen THEN 1 WHEN @c_agt THEN 2 WHEN @c_prg THEN 3 WHEN @c_eth THEN 4
      ELSE position END
    WHERE entity_id IN (@c_gen, @c_agt, @c_prg, @c_eth)',
  'DO 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := IF((SELECT COUNT(*) FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_7') > 0,
  'UPDATE catalog_category_flat_store_7 SET position = CASE entity_id
      WHEN @c_gen THEN 1 WHEN @c_agt THEN 2 WHEN @c_prg THEN 3 WHEN @c_eth THEN 4
      ELSE position END
    WHERE entity_id IN (@c_gen, @c_agt, @c_prg, @c_eth)',
  'DO 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
