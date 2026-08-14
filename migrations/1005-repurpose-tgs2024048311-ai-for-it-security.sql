-- 1005: Repurpose TGS-2024048311
--   "WSQ - Administering Information Protection and Compliance in Microsoft 365 (SC-400)"
--     -> "WSQ - AI for IT Security"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-14: pivot from the Microsoft SC-400
-- certification track to AI-assisted security monitoring, threat detection,
-- data protection, phishing/malware analysis and incident response.
--
-- Sibling of 955 (TGS-2023039344 -> "AI for IT Security Professionals") and
-- 1002 (TGS-2023039177 -> "AI for Cyber Security") -- same shape.
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope), meta_title,
-- meta_description, meta_keyword, short_description, description (24 Microsoft
-- Purview topics -> the 4 supplied topics; LSN_DATA JSON added in sync with the
-- visible markup), trainerprofile (all five bios name Microsoft 365 / SC-400 in
-- their teaching paragraph), whoshouldattend (one Microsoft-specific role),
-- image/small_image/thumbnail labels, media-gallery label, the learning_outcomes
-- cms/block, a 301 for the old bare slug, and category placement (add AI Courses
-- 252; drop the four Microsoft/Azure-specific listings), mirrored into
-- catalog_category_product_index.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * course_TGS-2024048311_skills_framework -- Data Governance ICT-SNA-4008-1.1
--     still describes the course; the four supplied LOs are the SAME accredited
--     outcomes with "with Microsoft Purview" removed, so the standard holds.
--   * course_TGS-2024048311_certification / _funding_and_grant / _brochure --
--     keyed on the SKU; the fee table and OpenCerts wording are unaffected.
--   * prerequisite / additional_note -- funding apparatus and logistics.
--   * assessment_methods -- unchanged assessment mode.
--   * badge tags (WSQ, SkillsFuture Credit, PSEA, UTAP, SFEC, MCES, Absentee
--     Payroll) -- funding eligibility is unchanged by the content pivot.
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url.
--   * cover PNG (course_image_url) -- re-rendered out of band from the admin.
--   * Categories 161 (IT Security), 301 (WSQ IT & Security Courses), 99 (Data
--     Management), 399 (Data Governance), 55 (Infocomm Technology), 182
--     (Certification Exam Prep -- the broad parent; the course still carries a
--     WSQ Statement of Achievement), and the WSQ/all-courses listings -- they
--     describe the NEW content correctly.
--
-- LEARNING OUTCOMES: the live LOs name Microsoft Purview explicitly in LO1 and
-- LO3. The supplied LOs are the same four outcomes de-Purview'd, matching what
-- the admin registered.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024048311' LIMIT 1);

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
   SET value = 'WSQ - AI for IT Security'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. SEO meta
-- meta_title: plain title. MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs
-- and appends the brand postfix at render time -- baking either in duplicates it.
-- Live rows exist at store 0 AND store 1, so no store_id filter here.
UPDATE catalog_product_entity_varchar
   SET value = 'AI for IT Security'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Learn to apply AI to identify, assess and respond to cybersecurity threats. Covers security log analysis, sensitive data classification, phishing and malware detection, data loss prevention and compliance monitoring. Enjoy up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'AI for IT security, AI threat detection, AI security monitoring, AI security log analysis, AI phishing detection, AI malware analysis, sensitive data classification, data loss prevention, AI incident response, security policy development, compliance monitoring, prompt injection, adversarial attacks, WSQ cybersecurity course'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. URL key
-- Delete url_path at EVERY scope so the Catalog URL Rewrites indexer regenerates
-- it; a surviving store-scoped row shadows the new URL.
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-ai-for-it-security'
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Remove any non-system squatter on the new path before inserting the 301,
-- so the INSERT IGNORE below cannot silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-ai-for-it-security.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the category paths).
-- NOTE: the old bare slug is held by this product's SYSTEM rewrite
-- (id_path 'product/<e>', is_system = 1), so a plain INSERT IGNORE silently
-- no-ops against the unique key on (request_path, store_id). Convert that row
-- in place into a permanent redirect instead; the indexer then mints a fresh
-- system row for the NEW slug.
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-for-it-security.html',
       is_system   = 0,
       options     = 'RP'
 WHERE request_path = 'wsq-administering-information-protection-and-compliance-in-microsoft-365-sc-400.html'
   AND id_path = CONCAT('product/', @e)
   AND @e IS NOT NULL;

-- Belt-and-braces for any store that had no system row on the old slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('TGS-2024048311-rp-1005-', s.store_id),
       'wsq-administering-information-protection-and-compliance-in-microsoft-365-sc-400.html',
       'wsq-ai-for-it-security.html',
       0, 'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- ------------------------------------------------- 4. Image alt text
-- Plain title (no "WSQ - " prefix): the cover itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'AI for IT Security'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'AI for IT Security'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------ 5. Topics Covered (description + JSON)
-- The visible <p><strong>Topic N</strong></p> markup and the LSN_DATA JSON
-- comment must stay in sync. The 24 Microsoft Purview topics (with
-- <h3 class="course-topic-h3">/<ul> subsections) are replaced wholesale by the
-- four supplied topics -- topic-level only, so subsecs are empty. Four topics --
-- matches LO1-LO4.
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: AI-Assisted Data Privacy Policies and Lifecycle Management","subsecs":[]},{"title":"Topic 2: AI for Sensitive Data Discovery, Classification and Protection","subsecs":[]},{"title":"Topic 3: AI-Powered Data Access, Transfer and Security Governance","subsecs":[]},{"title":"Topic 4: AI-Assisted Compliance Monitoring and Data Breach Investigation","subsecs":[]}] -->
<p><strong>Topic 1: AI-Assisted Data Privacy Policies and Lifecycle Management</strong></p>
<p><strong>Topic 2: AI for Sensitive Data Discovery, Classification and Protection</strong></p>
<p><strong>Topic 3: AI-Powered Data Access, Transfer and Security Governance</strong></p>
<p><strong>Topic 4: AI-Assisted Compliance Monitoring and Data Breach Investigation</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 6. About This Course (sdesc)
-- Full replace: the live short_description carries two Microsoft-partner tails
-- ("Microsoft Learning Partner" Org ID + "Certification Exam at Pearson Vue"
-- with a Microsoft certification deep link and an exam-voucher cross-sell). Both
-- are dead once the course stops preparing learners for the SC-400 exam, so the
-- whole attribute is replaced with the supplied prose. No <h2>Course Brochure</h2>
-- tail here (that lives in the _brochure cms/block), so nothing else is lost.
UPDATE catalog_product_entity_text
   SET value = '<p>AI for IT Security equips participants with practical skills to apply artificial intelligence to identify, assess, and respond to cybersecurity threats. The course explores how AI can support security monitoring, detect suspicious activities, analyze vulnerabilities, classify sensitive information, and improve incident response across organizational IT environments.</p>
<p>Participants will learn to use AI tools to analyze security logs, identify unusual patterns, summarize threat intelligence, evaluate potential risks, and generate recommended remediation actions. The course also covers AI-assisted data protection, access control, phishing detection, malware analysis, data loss prevention, security policy development, and compliance monitoring.</p>
<p>Through hands-on activities, learners will apply AI to realistic security scenarios, automate repetitive security tasks, investigate potential incidents, and produce clear security reports. Emphasis is placed on validating AI-generated findings, protecting confidential data, managing false positives, maintaining human oversight, and addressing risks such as prompt injection and adversarial attacks. By the end of the course, participants will be able to use AI responsibly to strengthen threat detection, accelerate security operations, and improve their organisation&rsquo;s overall cybersecurity posture.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- -------------------------------------------------- 7. Learning Outcomes block
-- The live block names Microsoft Purview in LO1 ("...guidelines with Microsoft
-- Purview") and LO3 ("Oversee organizational data transfers with Microsoft
-- Purview..."). The supplied LO1-LO4 are the SAME four accredited outcomes with
-- the Purview qualifier removed, so the Data Governance ICT-SNA-4008-1.1
-- standard still holds and the skills_framework block stays untouched.
UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Roll out organization-wide adherence to data privacy and develop data lifecycle management guidelines.</li>
<li>LO2:&nbsp;Communicate internal data management standards and ensure acquisition of necessary data handling approvals.</li>
<li>LO3:&nbsp;Oversee organizational data transfers in accordance with required approvals and ethical guidelines.</li>
<li>LO4:&nbsp;Monitor compliance with data policies and investigate indicators of potential data breaches systematically.</li>
</ul>'
 WHERE identifier = 'course_TGS-2024048311_learning_outcomes';

-- -------------------------------------------------------- 8. Trainer bios
-- Five bios, each two paragraphs: para 1 = career CREDENTIALS -- FACTS, left
-- untouched (the Microsoft/ICT experience the trainers actually have stays
-- accurate). Para 2 = a course-teaching claim naming Microsoft 365 compliance /
-- SC-400 -- every one is retargeted to the new subject.
-- Single-line REPLACE() on the full paragraph string (a multi-line pattern
-- no-ops against the WYSIWYG blob's CRLF line endings).

-- Sanjiv Venkatram
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this WSQ course, Sanjiv focuses on implementing Microsoft 365 compliance solutions, sensitivity labels, and data loss prevention policies. His teaching emphasizes hands-on practice and workplace applications, preparing learners to manage compliance requirements effectively.',
       'In this WSQ course, Sanjiv focuses on applying AI to sensitive data discovery, classification, and data loss prevention. His teaching emphasizes hands-on practice and workplace applications, preparing learners to use AI to protect organizational data and manage compliance requirements effectively.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Alec Tan
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'For this program, Alec trains learners in configuring Microsoft 365 compliance tools, managing insider risk, and implementing information governance frameworks. His sessions are applied and certification-focused, ensuring participants gain confidence in both theory and practice.',
       'For this program, Alec trains learners in using AI to monitor security activity, manage insider risk, and implement data governance and access-control practices. His sessions are applied and scenario-driven, ensuring participants gain confidence in both theory and practice.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Kishan Raaj
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this SC-400 course, Kishan guides learners in managing information protection policies, compliance reporting, and secure data lifecycles. His sessions are interactive and technically rigorous, equipping learners to apply compliance skills directly in organizational environments.',
       'In this course, Kishan guides learners in using AI to analyze security logs, investigate potential incidents, and produce clear security reports. His sessions are interactive and technically rigorous, equipping learners to apply AI-assisted security skills directly in organizational environments.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Quah Chee Yong
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'For this program, Quah emphasizes Microsoft 365 information governance and risk management practices, showing learners how to apply compliance solutions to safeguard organizational data. His sessions highlight practical use cases and workplace relevance, ensuring skills transfer into real business contexts.',
       'For this program, Quah emphasizes AI-assisted risk assessment and security governance practices, showing learners how to evaluate potential risks and safeguard organizational data. His sessions highlight practical use cases and workplace relevance, ensuring skills transfer into real business contexts.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Peter Cheong
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this WSQ program, Peter trains learners on compliance center configuration, audit logging, and records management in Microsoft 365. His teaching style is solution-driven and applied, ensuring participants can confidently implement compliance frameworks in their workplaces.',
       'In this WSQ program, Peter trains learners on AI-assisted phishing and malware analysis, audit log review, and compliance monitoring. His teaching style is solution-driven and applied, ensuring participants can validate AI-generated findings and maintain human oversight in their workplaces.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------ 8b. Who Should Attend
-- 20 roles, 19 of them generic security / compliance / IT titles that still fit
-- an AI-for-IT-security course. Only "Microsoft 365 Compliance Specialist" names
-- the retired product; retarget it rather than dropping the row.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li>Microsoft 365 Compliance Specialist</li>',
       '<li>Cybersecurity Analyst</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

-- ----------------------------------------------------- 9. Category placement
-- The repurpose changes the SUBJECT: the course is no longer about Microsoft 365
-- and no longer prepares learners for the SC-400 exam, so drop the four
-- Microsoft/Azure-specific listings:
--   135 "Microsoft Certification Exam Prep"   358 "Microsoft Certification Exam Prep"
--   411 "Azure Certification"                  72 "WSQ Media & Marketing Courses"
-- (72 was never right for a compliance course and is plainly wrong for an
-- IT-security one), plus 293 "WSQ Mfg & Green Courses" -- likewise unrelated.
-- Join 252 "AI Courses", the master listing every AI course belongs to.
-- The security / data listings (55, 99, 161, 301, 399), the broad 182
-- "Certification Exam Prep" parent, the WSQ listings (15, 292, 345) and
-- 3 "All Courses" all stay -- they describe the NEW content correctly.
-- Both sides mirrored into catalog_category_product_index or the storefront
-- listings never change.
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (72, 135, 293, 358, 411) AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (72, 135, 293, 358, 411) AND @e IS NOT NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 252, @e, COALESCE((SELECT MAX(position) FROM catalog_category_product WHERE category_id = 252), 0) + 1
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = 252);

INSERT IGNORE INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT 252, @e, cp.position, 1, s.store_id, 4
  FROM catalog_category_product cp
  CROSS JOIN core_store s
 WHERE cp.category_id = 252 AND cp.product_id = @e AND s.store_id > 0 AND @e IS NOT NULL;
