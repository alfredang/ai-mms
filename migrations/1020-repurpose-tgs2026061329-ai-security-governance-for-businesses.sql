-- 1020: Repurpose TGS-2026061329
--   "WSQ - Developing Ethical Strategies for Responsible Generative AI"
--     -> "WSQ - AI Security Governance for Businesses"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-14: pivot from societal/ethical AI strategy
-- to a business-focused AI SECURITY GOVERNANCE framework for GenAI + agentic AI
-- (policies, roles, risk classification, lifecycle controls, agentic-AI security
-- controls, risk assessment and implementation roadmap).
--
-- Sibling of 1002 (TGS-2023039177 -> "AI for Cyber Security") and 1005
-- (TGS-2024048311 -> "AI for IT Security") -- same shape.
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope), meta_title,
-- meta_description, meta_keyword, short_description, description (the Course
-- Outline held four BUSINESS-PRESENTATION learning units left over from an
-- earlier repurpose -- wholly unrelated to this course; replaced with the four
-- supplied topics, LSN_DATA JSON kept in sync with the visible markup),
-- trainerprofile (para 2 is a course-teaching claim scoped to the old subject),
-- whoshouldattend (three roles named the retired ethics/CSR framing),
-- image/small_image/thumbnail labels, media-gallery label, a 301 for the old
-- bare slug, and category placement (add 161 "IT Security"; drop 200 "GenAI
-- Content Creation" and 433 "Generative AI Series"), mirrored into
-- catalog_category_product_index.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * course_TGS-2026061329_learning_outcomes -- the supplied LO1-LO4 are
--     BYTE-IDENTICAL to the live block. These are the SSG-accredited outcomes
--     registered against the unchanged SKU; the new topics are delivered
--     against those same outcomes. Do NOT "fix" the surviving generative-AI
--     wording in the What You'll Learn card -- it is the registered standard.
--   * course_TGS-2026061329_skills_framework -- ICT-INT-0055-1.1 "Responsible AI
--     and Generative AI Practices" still describes an AI-governance course.
--   * course_TGS-2026061329_certification / _funding_and_grant / _brochure --
--     keyed on the SKU; the funding apparatus and OpenCerts wording are
--     unaffected by the content pivot. The funding block holds no old title.
--   * prerequisite -- holds the entire funding apparatus (Promotion Code, Minimum
--     Entry Requirement, PWM/Software/Hardware). No old-topic tool link to fix.
--   * additional_note / assessment_methods / duration (16h) / sessions (2).
--   * badge tags (WSQ, SkillsFuture Credit, PSEA, SFEC, MCES, Absentee Payroll) --
--     funding eligibility is unchanged by the content pivot.
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url.
--   * cover PNG (course_image_url) -- re-rendered out of band from the admin.
--   * Categories 3, 15, 55, 214 (AI Security Series -- now MORE apt: it already
--     holds C1440 "AI Security and Governance for AI Agents" and the WSQ AI
--     cyber-security courses), 252 (AI Courses), 284 (WSQ AI Ethics and
--     Governance -- 3 members, still the right listing for a governance course),
--     292, 301 (WSQ IT & Security Courses), 379 (WSQ Generative AI Courses --
--     the course still governs GenAI adoption) -- all describe the NEW content.
--
-- SLUG COLLISION CHECK: the non-WSQ twin C1440 is named "AI Security and
-- Governance for AI Agents" and owns 'ai-security-and-governance-for-ai-agents'.
-- The new 'wsq-ai-security-governance-for-businesses' does not collide, and the
-- 'wsq-' prefix keeps the two pages' rewrites permanently apart.
--
-- PRE-EXISTING URL DAMAGE (SG prod AND the local backup, verified 2026-08-14):
-- this product currently resolves at the SUFFIXED path
-- 'wsq-developing-ethical-strategies-for-responsible-generative-ai-2127.html'
-- while the clean bare slug is held by a SYSTEM rewrite pointing at a DIFFERENT
-- product (id 1867). See [[feedback_flat_url_collision_suffix_explosion]]. So the
-- 301 below is written against the SUFFIXED path (the URL that actually serves
-- this course today) and the bare old slug is left alone -- it belongs to 1867
-- and re-pointing it would hijack that product's page. The rename is the chance
-- to give this course a CLEAN unsuffixed URL again.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026061329' LIMIT 1);

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_tprof  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_who    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_ilab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------- 1. Title
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - AI Security Governance for Businesses'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. SEO meta
-- meta_title: plain title. MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs
-- and appends the brand postfix at render time -- baking either in duplicates it.
-- The live value did exactly that ("WSQ Developing ... | Tertiary Courses
-- Singapore"); this rename is the moment to fix it.
UPDATE catalog_product_entity_varchar
   SET value = 'AI Security Governance for Businesses'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Learn to build an AI security governance framework for Generative AI and agentic AI. Covers AI policies, risk classification, approval workflows, lifecycle controls, least-privilege permissions and human oversight. Enjoy up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'AI security governance, AI governance framework, generative AI risk management, agentic AI security, AI acceptable use policy, AI system inventory, AI risk classification, AI approval workflow, human oversight of AI, least privilege for AI agents, AI incident response, AI vendor assessment, AI compliance Singapore, WSQ AI governance course'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. URL key
-- Delete url_path at EVERY scope so the Catalog URL Rewrites indexer regenerates
-- it; a surviving store-scoped row shadows the new URL. (Store 1 currently holds
-- the damaged '-2127.html' suffixed value -- deleting it is what lets the
-- indexer claim the clean new path.)
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-ai-security-governance-for-businesses'
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Remove any non-system squatter on the NEW path before inserting the 301s, so
-- the indexer can claim it and the INSERT IGNOREs cannot no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-ai-security-governance-for-businesses.html'
   AND @e IS NOT NULL;

-- Clear the pre-existing '-<id>' suffix damage: the system rewrites this product
-- owns on the suffixed paths must go, or the indexer defensively re-mints a
-- suffixed slug instead of claiming the clean one.
DELETE FROM core_url_rewrite
 WHERE is_system = 1
   AND id_path = CONCAT('product/', @e)
   AND request_path LIKE 'wsq-developing-ethical-strategies-for-responsible-generative-ai%'
   AND @e IS NOT NULL;

-- Explicit 301 from the SUFFIXED path this course actually serves at today.
-- NOT the bare slug: that one is a SYSTEM rewrite belonging to product 1867, and
-- re-pointing it would hijack an unrelated live page.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('TGS-2026061329-rp-1020-', s.store_id),
       'wsq-developing-ethical-strategies-for-responsible-generative-ai-2127.html',
       'wsq-ai-security-governance-for-businesses.html',
       0, 'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- The historical '-<n>.html' aliases already 301 to '-2127.html'; retarget them
-- straight at the new slug so they do not become redirect chains.
--
-- ANCHOR ON THIS COURSE'S OWN SLUG STEM. A bare
-- `target_path = '...-2127.html'` predicate looks precise but is NOT: prod and
-- the local backup both carry rows whose REQUEST path belongs to a DIFFERENT
-- course yet whose target was long ago pointed here
-- ('wsq-iso-27001-information-security-management-system.html' and
-- 'wsq-iso-22301-business-continuity-managment-system-1881.html' -- the ISO
-- courses, which really belong to
-- 'wsq-information-security-management-and-compliance-frameworks' /
-- 'wsq-managing-business-disruptions-and-continuity'). Retargeting those would
-- hijack two live unrelated pages. See
-- [[feedback_rename_sibling_family_courses_anchor_matches]].
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-security-governance-for-businesses.html'
 WHERE is_system = 0
   AND options = 'RP'
   AND target_path = 'wsq-developing-ethical-strategies-for-responsible-generative-ai-2127.html'
   AND request_path LIKE 'wsq-%developing-ethical-strategies-for-responsible-generative-ai%'
   AND @e IS NOT NULL;

-- ------------------------------------------------- 4. Image alt text
-- Plain title (no "WSQ - " prefix): the cover itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'AI Security Governance for Businesses'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'AI Security Governance for Businesses'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------ 5. Topics Covered (description + JSON)
-- The visible <p><strong>Topic N</strong></p> markup and the LSN_DATA JSON
-- comment must stay in sync. The live value held four BUSINESS-PRESENTATION
-- learning units ("LU1: Foundations of Business Presentation Delivery in a
-- Generative AI World" ...) -- residue from an earlier repurpose that never
-- matched this course at all. Replaced wholesale by four topics drawn from the
-- supplied About-This-Course copy; topic-level only, so subsecs are empty.
-- Four topics -- matches LO1-LO4.
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: AI Security Governance Foundations and Business Risks","subsecs":[]},{"title":"Topic 2: Building an AI Governance Framework: Policies, Roles and Risk Ownership","subsecs":[]},{"title":"Topic 3: Governance Controls Across the AI Lifecycle","subsecs":[]},{"title":"Topic 4: Security Controls for Agentic AI, Risk Assessment and Implementation Roadmap","subsecs":[]}] -->
<p><strong>Topic 1: AI Security Governance Foundations and Business Risks</strong></p>
<p><strong>Topic 2: Building an AI Governance Framework: Policies, Roles and Risk Ownership</strong></p>
<p><strong>Topic 3: Governance Controls Across the AI Lifecycle</strong></p>
<p><strong>Topic 4: Security Controls for Agentic AI, Risk Assessment and Implementation Roadmap</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 6. About This Course (sdesc)
-- Full replace: the live short_description is intro prose only (the Brochure /
-- Skills Framework / Certification / WSQ Funding sections live in cms/blocks
-- after the 885-891 extraction), and it carries no ad-hoc vendor section, so
-- nothing is lost. Supplied copy, verbatim.
UPDATE catalog_product_entity_text
   SET value = '<p>This course equips business leaders, managers, governance professionals, and technology teams with the practical knowledge to establish an AI security governance framework for the responsible adoption of Generative AI and agentic AI. Participants will examine how these technologies introduce business risks relating to confidential data, inaccurate outputs, malicious instructions, excessive permissions, third-party integrations, automated actions, intellectual property, privacy, and regulatory compliance.</p>
<p>Learners will develop a structured governance framework covering AI policies, roles and responsibilities, risk ownership, acceptable-use requirements, AI system inventories, risk classification, approval processes, and human oversight. The course explains how governance controls can be applied across the AI lifecycle, from evaluating use cases and selecting vendors to deployment, monitoring, incident response, and system retirement.</p>
<p>Participants will also explore security controls for agentic AI, including identity and access management, least-privilege permissions, tool and data access restrictions, action approval, activity logging, output validation, and emergency suspension procedures. They will learn to assess AI solutions according to their business impact, data sensitivity, autonomy, and potential consequences.</p>
<p>Through practical business scenarios, learners will conduct AI risk assessments, define governance controls, develop organisational guidelines, and create an implementation roadmap. Emphasis is placed on aligning AI adoption with business objectives while maintaining accountability, transparency, fairness, security, and compliance.</p>
<p>By the end of the course, participants will be able to design and implement a business-focused AI security governance framework that enables responsible innovation while reducing the risks associated with Generative AI and autonomous AI agents.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- -------------------------------------------------- 7. Learning Outcomes block
-- NOT TOUCHED. The four LOs supplied by the admin are byte-identical to the live
-- course_TGS-2026061329_learning_outcomes block. They are the SSG-accredited
-- outcomes registered against the unchanged SKU, so the new topics are delivered
-- against those same outcomes and the ICT-INT-0055-1.1 standard still holds.
-- The card legitimately keeps its generative-AI/ethics wording -- that is the
-- registered standard, not a leak.

-- -------------------------------------------------------- 8. Trainer bio
-- One bio (Dwight Nuwan Fonseka), two paragraphs. Para 1 = career CREDENTIALS
-- (Head of Data Science at Plano, R/Keras/h2oAI/Spark/Tableau/AWS, predictive
-- healthcare analytics) -- FACTS, left untouched. Para 2 closes with a
-- course-teaching claim scoped to "responsible use of generative AI in business
-- and society"; retargeted to AI security governance. Single-line REPLACE() on
-- the exact tail string (a multi-line pattern no-ops against the WYSIWYG blob's
-- CRLF line endings). Guarded by the literal match => idempotent.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'His teaching philosophy emphasizes equipping learners with the ability to design and implement AI solutions that are not only technically sound but also ethically aligned&mdash;addressing issues like bias mitigation, transparency, and responsible deployment. With his unique blend of industry leadership and pedagogical expertise, Dwight is well-positioned to help professionals develop actionable strategies for responsible use of generative AI in business and society',
       'His teaching philosophy emphasizes equipping learners with the ability to govern AI solutions that are not only technically sound but also accountable and secure&mdash;addressing issues like risk classification, least-privilege access, and human oversight of autonomous agents. With his unique blend of industry leadership and pedagogical expertise, Dwight is well-positioned to help professionals build a practical AI security governance framework for Generative AI and agentic AI adoption')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- The bio's first paragraph also closes on an old-topic teaching claim (the
-- "pressing need for ethical frameworks" sentence sits at the end of para 1, not
-- in the credentials proper). Retarget just that sentence.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'These experiences have positioned him to understand both the transformative opportunities of generative AI and the pressing need for ethical frameworks to guide its adoption',
       'These experiences have positioned him to understand both the transformative opportunities of generative AI and the pressing need for security governance controls to guide its adoption')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------ 8b. Who Should Attend
-- 20 roles. Most are governance / risk / compliance / policy titles that fit an
-- AI security governance course better than they fitted the ethics course. Three
-- name the retired ethics/CSR/D&I framing specifically -- retarget rather than
-- drop, so the list keeps its 20 rows.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li>Corporate Social Responsibility (CSR) Manager</li>',
       '<li>Information Security Manager</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li>Research Analyst (AI Ethics)</li>',
       '<li>IT Risk and Controls Analyst</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li>Diversity and Inclusion Officer</li>',
       '<li>AI Assurance and Audit Lead</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li>Sustainability Analyst</li>',
       '<li>Third-Party / Vendor Risk Manager</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

-- ----------------------------------------------------- 9. Category placement
-- The repurpose changes the SUBJECT from societal/ethical GenAI strategy to
-- business AI security governance. Drop the two content-creation listings --
--   200 "GenAI Content Creation" (58 members, all content-creation courses)
--   433 "Generative AI Series"   (101 members, the GenAI-application series)
-- -- neither describes a security-governance course any more.
-- Join 161 "IT Security" (70 members), where the sibling WSQ AI security courses
-- and the non-WSQ twin C1440 "AI Security and Governance for AI Agents" sit.
-- KEEP 214 "AI Security Series", 284 "WSQ AI Ethics and Governance", 252 "AI
-- Courses", 301 "WSQ IT & Security Courses", 379 "WSQ Generative AI Courses",
-- 55 "Infocomm Technology" and the WSQ/all-courses listings (3, 15, 292) --
-- all describe the NEW content correctly.
-- Both sides mirrored into catalog_category_product_index or the storefront
-- listings never change.
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (200, 433) AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (200, 433) AND @e IS NOT NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 161, @e, COALESCE((SELECT MAX(position) FROM catalog_category_product WHERE category_id = 161), 0) + 1
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = 161);

INSERT IGNORE INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT 161, @e, cp.position, 1, s.store_id, 4
  FROM catalog_category_product cp
  JOIN core_store s ON s.store_id > 0
 WHERE cp.category_id = 161 AND cp.product_id = @e AND @e IS NOT NULL;
