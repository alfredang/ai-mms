-- 1012: Repurpose TGS-2024045799
--   "WSQ - Build a Generative AI LLM-Powered Chatbot to Enhance Customer Service"
--     ->  "WSQ - Agentic AI for Product Development"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-14. Entity id 1207.
--
-- This is a TOPIC PIVOT (LLM chatbots for customer service -> agentic AI across
-- the product-development lifecycle), not a retitle, so the surfaces that only
-- leak on a pivot are all in scope: whoshouldattend, trainerprofile para 2, the
-- learning-outcomes block, meta_*, and the course outline.
--
-- NO LIVE TWIN. Probed before writing (per
-- [[feedback_repurpose_target_name_may_already_exist_as_live_twin]]):
--   * catalog_product_entity_varchar `name`  LIKE '%Agentic AI for Product%'
--     and '%for Product Development%'  -> 0 rows;
--   * `url_key` LIKE '%agentic-ai-for-product%'                 -> 0 rows;
--   * core_url_rewrite on both 'agentic-ai-for-product-development.html' and
--     'wsq-agentic-ai-for-product-development.html'             -> 0 rows.
-- So the plain 'wsq-'-prefixed slug is free and is used (the prefix is the house
-- convention for a WSQ course, not a collision workaround here).
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope), meta_title
-- (also FIXES a pre-existing double-prefix bug -- see below), meta_description,
-- meta_keyword, short_description, description (3 topics), whoshouldattend,
-- trainerprofile (para 2 of each of the 5 bios), image/small_image/thumbnail
-- labels, media-gallery label, the learning_outcomes cms_block, and a 301 for
-- the old bare slug.
--
-- Deliberately UNCHANGED (each verified against live data BEFORE writing, per
-- the checklist's "scan, don't enumerate" rule -- both EAV value tables were
-- swept for 'chatbot' / 'LLM' / 'customer' / 'Javascript'):
--   * course_TGS-2024045799_skills_framework -- ALREADY reads "Automation
--     Management in Product Development ICT-TEM-4035-1.1 TSC". The accredited
--     standard registered against this unchanged SKU is a PRODUCT-DEVELOPMENT
--     one, so the new title fits it better than the old one did. Never rewrite
--     an accredited TSC to match a rename.
--   * course_TGS-2024045799_certification / _funding_and_grant / _brochure --
--     keyed on the unchanged SKU; generic WSQ copy, no course-specific text.
--   * prerequisite -- probed: LOCATE() = 0 for 'chatbot', 'LLM', 'customer' AND
--     'Javascript'. No old-tool link to retarget. (It also carries the entire
--     funding apparatus -- PWM, eligibility table, SkillsFuture/PSEA/SFEC/UTAP
--     deep links -- so it must never be rewritten wholesale.)
--   * courses_trainers.description -- the CENTRAL trainer profiles (Tan Woei
--     Ming id 236, Teh Siew Yee id 239, Yeo Hwee Theng id 251, all status = 1)
--     are what actually RENDER for those three trainers, and all three are
--     already course-agnostic (LOCATE('chatbot') = 0). They are shared across
--     dozens of courses and must NOT be rewritten for one repurpose --
--     [[feedback_trainer_bio_renders_from_courses_trainers_not_trainerprofile]].
--     Truman Ng and James Lee Kin Nam have NO central row, so for them the blob
--     edit below is the live rendered bio.
--   * image / small_image / thumbnail PATHS -- filesystem paths, not display
--     text; renaming them 404s the file. The storefront renders course_image_url.
--   * cover PNG (course_image_url) -- re-rendered out of band from the admin.
--   * catalogsearch_query -- probed: ZERO rows redirect at the old slug. The one
--     row matching the bare course code (query_id 56297, 'TGS-2024045799') has
--     redirect IS NULL and is left NULL -- an empty redirect is not a TODO.
--
-- CATEGORIES: 12 memberships, all still correct after the pivot and therefore
-- untouched. No certification brand is dropped (there was none), so there is no
-- exam-prep listing to shed. 187 "Multi AI Agents Series" and 139 "AI
-- Applications Series" now describe the course BETTER than before; 379/433/252/3
-- and the WSQ funding listings (15/292/293/301/72/55) are all subject-neutral or
-- still accurate. No catalog_category_product / _index churn on this repurpose.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024045799' LIMIT 1);

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_tprof  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_ilab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------- 1. Title
-- 'WSQ - ' prefix retained: the SKU is unchanged, so the segment is unchanged.
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Agentic AI for Product Development'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. SEO meta
-- meta_title: plain title. MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs
-- and appends the brand postfix at render time -- baking either in duplicates it.
-- The live value did BOTH ("WSQ Build a Generative AI LLM-Powered Chatbot to
-- Enhance Customer Service | Tertiary Courses Singapore"), at store 0 AND store 1,
-- so this repurpose is also the fix for that pre-existing bug (surface 2 / 853).
UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI for Product Development'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

-- NOTE: catalog_product_entity_varchar.value is varchar(255) -- keep this under
-- that cap (the first draft was 260 chars and apply.php aborted with error 1406).
UPDATE catalog_product_entity_varchar
   SET value = 'Learn to apply agentic AI across the product development lifecycle. Evaluate agentic AI builders, design multi-agent workflows for research, prototyping and QA, and deploy AI-powered product solutions. Enjoy up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'agentic AI for product development, AI product management course, multi-agent workflows, autonomous AI agents, AI product research, AI prototyping, agentic AI builders, AI product roadmap, AI user personas, WSQ agentic AI course Singapore'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. URL key
-- Delete url_path at EVERY scope so the Catalog URL Rewrites indexer regenerates
-- it; a surviving store-scoped row shadows the new URL. (Live rows exist at
-- store 0 AND store 1 here.)
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-agentic-ai-for-product-development'
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Remove any non-system squatter on the NEW path before inserting the 301,
-- so the INSERT IGNORE below cannot silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-agentic-ai-for-product-development.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the category paths).
-- NOTE: the old bare slug is held by this product's SYSTEM rewrite
-- (id_path 'product/1207', is_system = 1 -- confirmed row 6106473 at store 1), so
-- a plain INSERT IGNORE silently no-ops against the unique key on
-- (request_path, store_id). Convert that row in place into a permanent redirect;
-- the indexer then mints a fresh system row for the NEW slug.
-- See [[feedback_rename_301_vs_system_rewrite_suffix_trap]] for the live-reindex
-- ordering this implies (drop the 301 -> refreshProductRewrite -> re-add the 301),
-- without which refreshProductRewrite mints a '-1207'-suffixed slug.
UPDATE core_url_rewrite
   SET target_path = 'wsq-agentic-ai-for-product-development.html',
       is_system   = 0,
       options     = 'RP'
 WHERE request_path = 'wsq-build-a-generative-ai-llm-powered-chatbot-to-enhance-customer-service.html'
   AND id_path = CONCAT('product/', @e)
   AND @e IS NOT NULL;

-- Belt-and-braces for any store that had no system row on the old slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('TGS-2024045799-rp-1012-', s.store_id),
       'wsq-build-a-generative-ai-llm-powered-chatbot-to-enhance-customer-service.html',
       'wsq-agentic-ai-for-product-development.html',
       0, 'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- Re-point the 16 existing category-path alias rows (all of them this product's
-- own, verified: every match carries the FULL old filename, and no sibling course
-- shares that stem) so those URLs resolve in ONE hop instead of 301-chaining
-- through a now-redirecting path. Anchored on the FULL old filename per
-- [[feedback_rename_sibling_family_courses_anchor_matches]].
UPDATE core_url_rewrite
   SET target_path = 'wsq-agentic-ai-for-product-development.html'
 WHERE is_system = 0
   AND target_path = 'wsq-build-a-generative-ai-llm-powered-chatbot-to-enhance-customer-service.html'
   AND request_path <> 'wsq-agentic-ai-for-product-development.html'
   AND @e IS NOT NULL;

UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path,
                             '/wsq-build-a-generative-ai-llm-powered-chatbot-to-enhance-customer-service.html',
                             '/wsq-agentic-ai-for-product-development.html')
 WHERE is_system = 0
   AND target_path LIKE '%/wsq-build-a-generative-ai-llm-powered-chatbot-to-enhance-customer-service.html'
   AND @e IS NOT NULL;

-- ------------------------------------------------- 4. Image alt text
-- Plain title (no 'WSQ - ' prefix): the cover itself strips the prefix
-- (CourseImage/Model/Cover.php::cleanTitle). The media-gallery row's own `label`
-- column is what the product page actually renders as alt= -- the three *_label
-- attrs alone are NOT enough, see
-- [[feedback_media_gallery_label_is_the_real_alt_text]].
UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI for Product Development'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Agentic AI for Product Development'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------------ 5. Course Outline (description)
-- This course predates the LSN_DATA JSON shape -- its live markup is the older
-- '<h3 class="course-topic-h3">' + '<ul>' bullet form, which is preserved here.
-- The three supplied topic titles replace the old ones; the sub-bullets deliver
-- them against the unchanged accredited outcomes LO1-LO3.
UPDATE catalog_product_entity_text
   SET value = '<h3 class="course-topic-h3">Topic 1: Evaluating Agentic AI Tools for Product Research and Development</h3>
<ul>
<li>What are AI agents and agentic AI, and how they differ from single-turn generative AI</li>
<li>Use cases of agentic AI across the product development lifecycle</li>
<li>Evaluate various agentic AI builders to compare their strengths and limitations</li>
<li>Apply agentic AI to market and competitor research, customer needs discovery and user personas</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Building and Optimising Agentic AI Product Development Workflows</h3>
<ul>
<li>Fundamentals of building an agentic AI workflow with a visual agent builder</li>
<li>Design multi-agent workflows that coordinate research, design, development, documentation and quality assurance</li>
<li>Translate product ideas into requirements, user stories, journey maps, specifications and prototypes</li>
<li>Testing the performance of an agentic AI workflow</li>
<li>Apply optimisation techniques to enhance the performance of agentic AI</li>
</ul>
<h3 class="course-topic-h3">Topic 3: Deploying and Evaluating Agentic AI-Powered Product Solutions</h3>
<ul>
<li>Deploy agentic AI solutions into product team workflows and stakeholder feedback loops</li>
<li>Use agentic AI to evaluate prototypes, analyse user feedback, detect product gaps and monitor KPIs</li>
<li>Evaluate the benefits and trade-offs of deploying agentic AI</li>
<li>Human oversight, data quality, responsible AI practices, security, governance and validation of AI-generated outputs</li>
</ul>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 6. About This Course (sdesc)
-- Full replace. Verified first (checklist surface 12): the live short_description
-- is prose ONLY (1094 chars, two <p> paragraphs) -- no <h2>Course Brochure</h2>
-- tail and no ad-hoc inline certification-vendor sections -- so nothing is
-- silently destroyed. All five standard sections live in the
-- course_TGS-2024045799_* cms blocks.
UPDATE catalog_product_entity_text
   SET value = '<p>This course equips participants with practical skills to apply agentic AI across the product development lifecycle, from opportunity discovery and concept creation to prototyping, testing, launch, and continuous improvement. Learners will explore how autonomous AI agents can perform multi-step tasks, coordinate workflows, analyse information, and support product teams in making faster, evidence-based decisions.</p>
<p>Participants will use agentic AI to conduct market and competitor research, identify customer needs, develop user personas, generate product concepts, and prioritise features. They will learn to translate product ideas into requirements, user stories, journey maps, specifications, development plans, and prototypes that align with business objectives and user expectations.</p>
<p>The course also covers designing multi-agent workflows for coordinating research, design, development, documentation, quality assurance, and stakeholder feedback. Learners will apply agentic AI to evaluate prototypes, analyse user feedback, detect product gaps, monitor key performance indicators, and recommend improvements throughout iterative development cycles.</p>
<p>Emphasis is placed on human oversight, data quality, responsible AI practices, security, governance, and the validation of AI-generated outputs. Through hands-on projects, participants will develop an AI-assisted product concept and supporting development workflow. By the end of the course, learners will be able to use agentic AI to improve collaboration, reduce repetitive work, shorten development cycles, and create products that better address customer and market needs.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------- 7. Learning Outcomes cms_block
-- The block EXISTS (block_id 1857, is_active = 1) and wins over view.phtml's
-- regex fallback, so a plain UPDATE is correct here (no guarded-INSERT needed --
-- surface 6b does not apply). The supplied LO1-LO3 are the same three accredited
-- outcomes re-pointed from "LLM-powered chatbot" to "Agentic AI"; the &nbsp;
-- entities after the LO labels are preserved so the card renders unchanged.
UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Evaluate various Agentic AI builders to compare their strengths and limitations.</li>
<li>LO2:&nbsp;Apply optimization techniques to enhance the performance of Agentic AI.</li>
<li>LO3:&nbsp;Evaluate the benefits and trade-offs of deploying Agentic AI.</li>
</ul>'
 WHERE identifier = 'course_TGS-2024045799_learning_outcomes';

-- ------------------------------------------------------ 8. Who Should Attend
-- Surface 10: on a TOPIC PIVOT the job-role list names the OLD technology. Nine
-- of the 20 roles were chatbot/customer-service specific ("Chatbot Developer",
-- "UX/UI Designer for Chatbots", "Customer Experience Strategist", ...). Each is
-- re-pointed at its product-development equivalent; the 11 technology-neutral
-- roles (AI Product Manager, Data Analyst, Software Engineer, Business Analyst,
-- Innovation Manager, Project Manager, AI Researcher, Web Developer, IT Support
-- Specialist, Quality Assurance Engineer, E-commerce Manager) are kept, with the
-- three that read as support-desk roles retargeted to product-team equivalents.
UPDATE catalog_product_entity_text
   SET value = '<ul>
<li>Product Manager</li>
<li>Product Owner</li>
<li>AI Product Manager</li>
<li>Product Development Engineer</li>
<li>Digital Product Manager</li>
<li>UX/UI Designer</li>
<li>User Researcher</li>
<li>AI Implementation Consultant</li>
<li>Product Marketing Manager</li>
<li>Solution Architect</li>
<li>Web Developer</li>
<li>Data Analyst</li>
<li>Software Engineer</li>
<li>Business Analyst</li>
<li>Innovation Manager</li>
<li>Project Manager</li>
<li>AI Researcher</li>
<li>Customer Insights Analyst</li>
<li>Quality Assurance Engineer</li>
<li>R&amp;D Manager</li>
</ul>'
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------------- 9. Trainer profiles
-- Surface 6, applied per the para-1/para-2 split: paragraph 1 of each bio is
-- career-history CREDENTIALS (real NUS degrees, LangChain/PyTorch expertise,
-- Amplify Health / Standard Chartered / TikTok history, PMP/HCIE/ACLP certs) and
-- is left byte-identical -- rewriting it would falsify a bio. Only paragraph 2,
-- the course-teaching claim scoped to the old chatbot delivery, is retargeted.
-- One REPLACE() per bio on the FULL paragraph string, so the &ldquo;/&rsquo;
-- entities elsewhere in the blob survive. Guarded by the match itself (a re-run
-- finds no old text and no-ops).
-- Truman Ng and James Lee Kin Nam have no courses_trainers row, so their edits
-- are the LIVE rendered bio; the other three are the dormant fallback copy.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
'<p>In &ldquo;Build a Generative AI LLM-Powered Chatbot to Enhance Customer Service,&rdquo; Woei Ming teaches participants how to design and deploy conversational AI systems powered by large language models (LLMs). His sessions focus on fine-tuning pre-trained models, integrating APIs, and optimizing chatbots for contextual understanding and responsiveness. Through hands-on exercises, he empowers learners to develop scalable AI chatbots that enhance customer engagement and streamline support processes.</p>',
'<p>In &ldquo;Agentic AI for Product Development,&rdquo; Woei Ming teaches participants how to design and deploy autonomous AI agents that carry out multi-step product development tasks. His sessions focus on evaluating agentic AI builders, orchestrating multi-agent workflows, and optimizing agent performance for reliability and contextual accuracy. Through hands-on exercises, he empowers learners to build agentic systems that accelerate research, prototyping, and iteration.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
'<p>In &ldquo;Build a Generative AI LLM-Powered Chatbot to Enhance Customer Service,&rdquo; Hwee Theng focuses on bridging AI design with real-world application in enterprise contexts. Her sessions explore chatbot architecture, NLP-driven intent recognition, and the integration of LLMs with business workflows. With her strategic and technical insights, she guides learners to build intelligent, human-like customer service chatbots that deliver efficiency and personalization at scale.</p>',
'<p>In &ldquo;Agentic AI for Product Development,&rdquo; Hwee Theng focuses on bridging AI design with real-world application in enterprise product teams. Her sessions explore agent architecture, opportunity discovery and requirements generation, and the integration of agentic AI with product and business workflows. With her strategic and technical insights, she guides learners to build agentic solutions that shorten development cycles and support evidence-based product decisions.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
'<p>In &ldquo;Build a Generative AI LLM-Powered Chatbot to Enhance Customer Service,&rdquo; Siew Yee guides learners in understanding the practical implementation of AI chatbots to automate communication workflows. His sessions cover prompt engineering, intent classification, and API integration to create dynamic, customer-focused conversational systems. By combining business strategy with AI technology, he equips professionals with the skills to design impactful chatbots that elevate customer experiences.</p>',
'<p>In &ldquo;Agentic AI for Product Development,&rdquo; Siew Yee guides learners in understanding the practical implementation of AI agents to automate product development workflows. His sessions cover prompt engineering, task decomposition, and tool integration to create dynamic, goal-directed agentic systems. By combining business strategy with AI technology, he equips professionals with the skills to design agentic workflows that elevate product quality and speed to market.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Truman Ng: paragraph 1 also carries a course-scoped claim ("integrating
-- LLM-based chatbots with secure, scalable backend systems") -- that is a
-- capability statement about the OLD delivery, not a credential, so its final
-- sentence is retargeted while the PMP/ACTA/HCIE credentials before it stand.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
'Truman&rsquo;s expertise lies in integrating LLM-based chatbots with secure, scalable backend systems for enterprise applications.',
'Truman&rsquo;s expertise lies in integrating AI agents with secure, scalable backend systems for enterprise applications.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
'<p>In &ldquo;Build a Generative AI LLM-Powered Chatbot to Enhance Customer Service,&rdquo; Truman focuses on the technical implementation of AI chatbots within enterprise environments. His sessions highlight backend integration, deployment security, and performance optimization for AI conversational systems. Through real-world examples and demonstrations, he enables learners to build robust, cloud-ready chatbot solutions that deliver seamless and intelligent customer support.</p>',
'<p>In &ldquo;Agentic AI for Product Development,&rdquo; Truman focuses on the technical implementation of agentic AI within enterprise environments. His sessions highlight tool and API integration, deployment security, governance, and performance optimization for autonomous agent systems. Through real-world examples and demonstrations, he enables learners to build robust, cloud-ready agentic solutions that plug into existing product development pipelines.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
'<p>In &ldquo;Build a Generative AI LLM-Powered Chatbot to Enhance Customer Service,&rdquo; James helps participants understand how to design intuitive chatbot interfaces that improve user experience and engagement. His sessions emphasize prompt design, conversational flow, and integrating generative AI with visual communication. By blending creativity with technical design, he guides learners to create chatbots that communicate naturally, reflect brand personality, and deliver meaningful customer interactions.</p>',
'<p>In &ldquo;Agentic AI for Product Development,&rdquo; James helps participants understand how to use agentic AI to design product experiences that improve usability and engagement. His sessions emphasize prompt design, AI-assisted prototyping, journey mapping, and user-feedback analysis. By blending creativity with technical design, he guides learners to shape products that address real user needs and reflect a coherent brand experience.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;
