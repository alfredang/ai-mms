-- 1572: TGS-2026064716 "CASL - Business Innovation with Artificial Intelligence"
--       -- supplied About / Course Outline (2026-09-27).
--
-- Rewrites two things, keyed by SKU so a site without the course is a no-op
-- (SG-only; MY/GH have no TGS- SKUs):
--   * short_description -- the "About This Course" copy (4 paragraphs:
--     generative AI -> agentic AI -> AI agents, loop engineering, n8n / Claude
--     Code / Codex / OpenClaw / Hermes Agent / Paperclip, adoption + governance).
--   * description -- the "What You'll Learn" outline, replacing the five stale
--     2023 topics + sub-bullets with the five supplied topic headings. Same
--     headings-only house shape as 1564 / 999 (<h3 class="course-topic-h3">);
--     LSN_DATA comment dropped with the old topics (nothing reads it).
--   * meta_description -- was NULL, so the page head fell back to the raw
--     description HTML (live: the LSN_DATA JSON dump). Plain text, < 255 chars.
--
-- Untouched: cms_block course_TGS-2026064716_learning_outcomes (live LO1-LO5
-- already match the supplied outcomes), name, url_key, meta_title, price,
-- categories, trainers, brochure / funding_and_grant / skills_framework blocks.
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064716' LIMIT 1);
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>This course equips participants with the knowledge and practical skills to drive business innovation using generative AI, agentic AI and autonomous AI agents. Participants will examine the evolution of artificial intelligence from 2023 to 2026&mdash;from generative AI and prompt engineering to agentic AI, context engineering, harness engineering and AI-powered digital workers.</p><p>Participants will learn how AI is transforming traditional business models, operating processes and customer experiences. The course introduces key AI agent capabilities, including reasoning, memory, tool use, skills, workflow execution and human&ndash;AI collaboration. It also explains loop engineering, where agents repeatedly plan, act, observe, evaluate and improve their actions to accomplish complex business objectives.</p><p>Through practical demonstrations and real-world use cases, participants will explore technologies such as n8n, Claude Code, Codex, OpenClaw, Hermes Agent and Paperclip. They will examine how these technologies support automated workflows, multi-agent coordination, digital workers and natural-language interfaces for operating software and business systems. Applications involving Claude Cowork, ChatGPT for Work and n8n will demonstrate how agentic AI can improve administration, marketing, sales, customer service and operations.</p><p>Participants will identify potential AI opportunities, compare traditional and AI-enabled business models, and evaluate the costs, benefits, risks and feasibility of adoption. By the end of the course, they will be able to design and implement an AI-driven business innovation initiative supported by appropriate governance, human oversight and continuous improvement.</p>'
FROM DUAL WHERE @pid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1: Evolution of Business AI from Generative AI to Autonomous AI Agents</h3>
<h3 class="course-topic-h3">Topic 2: Generative AI, Agentic AI and AI Agent Technologies</h3>
<h3 class="course-topic-h3">Topic 3: Context, Harness and Loop Engineering for AI Agents</h3>
<h3 class="course-topic-h3">Topic 4: Business Opportunities and Innovative Agentic AI Use Cases</h3>
<h3 class="course-topic-h3">Topic 5: Evaluating and Implementing AI-Driven Business Innovation</h3>'
FROM DUAL WHERE @pid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- drop any store-scope overrides so the store-0 copy is what every scope serves
DELETE FROM catalog_product_entity_text WHERE entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0 AND @pid IS NOT NULL;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Drive business innovation with generative AI, agentic AI and AI agents. Explore n8n, Claude Code and Codex use cases, weigh costs and benefits, and implement AI-driven initiatives with governance and human oversight.'
FROM DUAL WHERE @pid IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar WHERE entity_id = @pid AND attribute_id = @a_mdesc AND store_id <> 0 AND @pid IS NOT NULL;
