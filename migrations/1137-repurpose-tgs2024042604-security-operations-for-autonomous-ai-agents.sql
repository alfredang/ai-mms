-- 1137: Repurpose TGS-2024042604
--   OLD: "WSQ - Microsoft Security Operations Analyst (SC-200)"
--   NEW: "WSQ - Security Operations for Autonomous AI Agents"
-- SKU unchanged (SkillsFuture / SFEC / SFC / PSEA deep links are keyed on it).
-- Content supplied by admin, 2026-08-27.
--
-- This is a "realign to own accredited TSC" repurpose: the skills_framework
-- block reads "Security Strategy ICT-SNA-5021-1.1" and the admin-supplied LOs
-- are the live SSG LOs with only "Microsoft 365 " removed. The competency
-- (security strategy/operations) stays; the Microsoft product + SC-200 cert
-- brand retire.
--
-- Surfaces touched (mechanical sweep of BOTH EAV value tables + cms_block +
-- media gallery + core_url_rewrite + catalogsearch_query on live SG prod,
-- 2026-08-27, per feedback_tgs_course_rename_checklist):
--   1  name                  -> keeps the "WSQ - " prefix
--   2  meta_title            -> plain title (old value wrongly baked in "WSQ"
--                               prefix + brand suffix that MMD_Seotitle adds at
--                               render time; dropped)
--   3  url_key + url_path    -> new slug wsq-security-operations-for-autonomous-
--                               ai-agents (collision-checked: bare + wsq- stems
--                               free; nearest sibling is the DISTINCT live
--                               wsq-ai-security-for-autonomous-ai-agents);
--                               explicit 301 for the old bare slug; 7 legacy
--                               alias RP rows flattened onto the new slug.
--   4  description           -> 4 admin-supplied topics, topics-only house
--                               shape (LSN_DATA in sync). Old shape was the
--                               54-topic MS-Learn outline.
--   5  short_description     -> full replace with the admin-supplied About
--                               copy. The old sdesc carried COMMERCIAL PROMISES
--                               that must go with the cert brand: "Microsoft
--                               Learning Partner (Org ID 5238476)" + "Pearson
--                               Vue Test Center" + the exam-voucher deep link
--                               (feedback_repurpose_away_from_certification_brand).
--                               Block-extracted course: no <h2> tail to splice.
--   6  meta_description      -> new copy, 252 chars (varchar 255 cap)
--   7  meta_keyword          -> agent-security terms
--   8  *_label (3) + media_gallery_value.label -> plain new title (cover
--                               strips the "WSQ - " prefix itself)
--   9  trainerprofile        -> para-2 course-teaching claims ONLY, all 5
--                               trainers (Sivanesan / Achim / Agus / Danny /
--                               Truman). Para-1 career credentials kept
--                               verbatim. Each REPLACE anchors on the full
--                               single-line para-2 text (CRLF-safe).
--  10  atc_partners          -> row deleted ('microsoft_lp' renders the
--                               "Authorised Microsoft Learning Partner" card;
--                               a commercial claim tied to the retired cert).
--  11  video                 -> row deleted (legacy "create ePUB from Word"
--                               YouTube embed left over from the pre-SC-200
--                               life of this entity; wrong for any version of
--                               this course).
--  12  learning_outcomes     -> cms_block: strip "Microsoft 365 " (4x), which
--                               yields exactly the admin-supplied LO1-LO4.
--  13  prerequisite          -> ONLY the one software <li> (Microsoft 365
--                               Defender download link) is swapped; the blob
--                               also holds the entire funding apparatus, never
--                               rewrite it wholesale.
--  14  categories            -> drop the 3 Microsoft vendor listings
--                               (11 Microsoft, 135 + 358 Microsoft
--                               Certification Exam Prep); add the AI-agent
--                               placements carried by the repurposed siblings
--                               TGS-2020503395 / TGS-2025054471 (196 WSQ
--                               Agentic AI, 252 AI Courses, 325 WSQ AI,
--                               415 AI Agents Series). Mirrored into
--                               catalog_category_product_index both ways.
--                               182 Certification Exam Prep + 345 WSQ
--                               Certification Courses KEPT per the
--                               TGS-2025054471 (933) precedent; all security
--                               listings (161/301/364/385/386) still describe
--                               the course and are kept.
--  15  catalogsearch_query   -> bare course code + generic security-ops terms
--                               follow the course to the new slug; the 10
--                               Microsoft/SC-200/SC-900-intent terms retarget
--                               to the Microsoft Certification Exam Prep
--                               category page (both SC-200 twins C542/C472 are
--                               DISABLED, so no live twin product exists;
--                               target verified HTTP 200 on the SG domain).
--
-- Deliberately NOT touched (verified against live SG data before writing):
--   * course_TGS-2024042604_skills_framework -- "Security Strategy
--     ICT-SNA-5021-1.1" is the registered TSC; unchanged by the repurpose.
--   * course_TGS-2024042604_certification / _funding_and_grant / _brochure --
--     generic Tertiary/OpenCerts + fee-table copy, no Microsoft text (swept).
--   * whoshouldattend -- all 15 roles are tool-neutral security roles that
--     still describe this course; verified, then skipped.
--   * tags (WSQ / SkillsFuture Credit / PSEA / SFEC / MCES / Absentee Payroll /
--     UTAP) -- funding eligibility unchanged.
--   * image / small_image / thumbnail -- filesystem PATHS, not display text.
--   * news_from_date / news_to_date (Funding Validity) -- no dates supplied.
--   * course_image_url -- R2 cover PNG bakes the OLD title; re-rendered
--     out-of-band post-deploy (cannot be done in SQL).
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement no-ops there (the search-redirect UPDATEs key on the SG domain URL,
-- which no partner row carries).
-- All replacement text is clean ASCII (apply.php connects charset=utf8).
-- Idempotent: UPDATEs converge; REPLACEs no-op on re-run; 301 is INSERT IGNORE
-- behind the is_system row delete; category adds are INSERT IGNORE.
--
-- POST-DEPLOY (manual, not doable in SQL):
--   1. refreshProductRewrite for entity 146 (new slug 404s until this runs;
--      also converts/mints the category-path 301s).
--   2. Reindex Product Flat + fulltext for the product; flush Redis.
--   3. Re-render the R2 cover (badges unchanged).
--   4. Regenerate the course brochure PDF (filesystem-first; still bakes the
--      old title otherwise).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024042604' LIMIT 1);

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpth  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_trainer := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_atc     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'atc_partners');
SET @a_video   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'video');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ---------------------------------------------------------------- 1. name
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Security Operations for Autonomous AI Agents'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------------ 2. meta_title
UPDATE catalog_product_entity_varchar
   SET value = 'Security Operations for Autonomous AI Agents'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

-- -------------------------------------------------------- 6. meta_description
UPDATE catalog_product_entity_varchar
   SET value = 'Learn to monitor, protect and respond to security risks from autonomous AI agents. Covers threat modelling, prompt injection defence, sandboxing, audit logging, anomaly detection and incident response for agentic systems. Up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

-- ----------------------------------------------------------- 7. meta_keyword
UPDATE catalog_product_entity_text
   SET value = 'Security Operations for Autonomous AI Agents, AI agent security, agentic AI security, autonomous AI agents, prompt injection defence, threat modelling, sandboxing, audit logging, anomaly detection, incident response, human-in-the-loop approvals, agent monitoring, WSQ cybersecurity course Singapore'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- ------------------------------------------------------------- 8. alt labels
UPDATE catalog_product_entity_varchar
   SET value = 'Security Operations for Autonomous AI Agents'
 WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Security Operations for Autonomous AI Agents'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------------------- 3. url_key / url_path / 301
-- Clear any is_system = 0 squatter on the NEW path first (INSERT IGNORE would
-- silently no-op against a stale row).
DELETE FROM core_url_rewrite
 WHERE request_path = 'wsq-security-operations-for-autonomous-ai-agents.html'
   AND is_system = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'wsq-security-operations-for-autonomous-ai-agents'
 WHERE entity_id = @e AND attribute_id = @a_urlkey AND @e IS NOT NULL;

-- Drop url_path at EVERY scope (store 0 + 1 both exist) so the URL-rewrite
-- indexer regenerates it.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlpth AND @e IS NOT NULL;

-- The old bare slug is held by an is_system = 1 row sharing id_path
-- 'product/146' with the 301 below; INSERT IGNORE would no-op against it AND
-- the rewrite refresh would mint a '-146' suffix for the new slug
-- (feedback_repurpose_301_needs_system_row_delete). Drop it first.
DELETE FROM core_url_rewrite
 WHERE product_id = @e
   AND request_path = 'wsq-microsoft-security-operations-analyst-sc-200.html'
   AND is_system = 1 AND @e IS NOT NULL;

INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id, NULL, @e,
       CONCAT('product/', @e),
       'wsq-microsoft-security-operations-analyst-sc-200.html',
       'wsq-security-operations-for-autonomous-ai-agents.html',
       0, 'RP', '1137 repurpose 301'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- Flatten the 7 legacy alias RP rows (epub/ebook-era + the two old exam-prep
-- slugs) onto the new slug so no visitor rides a 301 chain. Anchored on the
-- FULL old filename; sibling security courses are untouched.
UPDATE core_url_rewrite
   SET target_path = 'wsq-security-operations-for-autonomous-ai-agents.html'
 WHERE target_path = 'wsq-microsoft-security-operations-analyst-sc-200.html'
   AND is_system = 0 AND options = 'RP' AND @e IS NOT NULL;

-- --------------------------------------- 4. Topics Covered (description + JSON)
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Security Strategy and Standards for Autonomous AI Agents","subsecs":[]},{"title":"Topic 2: Agent Security Policies, Governance and Compliance","subsecs":[]},{"title":"Topic 3: AI Agent Risk Assessment and Security Control Evaluation","subsecs":[]},{"title":"Topic 4: Implementing and Monitoring Organization-Wide Agent Security Operations","subsecs":[]}] -->
<p><strong>Topic 1: Security Strategy and Standards for Autonomous AI Agents</strong></p>
<p><strong>Topic 2: Agent Security Policies, Governance and Compliance</strong></p>
<p><strong>Topic 3: AI Agent Risk Assessment and Security Control Evaluation</strong></p>
<p><strong>Topic 4: Implementing and Monitoring Organization-Wide Agent Security Operations</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------- 5. About This Course (full replace)
-- Drops the "Microsoft Learning Partner" + "Certification Exam at Pearson Vue"
-- sections and the exam-voucher deep link along with the old prose.
UPDATE catalog_product_entity_text
   SET value = '<p>Security Operations for Autonomous AI Agents equips participants with practical skills to monitor, protect, and respond to security risks arising from the deployment of autonomous AI agents. Learners will examine how agents interact with tools, APIs, files, memory systems, databases, and external services, and how these capabilities can introduce new attack surfaces and operational risks.</p>
<p>Through hands-on activities, participants will learn to secure agent identities, permissions, credentials, tool access, and communication channels. The course covers threat modelling, security monitoring, prompt-injection defence, sensitive-data protection, access control, sandboxing, audit logging, anomaly detection, and human-in-the-loop approvals. Learners will also investigate risks such as unauthorized tool execution, memory poisoning, data leakage, excessive agency, malicious inputs, and compromised third-party integrations.</p>
<p>Participants will develop workflows to collect and analyze agent activity logs, detect suspicious behaviour, investigate incidents, contain affected agents, and recommend remediation actions. They will also establish incident response procedures, security policies, operational guardrails, and recovery plans for agentic systems.</p>
<p>By the end of the course, learners will be able to implement security operations practices that improve the visibility, control, resilience, and responsible deployment of autonomous AI agents across organizational environments.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------- 9. trainerprofile
-- Retarget ONLY each trainer's para-2 course-teaching claim (5 trainers);
-- para-1 credentials are facts and stay verbatim. Each target is a single line.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Security Operations Analyst (SC-200),&rdquo; Sivanesan provides a structured approach to understanding threat management, incident response, and security operations using Microsoft tools such as Sentinel and Defender. His sessions focus on aligning cybersecurity practices with organizational governance frameworks, emphasizing proactive threat hunting, data protection, and compliance readiness. By integrating real-world examples with Microsoft&rsquo;s security ecosystem, he equips learners to detect, analyze, and mitigate cyber threats effectively in dynamic enterprise environments.',
       'In &ldquo;Security Operations for Autonomous AI Agents,&rdquo; Sivanesan provides a structured approach to understanding threat management, incident response, and security operations for agentic AI systems. His sessions focus on aligning agent security practices with organizational governance frameworks, emphasizing threat modelling, sensitive-data protection, and compliance readiness. By integrating real-world examples of agent deployments, he equips learners to detect, analyze, and mitigate security risks from autonomous AI agents effectively in dynamic enterprise environments.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Security Operations Analyst (SC-200),&rdquo; Achim focuses on teaching participants how to monitor, investigate, and respond to security threats using Microsoft Sentinel and Microsoft 365 Defender. His sessions emphasize data correlation, automated incident response, and security orchestration. Through hands-on labs and case-based discussions, he helps learners build proficiency in Microsoft&rsquo;s SIEM and XDR capabilities to ensure resilient and efficient security operations.',
       'In &ldquo;Security Operations for Autonomous AI Agents,&rdquo; Achim focuses on teaching participants how to monitor, investigate, and respond to security threats arising from autonomous AI agents. His sessions emphasize agent activity log analysis, automated incident response, and security orchestration. Through hands-on labs and case-based discussions, he helps learners build proficiency in agent monitoring, sandboxing, and anomaly detection to ensure resilient and efficient security operations.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Security Operations Analyst (SC-200),&rdquo; Agus helps learners master the tools and methodologies required for effective security monitoring and incident management. His sessions cover Microsoft Sentinel configuration, Defender integration, and proactive threat hunting using KQL queries. By combining technical depth with practical insights, he empowers participants to manage real-world cyber incidents confidently and enhance their organization&rsquo;s overall security maturity.',
       'In &ldquo;Security Operations for Autonomous AI Agents,&rdquo; Agus helps learners master the tools and methodologies required for effective security monitoring and incident management of agentic systems. His sessions cover securing agent identities and permissions, tool-access control, and proactive threat hunting across agent activity logs. By combining technical depth with practical insights, he empowers participants to manage real-world agent security incidents confidently and enhance their organization&rsquo;s overall security maturity.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Security Operations Analyst (SC-200),&rdquo; Danny delivers comprehensive instruction on managing and responding to security incidents using Microsoft&rsquo;s integrated security suite. His sessions emphasize advanced threat analytics, automation through Microsoft Sentinel, and the use of machine learning for anomaly detection. Drawing from his consulting and cloud engineering background, he guides learners to implement end-to-end security monitoring frameworks that enhance resilience and compliance across digital ecosystems.',
       'In &ldquo;Security Operations for Autonomous AI Agents,&rdquo; Danny delivers comprehensive instruction on managing and responding to security incidents involving autonomous AI agents. His sessions emphasize advanced threat analytics, automation of incident response workflows, and the use of anomaly detection to flag suspicious agent behaviour. Drawing from his consulting and cloud engineering background, he guides learners to implement end-to-end security monitoring frameworks that enhance resilience and compliance across digital ecosystems.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Security Operations Analyst (SC-200),&rdquo; Truman teaches participants how to operationalize Microsoft&rsquo;s security tools to safeguard enterprise systems. His sessions cover advanced topics such as Sentinel analytics, Defender for Cloud integration, and automation of threat response workflows. By combining hands-on technical practice with strategic security insights, he enables learners to develop robust, adaptive security operations capabilities aligned with industry best practices.',
       'In &ldquo;Security Operations for Autonomous AI Agents,&rdquo; Truman teaches participants how to operationalize security guardrails to safeguard enterprise AI agent deployments. His sessions cover advanced topics such as sandboxing, human-in-the-loop approvals, and automation of threat response workflows. By combining hands-on technical practice with strategic security insights, he enables learners to develop robust, adaptive security operations capabilities aligned with industry best practices.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------- 10. atc_partners
-- 'microsoft_lp' drives the "Authorised Microsoft Learning Partner" card on the
-- product page -- a commercial accreditation claim tied to the retired cert.
DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_atc AND @e IS NOT NULL;

-- ------------------------------------------------------------- 11. video
-- Legacy "create ePUB from Word document" YouTube embed from this entity's
-- pre-SC-200 life (see the epub/ebook alias rewrites). Wrong for any version
-- of this course.
DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_video AND @e IS NOT NULL;

-- ------------------------------------------------------- 12. learning_outcomes
-- The registered TSC (Security Strategy ICT-SNA-5021-1.1) is unchanged; the
-- admin-supplied LOs are the live LOs minus "Microsoft 365 ". A single strip
-- converges and preserves the block's existing markup exactly.
UPDATE cms_block
   SET content = REPLACE(content, 'Microsoft 365 ', '')
 WHERE identifier = 'course_TGS-2024042604_learning_outcomes';

-- ---------------------------------------------------------- 13. prerequisite
-- Swap ONLY the software <li> (Microsoft 365 Defender download). The blob also
-- holds the entire funding apparatus (PWM / eligibility table / SkillsFuture /
-- PSEA / SFEC / UTAP deep links / Appeal Process) -- never rewrite wholesale.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li><a href="https://www.microsoft.com/en-us/microsoft-365/microsoft-defender-for-individuals" target="_blank"><span style="text-decoration: underline;">Microsoft 365 Defender</span></a></li>',
       '<li><a href="https://claude.ai" target="_blank"><span style="text-decoration: underline;">Anthropic Claude</span></a> (or an equivalent AI agent platform, advised by the trainer)</li>')
 WHERE entity_id = @e AND attribute_id = @a_prereq AND @e IS NOT NULL;

-- ------------------------------------------------------------- 14. categories
-- Drop the Microsoft vendor listings; the course no longer teaches Microsoft
-- tools nor preps the SC-200 exam. Both tables must be hit
-- (feedback_category_swap_needs_index_mirror).
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (11, 135, 358) AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (11, 135, 358) AND @e IS NOT NULL;

-- Add the AI-agent placements the repurposed siblings carry
-- (196 WSQ Agentic AI, 252 AI Courses, 325 WSQ AI, 415 AI Agents Series),
-- appended at MAX(position)+1 so the category-ordering sweep renumbers later.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 196, @e, COALESCE((SELECT MAX(position) FROM catalog_category_product WHERE category_id = 196), 0) + 1
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = 196);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 252, @e, COALESCE((SELECT MAX(position) FROM catalog_category_product WHERE category_id = 252), 0) + 1
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = 252);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 325, @e, COALESCE((SELECT MAX(position) FROM catalog_category_product WHERE category_id = 325), 0) + 1
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = 325);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 415, @e, COALESCE((SELECT MAX(position) FROM catalog_category_product WHERE category_id = 415), 0) + 1
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = 415);

INSERT IGNORE INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, @e, cp.position, 1, s.store_id, 4
  FROM catalog_category_product cp
  CROSS JOIN core_store s
 WHERE cp.category_id IN (196, 252, 325, 415) AND cp.product_id = @e
   AND s.store_id > 0 AND @e IS NOT NULL;

-- --------------------------------------------------- 15. search redirects
-- Bare course code + generic security-operations intent follow the course.
UPDATE catalogsearch_query
   SET redirect = REPLACE(redirect,
       '/wsq-microsoft-security-operations-analyst-sc-200.html',
       '/wsq-security-operations-for-autonomous-ai-agents.html')
 WHERE redirect LIKE '%/wsq-microsoft-security-operations-analyst-sc-200.html'
   AND query_text IN ('TGS-2024042604', 'operations', 'security operations', 'Security Operations Analyst');

-- Microsoft / SC-200 / SC-900 cert intent: both non-WSQ twins (C542 SC-200,
-- C472 SC-900) are DISABLED, so no live twin product exists. Retarget to the
-- Microsoft Certification Exam Prep category page (flat URL, verified 200)
-- where the live Microsoft cert-prep courses (incl. SC-100) are listed.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/microsoft-certifications-exams.html'
 WHERE redirect LIKE '%/wsq-microsoft-security-operations-analyst-sc-200.html';
