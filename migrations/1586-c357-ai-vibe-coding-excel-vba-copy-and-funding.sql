-- 1586: C357 AI Vibe Coding for Excel VBA — non-WSQ twin of TGS-2021008700.
-- 1) "What's This Course About" (short_description) and the course topics
--    (description, LSN_DATA) copied from the WSQ parent, so both catalogue
--    entries describe the same 5-topic course; the old C357 copy stated
--    "2-day course" and carried a different topic list.
-- 2) meta_description rewritten without the day count.
-- 3) Funding block repointed from the unrelated "WSQ - AI Vibe Coding for Multi
--    Agents System" to the WSQ twin /wsq-ai-vibe-coding-for-excel-vba.html.
-- Idempotent, keyed by SKU. A site without C357 or without the WSQ parent
-- (partner sites) is a no-op.
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C357' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2021008700' LIMIT 1);
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_meta := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, t.attribute_id, 0, @pid, t.value
  FROM catalog_product_entity_text t
 WHERE t.entity_id = @src AND t.store_id = 0 AND t.attribute_id IN (@a_short, @a_desc)
   AND @pid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_meta, 0, @pid, 'Automate Excel with AI vibe coding. Master VBA macros, ranges, events, custom functions and userforms using AI coding assistants in this hands-on course at Tertiary Courses Singapore.'
  FROM DUAL WHERE @pid IS NOT NULL AND @src IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-excel-vba.html" title="WSQ - AI Vibe Coding for Excel VBA">WSQ - AI Vibe Coding for Excel VBA</a></span></p>'
 WHERE identifier = 'course_C357_funding_and_grant'
   AND (SELECT COUNT(*) FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2021008700') > 0;
