-- C781 Power BI Masterclass = the 2-day non-WSQ twin of TGS-2020505444 (WSQ - Data Analytics and
-- Visualization with Power BI). Courseware v1.0 converted from the WSQ v15.0 set.
--
-- 1. "What's This Course About" and course topics follow the WSQ parent (ASCII literals copied from prod;
--    "WSQ-endorsed course on Power BI" -> "Power BI Masterclass"; its 6 topics, LSN_DATA JSON + HTML).
-- 2. meta_description rewritten in ASCII (the old value carried latin1 mojibake for an em dash); no day count.
-- 3. Funding block points at the WSQ twin.
-- Name / slug / fee / duration / sessions are already Power BI Masterclass / power-bi-masterclass / $700 / 15 / 2,
-- and the course already sits on B09 (the parent moves to WSQ-B09 via the code path) -> unchanged here.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C781' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2020505444' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Master Microsoft Power BI in this hands-on Power BI Masterclass: connect and transform data with Power Query, build interactive reports and dashboards, model your data and analyse it with DAX at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id <> 0;

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Dive into the world of data analytics and visualization with our comprehensive Power BI Masterclass. This course is designed to teach you how to turn complex data into compelling visual stories. You\'ll learn to navigate the Power BI interface, connect to various data sources, and create interactive dashboards. Practical exercises and real-world examples are integrated into the curriculum, ensuring you\'ll gain actionable skills.</p>\r\n<p>By the end of this course, you\'ll be proficient in using Power BI to analyze data, create visualizations, and develop interactive dashboards that can inform business decisions. Whether you\'re a business professional looking to upskill, a data enthusiast, or someone in a decision-making role, this course equips you with the tools and knowledge to make data-driven decisions effectively.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Get Started on Power BI","subsecs":[{"title":"Overview of Power BI Desktop and Service","links":[]},{"title":"Import/Connect Data into Power BI","links":[]},{"title":"Transform Data","links":[]},{"title":"Combine Data","links":[]},{"title":"Filter Data","links":[]}]},{"title":"Topic 2: Create Data Visualization","subsecs":[{"title":"Create Data Visualizations","links":[]},{"title":"Format Visuals","links":[]},{"title":"Create Power BI Reports","links":[]}]},{"title":"Topic 3: Create Dashboard and Scoreboard","subsecs":[{"title":"What is Dashboard and Scoreboard","links":[]},{"title":"Create Dashboard","links":[]},{"title":"Customize Dashboard","links":[]}]},{"title":"Topic 4: Create Dynamic Visualization","subsecs":[{"title":"Create Dynamics Charts","links":[]},{"title":"Create Interactions","links":[]},{"title":"Create Visual Hierarchies","links":[]}]},{"title":"Topic 5: Create Data Model","subsecs":[{"title":"Overview of Data Model","links":[]},{"title":"Data Relationships","links":[]},{"title":"Calculation and Measures","links":[]}]},{"title":"Topic 6: Data Analytics with DAX","subsecs":[{"title":"Overview of DAX Language","links":[]},{"title":"Perform Data Queries and Analytics","links":[]}]}] -->\r\n<p><strong>Topic 1: Get Started on Power BI</strong></p>\r\n<p><em>Overview of Power BI Desktop and Service</em></p>\r\n<p><em>Import/Connect Data into Power BI</em></p>\r\n<p><em>Transform Data</em></p>\r\n<p><em>Combine Data</em></p>\r\n<p><em>Filter Data</em></p>\r\n<p><strong>Topic 2: Create Data Visualization</strong></p>\r\n<p><em>Create Data Visualizations</em></p>\r\n<p><em>Format Visuals</em></p>\r\n<p><em>Create Power BI Reports</em></p>\r\n<p><strong>Topic 3: Create Dashboard and Scoreboard</strong></p>\r\n<p><em>What is Dashboard and Scoreboard</em></p>\r\n<p><em>Create Dashboard</em></p>\r\n<p><em>Customize Dashboard</em></p>\r\n<p><strong>Topic 4: Create Dynamic Visualization</strong></p>\r\n<p><em>Create Dynamics Charts</em></p>\r\n<p><em>Create Interactions</em></p>\r\n<p><em>Create Visual Hierarchies</em></p>\r\n<p><strong>Topic 5: Create Data Model</strong></p>\r\n<p><em>Overview of Data Model</em></p>\r\n<p><em>Data Relationships</em></p>\r\n<p><em>Calculation and Measures</em></p>\r\n<p><strong>Topic 6: Data Analytics with DAX</strong></p>\r\n<p><em>Overview of DAX Language</em></p>\r\n<p><em>Perform Data Queries and Analytics</em></p>\r\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mdesc) AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C781 - Funding and Grant', 'course_C781_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C781_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C781_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C781_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-data-analytics-and-visualization-with-power-bi.html" title="WSQ - Data Analytics and Visualization with Power BI">WSQ - Data Analytics and Visualization with Power BI</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C781_funding_and_grant';
