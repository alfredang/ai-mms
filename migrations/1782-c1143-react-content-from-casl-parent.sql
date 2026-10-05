-- C1143 "AI Vibe Coding for React Development": re-aligned to its funded twin TGS-2026064534
-- (CASL - Build Full Stack React Web App with Vibe Coding), whose v4.0 courseware it now carries
-- (converted 2026-10-05). Name, slug, fee ($700), duration (15 hrs) and sessions (2) are already
-- correct and are not touched.
--
-- 1. About (short_description) + topics (description) copied from the parent. Neither states a
--    day count. This supersedes the C1143 copy written by 1781.
-- 2. meta_description rewritten: the old one ended "...in this hands-on 2-day React course".
-- 3. Funding block: linked wsq-build-full-stack-react-web-app-with-vibe-coding.html, which now
--    301s to the CASL page -> point straight at casl-ai-vibe-coding-with-react.html. Content-only
--    UPDATE (a cms/block model save would wipe cms_block_store).
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Not in SQL: schedule template B03 -> B09 (same code as the 2-day parent on (SG) WSQ-B09) is
-- switched on prod via the code path (CoursesaveController).
-- Post-deploy: flat reindex + cache flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1143' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064534' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- ---------------------------------------------- About + topics (parent) ----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, value
  FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @src AND attribute_id = @a_short AND store_id = 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, value
  FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @src AND attribute_id = @a_desc AND store_id = 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Build full stack React web apps with AI vibe coding. Master JSX, components, hooks, a serverless API over Neon Postgres, React Router and cloud deployment at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- an orphan TEXT-table meta_description would shadow the varchar value
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc;

-- ------------------------------------------- clear store-level overrides -----
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id <> 0;

-- ----------------------------------------------------- funding block -----
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/casl-ai-vibe-coding-with-react.html" title="CASL - Build Full Stack React Web App with Vibe Coding">CASL - Build Full Stack React Web App with Vibe Coding</a></span></p>'
 WHERE @ok AND identifier = 'course_C1143_funding_and_grant';
