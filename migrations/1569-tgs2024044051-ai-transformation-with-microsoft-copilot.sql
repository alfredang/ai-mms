-- 1569: TGS-2024044051 -> "WSQ - AI Transformation with Microsoft Copilot"
--
-- Converts the course from "Microsoft 365 Copilot for Teams" to "AI
-- Transformation with Microsoft Copilot" (admin request 2026-09-27). The SKU and
-- the accredited TSC (Technology and Systems Application EPW-TEM-4023-1.1,
-- cms_block course_TGS-2024044051_skills_framework) are UNCHANGED, so every
-- SkillsFuture / SFEC / SFC / PSEA / UTAP deep link, the funding block, the
-- certification block and the brochure block stay valid and are not touched.
--
-- Pre-write probe (SG prod, entity 1345) found the old topic on: name, url_key,
-- url_path, meta_*, short_description, description (LSN_DATA outline), the LO
-- block (LO1-LO4 said "Microsoft Teams"), the 3 alt labels + gallery label, the
-- course-teaching paragraph of all 5 trainer bios, 35 core_url_rewrite rows
-- (8 system + 27 legacy 301s) and blog post 142 (2 course links). No search
-- term redirects to the old slug. No non-WSQ twin teaches "Copilot for Teams".
--
-- LOs: the supplied LO1-LO4 are the live ones with "Microsoft Teams" ->
-- "Microsoft Copilot" (same TSC wording). LO2's double space in the supplied
-- text is normalised to one.
--
-- SLUG: `wsq-ai-transformation-with-microsoft-copilot` -- probe found no url_key
-- or core_url_rewrite row on it (the only "ai-transformation" product is 711,
-- AB-731, at its own distinct slug).
--
-- COVER: pre-rendered PNG on R2 with the title baked in. Re-rendered via
-- MMD_CourseImage_Model_Cover with the product's OWN badge set (WSQ, SkillsFuture
-- Credit, PSEA, SFEC, Absentee Payroll, MCES) and uploaded before this file:
--   course-covers/TGS-2024044051-20260926-163007.png  (168557 bytes, HTTP 200)
-- The superseded object stays on R2 so reverting is just repointing the URL.
--
-- POST-DEPLOY (code paths a migration cannot run, on the SG web container):
--   1. Mage::getSingleton('catalog/url')->refreshProductRewrite(1345), then
--      catalog_product_flat reindex + cache flush -- the NEW slug 404s until
--      this runs, even though the old slug already 301s.
--   2. scripts/seo/generate-sitemaps.php so the sitemap lists the new slug.
--
-- SG production only; keyed by SKU so a partner site with no TGS-2024044051
-- no-ops. Idempotent: plain UPDATEs, upserts, self-extinguishing REPLACE()s.

SET @e  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024044051' LIMIT 1);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------------------------------------------------------------------------
-- 1. Identity, metas, alt labels
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @et
   SET v.value = CASE a.attribute_code
         WHEN 'name'             THEN 'WSQ - AI Transformation with Microsoft Copilot'
         WHEN 'url_key'          THEN 'wsq-ai-transformation-with-microsoft-copilot'
         WHEN 'url_path'         THEN 'wsq-ai-transformation-with-microsoft-copilot.html'
         -- meta_title stored BARE (MMD_Seotitle adds "WSQ funded" + brand at render)
         WHEN 'meta_title'       THEN 'AI Transformation with Microsoft Copilot'
         -- varchar(255): this value is 218 chars
         WHEN 'meta_description' THEN 'Plan, secure and scale AI transformation with Microsoft 365 Copilot, Copilot Studio agents and Power Platform. Covers governance, responsible AI, MCP, multi-agent workflows and ROI. Enjoy up to 70% WSQ funding subsidy.'
         ELSE 'AI Transformation with Microsoft Copilot'
       END
 WHERE v.entity_id = @e AND @e IS NOT NULL
   AND a.attribute_code IN ('name','url_key','url_path','meta_title','meta_description',
                            'image_label','small_image_label','thumbnail_label');

-- media gallery label = the real alt text (the stored file PATH is left alone)
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'AI Transformation with Microsoft Copilot'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_keyword' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = 'AI transformation, Microsoft Copilot, Microsoft 365 Copilot, Copilot Studio, Microsoft Foundry, Power Platform, Dynamics 365, AI agents, agentic AI, multi-agent workflows, Model Context Protocol, Agent2Agent, Copilot governance, responsible AI, Copilot ROI, WSQ Copilot course'
 WHERE attribute_id = @a_mk AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. About This Course (short_description) -- intro copy only on this course
-- ---------------------------------------------------------------------------
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'short_description' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<p><strong>AI Transformation with Microsoft Copilot</strong> equips participants with practical skills to plan, design, implement, and evaluate AI-powered solutions using Microsoft Copilot and the broader Microsoft AI ecosystem.</p>',
'<p>Participants will explore Microsoft 365 Copilot, Copilot Studio, Microsoft Foundry, Power Platform, Dynamics 365, AI models, prompts, and agents to improve productivity, automate processes, and support business transformation. Learners will understand how Copilot uses organisational data, work files, web information, and application context while maintaining privacy, security, and data protection.</p>',
'<p>The course covers agentic AI, including designing custom agents, agentic-first solutions, and multi-agent workflows. Participants will explore AI prompts, language models, Model Context Protocol (MCP), Agent2Agent (A2A), and cross-platform integration to develop secure and scalable AI solutions.</p>',
'<p>Learners will apply Copilot to draft and analyse business content, manage communications, support meetings and collaboration, and automate workflows. They will also monitor agent performance, evaluate AI outputs, interpret telemetry, and conduct ROI analysis to measure business value.</p>',
'<p>The course emphasises responsible AI practices, including managing risks such as AI fabrications, prompt injection, over-reliance, and sensitive-data exposure. Participants will apply verification, human review, access controls, governance, and responsible AI principles to deploy trustworthy AI solutions that improve operations and support enterprise growth.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. Course Outline (description): LSN_DATA JSON + rendered markup, in the
--    shape the admin outline editor writes. Four supplied topics, no subsecs.
-- ---------------------------------------------------------------------------
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'description' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<!-- LSN_DATA: [{"title":"Topic 1: Microsoft 365 Copilot Implementation and Business Process Transformation","subsecs":[]},{"title":"Topic 2: Microsoft Copilot Administration, Security and Responsible AI","subsecs":[]},{"title":"Topic 3: Copilot Integration, AI Agents and Cross-Platform Workflows","subsecs":[]},{"title":"Topic 4: AI Optimization, Performance Monitoring and Business Value","subsecs":[]}] -->',
'\n<p><strong>Topic 1: Microsoft 365 Copilot Implementation and Business Process Transformation</strong></p>',
'\n<p><strong>Topic 2: Microsoft Copilot Administration, Security and Responsible AI</strong></p>',
'\n<p><strong>Topic 3: Copilot Integration, AI Agents and Cross-Platform Workflows</strong></p>',
'\n<p><strong>Topic 4: AI Optimization, Performance Monitoring and Business Value</strong></p>',
'\n')
 WHERE attribute_id = @a_desc AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 4. Learning outcomes block
-- ---------------------------------------------------------------------------
UPDATE cms_block
   SET content = CONCAT(
'<p>By end of the course, learners should be able to:</p>\n<ul>\n',
'<li>LO1: Develop technology implementation plans and business processes for Microsoft Copilot.</li>\n',
'<li>LO2: Develop control procedures for Microsoft Copilot to manage security.</li>\n',
'<li>LO3: Evaluate the integration of Microsoft Copilot to ensure alignment with business objectives.</li>\n',
'<li>LO4: Develop optimization plans for Microsoft Copilot to improve business operations.</li>\n',
'</ul>')
 WHERE identifier = 'course_TGS-2024044051_learning_outcomes';

-- ---------------------------------------------------------------------------
-- 5. Trainer bios: retarget ONLY the course-teaching paragraph of each of the
--    5 bios. Credential paragraphs are facts and stay.
-- ---------------------------------------------------------------------------
SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'trainerprofile' AND entity_type_id = @et);

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Sanjiv brings a strategic perspective to adopting AI inside enterprise Teams environments. His sessions focus on prompting techniques, meeting preparation, and responsible AI use within Microsoft Teams and Microsoft 365. Through a balance of hands-on practice and real-world workplace scenarios, he helps learners master the skills needed to summarise discussions, extract action items, and coordinate work more effectively across organizations.',
       'In this course, Sanjiv brings a strategic perspective to AI transformation with Microsoft Copilot. His sessions focus on Copilot implementation planning, redesigning business processes, and responsible AI use across Microsoft 365. Through a balance of hands-on practice and real-world workplace scenarios, he helps learners build the skills needed to plan, roll out and govern Copilot solutions effectively across organizations.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Agus guides learners through the full Copilot workflow in Teams&mdash;from writing effective prompts to drafting messages, recapping meetings and following up on actions. His practical sessions cover working across chats, channels and shared workplace content, and verifying AI-generated output before acting on it.',
       'In this course, Agus guides learners through building Copilot-powered solutions&mdash;from writing effective prompts to designing custom agents in Copilot Studio and automating workflows with Power Platform. His practical sessions cover cross-platform integration, multi-agent workflows, and verifying AI-generated output before acting on it.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'With a strong emphasis on hands-on practice and real-world scenarios, he equips learners to use Copilot in Teams effectively, ensuring responsible, compliant, and trustworthy AI use in modern workplace ecosystems.',
       'With a strong emphasis on hands-on practice and real-world scenarios, he equips learners to apply access controls, governance, and safeguards against prompt injection and sensitive-data exposure, ensuring responsible, compliant, and trustworthy AI use in modern workplace ecosystems.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Alec provides learners with an in-depth understanding of how Copilot works across Teams meetings, chats and Microsoft 365 content. His training emphasizes practical prompting, human oversight, and verifying AI output to ensure a reliable user experience. Leveraging his extensive consulting experience, Alec helps participants build the confidence to apply Microsoft 365 Copilot to everyday collaboration in large-scale enterprises.',
       'In this course, Alec provides learners with an in-depth understanding of how Copilot integrates with organisational data, applications and AI agents across the Microsoft ecosystem. His training emphasizes evaluating integrations against business objectives, human oversight, and verifying AI output to ensure reliable solutions. Leveraging his extensive consulting experience, Alec helps participants build the confidence to scale Microsoft Copilot across large-scale enterprises.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Bernard teaches participants how to use AI to work through enterprise collaboration efficiently and securely. His sessions cover meeting recaps, action-item tracking, and workflow optimization in hybrid environments.',
       'In this course, Bernard teaches participants how to optimise Microsoft Copilot solutions efficiently and securely. His sessions cover monitoring agent performance, interpreting telemetry, and ROI analysis to measure business value.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 6. Cover image
-- ---------------------------------------------------------------------------
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'course_image_url' AND entity_type_id = @et);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @e,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024044051-20260926-163007.png'
  FROM DUAL WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0
   AND @e IS NOT NULL AND @a_ciu IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 7. URL rewrites: every old system path (bare + category-prefixed) becomes a
--    custom 301 to the flat new slug under its OWN id_path. System rows are
--    deleted first: a 301 left on id_path product/<id> blocks the indexer from
--    minting the new canonical row.
-- ---------------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_1569_old;
CREATE TEMPORARY TABLE tmp_1569_old AS
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @e IS NOT NULL AND is_system = 1 AND product_id = @e
   AND (request_path = 'wsq-microsoft-365-copilot-for-teams.html'
        OR request_path LIKE '%/wsq-microsoft-365-copilot-for-teams.html');

DELETE r FROM core_url_rewrite r
  JOIN tmp_1569_old t ON t.store_id = r.store_id AND t.request_path = r.request_path;

-- clear any non-system squatter on the NEW paths
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND (request_path = 'wsq-ai-transformation-with-microsoft-copilot.html'
        OR request_path LIKE '%/wsq-ai-transformation-with-microsoft-copilot.html');

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT t.store_id,
       CONCAT('custom/tgs2024044051-teams-', LEFT(MD5(t.request_path), 10)),
       t.request_path, 'wsq-ai-transformation-with-microsoft-copilot.html', 0, 'RP',
       '1569: TGS-2024044051 converted to AI Transformation with Microsoft Copilot'
  FROM tmp_1569_old t
ON DUPLICATE KEY UPDATE target_path = VALUES(target_path), options = 'RP', is_system = 0;

DROP TEMPORARY TABLE IF EXISTS tmp_1569_old;

-- flatten every legacy 301 (MS-700 / Teams Administrator eras) that lands on an
-- old path, so all resolve in one hop
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-transformation-with-microsoft-copilot.html', options = 'RP'
 WHERE is_system = 0
   AND (target_path = 'wsq-microsoft-365-copilot-for-teams.html'
        OR target_path LIKE '%/wsq-microsoft-365-copilot-for-teams.html');

-- ---------------------------------------------------------------------------
-- 8. Search terms: "ai transformation" / "DIGITAL ai TRANSFORMATION" already
--    redirect to the GenAI digital-transformation course and are left alone.
--    The two course-code terms (on MS-700-era slugs) go straight to the new
--    slug. The ~15 Teams / MS-700 worded terms are left: they already reach
--    this course in one hop via the flattened 301s above, and no other course
--    teaches Teams.
-- ---------------------------------------------------------------------------
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/wsq-ai-transformation-with-microsoft-copilot.html'
 WHERE query_text IN ('TGS-2024044051',
                      'TGS-2024044051 - Microsoft Teams Administrator Associate (MS-700)')
   AND redirect LIKE '%/wsq-microsoft-teams-administrator-associate-%'
   AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 9. Blog post 142 (M365 Copilot productivity guide): the "goes deeper on the
--    collaboration side" pointer no longer fits the course, so that sentence is
--    rewritten; the series list keeps the link under the new name.
-- ---------------------------------------------------------------------------
UPDATE mmd_blog_post
   SET content = REPLACE(REPLACE(content,
         'The <a href="https://www.tertiarycourses.com.sg/wsq-microsoft-365-copilot-for-teams.html">WSQ Microsoft 365 Copilot for Teams</a> course goes deeper on the collaboration side if that is where most of your day is spent.',
         'If you are leading the organisation-wide rollout rather than using it day to day, the <a href="https://www.tertiarycourses.com.sg/wsq-ai-transformation-with-microsoft-copilot.html">WSQ AI Transformation with Microsoft Copilot</a> course covers implementation planning, governance, agents and measuring ROI.'),
         '<a href="https://www.tertiarycourses.com.sg/wsq-microsoft-365-copilot-for-teams.html">Copilot for Teams</a>',
         '<a href="https://www.tertiarycourses.com.sg/wsq-ai-transformation-with-microsoft-copilot.html">AI Transformation with Microsoft Copilot</a>')
 WHERE content LIKE '%/wsq-microsoft-365-copilot-for-teams.html%'
   AND @e IS NOT NULL;
