-- C1154 AI Vibe Coding for SQL: "What's This Course About" and the course topics copied from the
-- WSQ parent TGS-2021002619 (WSQ - AI Vibe Coding for SQL), so both catalogue entries describe the
-- same 4-topic course. The old 2-topic syllabus is replaced. The copied text states no day count.
-- meta_description rewritten without the old "1-day course" wording and without WSQ/funding.
-- Literal upserts at store 0 (a parent-JOIN copy can no-op on prod); store overrides removed.
-- SG-only (store guard + parent must exist) -> no-op on MY/GH. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1154' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2021002619' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>AI Vibe Coding for SQL equips learners with practical skills to design, query and manage relational databases using natural-language instructions and AI coding assistants. Participants will learn how to translate business and application requirements into database structures and working SQL statements without having to write every command manually.</p>\n<p>The course covers essential SQL concepts, including tables, relationships, data types, primary and foreign keys, data insertion, filtering, sorting, joins, aggregation and subqueries. Learners will use AI-assisted workflows to generate, explain, refine and optimise SQL queries for common data management and reporting tasks.</p>\n<p>Through hands-on exercises, participants will create relational database schemas, import and organise data, perform CRUD operations and connect databases to applications and interactive dashboards. They will also apply AI tools to troubleshoot query errors, identify data-quality issues and recommend improvements to database performance.</p>\n<p>Emphasis is placed on validating AI-generated SQL for accuracy, efficiency and security. By the end of the course, participants will be able to use AI Vibe Coding techniques to develop database solutions, analyse structured data and produce meaningful reports that support business and application needs.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1: AI-Assisted SQL Data Modelling and Database Design</h3>\n<h3 class="course-topic-h3">Topic 2: SQL Data Processing, Querying and Analysis</h3>\n<h3 class="course-topic-h3">Topic 3: SQL Data Aggregation and Transformation</h3>\n<h3 class="course-topic-h3">Topic 4: Data Mapping, Warehousing and Dashboard Development</h3>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Learn AI Vibe Coding for SQL: design, query and manage relational databases with AI coding assistants. Build schemas, run queries and dashboards. Hands-on course in Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id <> 0;
