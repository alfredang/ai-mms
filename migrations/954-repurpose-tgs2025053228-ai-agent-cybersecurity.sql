-- 954: Repurpose TGS-2025053228
--   "WSQ - Pearson Vue Certified IT Specialist Cybersecurity"
--     -> "WSQ - AI Agent Cybersecurity"
-- SKU unchanged (all SkillsFuture / SFEC / SFC / PSEA / UTAP deep links in the
-- funding_and_grant cms_block stay valid -- that block is NOT touched here).
--
-- Surfaces touched (per the TGS- rename checklist):
--   1  name
--   2  meta_title      (plain title: MMD_Seotitle prepends "WSQ funded" and
--                       appends the brand postfix at render time)
--   3  url_key + url_path deleted at EVERY scope + explicit 301 for old slug
--   4  short_description  -> About This Course prose ONLY
--   5  image/small_image/thumbnail _label + media-gallery label
--   6  trainerprofile   (course-teaching paragraph per trainer; credentials kept)
--                       + DELETE the stale store-1 override (IoT trainers)
--   7  meta_description
--   8  meta_keyword
--   9  whoshouldattend  (job roles named the old certification track)
--  10  prerequisite     (Minimum Software Requirement "TBD" -> the agent tools)
--  11  description      (Course Outline, LSN_DATA JSON kept in sync)
--  12  learning_outcomes cms_block  (LO1-LO3 reworded per the new brief)
--  13  categories: DROP the three Pearson-VUE / exam-prep categories,
--                  ADD the AI Security + AI Agents series (+ index mirror)
--
-- NOT touched (deliberate):
--   * funding_and_grant cms_block -- SKU unchanged, fee table + all deep links
--     remain correct. Rewriting it would risk breaking the PSEA/SFEC links.
--   * certification cms_block -- Certificate of Achievement + OpenCerts copy is
--     generic WSQ boilerplate, still accurate.
--   * skills_framework cms_block -- ACC-ICT-5002-1.1 Cyber Security is the
--     accredited competency standard tied to the TGS- code; it does not change
--     when the delivery method changes.
--   * brochure cms_block -- brochure PDF is regenerated out-of-band.
--   * price / custom options / class dates.
--
-- Idempotent: every write is guarded (LOCATE probes / ON DUPLICATE KEY UPDATE /
-- NOT EXISTS), so a re-run converges.
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => all
-- statements are guarded no-ops there (never a NULL entity_id INSERT).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025053228' LIMIT 1);

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_pre    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_tp     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_il     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tl     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------------ 1. name
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - AI Agent Cybersecurity'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------- 2. meta_title (plain)
-- No leading "WSQ", no "| Tertiary Courses Singapore" suffix -- MMD_Seotitle
-- composes both at render time; baking them in yields "WSQ funded WSQ ...".
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @e, 'AI Agent Cybersecurity'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND store_id <> 0 AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. url_key + 301
SET @old_slug := 'wsq-pearson-vue-certified-it-specialist-cybersecurity';
SET @new_slug := 'wsq-ai-agent-cybersecurity';

-- Remove any is_system = 0 squatter on the new path first: INSERT IGNORE
-- silently no-ops against a stale row.
DELETE FROM core_url_rewrite
 WHERE request_path = CONCAT(@new_slug, '.html') AND is_system = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = @new_slug
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL Rewrites indexer regenerates it;
-- a surviving store-scoped row still holding the old slug shadows the new URL.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the ~13 category
-- paths from its own rewrite history, but not this one).
INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options)
SELECT 1, NULL, @e, CONCAT('product/', @e, '/rp-954'), CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'), 0, 'RP'
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                    WHERE x.request_path = CONCAT(@old_slug, '.html') AND x.store_id = 1);

-- ---------------------------------------------- 4. short_description (About)
UPDATE catalog_product_entity_text
   SET value = '<p>AI Agent Cybersecurity equips participants with practical skills to deploy and manage autonomous AI agents for cybersecurity operations using OpenClaw and Hermes Agent. Learners will explore how AI agents can monitor security events, analyze system and network logs, identify suspicious behaviour, assess vulnerabilities, and support faster incident investigation and response.</p>
<p>Through hands-on activities, participants will configure agents with appropriate tools, skills, memory, context, and permissions to perform security-related tasks. They will develop agentic workflows for threat intelligence analysis, vulnerability assessment, phishing detection, security reporting, risk prioritization, and remediation planning. The course also covers human-in-the-loop approvals and multi-agent collaboration for coordinating complex security operations.</p>
<p>Emphasis is placed on securing the AI agents themselves through access controls, sandboxing, least-privilege permissions, secure tool integration, prompt-injection defence, sensitive-data protection, audit trails, and operational guardrails. Participants will learn to validate agent findings and prevent unsafe or unauthorized actions. By the end of the course, learners will be able to use OpenClaw and Hermes Agent responsibly to automate repetitive security tasks, strengthen threat detection, and improve organizational cyber resilience.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- Any store-scoped short_description override would shadow store 0.
DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id <> 0 AND @e IS NOT NULL;

-- --------------------------------- 11. description (Course Outline + LSN_DATA)
-- The three new topics map 1:1 onto the three existing Learning Units, which in
-- turn map 1:1 onto LO1 / LO2 / LO3. The LU scaffolding is kept (it mirrors the
-- accredited competency standard); only the topics beneath it are replaced.
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"LU1 Organization\'s Cyber Security Policies and Procedures","subsecs":[]},{"title":"Topic 1: Developing Cybersecurity Policies with OpenClaw and Hermes Agents","subsecs":[{"title":"Overview of autonomous AI agents for cybersecurity operations","links":[]},{"title":"Setting up OpenClaw and Hermes Agent for security workflows","links":[]},{"title":"Configuring agent tools, skills, memory, context and permissions","links":[]},{"title":"Drafting organizational cybersecurity policies with agent assistance","links":[]},{"title":"Access controls, sandboxing and least-privilege agent permissions","links":[]},{"title":"Protecting confidentiality and integrity of information handled by agents","links":[]}]},{"title":"LU2 Implementation of Organization\'s Cyber Security Policies and Procedure","subsecs":[]},{"title":"Topic 2: AI Agent Monitoring, Compliance and Response to Emerging Threats","subsecs":[{"title":"Agentic workflows for security event and log monitoring","links":[]},{"title":"Threat intelligence analysis and phishing detection with AI agents","links":[]},{"title":"Vulnerability assessment and risk prioritization","links":[]},{"title":"Compliance checking against cybersecurity policies and procedures","links":[]},{"title":"Incident investigation, security reporting and remediation planning","links":[]},{"title":"Human-in-the-loop approvals and multi-agent collaboration","links":[]}]},{"title":"LU3 Assessment and Continuous Improvement of Organization\'s Cyber Security Policies and Procedure","subsecs":[]},{"title":"Topic 3: Continuous Cybersecurity Improvement with Autonomous AI Agent","subsecs":[{"title":"Validating agent findings and preventing unsafe or unauthorized actions","links":[]},{"title":"Prompt-injection defence and sensitive-data protection","links":[]},{"title":"Secure tool integration, audit trails and operational guardrails","links":[]},{"title":"Evaluating agent performance and refining agentic security workflows","links":[]},{"title":"Reviewing and improving cybersecurity policies from agent insights","links":[]},{"title":"Automating repetitive security tasks to strengthen cyber resilience","links":[]}]}] -->
<p><strong>LU1 Organization&rsquo;s Cyber Security Policies and Procedures</strong></p>
<p><strong>Topic 1: Developing Cybersecurity Policies with OpenClaw and Hermes Agents</strong></p>
<p><em>Overview of autonomous AI agents for cybersecurity operations</em></p>
<p><em>Setting up OpenClaw and Hermes Agent for security workflows</em></p>
<p><em>Configuring agent tools, skills, memory, context and permissions</em></p>
<p><em>Drafting organizational cybersecurity policies with agent assistance</em></p>
<p><em>Access controls, sandboxing and least-privilege agent permissions</em></p>
<p><em>Protecting confidentiality and integrity of information handled by agents</em></p>
<p><strong>LU2 Implementation of Organization&rsquo;s Cyber Security Policies and Procedure</strong></p>
<p><strong>Topic 2: AI Agent Monitoring, Compliance and Response to Emerging Threats</strong></p>
<p><em>Agentic workflows for security event and log monitoring</em></p>
<p><em>Threat intelligence analysis and phishing detection with AI agents</em></p>
<p><em>Vulnerability assessment and risk prioritization</em></p>
<p><em>Compliance checking against cybersecurity policies and procedures</em></p>
<p><em>Incident investigation, security reporting and remediation planning</em></p>
<p><em>Human-in-the-loop approvals and multi-agent collaboration</em></p>
<p><strong>LU3 Assessment and Continuous Improvement of Organization&rsquo;s Cyber Security Policies and Procedure</strong></p>
<p><strong>Topic 3: Continuous Cybersecurity Improvement with Autonomous AI Agent</strong></p>
<p><em>Validating agent findings and preventing unsafe or unauthorized actions</em></p>
<p><em>Prompt-injection defence and sensitive-data protection</em></p>
<p><em>Secure tool integration, audit trails and operational guardrails</em></p>
<p><em>Evaluating agent performance and refining agentic security workflows</em></p>
<p><em>Reviewing and improving cybersecurity policies from agent insights</em></p>
<p><em>Automating repetitive security tasks to strengthen cyber resilience</em></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id <> 0 AND @e IS NOT NULL;

-- ------------------------------------------------------- 7. meta_description
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @e, 'Deploy autonomous AI agents for cybersecurity with OpenClaw and Hermes Agent. This WSQ-funded course covers agentic threat monitoring, vulnerability assessment, incident response and agent security guardrails. Enjoy up to 70% funding. Enrol now.'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND store_id <> 0 AND @e IS NOT NULL;

-- ----------------------------------------------------------- 8. meta_keyword
UPDATE catalog_product_entity_text
   SET value = 'AI Agent Cybersecurity, Agentic AI Security, OpenClaw, Hermes Agent, AI security agents, autonomous threat detection, agentic incident response, vulnerability assessment, prompt injection defence, cybersecurity policies, WSQ, WSQ Funding'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- ------------------------------------------------------- 5. cover alt labels
-- Plain title (no "WSQ - " prefix): the cover image itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'AI Agent Cybersecurity'
 WHERE entity_id = @e AND attribute_id IN (@a_il, @a_sil, @a_tl) AND @e IS NOT NULL;

-- The media-gallery per-image label renders as the zoom gallery's img
-- title/alt -- the rename template historically missed it.
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'AI Agent Cybersecurity'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- --------------------------------------------------------- 9. whoshouldattend
-- The old list named certification-track roles (Penetration Tester, Digital
-- Forensics Specialist, CISO...). Re-pointed at the AI-agent security audience
-- while keeping the core security-operations roles this course still serves.
UPDATE catalog_product_entity_text
   SET value = '<ul>
<li>Cybersecurity Specialist</li>
<li>IT Security Analyst</li>
<li>Security Operations Center (SOC) Analyst</li>
<li>AI Security Engineer</li>
<li>AI Agent Developer</li>
<li>Automation Engineer</li>
<li>Threat Intelligence Analyst</li>
<li>Vulnerability Analyst</li>
<li>Incident Response Analyst</li>
<li>Network Security Engineer</li>
<li>Information Security Officer</li>
<li>Security Compliance Auditor</li>
<li>IT Governance and Risk Specialist</li>
<li>Security Administrator</li>
<li>Cloud Security Engineer</li>
<li>DevSecOps Engineer</li>
<li>IT Manager</li>
<li>Digital Transformation Specialist</li>
</ul>'
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------------ 10. prerequisite
-- This blob ALSO holds the promo code, entry requirements and hardware note --
-- NEVER rewrite it wholesale. Replace ONLY the "TBD" software placeholder.
--
-- Byte-probed: this blob uses CRLF (0D0A) line endings, so a multi-line
-- REPLACE() target written with bare LF silently no-ops. The target is kept to
-- a SINGLE line so no line-ending bytes appear inside it at all.
-- (memory: feedback_multiline_replace_fails_on_crlf_blobs)
UPDATE catalog_product_entity_text
   SET value = REPLACE(
        value,
        '<p>TBD</p>',
        '<ul><li>OpenClaw</li><li>Hermes Agent</li></ul><p>Installation instructions will be provided before the class.</p>')
 WHERE entity_id = @e AND attribute_id = @a_pre AND store_id = 0 AND @e IS NOT NULL
   AND LOCATE('<p>TBD</p>', value) > 0;

-- ----------------------------------------------------------- 6. trainerprofile
-- Each bio is two paragraphs: para 1 = career CREDENTIALS (real facts about the
-- trainer -- kept verbatim, rewriting them would falsify the bio), para 2 = a
-- course-teaching claim scoped to the OLD Pearson VUE certification. Only the
-- claim paragraphs are retargeted, one exact-string REPLACE() each.
--
-- Byte-probed: the dash in "IT Specialist - Cybersecurity" is a LITERAL UTF-8
-- en-dash (U+2013), NOT the &ndash; entity -- writing the entity here would
-- make both REPLACE()s silently no-op. Each target is one whole <p> on a single
-- source line, so the blob's CRLF line endings never fall inside a target.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        '<p data-start="914" data-end="1393">In the Pearson VUE Certified IT Specialist – Cybersecurity course, Achim brings a wealth of real-world experience in threat detection and incident management. His training focuses on developing practical skills in network defense, vulnerability analysis, and forensic investigation. Learners benefit from his structured, hands-on approach to mastering cybersecurity fundamentals and implementing effective strategies to protect enterprise environments against evolving threats.</p>',
        '<p data-start="914" data-end="1393">In the AI Agent Cybersecurity course, Achim brings a wealth of real-world experience in threat detection and incident management. His training focuses on deploying autonomous AI agents for security event monitoring, log analysis, and vulnerability assessment. Learners benefit from his structured, hands-on approach to building agentic security workflows and implementing effective guardrails that protect enterprise environments against evolving threats.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        '<p data-start="2021" data-end="2518">In this course, Agus guides learners through the principles of cybersecurity architecture and defense strategies, focusing on hands-on implementation of security controls across enterprise and cloud environments. His sessions emphasize practical problem-solving, risk mitigation, and adherence to international cybersecurity standards. Through his mentorship, participants gain both the theoretical foundation and applied skills needed to manage modern cyber threats confidently and effectively.</p>',
        '<p data-start="2021" data-end="2518">In this course, Agus guides learners through the principles of agentic cybersecurity operations, focusing on hands-on configuration of AI agents with the right tools, permissions, and sandboxing across enterprise and cloud environments. His sessions emphasize practical problem-solving, risk prioritization, and adherence to international cybersecurity standards. Through his mentorship, participants gain both the theoretical foundation and applied skills needed to manage modern cyber threats confidently and effectively.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        '<p data-start="3210" data-end="3745">In the Pearson VUE Certified IT Specialist – Cybersecurity course, Danny draws from his extensive industry experience to help learners build competence in secure network architecture, cloud security, and risk management. His sessions integrate theory with practical cybersecurity simulations, preparing participants to detect, analyze, and respond to real-world security incidents. Through his engaging facilitation, learners gain the confidence and technical foundation required to excel in cybersecurity practice and certification.</p>',
        '<p data-start="3210" data-end="3745">In the AI Agent Cybersecurity course, Danny draws from his extensive industry experience to help learners build competence in secure agent design, cloud security, and risk management. His sessions integrate theory with practical agentic security simulations, preparing participants to detect, analyze, and respond to real-world security incidents with human-in-the-loop oversight. Through his engaging facilitation, learners gain the confidence and technical foundation required to excel in modern cybersecurity practice.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id = 0 AND @e IS NOT NULL;

-- Terence Ee and Praveen Dayal's second paragraphs describe their general WSQ
-- teaching practice (leadership / IT governance / cybersecurity governance) and
-- never name the Pearson VUE track -- left verbatim, they remain accurate.

-- The store-1 trainerprofile override is stale Arduino/IoT-era content (Shawn
-- Koh, Man Guo Chang -- IoT and semiconductor trainers) left over from a much
-- earlier repurpose of entity 346. It SHADOWS the store-0 cybersecurity
-- trainers, so the storefront currently shows the wrong people entirely.
DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id <> 0 AND @e IS NOT NULL;

-- ------------------------------------------- 12. learning_outcomes cms_block
-- The block already exists; guarded-INSERT first anyway so a rebuilt DB
-- converges (915/931 shape).
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2025053228 - Learning Outcomes', 'course_TGS-2025053228_learning_outcomes', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM cms_block) b
                    WHERE b.identifier = 'course_TGS-2025053228_learning_outcomes');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
 WHERE b.identifier = 'course_TGS-2025053228_learning_outcomes' AND @e IS NOT NULL;

UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Establish organizational cybersecurity policies and procedures to protect information confidentiality and integrity.</li>
<li>LO2: Ensure adherence to cybersecurity policies and procedures in response to evolving security developments.</li>
<li>LO3: Continuously improve cybersecurity policies and procedures to enhance organizational security measures.</li>
</ul>',
       is_active = 1,
       update_time = NOW()
 WHERE identifier = 'course_TGS-2025053228_learning_outcomes' AND @e IS NOT NULL;

-- ------------------------------------------------------------ 13. categories
-- DROP: the course is no longer a Pearson VUE certification exam-prep course.
--   182 Certification Exam Prep
--   402 IT Specialists Exam Prep
--   435 Pearson VUE Certification Exam Prep
-- Deletes MUST be mirrored into catalog_category_product_index or the
-- storefront listing never changes.
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (182, 402, 435) AND @e IS NOT NULL;
DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (182, 402, 435) AND @e IS NOT NULL;

-- ADD: the AI series categories this course now belongs to.
--   214 AI Security Series   (under 252 AI Courses)
--   415 AI Agents Series     (under 252 AI Courses)
--   196 WSQ Agentic AI Courses (under 325 WSQ AI Courses)
--   325 WSQ AI Courses       (under 292 WSQ Funded Courses)
--   252 AI Courses           (top-level AI hub)
-- position 0 => the nightly category-ordering sweep slots it correctly.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.category_id, @e, 0
  FROM (SELECT 214 AS category_id UNION ALL SELECT 415 UNION ALL SELECT 196
        UNION ALL SELECT 325 UNION ALL SELECT 252) c
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity ce WHERE ce.entity_id = c.category_id);

-- Mirror into the index so the storefront listing picks it up before the next
-- full reindex. store_id 1 = SG; is_parent 1 for a direct assignment.
INSERT IGNORE INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT c.category_id, @e, 0, 1, 1,
       (SELECT i.value FROM catalog_product_entity_int i
         WHERE i.entity_id = @e AND i.store_id = 0
           AND i.attribute_id = (SELECT attribute_id FROM eav_attribute
                                  WHERE entity_type_id = 4 AND attribute_code = 'visibility')
         LIMIT 1)
  FROM (SELECT 214 AS category_id UNION ALL SELECT 415 UNION ALL SELECT 196
        UNION ALL SELECT 325 UNION ALL SELECT 252) c
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity ce WHERE ce.entity_id = c.category_id);
