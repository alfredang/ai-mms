-- 1024: Repurpose TGS-2025060473
--   OLD: "WSQ - Core Principles and Ethical Challenges in Generative AI"
--   NEW: "WSQ - AI Security for Autonomous AI Agents"
-- SKU unchanged (SkillsFuture / SFEC / SFC / PSEA deep links are keyed on it).
-- Content supplied by admin, 2026-08-15.
--
-- Surfaces touched (mechanical sweep of BOTH EAV value tables + cms_block +
-- media gallery for 'Generative AI' / 'ethical' / the old slug, per
-- feedback_tgs_course_rename_checklist):
--   1  name                  -> keeps the "WSQ - " prefix
--   2  meta_title            -> plain title at BOTH scopes (store 0 and 1).
--                               MMD_Seotitle adds the "WSQ funded" prefix and
--                               the brand postfix at render time; the OLD value
--                               wrongly baked in both, so they are dropped.
--   3  url_key + url_path    -> new slug; url_path deleted at every scope so the
--                               URL-rewrite indexer regenerates; explicit 301
--                               for the old bare slug.
--   4  description           -> 3 flat topics (LSN_DATA JSON kept in sync).
--                               Old shape was nested LU/T subsecs (10 topics).
--   5  short_description     -> full replace. This course PRE-dates nothing:
--                               its sdesc is pure intro prose with NO trailing
--                               "<h2>Skills Framework</h2>" section (verified),
--                               so a full replace loses nothing.
--   6  meta_description      -> BOTH scopes (store 0 and 1).
--   7  meta_keyword          -> BOTH scopes; retargeted to AI-security terms.
--   8  *_label (3) + media_gallery_value.label -> alt text. The gallery label is
--                               the alt the storefront actually renders (see
--                               feedback_media_gallery_label_is_the_real_alt_text);
--                               the 3 *_label attrs are updated for consistency.
--   9  trainerprofile        -> para 2 ONLY (the course-teaching claim). Para 1
--                               is career CREDENTIALS (real roles, degrees,
--                               ACLP cert) = facts, kept verbatim.
--  10  whoshouldattend       -> 20 hospitality/customer-service roles replaced
--                               with 20 security/agent-ops roles.
--  11  learning_outcomes     -> cms_block, admin-supplied wording VERBATIM.
--  12  categories            -> drop the 3 stale generative-AI listings
--                               (284 WSQ AI Ethics and Governance,
--                                379 WSQ Generative AI Courses,
--                                433 Generative AI Series),
--                               mirrored into catalog_category_product_index.
--                               Course already sits in 214 (AI Security Series)
--                               and 301 (WSQ IT & Security) -- both kept, as are
--                               the generic 3 / 15 / 252 / 292 / 325.
--
-- Deliberately NOT touched (verified against live data before writing):
--   * course_TGS-2025060473_skills_framework -- "ICT-INT-0052-1.1: Generative AI
--     Principles and Applications" is the SSG competency standard this TGS-
--     accreditation is registered against and what the OpenCerts Statement of
--     Achievement certifies. Registry data, not marketing copy: changing it in
--     the storefront without an SSG re-accreditation would misstate the cert.
--     Admin confirmed 2026-08-15. The _certification block's "the above Skills
--     Framework" reference therefore stays coherent.
--   * prerequisite -- holds the funding apparatus AND contains invalid UTF-8
--     bytes (0x96 smart quotes in "GCE 'O' Levels"). apply.php connects
--     charset=utf8 and ABORTS the whole chain on error 1366 (see
--     feedback_migration_applyphp_utf8_outage). Its software line is "TBD" --
--     nothing course-specific to change. Do not REPLACE() into this attribute.
--   * certification / funding_and_grant / brochure cms_blocks -- keyed on the
--     SKU; OpenCerts wording and the fee table are unaffected by a rename.
--   * tags (WSQ / SkillsFuture Credit / PSEA / SFEC / MCES / Absentee Payroll)
--     -- funding eligibility is unchanged by the content swap.
--   * image / small_image / thumbnail -- filesystem PATHS, not display text;
--     renaming them 404s the JPG. The storefront renders the R2 cover.
--   * course_image_url -- R2 cover PNG still bakes the OLD title. Re-render from
--     the admin cover dialog after deploy (cannot be done in SQL).
--   * catalogsearch_query -- 3 rows match the old title but all have
--     redirect IS NULL, so they fall through to normal search. No dead redirect
--     to repair; nothing to overwrite (feedback_search_redirects_rot_when_course_disabled
--     concerns disabled courses, and this one stays enabled).
--   * upsell links (9 rows) -- "Recommended Courses" are curated relationships;
--     retargeting them is a separate editorial call.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement no-ops there.
-- All replacement text is clean ASCII (apply.php connects charset=utf8).
-- Idempotent: UPDATEs converge; the sdesc splice is phrase-guarded; the 301 is
-- INSERT IGNORE behind a squatter DELETE.
--
-- POST-DEPLOY (manual, not doable in SQL -- see
-- feedback_prod_rename_needs_manual_rewrite_refresh):
--   1. Refresh the product URL rewrite so the new slug resolves (apply.php never
--      reindexes; the new URL 404s until this runs).
--   2. Reindex Catalog URL Rewrites + Category Flat Data + Product Flat Data.
--   3. Flush Redis (prod CMS/name reads are cached).
--   4. Re-render the R2 cover from the admin cover dialog.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025060473' LIMIT 1);

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpth  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_trainer := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ---------------------------------------------------------------- 1. name
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - AI Security for Autonomous AI Agents'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------------ 2. meta_title
-- Plain title only, at EVERY scope (this course carries a store_id = 1 override
-- as well as the store 0 default -- both baked in the old prefix/postfix).
UPDATE catalog_product_entity_varchar
   SET value = 'AI Security for Autonomous AI Agents'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

-- -------------------------------------------------------- 6. meta_description
UPDATE catalog_product_entity_varchar
   SET value = 'Learn to secure autonomous AI agents with OpenClaw, Hermes Agent and Paperclip. Covers prompt injection, least-privilege permissions, memory protection, agent governance and monitoring. Up to 70% WSQ funding subsidy available.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

-- ----------------------------------------------------------- 7. meta_keyword
UPDATE catalog_product_entity_text
   SET value = 'AI security course Singapore, autonomous AI agents, AI agent security, OpenClaw, Hermes Agent, Paperclip, prompt injection, least privilege permissions, agent governance, multi-agent workflows, AI risk management, secure tool execution, agent monitoring'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- ------------------------------------------------------------- 8. alt labels
-- The cover strips the segment prefix (CourseImage/Model/Cover.php::cleanTitle)
-- so these carry no "WSQ - ".
UPDATE catalog_product_entity_varchar
   SET value = 'AI Security for Autonomous AI Agents'
 WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel) AND @e IS NOT NULL;

-- The alt text the storefront ACTUALLY renders lives here, not in the 3 attrs
-- above (feedback_media_gallery_label_is_the_real_alt_text).
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'AI Security for Autonomous AI Agents'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------------------- 3. url_key / url_path / 301
-- Clear any is_system = 0 squatter on the NEW path first: INSERT IGNORE would
-- silently no-op against a stale row (see 647).
DELETE FROM core_url_rewrite
 WHERE request_path = 'wsq-ai-security-for-autonomous-ai-agents.html'
   AND is_system = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'wsq-ai-security-for-autonomous-ai-agents'
 WHERE entity_id = @e AND attribute_id = @a_urlkey AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL-rewrite indexer regenerates it.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlpth AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug. The indexer auto-301s the category paths;
-- this row covers the canonical flat URL.
--
-- CRITICAL (feedback_rename_301_vs_system_rewrite_suffix_trap -- hit for real on
-- this course during the local dry-run): the old bare slug is ALREADY held by an
-- is_system = 1 row whose id_path is 'product/1884' -- the same id_path the 301
-- below needs. INSERT IGNORE therefore no-ops against the unique key and NO
-- redirect is created; worse, leaving the system row in place makes the rewrite
-- refresh treat the old path as occupied and mint a '-1884' suffix for the new
-- slug, so the new URL 404s. Drop the system row for the OLD path first.
DELETE FROM core_url_rewrite
 WHERE product_id = @e
   AND request_path = 'wsq-core-principles-and-ethical-challenges-in-generative-ai.html'
   AND is_system = 1 AND @e IS NOT NULL;

INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id, NULL, @e,
       CONCAT('product/', @e),
       'wsq-core-principles-and-ethical-challenges-in-generative-ai.html',
       'wsq-ai-security-for-autonomous-ai-agents.html',
       0, 'RP', '1024 repurpose 301'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- --------------------------------------- 4. Topics Covered (description + JSON)
-- Old shape was nested LU1-LU3 with 10 T-subsecs; new content is 3 flat topics.
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Autonomous AI Agent Fundamentals with OpenClaw and Hermes Agent","subsecs":[]},{"title":"Topic 2: Securing AI Agent Tools, Data, Memory and Multi-Agent Workflows","subsecs":[]},{"title":"Topic 3: AI Agent Governance, Risk Management and Security Monitoring with Paperclip","subsecs":[]}] -->
<p><strong>Topic 1: Autonomous AI Agent Fundamentals with OpenClaw and Hermes Agent</strong></p>
<p><strong>Topic 2: Securing AI Agent Tools, Data, Memory and Multi-Agent Workflows</strong></p>
<p><strong>Topic 3: AI Agent Governance, Risk Management and Security Monitoring with Paperclip</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------- 5. About This Course (full replace)
-- Verified: this sdesc is intro prose ONLY -- no trailing Skills Framework /
-- Google-Drive section to preserve, so no splice is needed (contrast 961).
UPDATE catalog_product_entity_text
   SET value = '<p>This course equips participants with essential knowledge and practical skills to secure autonomous AI agents operating across business systems, data sources, digital tools, and multi-step workflows. Learners will examine how platforms such as OpenClaw, Hermes Agent, and Paperclip enable AI agents to perform tasks, use tools, retain context, coordinate work, and collaborate within multi-agent environments.</p>
<p>Participants will explore security risks associated with autonomous agents, including prompt injection, malicious instructions, excessive permissions, confidential data exposure, unsafe tool execution, identity misuse, compromised memory, unauthorised system changes, and uncontrolled agent-to-agent communication. They will learn to assess the potential business impact of agent actions and identify vulnerabilities throughout the agent lifecycle.</p>
<p>The course covers practical safeguards such as identity and access management, least-privilege permissions, isolated execution, tool allowlists, secure credential handling, memory protection, action approval, activity logging, output validation, and emergency shutdown procedures. Learners will apply these controls to OpenClaw and Hermes Agent workflows and establish governance measures for coordinating and supervising multiple agents with Paperclip.</p>
<p>Through hands-on scenarios, participants will configure secure agent workflows, assess agent behaviour, investigate suspicious activities, respond to incidents, and improve security controls. Emphasis is placed on human oversight, accountability, privacy, transparency, ethical use, and compliance with organisational policies.</p>
<p>By the end of the course, learners will be able to evaluate risks and implement security controls for autonomous AI agents, enabling organisations to adopt OpenClaw, Hermes Agent, and Paperclip more safely and responsibly.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------- 9. trainerprofile
-- Single trainer (Dwight Nuwan Fonseka). Retarget ONLY the para-2 teaching
-- claim; para 1 is career credentials (Head of Data Science at Plano, NTU/NUS
-- degrees, ACLP cert) -- facts about the person, rewriting them falsifies the
-- bio. Kept on ONE line: multi-line REPLACE() no-ops on CRLF WYSIWYG blobs
-- (feedback_multiline_replace_fails_on_crlf_blobs). The para-1 text contains
-- invalid UTF-8 bytes, so the match anchors strictly inside clean-ASCII para 2.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'He has taught extensively on R, deep learning frameworks, and AI deployment, with a focus on bridging technical proficiency and ethical responsibility. His dual background in applied data science and training makes him well-positioned to guide learners through the core principles of generative AI, addressing critical challenges such as bias, misinformation, environmental impact, and responsible deployment. With a strong record of both real-world application and teaching, Dwight equips professionals with the knowledge to navigate the opportunities and ethical dilemmas posed by generative AI',
       'He has taught extensively on AI deployment, model pipelines, and the operational controls that keep automated systems accountable. His dual background in applied data science and training makes him well-positioned to guide learners through securing autonomous AI agents, addressing risks such as prompt injection, excessive permissions, unsafe tool execution, and compromised agent memory. With a strong record of both real-world application and teaching, Dwight equips professionals with the knowledge to deploy AI agents with least-privilege access, human oversight, and effective security monitoring')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0 AND @e IS NOT NULL;

-- --------------------------------------------------------- 10. whoshouldattend
-- Old list was 20 hospitality / customer-service roles tied to the retired
-- course angle. Replaced wholesale with security + agent-operations roles.
UPDATE catalog_product_entity_text
   SET value = '<ul><li>AI Security Engineer</li><li>Cybersecurity Analyst</li><li>Security Operations Engineer</li><li>AI Governance Manager</li><li>Risk and Compliance Officer</li><li>IT Security Manager</li><li>AI Agent Developer</li><li>Automation Engineer</li><li>Solutions Architect</li><li>DevOps Engineer</li><li>Identity and Access Management Specialist</li><li>Data Protection Officer</li><li>IT Operations Manager</li><li>Systems Administrator</li><li>Incident Response Analyst</li><li>Technology Risk Consultant</li><li>Digital Transformation Lead</li><li>Enterprise Architect</li><li>Machine Learning Engineer</li><li>AI Adoption Consultant</li></ul>'
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------- 11. learning_outcomes
-- Admin-supplied wording, VERBATIM (confirmed 2026-08-15). Identifier is matched
-- by HEX to dodge whitespace taint in cms_block.identifier
-- (feedback_cms_block_identifier_whitespace_taint). UPDATE only -- cms_block has
-- NO unique key on identifier, so INSERT ... ON DUPLICATE KEY would duplicate
-- the block (feedback_cms_block_identifier_has_no_unique_key).
UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p><ul><li>LO1: Demonstrate generative and discriminative AI concepts and applications relevant to customer service and hospitality management.</li><li>LO2: Apply prompt engineering techniques and analyse output variations based on model training data and outputs to improve generative AI performance.</li><li>LO3: Identify ethical risks and analyse bias in AI-generated content based on model training data and outputs.</li></ul>'
 WHERE identifier = UNHEX('636F757273655F5447532D323032353036303437335F6C6561726E696E675F6F7574636F6D6573');

-- ------------------------------------------------------------- 12. categories
-- Drop the 3 stale generative-AI listings. The course keeps 214 (AI Security
-- Series) and 301 (WSQ IT & Security) -- both already assigned -- plus the
-- generic 3 / 15 / 252 / 292 / 325. Both tables must be hit or the storefront
-- listings never change (feedback_category_swap_needs_index_mirror).
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (284, 379, 433) AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (284, 379, 433) AND @e IS NOT NULL;
