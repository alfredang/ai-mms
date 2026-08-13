-- 960: Repurpose TGS-2024049182
--   OLD: "WSQ - Driving Digital Transformation with Microsoft 365 Copilot for Organizations"
--   NEW: "WSQ - Business Transformation with Agentic AI and AI Agents"
-- SKU unchanged (SkillsFuture / SFEC / SFC / PSEA deep links are keyed on it).
-- Content supplied by admin, 2026-08-13.
--
-- Surfaces touched (from a mechanical sweep of BOTH EAV value tables for
-- 'Copilot' / 'Microsoft 365', per feedback_tgs_course_rename_checklist):
--   1  name                 -> keeps the "WSQ - " prefix
--   2  meta_title           -> plain title (MMD_Seotitle adds "WSQ funded" +
--                              brand postfix at render time; the OLD value
--                              wrongly baked in BOTH)
--   3  url_key + url_path   -> new slug, url_path deleted at every scope so the
--                              URL-rewrite indexer regenerates; explicit 301 for
--                              the old bare slug
--   4  description          -> 3 flat topics (LSN_DATA JSON kept in sync)
--   5  short_description    -> intro prose replaced, Skills Framework tail kept
--   6  meta_description     -> varchar attr; feeds meta/og/twitter/JSON-LD
--   7  meta_keyword         -> retargeted to agentic-AI terms
--   8  *_label (3)          -> alt text, plain title (no "WSQ - " prefix)
--   9  trainerprofile       -> para 2 ONLY of each of the 5 bios (the
--                              course-teaching claim). Para 1 is career
--                              CREDENTIALS (real Microsoft certs) = facts, kept.
--  10  prerequisite         -> the ONE software <li> only. This attribute also
--                              holds the whole funding apparatus (PWM, funding
--                              table, MSF/NTUC/MOM deep links) -- never rewrite
--                              wholesale. Baseline to survive: 4 msf / 2 ntuc /
--                              1 mom / 44 <li>.
--
-- Verified-clean, deliberately NOT touched:
--   - learning_outcomes cms_block: admin reaffirmed the supplied LO wording
--     verbatim (2026-08-13). It is byte-identical to the live block => no-op.
--   - whoshouldattend: all 20 job roles are framework-neutral (no tool names).
--   - image / small_image / thumbnail: filesystem PATHS, not display text --
--     renaming them 404s the JPG. The storefront renders the R2 cover.
--   - certification / skills_framework / funding_and_grant / brochure blocks,
--     categories, tags (WSQ/SFC/PSEA/UTAP/SFEC/MCES/Absentee Payroll).
--   - catalogsearch_query: no row targets this course's slug or code (checked).
--
-- Cover PNG still bakes the old title -> re-render from the admin after deploy.
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => no-op.
-- All replacement text is clean ASCII/UTF-8 (apply.php connects charset=utf8).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024049182' LIMIT 1);

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpth := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_trainer := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ---------------------------------------------------------------- 1. name
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Business Transformation with Agentic AI and AI Agents'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------------ 2. meta_title
-- Plain title only: MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs and
-- appends the brand postfix at render time (Block/Html/Head.php::_fundingPrefix).
UPDATE catalog_product_entity_varchar
   SET value = 'Business Transformation with Agentic AI and AI Agents'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

-- -------------------------------------------------------- 6. meta_description
UPDATE catalog_product_entity_varchar
   SET value = 'Learn to drive business transformation with agentic AI and AI agents. Redesign workflows, automate multi-step tasks and build an adoption roadmap with human oversight. Enjoy up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

-- ----------------------------------------------------------- 7. meta_keyword
UPDATE catalog_product_entity_text
   SET value = 'agentic AI, AI agents, business transformation, AI workflow automation, enterprise AI adoption, multi-step task automation, AI governance, human oversight, AI agent use cases, business process transformation, workforce enablement, AI adoption roadmap, responsible AI'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------------- 8. alt labels
-- Alt text on the cover; the cover itself strips the segment prefix
-- (CourseImage/Model/Cover.php::cleanTitle) so these carry no "WSQ - ".
UPDATE catalog_product_entity_varchar
   SET value = 'Business Transformation with Agentic AI and AI Agents'
 WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel) AND @e IS NOT NULL;

-- ------------------------------------------------- 3. url_key / url_path / 301
-- Clear any is_system = 0 squatter on the NEW path first: INSERT IGNORE would
-- silently no-op against a stale row (see 647).
DELETE FROM core_url_rewrite
 WHERE request_path = 'business-transformation-with-agentic-ai-and-ai-agents.html'
   AND is_system = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'business-transformation-with-agentic-ai-and-ai-agents'
 WHERE entity_id = @e AND attribute_id = @a_urlkey AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL-rewrite indexer regenerates it.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlpth AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug. The indexer auto-301s the ~20 category
-- paths; this row covers the canonical flat URL.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id, NULL, @e,
       CONCAT('product/', @e),
       'wsq-driving-digital-transformation-with-microsoft-365-copilot-for-organizations.html',
       'business-transformation-with-agentic-ai-and-ai-agents.html',
       0, 'RP', '960 repurpose 301'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- --------------------------------------- 4. Topics Covered (description + JSON)
-- Old shape was nested LU/subsecs (20 topics); new content is 3 flat topics.
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Business Process Transformation and Cross-Functional AI Agent Use Cases","subsecs":[]},{"title":"Topic 2: Transition Planning, Workflow Integration and AI Agent Implementation","subsecs":[]},{"title":"Topic 3: Workforce Enablement, AI Governance and Business Value Optimisation","subsecs":[]}] -->
<p><strong>Topic 1: Business Process Transformation and Cross-Functional AI Agent Use Cases</strong></p>
<p><strong>Topic 2: Transition Planning, Workflow Integration and AI Agent Implementation</strong></p>
<p><strong>Topic 3: Workforce Enablement, AI Governance and Business Value Optimisation</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------- 5. About This Course (sdesc splice)
-- This course PRE-dates the 885-891 block extraction: its short_description is
-- intro prose + a trailing "<h2>Skills Framework</h2>" section. A full replace
-- (the 943 shape) would DELETE that section, so splice instead -- new prose +
-- everything from the Skills Framework heading onward, byte-identical.
-- Guarded on the new phrase so a re-run converges.
UPDATE catalog_product_entity_text
   SET value = CONCAT(
       '<p>This course equips organisations with the knowledge and practical skills to drive business transformation using agentic AI and AI agents. Participants will explore how AI agents can perform multi-step tasks, use digital tools, analyse information, coordinate workflows, and collaborate with employees across different business functions.</p>
<p>Learners will identify suitable transformation opportunities by examining existing processes, operational challenges, customer needs, and performance gaps. They will redesign workflows by assigning appropriate responsibilities to employees and AI agents, enabling repetitive activities to be automated while keeping important decisions under human oversight.</p>
<p>The course covers practical applications across executive management, sales, marketing, customer service, finance, human resources, IT, administration, and operations. Participants will develop AI-assisted workflows for research, reporting, document processing, data analysis, customer engagement, task coordination, and decision support.</p>
<p>Learners will also develop a structured adoption plan covering business objectives, process priorities, workforce readiness, roles and responsibilities, system integration, data requirements, implementation timelines, and performance indicators. Emphasis is placed on change management, employee onboarding, security, privacy, governance, accountability, and responsible AI use.</p>
<p>Through hands-on activities and business scenarios, participants will evaluate the benefits, costs, risks, and operational impact of AI agent adoption. By the end of the course, learners will be able to create a practical transformation roadmap that uses agentic AI to improve productivity, service quality, decision-making, scalability, and overall business performance.</p>
',
       SUBSTRING(value, LOCATE('<h2><a href="https://drive.google.com', value))
   )
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0
   AND LOCATE('<h2><a href="https://drive.google.com', value) > 0
   AND LOCATE('drive business transformation using agentic AI', value) = 0
   AND @e IS NOT NULL;

-- ---------------------------------------------------------- 9. trainerprofile
-- Retarget ONLY the course-teaching sentence in para 2 of each bio. Para 1 holds
-- career CREDENTIALS (genuine Microsoft 365 / Azure / MCT expertise) -- those are
-- facts about the trainer, and rewriting them would falsify the bio.
-- Single-line REPLACE()s: the blob is one line, but keep each target string on
-- ONE line regardless (multi-line REPLACE no-ops on CRLF WYSIWYG blobs --
-- see feedback_multiline_replace_fails_on_crlf_blobs).
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'As a corporate trainer and technology evangelist, Sanjiv focuses on equipping professionals with the skills to harness Microsoft 365 Copilot for workplace innovation. His training emphasizes practical, hands-on learning that bridges cloud computing, data analytics, and AI-assisted collaboration. In &ldquo;Empower Your Workforce with Microsoft 365 Copilot,&rdquo; Sanjiv guides participants in leveraging Microsoft&rsquo;s AI capabilities to streamline workflows, enhance communication, and unlock creativity within the modern digital workplace.',
       'As a corporate trainer and technology evangelist, Sanjiv focuses on equipping professionals with the skills to harness agentic AI and AI agents for business innovation. His training emphasizes practical, hands-on learning that bridges business process design, data analytics, and human-agent collaboration. In &ldquo;Business Transformation with Agentic AI and AI Agents,&rdquo; Sanjiv guides participants in redesigning workflows so AI agents automate repetitive multi-step tasks while important decisions stay under human oversight.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'A passionate educator and digital strategist, James integrates AI, design thinking, and automation tools into his training to help professionals adapt to the evolving digital landscape. In &ldquo;Empower Your Workforce with Microsoft 365 Copilot,&rdquo; he focuses on enabling learners to combine creative productivity with AI-driven insights&mdash;helping them craft compelling content, improve communication, and streamline collaborative workflows using Microsoft Copilot and Microsoft 365 applications.',
       'A passionate educator and digital strategist, James integrates AI, design thinking, and automation tools into his training to help professionals adapt to the evolving digital landscape. In &ldquo;Business Transformation with Agentic AI and AI Agents,&rdquo; he focuses on enabling learners to apply AI agents across marketing, customer engagement and content operations&mdash;helping them coordinate research, reporting and document processing through AI-assisted workflows.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'Eugene&rsquo;s training philosophy centers on real-world applicability and hands-on learning. As an ACLP-certified trainer, he delivers engaging sessions that empower learners to harness Microsoft Copilot to automate processes, manage projects, and visualize data. In &ldquo;Empower Your Workforce with Microsoft 365 Copilot,&rdquo; Eugene equips professionals with the ability to integrate AI seamlessly into daily workflows&mdash;enhancing team efficiency and strategic decision-making in an AI-powered workplace.',
       'Eugene&rsquo;s training philosophy centers on real-world applicability and hands-on learning. As an ACLP-certified trainer, he delivers engaging sessions that empower learners to harness AI agents to automate processes, manage projects, and visualize data. In &ldquo;Business Transformation with Agentic AI and AI Agents,&rdquo; Eugene equips professionals with the ability to integrate AI agents into IT, administration and operations workflows&mdash;covering system integration, data requirements and the governance that keeps adoption accountable.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'With his strong foundation in both data and business intelligence, Bernard brings a unique perspective to digital workplace transformation. In &ldquo;Empower Your Workforce with Microsoft 365 Copilot,&rdquo; he focuses on empowering professionals to integrate AI, analytics, and automation into daily business operations. His sessions emphasize practical AI use in Microsoft 365, helping learners unlock productivity, improve decision accuracy, and drive innovation through Copilot&rsquo;s intelligent tools.',
       'With his strong foundation in both data and business intelligence, Bernard brings a unique perspective to business transformation. In &ldquo;Business Transformation with Agentic AI and AI Agents,&rdquo; he focuses on empowering professionals to integrate AI agents, analytics, and automation into daily business operations. His sessions emphasize evaluating the benefits, costs, risks and operational impact of AI agent adoption, helping learners unlock productivity and improve decision accuracy across finance and reporting workflows.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'As a technology trainer, Truman blends technical mastery with a learner-focused approach, emphasizing real-world applications of cloud and AI technologies. In &ldquo;Empower Your Workforce with Microsoft 365 Copilot,&rdquo; he teaches professionals how to integrate Microsoft Copilot into business workflows&mdash;transforming productivity through intelligent automation, collaboration, and data-driven decision-making. His sessions prepare learners to leverage AI confidently within Microsoft 365 for modern, agile, and efficient teamwork.',
       'As a technology trainer, Truman blends technical mastery with a learner-focused approach, emphasizing real-world applications of cloud and AI technologies. In &ldquo;Business Transformation with Agentic AI and AI Agents,&rdquo; he teaches professionals how to integrate AI agents into business workflows&mdash;transforming productivity through intelligent automation, collaboration, and data-driven decision-making. His sessions prepare learners to scale AI agent adoption confidently, with attention to security, privacy and responsible AI use.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------------ 10. prerequisite
-- ONE <li> only (the old tool download link). Everything else in this attribute
-- is the funding apparatus and must survive byte-identical.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li><a href="https://www.microsoft.com/en-us/microsoft-365/microsoft-defender-for-individuals" target="_blank"><span style="text-decoration: underline;">Microsoft 365 Defender</span></a></li>',
       '<li><a href="https://chatgpt.com/" target="_blank"><span style="text-decoration: underline;">ChatGPT</span></a></li>')
 WHERE entity_id = @e AND attribute_id = @a_prereq AND store_id = 0 AND @e IS NOT NULL;
