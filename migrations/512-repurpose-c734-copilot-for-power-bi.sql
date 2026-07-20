-- Repurpose course C734 from "Basic Microsoft Power BI Training" to
-- "Copilot for Power BI" (name, overview, curriculum, meta, url_key,
-- image labels, media-gallery label, cover).
-- Price ($350) and 1-day duration (7.5) are intentionally kept.
-- Cover re-rendered 2026-07-18 with the new title (no funding chips) and
-- uploaded to R2.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0, and drops url_path at every scope so the
-- Catalog URL Rewrites indexer regenerates the new URL (old URL 301s).
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C734.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C734');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Copilot for Power BI' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Bring the power of AI into your business intelligence workflow with this hands-on 1-day Copilot for Power BI course. Copilot, Microsoft&rsquo;s AI assistant built into Power BI and Microsoft Fabric, lets you create report pages from plain-English prompts, generate DAX measures without memorising syntax, and produce instant narrative summaries of your dashboards. You will start by setting up Copilot in Power BI Desktop and the Power BI Service, then learn the prompting techniques that turn a business question into a polished, interactive report page.</p>
<p>The course then goes deeper into AI-assisted data modelling and analysis: using Copilot to prepare and transform data, write and explain DAX calculations, configure Q&amp;A so business users can query data in natural language, and summarise insights with the narrative visual. By the end of the course, you will be able to combine Copilot with core Power BI skills to build reports and dashboards faster, communicate insights more clearly, and roll out AI-assisted reporting across your organisation.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Get Started with Copilot in Power BI</h3>
<ul>
<li>What is Copilot for Power BI and Microsoft Fabric</li>
<li>Licensing, Requirements and Enabling Copilot</li>
<li>Copilot in Power BI Desktop vs Power BI Service</li>
<li>Effective Prompting for Reports and Analysis</li>
<li>Connecting and Preparing Data for Copilot</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Create Reports and Visuals with Copilot</h3>
<ul>
<li>Generating Report Pages from Prompts</li>
<li>Refining Visuals and Layouts with Copilot</li>
<li>Narrative Visuals and AI Summaries</li>
<li>Formatting and Storytelling Best Practices</li>
</ul>
<h3 class="course-topic-h3">Topic 3 AI-Assisted Data Modeling and Analysis</h3>
<ul>
<li>Generating and Explaining DAX Measures with Copilot</li>
<li>Setting Up Q&amp;A and Natural Language Queries</li>
<li>Summarising Insights and Answering Business Questions</li>
<li>Sharing AI-Assisted Reports and Dashboards</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Copilot for Power BI' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Copilot for Power BI, Power BI Copilot, Microsoft Fabric, AI Business Intelligence, AI Data Visualization, DAX with Copilot, Power BI Reports, Power BI Dashboard, AI Reporting, Power BI Course, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Build Power BI reports faster with AI. Learn Copilot for Power BI - generate report pages from prompts, create DAX measures, and summarise insights in this hands-on 1-day course at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'copilot-for-power-bi' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- New cover rendered from the new title, uploaded to R2 2026-07-18
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C734-20260717-175314.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Copilot for Power BI' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Copilot for Power BI' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Copilot for Power BI' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Product-page zoom gallery renders the per-image label as img title/alt
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Copilot for Power BI'
WHERE g.entity_id = @e AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_il, @a_sil, @a_til, @a_ciu);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);

-- Stale url_path rows point at the old microsoft-power-bi-training URL;
-- drop them at every scope so the Catalog URL Rewrites indexer regenerates
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND attribute_id=@a_up AND @a_up IS NOT NULL;

-- Funding block: the old WSQ link 301s; point directly at the live 200 URL
-- (WSQ - Data Analytics and Visualization with Power BI, still the closest
-- funded Power BI course). Content-only UPDATE by identifier - never a
-- cms/block model save, which would wipe the cms_block_store mapping.
-- No-op on sites without the block.
UPDATE cms_block SET content='<h2>Funding and Grant Applications</h2>\n\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-data-analytics-and-visualization-with-power-bi.html" title="WSQ - Data Analytics and Visualization with Power BI">WSQ - Data Analytics and Visualization with Power BI</a></span></p>'
WHERE identifier='course_C734_funding_and_grant';
