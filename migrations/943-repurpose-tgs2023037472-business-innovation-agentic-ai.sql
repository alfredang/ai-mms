-- 943: Repurpose TGS-2023037472
--   "WSQ - Digital Transformation and Business Innovation with Generative AI (GenAI)"
--     -> "WSQ - Business Innovation with Agentic AI and AI Agents"
-- SKU unchanged (SkillsFuture / SFEC / SFC / PSEA deep links are keyed on it).
-- Content + title supplied by admin, 2026-08-13.
--
-- SIBLING WARNING -- TGS-2020503395 is live as "WSQ - Business Innovation with
-- AI Agents" at slug wsq-business-innovation-with-ai-agents (repurposed by
-- migration 931). Its title/slug differ from this course's by one word, so
-- EVERY sweep below is anchored on this course's FULL old filename, never on a
-- shared stem like 'business-innovation'. Do not relax those predicates.
--
-- Surfaces touched (sweep of both EAV value tables ran before authoring):
--   1 name              2 meta_title (also fixes pre-existing WSQ+brand doubling)
--   3 meta_description  4 url_key + url_path delete + 301
--   5 image/small/thumbnail_label (alt text)
--   6 trainerprofile    -- para 2 of each of 5 bios only
--   7 learning_outcomes cms_block
--   8 description (Topics + LSN_DATA)
--   9 short_description (About This Course)
-- Verified-clean, deliberately NOT touched: whoshouldattend (roles are
-- framework-neutral), prerequisite (no old-tool link; holds the funding
-- apparatus), image/small_image/thumbnail (filesystem paths, not display text),
-- brochure/certification/skills_framework/funding_and_grant blocks, categories.
-- catalogsearch_query: the only row (56239, 'TGS-2023037472') has redirect NULL
-- -- nothing to retarget; bare course code follows the course anyway.
--
-- The outgoing rows carry latin1 \x96 bytes; all replacement text below is
-- clean ASCII/UTF-8 so apply.php (charset=utf8) cannot choke (see 2026-06-05).
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => no-op.
-- Idempotent: every UPDATE is a full-value set or a targeted REPLACE().

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023037472' LIMIT 1);

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_ukey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_upath   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_trainer := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- ------------------------------------------------------------ 1. name
-- Keep the 'WSQ - ' prefix; the storefront H1 wants it.
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Business Innovation with Agentic AI and AI Agents'
 WHERE entity_id = @e AND attribute_id = @a_name;

-- ------------------------------------------------------------ 2. meta_title
-- Plain title only: MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs and
-- appends the brand postfix at render time (Block/Html/Head.php::_fundingPrefix).
-- The outgoing value baked in BOTH, rendering "WSQ funded WSQ ... | Tertiary
-- Courses Singapore" -- fix it here rather than copying the broken shape.
UPDATE catalog_product_entity_varchar
   SET value = 'Business Innovation with Agentic AI and AI Agents'
 WHERE entity_id = @e AND attribute_id = @a_mtitle;

-- ------------------------------------------------------- 3. meta_description
UPDATE catalog_product_entity_varchar
   SET value = 'Learn to drive business innovation with agentic AI and AI agents. Identify opportunities, design digital architectures and multi-agent workflows, and govern adoption. Enjoy up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc;

-- ------------------------------------------------ 4. url_key / url_path / 301
-- New slug carries the distinguishing 'agentic-ai-and-' segment so it can never
-- be confused with the sibling's wsq-business-innovation-with-ai-agents.
SET @old_slug := 'wsq-digital-transformation-and-business-innovation-with-generative-ai-genai';
SET @new_slug := 'wsq-business-innovation-with-agentic-ai-and-ai-agents';

UPDATE catalog_product_entity_varchar
   SET value = @new_slug
 WHERE entity_id = @e AND attribute_id = @a_ukey;

-- Drop url_path at EVERY scope so the URL Rewrites indexer regenerates it.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_upath;

-- Clear any is_system = 0 squatter on the old bare path first: INSERT IGNORE
-- silently no-ops against a stale row (see migration 647).
DELETE FROM core_url_rewrite
 WHERE request_path = CONCAT(@old_slug, '.html')
   AND is_system = 0
   AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug. The indexer auto-301s the ~20 category
-- paths; this covers the flat product URL.
INSERT IGNORE INTO core_url_rewrite
       (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1,
       CONCAT('product/', @e, '/rename943'),
       CONCAT(@old_slug, '.html'),
       CONCAT(@new_slug, '.html'),
       0, 'RP', 'TGS-2023037472 repurpose 943'
  FROM DUAL
 WHERE @e IS NOT NULL;

-- ------------------------------------------------------------ 5. alt text
-- Plain title, no 'WSQ - ' prefix: the cover renderer strips it
-- (CourseImage/Model/Cover.php::cleanTitle). The cover PNG still bakes the old
-- title -- regenerate it from the admin after deploy.
UPDATE catalog_product_entity_varchar
   SET value = 'Business Innovation with Agentic AI and AI Agents'
 WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

-- ------------------------------------------------------- 6. trainerprofile
-- Retarget ONLY paragraph 2 of each bio (the course-teaching claim). Paragraph 1
-- is career-history CREDENTIALS -- rewriting it would falsify a real person's
-- bio. Targeted REPLACE() per bio keeps the &ldquo;/&rsquo; entities and the
-- data-start/data-end attributes byte-identical.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Digital Transformation and Business Innovation with Generative AI (GenAI),&rdquo; Allen helps learners explore the intersection of creativity, technology, and business innovation. His sessions focus on using AI tools to streamline design workflows, automate content creation, and enhance customer experience. By blending artistic vision with technological insight, he equips participants to reimagine digital transformation strategies that harness the full potential of Generative AI.',
       'In &ldquo;Business Innovation with Agentic AI and AI Agents,&rdquo; Allen helps learners explore the intersection of creativity, technology, and business innovation. His sessions focus on using AI agents to streamline design workflows, automate multi-step content tasks, and enhance customer experience. By blending artistic vision with technological insight, he equips participants to reimagine business innovation strategies that harness the full potential of agentic AI.')
 WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Digital Transformation and Business Innovation with Generative AI (GenAI),&rdquo; James focuses on enabling professionals to integrate Generative AI tools into business innovation workflows. His lessons explore prompt engineering, automation strategies, and AI-assisted creative processes. By combining digital media expertise with applied AI concepts, he helps learners transform traditional business operations into agile, innovation-driven ecosystems.',
       'In &ldquo;Business Innovation with Agentic AI and AI Agents,&rdquo; James focuses on enabling professionals to integrate AI agents into business innovation workflows. His lessons explore agent roles, automation strategies, and human-agent collaboration. By combining digital media expertise with applied AI concepts, he helps learners transform traditional business operations into agile, innovation-driven ecosystems.')
 WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Digital Transformation and Business Innovation with Generative AI (GenAI),&rdquo; Woei Ming guides learners in understanding how AI models and Generative AI technologies can reshape business operations. His sessions focus on automation design, data-driven strategy, and innovation frameworks that leverage AI for enterprise transformation. Through real-world case studies, he equips professionals with the technical understanding and strategic mindset needed to drive digital innovation.',
       'In &ldquo;Business Innovation with Agentic AI and AI Agents,&rdquo; Woei Ming guides learners in understanding how AI agents and multi-agent workflows can reshape business operations. His sessions focus on automation design, data-driven strategy, and innovation frameworks that leverage agentic AI for enterprise transformation. Through real-world case studies, he equips professionals with the technical understanding and strategic mindset needed to drive business innovation.')
 WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Digital Transformation and Business Innovation with Generative AI (GenAI),&rdquo; Hwee Theng helps professionals bridge data science, business analytics, and Generative AI. Her sessions emphasize applied AI innovation, prompt engineering, and enterprise integration strategies that enhance decision-making and efficiency. Through hands-on exploration, she enables learners to harness AI&rsquo;s transformative potential to innovate sustainably and strategically within their organizations.',
       'In &ldquo;Business Innovation with Agentic AI and AI Agents,&rdquo; Hwee Theng helps professionals bridge data science, business analytics, and agentic AI. Her sessions emphasize applied AI innovation, agent orchestration, and enterprise integration strategies that enhance decision-making and efficiency. Through hands-on exploration, she enables learners to harness AI&rsquo;s transformative potential to innovate sustainably and strategically within their organizations.')
 WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Digital Transformation and Business Innovation with Generative AI (GenAI),&rdquo; Siew Yee focuses on helping organizations align AI capabilities with business strategy. His sessions cover AI governance, change management, and the use of Generative AI for process innovation. With a focus on practical implementation, he equips participants to identify opportunities for digital reinvention and lead data-driven innovation initiatives within their organizations.',
       'In &ldquo;Business Innovation with Agentic AI and AI Agents,&rdquo; Siew Yee focuses on helping organizations align AI capabilities with business strategy. His sessions cover AI governance, change management, and the use of AI agents for process innovation. With a focus on practical implementation, he equips participants to identify opportunities for business reinvention and lead data-driven innovation initiatives within their organizations.')
 WHERE entity_id = @e AND attribute_id = @a_trainer;

-- ------------------------------------------------ 7. Learning Outcomes block
UPDATE cms_block SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Evaluate and investigate agentic AI and AI agents business strategies to identify viable opportunities compatible with organizational objectives.</li>
<li>LO2: Develop action plans to implement business innovation with agentic AI and design digital architectures to apply technologies across the business.</li>
<li>LO3: Manage business innovation and facilitate information flow among stakeholders to review success and develop innovative ideas.</li>
</ul>'
 WHERE identifier = 'course_TGS-2023037472_learning_outcomes' AND @e IS NOT NULL;

-- ------------------------------------- 8. Topics Covered (description + JSON)
-- LSN_DATA JSON kept in sync with the visible markup. Empty subsecs: the admin
-- supplied topic headings only (same shape as sibling TGS-2020503395).
UPDATE catalog_product_entity_text SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Identifying Business Innovation Opportunities with Agentic AI and AI Agents","subsecs":[]},{"title":"Topic 2: Designing Digital Architectures and AI Agent Implementation Plans","subsecs":[]},{"title":"Topic 3: Managing AI-Driven Innovation, Governance and Stakeholder Collaboration","subsecs":[]}] -->
<p><strong>Topic 1: Identifying Business Innovation Opportunities with Agentic AI and AI Agents</strong></p>
<p><strong>Topic 2: Designing Digital Architectures and AI Agent Implementation Plans</strong></p>
<p><strong>Topic 3: Managing AI-Driven Innovation, Governance and Stakeholder Collaboration</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;

-- ------------------------------------------- 9. About This Course (sdesc)
-- Post-885 block model: this course's short_description is prose only (no
-- <h2>Course Brochure</h2> tail, no SKU deep links) => full replace is correct.
-- Verified by dump before authoring; a LOCATE-guarded splice would no-op here.
UPDATE catalog_product_entity_text SET value = '<p>This course equips professionals with the knowledge and practical skills to drive business innovation using agentic AI and AI agents. Participants will explore how autonomous and collaborative agents can analyse information, use digital tools, coordinate multi-step tasks, and support employees in developing new products, services, processes, and customer experiences.</p>
<p>Learners will examine current and emerging AI agent technologies and evaluate their strengths, limitations, risks, and suitability for different organisational needs. Through case studies and real-world business scenarios, they will identify innovation opportunities, analyse customer and operational challenges, and conceptualise viable AI-enabled business solutions aligned with strategic objectives.</p>
<p>The course covers the design of digital architectures and multi-agent workflows that integrate AI agents with existing data sources, applications, and business processes. Participants will learn to assign specialised roles to agents, coordinate human-agent collaboration, and develop implementation plans covering resources, responsibilities, timelines, performance indicators, and expected business outcomes.</p>
<p>Learners will also evaluate the commercial, operational, legal, ethical, privacy, and security implications of adopting AI agents. Emphasis is placed on human oversight, governance, stakeholder engagement, change management, and the responsible scaling of successful initiatives.</p>
<p>By the end of the course, participants will be able to develop and present an actionable business innovation plan using agentic AI and AI agents to improve productivity, create new value, strengthen competitiveness, and support sustainable organisational growth.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0;
