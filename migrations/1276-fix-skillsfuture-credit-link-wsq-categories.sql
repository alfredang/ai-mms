-- Fix the broken "SkillsFuture Credit" link in WSQ category descriptions.
--
-- The old target https://www.myskillsfuture.sg/content/portal/en/index.html is
-- dead (the domain no longer resolves). Point the anchor at our own guide page
-- https://www.tertiarycourses.com.sg/how-to-claim-skillsfuture-credit.html and
-- refresh the stale title attribute; drop target="_blank" since the link is now
-- internal (matches the existing SFC link on the same pages).
--
-- Affects 9 WSQ category descriptions sharing the identical anchor boilerplate
-- (wsq-soft-skills-courses, wsq-finance-courses, wsq-project-management-courses,
-- wsq-media-marketing-courses, wsq-soft-skill-and-critical-core-skill-project-
-- management-courses, wsq-finance-mfg-green-courses, wsq-it-security-courses,
-- wsq-finance-accounting-courses, wsq-accounting-courses).
--
-- Idempotent: REPLACE no-ops once applied. Partner-safe: partner DBs carry no
-- WSQ category boilerplate, so the LIKE matches nothing and the whole file
-- no-ops. Flat tables updated in place (guarded per table), so no Category
-- Flat Data reindex is needed. Post-deploy: prod Redis cache flush so the
-- cached category pages pick up the new description.

SET @desc_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description');
SET @old_anchor := 'href="https://www.myskillsfuture.sg/content/portal/en/index.html" title="MySKillsFuture Portal" target="_blank"';
SET @new_anchor := 'href="https://www.tertiarycourses.com.sg/how-to-claim-skillsfuture-credit.html" title="How to Claim SkillsFuture Credit"';

UPDATE catalog_category_entity_text
SET value = REPLACE(value, @old_anchor, @new_anchor)
WHERE attribute_id = @desc_attr
  AND value LIKE '%myskillsfuture.sg/content/portal/en/index.html%';

-- Mirror into the flat category tables (guarded: a DB missing one is a no-op
-- rather than an apply.php abort).
SET @sql = IF((SELECT COUNT(*) FROM information_schema.TABLES
               WHERE TABLE_SCHEMA = DATABASE()
                 AND TABLE_NAME = 'catalog_category_flat_store_1') > 0,
  'UPDATE catalog_category_flat_store_1 SET description = REPLACE(description, @old_anchor, @new_anchor) WHERE description LIKE ''%myskillsfuture.sg/content/portal/en/index.html%''', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.TABLES
               WHERE TABLE_SCHEMA = DATABASE()
                 AND TABLE_NAME = 'catalog_category_flat_store_2') > 0,
  'UPDATE catalog_category_flat_store_2 SET description = REPLACE(description, @old_anchor, @new_anchor) WHERE description LIKE ''%myskillsfuture.sg/content/portal/en/index.html%''', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.TABLES
               WHERE TABLE_SCHEMA = DATABASE()
                 AND TABLE_NAME = 'catalog_category_flat_store_3') > 0,
  'UPDATE catalog_category_flat_store_3 SET description = REPLACE(description, @old_anchor, @new_anchor) WHERE description LIKE ''%myskillsfuture.sg/content/portal/en/index.html%''', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
