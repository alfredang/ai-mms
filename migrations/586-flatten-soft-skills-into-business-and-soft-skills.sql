-- Flatten the "Soft Skills" sub-tree into "Business & Soft Skills" (id 68) and
-- set the agreed menu order.
--
-- Before:                             After:
--   Business & Soft Skills (68)         Business & Soft Skills (68)
--     Project Management (125)            1 Project Management (125)
--     Soft  Skills (300)                  2 HR Management (150)
--       Communication (387)               3 Communication (387)
--       Customer Service (424)            4 Leadership (127)
--       Critical Thinking & PS (353)      5 Coaching & Mentoring (362)
--       Leadership (127)                  6 Customer Service (424)
--     HR Management (150)                 7 Problem Solving (353)
--       Coaching & Mentoring (362)        8 Design Thinking (221)
--     Corporate Governance (306)          9 Corporate Governance (306)
--     Design Thinking (221)
--     Speed Typing (194, disabled)      Soft Skills (300) -> disabled/hidden
--
-- Moves 5 categories to be direct children of 68:
--   387, 424, 353, 127 (out of Soft Skills 300)
--   362              (out of HR Management 150)
--
-- REPARENTING RULE (repo): a move touches ONLY parent_id / path / level /
-- position. url_key and url_path are deliberately NOT written, so every
-- category keeps its existing /<url_key>.html URL under MMD_FlatCategoryUrl.
-- No 301s needed, no rewrite churn, no SEO impact.
--
-- 353 is RENAMED "Critical Thinking & Problem Solving" -> "Problem Solving"
-- (name only; url_key untouched, so the URL is preserved).
--
-- 300 ("Soft  Skills") keeps its own URL but is emptied of children, so it is
-- disabled + removed from the menu. Its 3 remaining courses are first ensured
-- to sit directly in 68 so nothing is orphaned (2 already are; C776 is not).
--
-- Speed Typing (194) is already disabled/hidden and is left untouched.
--
-- All ids resolved BY NAME (never hardcoded) so this is a no-op on partner
-- sites that lack these categories. Every statement is idempotent.
-- After deploy: reindex catalog_category_flat + flush block_html/full_page.

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name');
SET @a_act   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='is_active');
SET @a_menu  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='include_in_menu');

-- Resolve the parent by name at level 3 under Adult Courses.
SET @bss := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_name AND v.store_id=0
  WHERE TRIM(v.value)='Business & Soft Skills' AND e.level=3 LIMIT 1) r);

SET @bss_path  := (SELECT path  FROM catalog_category_entity WHERE entity_id=@bss);
SET @bss_level := (SELECT level FROM catalog_category_entity WHERE entity_id=@bss);

-- Children resolved by name, scoped to the sub-tree of @bss so unrelated
-- same-named categories elsewhere in the tree can never be caught.
SET @ss   := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_name AND v.store_id=0
  WHERE TRIM(v.value)='Soft  Skills' AND e.path LIKE CONCAT(@bss_path,'/%') LIMIT 1) r);
SET @hr   := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_name AND v.store_id=0
  WHERE TRIM(v.value)='HR Management' AND e.path LIKE CONCAT(@bss_path,'/%') LIMIT 1) r);
SET @pm   := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_name AND v.store_id=0
  WHERE TRIM(v.value)='Project Management' AND e.path LIKE CONCAT(@bss_path,'/%') LIMIT 1) r);
SET @comm := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_name AND v.store_id=0
  WHERE TRIM(v.value)='Communication' AND e.path LIKE CONCAT(@bss_path,'/%') LIMIT 1) r);
SET @lead := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_name AND v.store_id=0
  WHERE TRIM(v.value)='Leadership' AND e.path LIKE CONCAT(@bss_path,'/%') LIMIT 1) r);
SET @coach := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_name AND v.store_id=0
  WHERE TRIM(v.value)='Coaching & Mentoring' AND e.path LIKE CONCAT(@bss_path,'/%') LIMIT 1) r);
SET @cs   := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_name AND v.store_id=0
  WHERE TRIM(v.value)='Customer Service' AND e.path LIKE CONCAT(@bss_path,'/%') LIMIT 1) r);
-- Match either the pre- or post-rename name so this is safe to re-run.
SET @ps   := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_name AND v.store_id=0
  WHERE TRIM(v.value) IN ('Critical Thinking & Problem Solving','Problem Solving')
    AND e.path LIKE CONCAT(@bss_path,'/%') LIMIT 1) r);
SET @dt   := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_name AND v.store_id=0
  WHERE TRIM(v.value)='Design Thinking' AND e.path LIKE CONCAT(@bss_path,'/%') LIMIT 1) r);
SET @cg   := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_name AND v.store_id=0
  WHERE TRIM(v.value) LIKE 'Corporate Governance%' AND e.path LIKE CONCAT(@bss_path,'/%') LIMIT 1) r);

-- Guard: only proceed when the whole shape resolved.
SET @ok := (@bss IS NOT NULL AND @ss IS NOT NULL AND @hr IS NOT NULL
        AND @comm IS NOT NULL AND @lead IS NOT NULL AND @coach IS NOT NULL
        AND @cs IS NOT NULL AND @ps IS NOT NULL);

-- 1. Keep the 3 courses sitting directly in Soft Skills from being orphaned:
--    ensure each is also assigned directly to Business & Soft Skills.
INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT @bss, p.product_id, 0 FROM catalog_category_product p
WHERE @ok AND p.category_id=@ss
  AND p.product_id NOT IN (SELECT product_id FROM catalog_category_product WHERE category_id=@bss)
ON DUPLICATE KEY UPDATE position = catalog_category_product.position;

-- 2. Reparent the 5 categories to be direct children of Business & Soft Skills.
--    parent_id / path / level only -- never url_key or url_path.
UPDATE catalog_category_entity
SET parent_id = @bss,
    path      = CONCAT(@bss_path, '/', entity_id),
    level     = @bss_level + 1
WHERE @ok AND entity_id IN (@comm, @lead, @coach, @cs, @ps);

-- 3. Rename "Critical Thinking & Problem Solving" -> "Problem Solving".
--    Name only; url_key untouched so the URL is preserved.
UPDATE catalog_category_entity_varchar
SET value = 'Problem Solving'
WHERE @ok AND attribute_id = @a_name AND entity_id = @ps;

-- 4. Disable + hide the now-empty "Soft Skills" container.
INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_act, 0, @ss, 0 FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_menu, 0, @ss, 0 FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_category_entity_int WHERE @ok AND entity_id=@ss AND attribute_id IN (@a_act,@a_menu) AND store_id<>0;

-- 5. Menu order.
UPDATE catalog_category_entity SET position = 1 WHERE @ok AND entity_id = @pm;
UPDATE catalog_category_entity SET position = 2 WHERE @ok AND entity_id = @hr;
UPDATE catalog_category_entity SET position = 3 WHERE @ok AND entity_id = @comm;
UPDATE catalog_category_entity SET position = 4 WHERE @ok AND entity_id = @lead;
UPDATE catalog_category_entity SET position = 5 WHERE @ok AND entity_id = @coach;
UPDATE catalog_category_entity SET position = 6 WHERE @ok AND entity_id = @cs;
UPDATE catalog_category_entity SET position = 7 WHERE @ok AND entity_id = @ps;
UPDATE catalog_category_entity SET position = 8 WHERE @ok AND entity_id = @dt;
UPDATE catalog_category_entity SET position = 9 WHERE @ok AND entity_id = @cg;
UPDATE catalog_category_entity SET position = 99 WHERE @ok AND entity_id = @ss;

-- 6. Mirror name/position/active into the category flat tables where present.
--    The flat rows also carry parent_id/level/path, but a full flat reindex
--    runs after deploy, so only the menu-visible fields are patched here.
SET @f := " f SET f.name='Problem Solving' WHERE f.entity_id=@ps AND @ok";
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0, CONCAT('UPDATE catalog_category_flat_store_1', @f), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0, CONCAT('UPDATE catalog_category_flat_store_2', @f), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0, CONCAT('UPDATE catalog_category_flat_store_3', @f), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @children := (SELECT COUNT(*) FROM catalog_category_entity WHERE parent_id=@bss);
UPDATE catalog_category_entity SET children_count = @children WHERE @ok AND entity_id=@bss;
UPDATE catalog_category_entity SET children_count = 0 WHERE @ok AND entity_id=@ss;
UPDATE catalog_category_entity SET children_count = (SELECT COUNT(*) FROM (SELECT entity_id FROM catalog_category_entity WHERE parent_id=@hr) x) WHERE @ok AND entity_id=@hr;
