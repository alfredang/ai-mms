-- 1006: Repurpose TGS-2023036153
--   OLD: "WSQ - Mastering Prompt Engineering for Generative AI Content Creation"
--   NEW: "WSQ - Multi AI Agents Workflow for Content Creation"
-- SKU unchanged (SkillsFuture / SFEC / SFC / PSEA deep links are keyed on it).
-- Content supplied by admin, 2026-08-14.
--
-- Surfaces touched (mechanical sweep of BOTH EAV value tables + cms_block for
-- 'Prompt Engineering' / 'prompt', per feedback_tgs_course_rename_checklist):
--   1  name                 -> keeps the "WSQ - " prefix
--   2  meta_title           -> plain title; the OLD value wrongly baked in BOTH
--                              the "WSQ" funding token and the brand suffix that
--                              MMD_Seotitle adds at render time. Store 1 override
--                              exists -> update BOTH scopes.
--   3  url_key + url_path   -> new slug; url_path deleted at every scope so the
--                              URL-rewrite indexer regenerates. The old bare slug
--                              is held by the product's own is_system = 1 row, so
--                              INSERT IGNORE would no-op -> convert it in place
--                              (feedback_rename_301_vs_system_rewrite_suffix_trap).
--   4  description          -> 4 new topics (no LSN_DATA on this course; it uses
--                              the <h3 class="course-topic-h3"> + <ul> shape)
--   5  short_description    -> full replace: post-885 block model, prose ONLY
--                              (no Brochure/Skills Framework/Funding tail -- all
--                              already extracted to cms_block rows). Verified by
--                              dumping the whole value: 1139 bytes of <p> only.
--   6  meta_description     -> varchar attr, store 0 + store 1 override
--   7  meta_keyword         -> retargeted to multi-agent terms, store 0 + store 1
--   8  *_label (3) + media_gallery_value.label -> alt text, plain title
--   9  trainerprofile       -> para 2 ONLY of each of the 4 bios (the
--                              course-teaching claim). Para 1 = career
--                              CREDENTIALS (real Adobe/NUS/NTU history) = facts.
--  10  whoshouldattend      -> 2 prompt-engineering-specific roles retargeted;
--                              the other 13 are framework-neutral marketing roles.
--  11  learning_outcomes    -> cms_block: drops "with prompt engineering" from
--                              LO1-LO3 per the admin-supplied wording. The LOs are
--                              otherwise the SSG-accredited outcomes on the
--                              UNCHANGED SKU, so the substance is preserved.
--  12  categories           -> drop 188 "Prompt Engineering" (course no longer
--                              teaches it as the subject; the cat holds only 3
--                              products, 2 of them prompt-specific), add 187
--                              "Multi AI Agents Series" (the sibling home of every
--                              multi-agent WSQ course) + 415 "AI Agents Series".
--                              Mirrored into catalog_category_product_index
--                              (feedback_category_swap_needs_index_mirror).
--
-- Verified-clean, deliberately NOT touched:
--   - prerequisite: its "Minimum Software/Hardware" list is generic GenAI tools
--     (ChatGPT / Claude / Copilot / Gemini / Designer / Firefly) that multi-agent
--     content workflows still use -- no old-tool link to retarget. The rest of the
--     attribute is the funding apparatus (PWM, funding table, MSF/NTUC/MOM deep
--     links, Appeal Process) and must survive byte-identical.
--   - certification / skills_framework / funding_and_grant / brochure cms_blocks:
--     Content Strategy ICT-SNM-4004-1.1 TSC still applies (the course still
--     delivers content strategy), funding is keyed on the unchanged SKU.
--   - image / small_image / thumbnail: filesystem PATHS, not display text --
--     renaming them 404s the JPG. The storefront renders the R2 cover.
--   - tags (WSQ/SkillsFuture Credit/PSEA/UTAP/SFEC/MCES/Absentee Payroll).
--   - catalogsearch_query: NO row's redirect targets this course's slug or code
--     (checked); the 28 rows matching "prompt engineering" all have empty
--     redirects or belong to other live courses -- filling them would be wrong
--     (feedback_repurpose_target_name_may_already_exist_as_live_twin).
--   - No name/slug collision: nearest live course is TGS-2024042961
--     "WSQ - Develop Multi AI Agent Applications with Gemini Agent ADK"
--     (slug wsq-develop-multi-ai-agent-applications-with-gemini-agent-adk).
--
-- Cover PNG still bakes the old title -> re-render from the admin after deploy.
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => no-op.
-- All replacement text is clean ASCII/UTF-8 (apply.php connects charset=utf8).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023036153' LIMIT 1);

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpth := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_trainer := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_wsa    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_ilabel := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slabel := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlabel := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ---------------------------------------------------------------- 1. name
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Multi AI Agents Workflow for Content Creation'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------------ 2. meta_title
-- Plain title only, EVERY scope (a store-1 override exists). MMD_Seotitle
-- prepends "WSQ funded" for SG TGS- SKUs and appends the brand postfix at
-- render time (Block/Html/Head.php::_fundingPrefix) -- the old value baked in
-- both, yielding "WSQ funded WSQ ... | Tertiary Courses Singapore".
UPDATE catalog_product_entity_varchar
   SET value = 'Multi AI Agents Workflow for Content Creation'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

-- -------------------------------------------------------- 6. meta_description
UPDATE catalog_product_entity_varchar
   SET value = 'Learn to design and manage multi AI agent workflows for end-to-end content creation. Coordinate research, strategy, writing, design and publishing agents to produce marketing content at scale. Enjoy up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

-- ----------------------------------------------------------- 7. meta_keyword
UPDATE catalog_product_entity_text
   SET value = 'multi AI agents workflow, AI content creation, AI agent collaboration, content strategy, digital storyboarding, audience research, multi-channel content, agent handoffs, content distribution, marketing content automation, brand guidelines, responsible AI, human oversight'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- ------------------------------------------------------------- 8. alt labels
-- Alt text on the cover; the cover itself strips the segment prefix
-- (CourseImage/Model/Cover.php::cleanTitle) so these carry no "WSQ - ".
UPDATE catalog_product_entity_varchar
   SET value = 'Multi AI Agents Workflow for Content Creation'
 WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel) AND @e IS NOT NULL;

-- Media-gallery label: the product-page zoom gallery renders THIS as img alt/title,
-- and it is NOT covered by the three *_label attrs above.
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Multi AI Agents Workflow for Content Creation'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------------------- 3. url_key / url_path / 301
-- Clear any is_system = 0 squatter on the NEW path first: INSERT IGNORE would
-- silently no-op against a stale row (see 647).
DELETE FROM core_url_rewrite
 WHERE request_path = 'multi-ai-agents-workflow-for-content-creation.html'
   AND is_system = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'multi-ai-agents-workflow-for-content-creation'
 WHERE entity_id = @e AND attribute_id = @a_urlkey AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL-rewrite indexer regenerates it
-- (a store-1 override exists and would shadow the new URL).
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlpth AND @e IS NOT NULL;

-- The old bare slug is owned by the product's own SYSTEM rewrite
-- (id_path = 'product/<e>', is_system = 1), so the usual INSERT IGNORE 301 hits
-- the unique key on (request_path, store_id) and does NOTHING. Convert that row
-- in place into a 301 instead. See
-- feedback_rename_301_vs_system_rewrite_suffix_trap.
UPDATE core_url_rewrite
   SET target_path = 'multi-ai-agents-workflow-for-content-creation.html',
       is_system   = 0,
       options     = 'RP',
       description = '1006 repurpose 301'
 WHERE request_path = 'wsq-mastering-prompt-engineering-for-generative-ai-content-creation.html'
   AND product_id = @e AND @e IS NOT NULL;

-- Cover the case where the old path is NOT already owned by a rewrite row
-- (fresh DB / already-reindexed prod) so re-runs still leave a working 301.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id, NULL, @e,
       CONCAT('product/', @e),
       'wsq-mastering-prompt-engineering-for-generative-ai-content-creation.html',
       'multi-ai-agents-workflow-for-content-creation.html',
       0, 'RP', '1006 repurpose 301'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- --------------------------------------------- 4. Course Outline (description)
-- This course has NO LSN_DATA JSON comment -- it uses the plain
-- <h3 class="course-topic-h3"> + <ul> shape. Keep that shape.
UPDATE catalog_product_entity_text
   SET value = '<h3 class="course-topic-h3">Topic 1: Multi-AI-Agent Content Ideation and Digital Storyboarding</h3>
<ul>
<li>Introduction to multi-AI-agent workflows for content creation</li>
<li>Assigning agent roles: researcher, strategist, writer, designer, editor, reviewer and publishing coordinator</li>
<li>Conceptualize content ideas with AI agents to meet marketing objectives</li>
<li>Map out digital storyboards as part of a content strategy</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Audience Research and Content Requirement Analysis</h3>
<ul>
<li>Multi-agent market, audience and competitor research</li>
<li>Identify content requirements based on evaluation of customers and potential customer preferences</li>
<li>Determine frequency of delivering marketing content to customers</li>
</ul>
<h3 class="course-topic-h3">Topic 3: Multi-Channel Content Creation and Agent Workflow Coordination</h3>
<ul>
<li>Creating content for websites, blogs, email campaigns, advertisements, videos and social media</li>
<li>Adapting messaging, formats, styles and calls to action per customer segment and channel</li>
<li>Determine types and styles of content to be delivered to customers</li>
<li>Coordinating agent handoffs, reference materials, brand guidelines and quality criteria</li>
</ul>
<h3 class="course-topic-h3">Topic 4: Content Distribution, Strategy Guidelines and Responsible AI Practices</h3>
<ul>
<li>Determine modes and processes for distributing content</li>
<li>Reviewing outputs, managing feedback loops and iterative refinement</li>
<li>Human oversight, factual accuracy, copyright, data privacy and brand safety</li>
<li>Develop guidelines for content strategy execution</li>
</ul>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------- 5. About This Course (sdesc)
-- Full replace is correct here: this course's short_description is intro prose
-- ONLY (verified by dumping all 1139 bytes -- no <h2> Brochure / Skills Framework
-- / Certification / WSQ Funding tail; those live in cms_block rows since the
-- 885-891 extraction). Guarded on the new phrase so a re-run converges.
UPDATE catalog_product_entity_text
   SET value = '<p>This course equips participants with practical skills to design and manage multi-AI-agent workflows for end-to-end content creation. Learners will explore how specialised AI agents can collaborate as researchers, strategists, writers, designers, editors, reviewers, and publishing coordinators to produce high-quality content aligned with marketing objectives.</p>
<p>Participants will learn how to define content goals, analyse target audiences, conduct market and competitor research, generate content ideas, and develop digital storyboards. They will assign clear roles, tasks, reference materials, brand guidelines, and quality criteria to different AI agents, enabling content to move through a structured production workflow.</p>
<p>The course covers the creation of content for websites, blogs, email campaigns, advertisements, videos, and social media platforms. Learners will use multi-agent processes to adapt messaging, formats, styles, and calls to action for different customer segments and communication channels while maintaining a consistent brand identity.</p>
<p>Participants will also learn to coordinate agent handoffs, review outputs, manage feedback loops, detect errors, and improve content through iterative refinement. Emphasis is placed on human oversight, factual accuracy, copyright, data privacy, brand safety, and responsible AI use. By the end of the course, learners will be able to build scalable multi-AI-agent workflows that improve content quality, consistency, production speed, and marketing effectiveness.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0
   AND LOCATE('multi-AI-agent workflows for end-to-end content creation', value) = 0
   AND @e IS NOT NULL;

-- ------------------------------------------------------- 11. learning_outcomes
-- Guarded INSERT first: courses predating the 885-891 extraction may have no
-- block at all, in which case a bare UPDATE silently no-ops (see 931/915 shape).
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2023036153 - Learning Outcomes', 'course_TGS-2023036153_learning_outcomes', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_TGS-2023036153_learning_outcomes');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2023036153_learning_outcomes';

UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Conceptualize content ideas to meet marketing objectives and map out digital storyboards as part of a content strategy.</li>
<li>LO2: Identify content requirements based on evaluation of customers and potential customer preferences and determine frequency of delivering marketing content.</li>
<li>LO3: Determine types and styles of content to be delivered to customers and decide on modes and processes for distributing content.</li>
<li>LO4: Develop guidelines for content strategy execution using appropriate modes of content delivery for marketing.</li>
</ul>',
       update_time = NOW()
 WHERE identifier = 'course_TGS-2023036153_learning_outcomes';

-- ---------------------------------------------------------- 9. trainerprofile
-- Retarget ONLY the course-teaching sentence in para 2 of each bio. Para 1 holds
-- career CREDENTIALS (Adobe Certified Expert, NUS Master's, NTU First-Class,
-- Medistation, ACLP) -- those are facts and rewriting them would falsify the bio.
-- Each target string is kept on ONE line: a multi-line REPLACE() no-ops against
-- CRLF WYSIWYG blobs (feedback_multiline_replace_fails_on_crlf_blobs).
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this program, James guides learners in mastering prompt engineering techniques for generative AI tools, showing how carefully crafted prompts can drive higher-quality outputs in content creation, branding, and marketing campaigns.',
       'In this program, James guides learners in orchestrating multi-AI-agent content workflows, showing how researcher, writer, designer and editor agents can hand off work to each other to produce higher-quality outputs in content creation, branding, and marketing campaigns.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Allen leverages his deep experience in AI-powered marketing and automation to teach learners how to design prompts that maximize output quality from generative AI systems. His hands-on approach emphasizes real-world business applications such as campaign design, personalized content generation, and customer engagement strategies. By combining strategic marketing insight with technical knowledge of AI, Allen empowers participants to confidently use prompt engineering to enhance digital creativity and business impact.',
       'In this course, Allen leverages his deep experience in AI-powered marketing and automation to teach learners how to coordinate teams of AI agents across the content production pipeline. His hands-on approach emphasizes real-world business applications such as campaign design, multi-channel content generation, and customer engagement strategies. By combining strategic marketing insight with technical knowledge of AI, Allen empowers participants to confidently run multi-agent content workflows that scale digital creativity and business impact.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Mastering Prompt Engineering for Generative AI Content Creation,&rdquo; Woei Ming teaches participants how to leverage the power of generative AI through effective prompt design and optimization. His sessions focus on understanding LLM behavior, crafting structured prompts, and applying AI models for real-world creative and analytical tasks. By combining deep technical knowledge with practical experimentation, he helps learners master prompt engineering techniques that enhance creativity, precision, and productivity in generative AI workflows.',
       'In &ldquo;Multi AI Agents Workflow for Content Creation,&rdquo; Woei Ming teaches participants how to design agent roles, tasks and handoffs across a structured content production workflow. His sessions focus on understanding agent behavior, assigning reference materials and quality criteria, and applying AI models for real-world creative and analytical tasks. By combining deep technical knowledge with practical experimentation, he helps learners build multi-agent workflows that enhance creativity, precision, and productivity.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Mastering Prompt Engineering for Generative AI Content Creation,&rdquo; Teddy focuses on helping professionals develop practical prompt engineering skills for creativity, communication, and business innovation. His sessions explore real-world applications of AI content generation, from crafting marketing narratives to automating communication workflows. By merging his expertise in training and AI adoption, he empowers learners to effectively harness GenAI tools to produce engaging, high-quality, and purpose-driven content.',
       'In &ldquo;Multi AI Agents Workflow for Content Creation,&rdquo; Teddy focuses on helping professionals apply multi-agent content workflows for creativity, communication, and business innovation. His sessions explore real-world applications of AI content generation, from crafting marketing narratives to automating review and publishing workflows, with attention to human oversight and brand safety. By merging his expertise in training and AI adoption, he empowers learners to produce engaging, high-quality, and purpose-driven content.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------- 10. whoshouldattend
-- Only the two prompt-engineering-specific roles retarget; the other 13 are
-- framework-neutral marketing/content roles that still apply.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li>Language Model Developer</li>',
       '<li>AI Agent Workflow Developer</li>')
 WHERE entity_id = @e AND attribute_id = @a_wsa AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li>AI Content Tool Specialist</li>',
       '<li>AI Content Automation Specialist</li>')
 WHERE entity_id = @e AND attribute_id = @a_wsa AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------------- 12. categories
-- Resolve BY NAME (ids differ per site) and mirror every change into
-- catalog_category_product_index or the storefront listing never changes
-- (feedback_category_swap_needs_index_mirror).

-- Drop: the course no longer teaches prompt engineering as its subject.
DELETE cp FROM catalog_category_product cp
  JOIN catalog_category_entity_varchar cv ON cv.entity_id = cp.category_id AND cv.store_id = 0
   AND cv.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name')
 WHERE cp.product_id = @e AND cv.value = 'Prompt Engineering' AND @e IS NOT NULL;

DELETE ci FROM catalog_category_product_index ci
  JOIN catalog_category_entity_varchar cv ON cv.entity_id = ci.category_id AND cv.store_id = 0
   AND cv.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name')
 WHERE ci.product_id = @e AND cv.value = 'Prompt Engineering' AND @e IS NOT NULL;

-- Add: the sibling home of every multi-agent WSQ course. Append at MAX(position)+1
-- so the category-ordering sweep can renumber later.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT cv.entity_id, @e,
       COALESCE((SELECT MAX(x.position) FROM catalog_category_product x WHERE x.category_id = cv.entity_id), 0) + 1
  FROM catalog_category_entity_varchar cv
 WHERE cv.store_id = 0
   AND cv.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name')
   AND cv.value IN ('Multi AI Agents Series', 'AI Agents Series')
   AND @e IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
    (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, s.store_id, 4
  FROM catalog_category_product cp
  JOIN catalog_category_entity_varchar cv ON cv.entity_id = cp.category_id AND cv.store_id = 0
   AND cv.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name')
  JOIN core_store s ON s.store_id > 0
 WHERE cp.product_id = @e
   AND cv.value IN ('Multi AI Agents Series', 'AI Agents Series')
   AND @e IS NOT NULL;
