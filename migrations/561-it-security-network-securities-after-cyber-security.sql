-- Reorder the IT Security dropdown (level 5, under Infocomm Technology > IT Security).
--
-- Before: Cyber Security 1, Pentest & Ethical Hacking 2, Network Securities 3.
-- After:  Cyber Security 1, Network Securities 2, Pentest & Ethical Hacking 3.
--
-- "Cyber Security" here is the child renamed from "CyberSecurity & Threat
-- Analysis" by migration 560, so 560 MUST have run first — this file matches on
-- the post-560 names. Parent is resolved by its post-560 name 'IT Security'.
--
-- Position only — no name, url_key or parent change, so URLs and SEO untouched.
-- Resolved by NAME rather than hardcoded ids so it lands correctly on every site.
-- Idempotent: re-running sets the same absolute positions.
-- Mirrored into each catalog_category_flat_store_N present on this instance
-- (SG=1, MY=2, GH=3), information_schema-guarded.
-- After deploy, reindex catalog_category_flat + flush block_html/FPC.

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');

SET @parent := (
  SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v
    ON v.entity_id = e.entity_id AND v.attribute_id = @a_name AND v.store_id = 0
  WHERE TRIM(v.value) = 'IT Security'
  LIMIT 1
);

UPDATE catalog_category_entity c
JOIN catalog_category_entity_varchar v
  ON v.entity_id = c.entity_id AND v.attribute_id = @a_name AND v.store_id = 0
SET c.position = CASE TRIM(v.value)
    WHEN 'Cyber Security'            THEN 1
    WHEN 'Network Securities'        THEN 2
    WHEN 'Pentest & Ethical Hacking' THEN 3
  END
WHERE c.parent_id = @parent
  AND TRIM(v.value) IN ('Cyber Security', 'Network Securities', 'Pentest & Ethical Hacking');

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  "UPDATE catalog_category_flat_store_1 SET position = CASE TRIM(name) WHEN 'Cyber Security' THEN 1 WHEN 'Network Securities' THEN 2 WHEN 'Pentest & Ethical Hacking' THEN 3 END WHERE parent_id = @parent AND TRIM(name) IN ('Cyber Security','Network Securities','Pentest & Ethical Hacking')", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  "UPDATE catalog_category_flat_store_2 SET position = CASE TRIM(name) WHEN 'Cyber Security' THEN 1 WHEN 'Network Securities' THEN 2 WHEN 'Pentest & Ethical Hacking' THEN 3 END WHERE parent_id = @parent AND TRIM(name) IN ('Cyber Security','Network Securities','Pentest & Ethical Hacking')", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  "UPDATE catalog_category_flat_store_3 SET position = CASE TRIM(name) WHEN 'Cyber Security' THEN 1 WHEN 'Network Securities' THEN 2 WHEN 'Pentest & Ethical Hacking' THEN 3 END WHERE parent_id = @parent AND TRIM(name) IN ('Cyber Security','Network Securities','Pentest & Ethical Hacking')", 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
