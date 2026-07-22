-- 665: Repurpose C735 "AI Agents with n8n" -> "Agentic AI with n8n"
-- Topics follow the WSQ counterpart (wsq-agentic-ai-automation-with-n8n, TGS-2023035977).
-- Category: drop "AI Agents Series", ensure "Agentic AI Series" (resolved by name).
-- Partner-safe: every statement guarded on @e / name-resolution; NO funding content here
-- (SG WSQ funding block is a direct SG-prod-only edit, never shared).

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C735' LIMIT 1);

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'name');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_title');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_key');
SET @a_up   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_path');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'thumbnail_label');
SET @a_ciu  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'course_image_url');
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'short_description');
SET @a_d    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'description');

-- Store-0 varchar attributes
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_name, 0, @e, 'Agentic AI with n8n' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mt, 0, @e, 'Agentic AI with n8n | Tertiary Courses Singapore' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_uk, 0, @e, 'agentic-ai-with-n8n' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_il, 0, @e, 'Agentic AI with n8n' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sil, 0, @e, 'Agentic AI with n8n' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_til, 0, @e, 'Agentic AI with n8n' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C735-20260722-023257.png' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- url_path: delete at EVERY scope; the Catalog URL Rewrites indexer regenerates it
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up AND @e IS NOT NULL;

-- Clear partner/store-scoped overrides so store 0 wins everywhere (GH shadow fix)
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND store_id <> 0 AND attribute_id IN (@a_name, @a_mt, @a_uk, @a_il, @a_sil, @a_til, @a_ciu) AND @e IS NOT NULL;
DELETE FROM catalog_product_entity_text WHERE entity_id = @e AND store_id <> 0 AND attribute_id IN (@a_sd, @a_d) AND @e IS NOT NULL;

-- Store-0 overview (short_description) — agentic rewrite, NO funding content
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sd, 0, @e, '<p>Master intelligent automation with Agentic AI with n8n. This hands-on course teaches you how to combine n8n&rsquo;s low-code workflow orchestration with autonomous AI capabilities to design, build and deploy agentic AI systems that can plan and execute tasks independently. From workflow automation fundamentals to event-driven agentic automations, you will learn to orchestrate tools, APIs and AI agents into reliable workflows that get real work done.</p>\n<p>Through practical projects, participants will build workflow automations in n8n, create agentic process automations with AI agents, trigger automations through webhooks and HTTP requests, enhance workflows with agentic retrieval-augmented generation (RAG), and apply human-in-the-loop approvals, monitoring and security best practices. By the end of the course, you will be able to design, build and deploy secure, monitored agentic AI automations with n8n that boost operational efficiency and scale your operations.</p>' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Store-0 topics (description) — mirrors the WSQ course topics
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_d, 0, @e, '<p><strong>Topic 1: Workflow Automation with n8n</strong></p>\n<p><strong>Topic 2: Agentic Process Automation with AI Agents</strong></p>\n<p><strong>Topic 3: Agentic Automation with Webhooks and HTTP Requests</strong></p>\n<p><strong>Topic 4: Enhancing Workflow Automation with Agentic RAG</strong></p>\n<p><strong>Topic 5: Human-in-the-Loop, Monitoring, and Security in n8n</strong></p>' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Media gallery per-image label (zoom gallery renders this as img title/alt)
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Agentic AI with n8n'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- Category move: out of "AI Agents Series", into "Agentic AI Series" (name-resolved)
SET @a_catname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category') AND attribute_code = 'name');

DELETE cp FROM catalog_category_product cp
JOIN catalog_category_entity_varchar v ON v.entity_id = cp.category_id AND v.attribute_id = @a_catname AND v.store_id = 0
WHERE v.value = 'AI Agents Series' AND cp.product_id = @e AND @e IS NOT NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT v.entity_id, @e, 0 FROM catalog_category_entity_varchar v
WHERE v.attribute_id = @a_catname AND v.store_id = 0 AND v.value = 'Agentic AI Series' AND @e IS NOT NULL;
