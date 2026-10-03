-- C1800 "AI Vibe Coding for Full Stack Web Development" becomes the non-WSQ twin of
-- TGS-2021008635 (WSQ - AI Vibe Coding for Full Stack Web Applications); its courseware is now
-- the converted WSQ set (github.com/tertiarycourses/C1800-AI-Vibe-Coding-for-Full-Stack-Web-Development).
--
-- 1. About + topics copied from the WSQ parent (5 topics; replaces the previous build's 4-topic
--    copy). The opener names the C1800 title. Neither text states a day count.
-- 2. meta_description rewritten without the "2-day course" phrase.
-- 3. Funding block repointed from wsq-build-full-stack-react-web-app-with-vibe-coding.html
--    to the real twin, wsq-ai-vibe-coding-for-full-stack-web-applications.html.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Not in SQL: the schedule template switch B03 -> B05 (matches the parent's (SG) WSQ-B05) is a
-- code path (CoursesaveController::switchScheduleTemplateAction), run on prod separately.
-- Post-deploy: flat reindex + cache flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1800' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2021008635' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- ---------------------------------------------- About + topics (parent) ----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid,
       REPLACE(value, '<p>AI Vibe Coding for Full Stack Web Applications equips',
                      '<p>AI Vibe Coding for Full Stack Web Development equips')
  FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @src AND attribute_id = @a_short AND store_id = 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, value
  FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @src AND attribute_id = @a_desc AND store_id = 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'AI Vibe Coding for Full Stack Web Development in Singapore: build a React, Express and SQLite web app with AI coding assistants, from requirements and UI to APIs, data, testing and release.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id <> 0;

-- an orphan TEXT-table meta_description would shadow the varchar value
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc;

-- ----------------------------------------------------- funding block -----
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-full-stack-web-applications.html" title="WSQ - AI Vibe Coding for Full Stack Web Applications">WSQ - AI Vibe Coding for Full Stack Web Applications</a></span></p>'
 WHERE @ok AND identifier = 'course_C1800_funding_and_grant';
