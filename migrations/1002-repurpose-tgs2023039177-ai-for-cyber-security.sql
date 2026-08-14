-- 1002: Repurpose TGS-2023039177
--   "WSQ - Microsoft Cybersecurity Architect (SC-100) Training"
--     -> "WSQ - AI for Cyber Security"
-- SKU unchanged (all SkillsFuture / SFEC / SFC / PSEA / PSEA deep links and the
-- registered Skills Framework competency stay valid).
--
-- This is a repurpose AWAY from a certification brand: the course no longer
-- preps the Microsoft SC-100 exam, so the Microsoft Learning Partner / Pearson
-- VUE / exam-voucher sections and the Microsoft & Azure certification-exam
-- categories are DROPPED (feedback_repurpose_away_from_certification_brand).
--
-- Surfaces touched (per the TGS- rename checklist, driven by an EAV sweep of
-- BOTH value tables for the old title AND the tech words
-- "Microsoft"/"SC-100"/"Azure"/"Pearson"/"Architect"):
--   1  name
--   2  meta_title      (plain title: MMD_Seotitle prepends "WSQ funded" and
--                       appends the brand postfix at render time -- the live
--                       value baked BOTH in, so this is also a cleanup)
--   3  url_key + url_path deleted at EVERY scope + explicit 301 for old slug
--   4  short_description -> About This Course prose ONLY (the Microsoft
--                           Learning Partner / Pearson VUE / exam-voucher
--                           sections are DROPPED)
--   5  image/small_image/thumbnail _label + media-gallery label + cover URL
--   6  trainerprofile   (the course-teaching claim paragraph per trainer;
--                        career credentials kept verbatim)
--   7  meta_description
--   8  meta_keyword
--   9  whoshouldattend  (job roles named the retired certification track)
--  11  description      (Course Outline: the 4 admin-supplied topics)
--  12  learning_outcomes cms_block (already matches the supplied LOs -- the
--                        UPDATE is a no-op reassert so a rebuilt DB converges)
--  14  categories: drop Microsoft / exam-prep / Azure (11, 135, 182, 358, 411),
--                  add AI Courses (252), AI Security Series (214) and
--                  WSQ AI Courses (325)
--                  -- both mirrored into catalog_category_product_index
--
-- Deliberately NOT touched:
--   - `image`/`small_image`/`thumbnail` filesystem paths (they are file paths,
--     not display text; renaming them 404s the PNG -- the storefront renders
--     the R2 `course_image_url` cover instead).
--   - `prerequisite`: the ONE tech reference is a free Microsoft Account
--     signup under "Minimum Software/Hardware Requirement". Retargeted to a
--     generic AI-tool account line; the rest of the blob (PWM, eligibility
--     table, SkillsFuture / PSEA / SFEC / UTAP deep links, appeal process) is
--     NEVER rewritten wholesale.
--   - the skills_framework / certification / funding_and_grant cms_blocks: the
--     Skills Framework code (Security Strategy ICT-SNA-4021-1.1) is registered
--     against the UNCHANGED SKU and still describes the competency delivered;
--     the funding block carries no old-title string (probed).
--   - the WSQ funding table + fee figures (price unchanged at $2,000).
--   - the funding badge tags (WSQ / SkillsFuture Credit / PSEA / UTAP / SFEC /
--     Absentee Payroll / MCES) -- funding eligibility is unchanged.
--
-- SLUG NOTE: the clean slug `ai-for-cyber-security` is ALREADY OWNED by the
-- live non-WSQ twin C434 "AI for Cyber Security" (status = enabled, $350).
-- This WSQ course therefore takes the `wsq-` prefixed slug -- taking the bare
-- slug would collide and mint a `-618` suffix
-- (feedback_repurpose_target_name_may_already_exist_as_live_twin).
--
-- Idempotent: every write is guarded (LOCATE probes / ON DUPLICATE KEY UPDATE /
-- NOT EXISTS), so a re-run converges.
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => all
-- statements are guarded no-ops there (never a NULL entity_id INSERT).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023039177' LIMIT 1);

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
SET @a_ciu    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

-- ------------------------------------------------------------------ 1. name
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - AI for Cyber Security'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------- 2. meta_title (plain)
-- The live value was "WSQ Microsoft Cybersecurity Architect Certification Prep
-- | Advance Your Skills Now | Tertiary Courses Singapore" -- it baked in BOTH
-- the WSQ token and the brand postfix that MMD_Seotitle adds at render time,
-- yielding "WSQ funded WSQ ... | Tertiary Courses Singapore". Fixed here.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @e, 'AI for Cyber Security'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND store_id <> 0 AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. url_key + 301
-- Collision check done: C434 (live, enabled) owns 'ai-for-cyber-security', so
-- this course takes the wsq- prefixed slug. Probed: nothing owns
-- 'wsq-ai-for-cyber-security' (TGS-2025053228 owns 'wsq-ai-agent-cybersecurity').
SET @old_slug := 'wsq-microsoft-cybersecurity-architect-sc-100-training';
SET @new_slug := 'wsq-ai-for-cyber-security';

-- Remove any is_system = 0 squatter on the new path first: INSERT IGNORE
-- silently no-ops against a stale row.
DELETE FROM core_url_rewrite
 WHERE request_path = CONCAT(@new_slug, '.html') AND is_system = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = @new_slug
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL Rewrites indexer regenerates it;
-- the store-1 row still holds the OLD slug and would shadow the new URL
-- (this course HAS a store-1 url_path row -- confirmed by probe).
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the category
-- paths from its own rewrite history, but not this one).
INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options)
SELECT 1, NULL, @e, CONCAT('product/', @e, '/rp-1002'), CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'), 0, 'RP'
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                    WHERE x.request_path = CONCAT(@old_slug, '.html') AND x.store_id = 1);

-- ---------------------------------------------- 4. short_description (About)
-- Admin-supplied prose. The old value also carried "<h2>Microsoft Learning
-- Partner</h2>" and "<h2>Certification Exam at Pearson Vue</h2>" plus the
-- Microsoft Role-Based Exam Voucher link -- ALL dropped: the repurposed course
-- does not prepare for the SC-100 exam, so keeping them would advertise a
-- voucher and a testing-centre pathway that are no longer part of the course.
UPDATE catalog_product_entity_text
   SET value = '<p>AI for Cyber Security equips participants with practical knowledge of how artificial intelligence is transforming cyber defence, threat detection, security analysis, and incident response. The course explores how AI can process large volumes of security data, identify unusual behaviour, detect emerging threats, and support faster, more informed security decisions.</p>
<p>Participants will learn to apply AI tools to analyze system and network logs, identify indicators of compromise, assess vulnerabilities, detect phishing and malicious activities, and summarize threat intelligence. They will also explore how AI can assist with attack-pattern recognition, risk prioritization, incident investigation, response planning, and the automation of repetitive security tasks.</p>
<p>The course examines both the defensive and malicious uses of AI, including AI-generated phishing, automated cyberattacks, deepfakes, adversarial techniques, and attacks targeting AI systems. Through hands-on security scenarios, learners will practise evaluating AI-generated findings, reducing false positives, protecting sensitive information, and maintaining appropriate human oversight. By the end of the course, participants will understand how to use AI responsibly to strengthen cyber threat analysis, improve incident response, and enhance organizational cyber resilience.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- Any store-scoped short_description override would shadow store 0.
DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id <> 0 AND @e IS NOT NULL;

-- ------------------------------------------------ 11. description (Outline)
-- The old value was the SC-100 exam syllabus: a stale LSN_DATA JSON comment
-- plus ~150 <p><em> sub-bullet lines (several carrying U+FFFD replacement
-- bytes from a legacy latin1 write). Replaced wholesale with the four
-- admin-supplied topic headings, in the house
-- <h3 class="course-topic-h3"> shape and topic-headings-only form
-- (migrations 960/967/999 trimmed other TGS- outlines the same way).
UPDATE catalog_product_entity_text
   SET value = '<h3 class="course-topic-h3">Topic 1: AI-Assisted Security Risk, Threat and Control-Gap Analysis</h3>
<h3 class="course-topic-h3">Topic 2: Designing AI-Powered Cybersecurity Programmes</h3>
<h3 class="course-topic-h3">Topic 3: Developing AI-Driven Security Architecture and Action Plans</h3>
<h3 class="course-topic-h3">Topic 4: Monitoring, Evaluating and Governing AI Security Solutions</h3>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id <> 0 AND @e IS NOT NULL;

-- ------------------------------------------------------- 7. meta_description
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @e, 'Apply AI to cyber threat detection, log analysis, incident response and security governance. WSQ-accredited course with up to 70% funding subsidy. Enrol now.'
 WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND store_id <> 0 AND @e IS NOT NULL;

-- ----------------------------------------------------------- 8. meta_keyword
UPDATE catalog_product_entity_text
   SET value = 'AI for Cyber Security, AI Threat Detection, AI Security Operations, Cybersecurity AI, Incident Response, Threat Intelligence, WSQ, WSQ Funding Subsidy'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- ------------------------------------------------------- 5. cover alt labels
-- Plain title (no "WSQ - " prefix): the cover image itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'AI for Cyber Security'
 WHERE entity_id = @e AND attribute_id IN (@a_il, @a_sil, @a_tl) AND @e IS NOT NULL;

-- The media-gallery per-image label renders as the zoom gallery's img
-- title/alt -- it is the REAL alt text, not the three *_label attrs above
-- (feedback_media_gallery_label_is_the_real_alt_text).
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'AI for Cyber Security'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- Fresh branded cover PNG (rendered from the NEW title, badges preserved:
-- WSQ / SkillsFuture Credit / PSEA / UTAP / SFEC / Absentee Payroll / MCES)
-- and uploaded to R2. Without this the storefront keeps serving the cover
-- baked with the OLD course title.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023039177-20260814-130218.png'
 WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Store-scoped covers would shadow the store-0 value above.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0 AND @e IS NOT NULL;

-- --------------------------------------------------------- 9. whoshouldattend
-- The old list was built around the SC-100 certification track
-- ("Cybersecurity Architect", "Security Solutions Architect"). Re-pointed at
-- AI-assisted security equivalents; the genuinely tool-neutral roles are kept.
UPDATE catalog_product_entity_text
   SET value = '<ul>
<li>Security Analyst</li>
<li>SOC Analyst</li>
<li>Information Security Analyst</li>
<li>Threat Intelligence Analyst</li>
<li>Incident Responder</li>
<li>Cybersecurity Engineer</li>
<li>Network Security Engineer</li>
<li>IT Security Manager</li>
<li>Security Consultant</li>
<li>IT Manager</li>
<li>Systems Administrator</li>
<li>Risk Manager</li>
<li>Compliance Officer</li>
<li>Security Researcher</li>
<li>Security professional adopting AI-assisted workflows</li>
</ul>'
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------------ 10. prerequisite
-- This blob ALSO holds the entire funding apparatus (PWM, eligibility table,
-- SkillsFuture / PSEA / SFEC / UTAP deep links, appeal process) -- NEVER
-- rewrite it wholesale. Replace ONLY the <p> holding the Microsoft Account
-- signup line. Byte-probed: single-line, no CRLF inside this <p>.
UPDATE catalog_product_entity_text
   SET value = REPLACE(
        value,
        '<p>Sign up for a free <span style="text-decoration: underline;"><a href="https://account.microsoft.com/" target="_blank">Microsoft Account</a></span></p>',
        '<p>Sign up for a free <span style="text-decoration: underline;"><a href="https://chatgpt.com/" target="_blank">AI assistant account</a></span> (e.g. ChatGPT, Claude or Gemini)</p>')
 WHERE entity_id = @e AND attribute_id = @a_pre AND store_id = 0 AND @e IS NOT NULL
   AND LOCATE('account.microsoft.com', value) > 0;

-- ----------------------------------------------------------- 6. trainerprofile
-- The blob renders the Trainers tab: courses_trainers holds no bio for any of
-- these five names (probed), so this blob is the LIVE source, not dormant
-- (feedback_trainer_bio_renders_from_courses_trainers_not_trainerprofile).
--
-- Each bio is exactly two paragraphs: para 1 = career CREDENTIALS (real facts
-- about each trainer's security background -- kept verbatim, rewriting them
-- would falsify the bio), para 2 = a course-teaching claim naming the OLD
-- course. Only the claim paragraphs are retargeted, one exact-string
-- REPLACE() each. Byte-probed: each claim paragraph is a single line.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        '<p>In &ldquo;Microsoft Cybersecurity Architect (SC-100) Training,&rdquo; Sivanesan draws on his expertise in enterprise security architecture and governance to guide learners through advanced defense strategies using Microsoft technologies. His sessions emphasize risk mitigation, zero-trust frameworks, and integrated cloud security architecture. Through hands-on case studies, he equips participants to design, evaluate, and maintain resilient cybersecurity systems aligned with organizational goals and compliance requirements.</p>',
        '<p>In &ldquo;AI for Cyber Security,&rdquo; Sivanesan draws on his expertise in enterprise security architecture and governance to guide learners through AI-assisted risk, threat and control-gap analysis. His sessions emphasize risk prioritization, security programme design, and the governance of AI security solutions. Through hands-on case studies, he equips participants to design, evaluate, and maintain resilient cybersecurity systems aligned with organizational goals and compliance requirements.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        '<p>In &ldquo;Microsoft Cybersecurity Architect (SC-100) Training,&rdquo; Achim leverages his international experience to help learners understand and implement advanced cybersecurity strategies. His teaching covers enterprise security posture management, cloud security architecture, and identity governance. Through a blend of technical insights and real-world best practices, he prepares professionals to architect secure, scalable, and compliant systems across Microsoft environments.</p>',
        '<p>In &ldquo;AI for Cyber Security,&rdquo; Achim leverages his international experience to help learners apply AI to threat detection and security analysis. His teaching covers AI-assisted log and vulnerability analysis, security posture management, and the evaluation of AI-generated findings. Through a blend of technical insights and real-world best practices, he prepares professionals to use AI responsibly to strengthen organizational cyber resilience.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        '<p>In &ldquo;Microsoft Cybersecurity Architect (SC-100) Training,&rdquo; Agus focuses on helping learners design secure enterprise architectures aligned with Microsoft&rsquo;s cloud security principles. His training covers advanced topics such as zero-trust implementation, workload protection, and hybrid identity management. By combining technical expertise with real-world project experience, Agus ensures participants develop the skills needed to architect secure and resilient digital environments.</p>',
        '<p>In &ldquo;AI for Cyber Security,&rdquo; Agus focuses on helping learners apply AI to security operations and incident response. His training covers advanced topics such as attack-pattern recognition, indicator-of-compromise identification, and the automation of repetitive security tasks. By combining technical expertise with real-world project experience, Agus ensures participants develop the skills needed to build secure and resilient digital environments.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        '<p>In &ldquo;Microsoft Cybersecurity Architect (SC-100) Training,&rdquo; Danny helps learners master the core principles of Microsoft&rsquo;s enterprise security architecture. His sessions emphasize practical implementation of threat protection, information governance, and security monitoring across Azure and Microsoft 365. Through real-world examples and interactive discussions, he prepares participants to apply cybersecurity architecture frameworks effectively in professional settings.</p>',
        '<p>In &ldquo;AI for Cyber Security,&rdquo; Danny helps learners master the core principles of AI-assisted cyber defence. His sessions emphasize practical implementation of threat protection, phishing and malicious-activity detection, and security monitoring. Through real-world examples and interactive discussions, he prepares participants to apply AI-driven security practices effectively in professional settings.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        '<p>In &ldquo;Microsoft Cybersecurity Architect (SC-100) Training,&rdquo; Truman focuses on helping learners develop a holistic understanding of Microsoft&rsquo;s cybersecurity architecture and its integration across hybrid and cloud environments. His sessions highlight threat modeling, governance, and incident response planning within the Microsoft ecosystem. By merging strategic and technical perspectives, he equips professionals with the knowledge and frameworks needed to design, secure, and manage complex enterprise infrastructures.</p>',
        '<p>In &ldquo;AI for Cyber Security,&rdquo; Truman focuses on helping learners develop a holistic understanding of how AI is applied across cyber threat analysis and defence. His sessions highlight threat modeling, AI governance, and incident response planning, including the malicious uses of AI such as automated attacks and deepfakes. By merging strategic and technical perspectives, he equips professionals with the knowledge and frameworks needed to design, secure, and manage complex enterprise infrastructures.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------- 12. learning_outcomes cms_block
-- Guarded-INSERT first, then UPDATE, so a re-run converges even if the block
-- is ever absent on a given instance (915/931/952 shape).
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2023039177 - Learning Outcomes', 'course_TGS-2023039177_learning_outcomes', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM cms_block) b
                    WHERE b.identifier = 'course_TGS-2023039177_learning_outcomes');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
 WHERE b.identifier = 'course_TGS-2023039177_learning_outcomes' AND @e IS NOT NULL;

-- The four SSG-accredited outcomes registered against the UNCHANGED SKU. These
-- already match the admin-supplied LOs verbatim, so on the live SG DB this is
-- a no-op reassert; it exists so a rebuilt DB converges to the same state.
UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Identify security risks, threats, and assess gaps in controls impacting business processes.</li>
<li>LO2: Translate security objectives into specific programmes considering security programme design techniques.</li>
<li>LO3: Develop a detailed action plan for security programmes in line with information security architectures.</li>
<li>LO4: Deliver advice for adoption of security architectures, monitoring their effectiveness against standards.</li>
</ul>',
       is_active = 1,
       update_time = NOW()
 WHERE identifier = 'course_TGS-2023039177_learning_outcomes' AND @e IS NOT NULL;

-- --------------------------------------------------------- 14. categories
-- Drop: the course no longer runs on Microsoft tooling and no longer preps any
-- certification exam. Every DELETE is mirrored into
-- catalog_category_product_index or the storefront listing never changes.
--   11  Microsoft
--  135  Microsoft Certification Exam Prep
--  182  Certification Exam Prep
--  358  Microsoft Certification Exam Prep (duplicate row)
--  411  Azure Certification
DELETE FROM catalog_category_product       WHERE category_id IN (11, 135, 182, 358, 411) AND product_id = @e AND @e IS NOT NULL;
DELETE FROM catalog_category_product_index WHERE category_id IN (11, 135, 182, 358, 411) AND product_id = @e AND @e IS NOT NULL;

-- Add: mirrors the closest sibling (C434 "AI for Cyber Security", which sits in
-- 252 + 214) plus the WSQ AI listing.
--  214  AI Security Series
--  252  AI Courses
--  325  WSQ AI Courses
-- Appended at MAX(position)+1 so the category-ordering sweep can renumber later.
INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT 214, @e, (SELECT COALESCE(MAX(position), 0) + 1 FROM (SELECT * FROM catalog_category_product) c WHERE c.category_id = 214)
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_product) x
                    WHERE x.category_id = 214 AND x.product_id = @e);

INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT 252, @e, (SELECT COALESCE(MAX(position), 0) + 1 FROM (SELECT * FROM catalog_category_product) c WHERE c.category_id = 252)
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_product) x
                    WHERE x.category_id = 252 AND x.product_id = @e);

INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT 325, @e, (SELECT COALESCE(MAX(position), 0) + 1 FROM (SELECT * FROM catalog_category_product) c WHERE c.category_id = 325)
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_product) x
                    WHERE x.category_id = 325 AND x.product_id = @e);

-- Mirror the adds into the index (store 1, is_parent/visibility matching the
-- product's surviving index rows) so the listing shows the course immediately.
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, 1, 4
  FROM catalog_category_product cp
 WHERE cp.product_id = @e AND cp.category_id IN (214, 252, 325) AND @e IS NOT NULL;
