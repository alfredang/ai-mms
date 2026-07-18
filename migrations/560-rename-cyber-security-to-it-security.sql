-- Rename, under Infocomm Technology:
--   "Cyber Security"                  -> "IT Security"    (level 4 parent, id 161 on SG)
--   "CyberSecurity & Threat Analysis" -> "Cyber Security" (its level 5 child, id 385 on SG)
--
-- NOTE the source names are distinct strings: the child is "CyberSecurity"
-- (one word, no space) while the parent is "Cyber Security" (two words). The
-- two UPDATEs below are therefore order-independent and cannot collide, even
-- though the child's NEW name equals the parent's OLD name. Do not "tidy" these
-- into a single LIKE '%Cyber%Security%' match — that would rename both rows to
-- the same value and also catch the unrelated siblings
-- "WSQ Cyber Security & PDPA" and "Cyber Security Certification Exam Prep".
--
-- Name only. url_keys are untouched, so category URLs, existing links and SEO
-- are unchanged (no rewrite churn, no 301 needed).
--
-- Matched by the CURRENT NAME rather than a hardcoded id so it lands on the
-- right row on every site (ids differ per instance) and is a no-op once renamed.
-- Mirrored into each catalog_category_flat_store_N present on this instance
-- (SG=1, MY=2, GH=3), information_schema-guarded so a missing flat table is a
-- no-op — the storefront menu reads flat and there is no reindex hook at deploy.
-- Idempotent. After deploy, reindex catalog_category_flat + flush block_html/FPC.

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');

UPDATE catalog_category_entity_varchar
SET value = 'IT Security'
WHERE attribute_id = @a_name AND TRIM(value) = 'Cyber Security';

UPDATE catalog_category_entity_varchar
SET value = 'Cyber Security'
WHERE attribute_id = @a_name AND TRIM(value) = 'CyberSecurity & Threat Analysis';

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  "UPDATE catalog_category_flat_store_1 SET name='IT Security' WHERE TRIM(name)='Cyber Security'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  "UPDATE catalog_category_flat_store_1 SET name='Cyber Security' WHERE TRIM(name)='CyberSecurity & Threat Analysis'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  "UPDATE catalog_category_flat_store_2 SET name='IT Security' WHERE TRIM(name)='Cyber Security'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  "UPDATE catalog_category_flat_store_2 SET name='Cyber Security' WHERE TRIM(name)='CyberSecurity & Threat Analysis'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  "UPDATE catalog_category_flat_store_3 SET name='IT Security' WHERE TRIM(name)='Cyber Security'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  "UPDATE catalog_category_flat_store_3 SET name='Cyber Security' WHERE TRIM(name)='CyberSecurity & Threat Analysis'", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
