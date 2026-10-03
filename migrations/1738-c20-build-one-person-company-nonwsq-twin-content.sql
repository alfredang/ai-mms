-- C20 "Build One Person Company with Multi AI Agents" becomes the non-WSQ twin of
-- TGS-2023036646 (WSQ - Manage AI Agents with Paperclip); its courseware is now the converted
-- WSQ set (github.com/tertiarycourses/C20-Build-One-Person-Company-with-Multi-AI-Agents).
--
-- 1. About + topics copied from the WSQ parent (4 topics; replaces the previous build's
--    "One Person Company Model" copy). The opener names the C20 title instead of the WSQ one.
--    Neither text states a day count.
-- 2. meta_description rewritten without the "1-day course" phrase; the orphan TEXT-table
--    meta_description (which shadows the varchar value) is removed.
-- 3. Funding block repointed from wsq-build-a-human-ai-workforce-with-autonomous-ai-agents.html
--    to the real twin, wsq-manage-ai-agents-with-paperclip.html.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Not in SQL: the schedule template switch A14 -> A07 (user's choice; the parent is on
-- (SG) WSQ-B07 but runs 2 days vs C20's 1, so the same-code rule does not apply) is a code path
-- (CoursesaveController::switchScheduleTemplateAction), run on prod separately.
-- Post-deploy: flat reindex + cache flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C20' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023036646' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- ---------------------------------------------- About + topics (parent) ----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid,
       REPLACE(value, '<p><strong>WSQ Manage AI Agents with Paperclip</strong> is',
                      '<p><strong>Build One Person Company with Multi AI Agents</strong> is')
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
SELECT 4, @a_mdesc, 0, @pid, 'Build a one-person company run by a team of AI agents with Paperclip: org charts, missions, issues, budgets, routines and approvals to coordinate and govern your AI workforce.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id <> 0;

-- an orphan TEXT-table meta_description would shadow the varchar value
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc;

-- ----------------------------------------------------- funding block -----
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-manage-ai-agents-with-paperclip.html" title="WSQ - Manage AI Agents with Paperclip">WSQ - Manage AI Agents with Paperclip</a></span></p>'
 WHERE @ok AND identifier = 'course_C20_funding_and_grant';
