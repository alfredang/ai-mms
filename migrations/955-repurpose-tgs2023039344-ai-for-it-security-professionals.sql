-- 955: Repurpose TGS-2023039344
--   "WSQ - Microsoft Azure Security Engineer Associate (AZ-500)"
--     -> "WSQ - AI for IT Security Professionals"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-13: pivot from the Microsoft AZ-500
-- certification track to AI-assisted security monitoring, threat detection,
-- vulnerability analysis and incident response.
--
-- Sibling of 950 (TGS-2024052076) and 951 (TGS-2024051414) -- same shape.
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope), meta_title,
-- meta_description, meta_keyword, short_description, description (16 Azure topics
-- -> the 4 supplied topics; LSN_DATA JSON added in sync with the visible markup),
-- trainerprofile (all five bios name AZ-500 in their teaching paragraph),
-- image/small_image/thumbnail labels, media-gallery label, the learning_outcomes
-- cms/block, a 301 for the old bare slug, and category placement (add AI Courses
-- 252; drop the six Microsoft/Azure-specific listings), mirrored into
-- catalog_category_product_index.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * course_TGS-2023039344_skills_framework -- Security Administration
--     ICT-OUS-3012-1.1 still describes the course; the four supplied LOs are the
--     SAME accredited outcomes with "Azure" removed, so the standard still holds.
--   * course_TGS-2023039344_certification / _funding_and_grant / _brochure --
--     keyed on the SKU; the fee table and OpenCerts wording are unaffected.
--   * whoshouldattend -- 15 generic security/IT roles, none Azure- or
--     Microsoft-specific; every one still fits an AI-for-IT-security course.
--   * prerequisite / additional_note -- funding apparatus and logistics.
--   * assessment_methods -- unchanged assessment mode.
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url.
--   * cover PNG (course_image_url) -- re-rendered out of band from the admin.
--   * Categories 161 (IT Security), 364 (WSQ Cyber Security & PDPA), 385 (Cyber
--     Security), 386 (Network Securities), 301 (WSQ IT & Security Courses),
--     182 (Certification Exam Prep -- the broad parent; the course still carries
--     a WSQ Statement of Achievement), and the WSQ/all-courses listings --
--     they describe the NEW content correctly.
--
-- LEARNING OUTCOMES: unlike 951, this block IS rewritten -- the live LOs name
-- Azure explicitly ("Perform Azure system administration"). The supplied LOs are
-- the same four outcomes de-Azure'd, matching what the admin registered.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023039344' LIMIT 1);

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_tprof  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_ilab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------- 1. Title
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - AI for IT Security Professionals'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. SEO meta
-- meta_title: plain title. MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs
-- and appends the brand postfix at render time -- baking either in duplicates it.
UPDATE catalog_product_entity_varchar
   SET value = 'AI for IT Security Professionals'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Learn to apply AI to security monitoring, threat detection, vulnerability analysis and incident response. Covers log analysis, indicators of compromise, identity and access security, risk prioritization and AI-related security risks.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'AI for IT security, AI threat detection, AI security monitoring, AI vulnerability analysis, AI incident response, security log analysis, indicators of compromise, threat intelligence, identity and access security, prompt injection, adversarial attacks, cyber resilience, WSQ cybersecurity course'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. URL key
-- Delete url_path at EVERY scope so the Catalog URL Rewrites indexer regenerates
-- it; a surviving store-scoped row shadows the new URL.
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-ai-for-it-security-professionals'
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Remove any non-system squatter on the new path before inserting the 301,
-- so the INSERT IGNORE below cannot silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-ai-for-it-security-professionals.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the category paths).
-- NOTE: the old bare slug is held by this product's SYSTEM rewrite
-- (id_path 'product/<e>', is_system = 1), so a plain INSERT IGNORE silently
-- no-ops against the unique key on (request_path, store_id). Convert that row
-- in place into a permanent redirect instead; the indexer then mints a fresh
-- system row for the NEW slug.
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-for-it-security-professionals.html',
       is_system   = 0,
       options     = 'RP'
 WHERE request_path = 'wsq-microsoft-azure-security-engineer-associate-az-500.html'
   AND id_path = CONCAT('product/', @e)
   AND @e IS NOT NULL;

-- Belt-and-braces for any store that had no system row on the old slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('TGS-2023039344-rp-955-', s.store_id),
       'wsq-microsoft-azure-security-engineer-associate-az-500.html',
       'wsq-ai-for-it-security-professionals.html',
       0, 'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- ------------------------------------------------- 4. Image alt text
-- Plain title (no "WSQ - " prefix): the cover itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'AI for IT Security Professionals'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'AI for IT Security Professionals'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------ 5. Topics Covered (description + JSON)
-- The visible <p><strong>Topic N</strong></p> markup and the LSN_DATA JSON
-- comment must stay in sync. The 16 Azure topics (with <h3>/<ul> subsections)
-- are replaced wholesale by the four supplied topics -- topic-level only, so
-- subsecs are empty. Four topics -- matches LO1-LO4.
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: AI-Assisted Security Programme Administration and System Updates","subsecs":[]},{"title":"Topic 2: AI for System, Network and Device Security","subsecs":[]},{"title":"Topic 3: AI-Assisted Security Troubleshooting and Access Management","subsecs":[]},{"title":"Topic 4: AI-Powered Access Monitoring and Unauthorized Access Investigation","subsecs":[]}] -->
<p><strong>Topic 1: AI-Assisted Security Programme Administration and System Updates</strong></p>
<p><strong>Topic 2: AI for System, Network and Device Security</strong></p>
<p><strong>Topic 3: AI-Assisted Security Troubleshooting and Access Management</strong></p>
<p><strong>Topic 4: AI-Powered Access Monitoring and Unauthorized Access Investigation</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 6. About This Course (sdesc)
-- Full replace: the live short_description carries two Microsoft-partner tails
-- ("Microsoft Learning Partner" Org ID + "Certification Exam at Pearson Vue"
-- with an AZ-500 registration deep link and an exam-voucher cross-sell). Both
-- are dead once the course stops preparing learners for the AZ-500 exam, so the
-- whole attribute is replaced with the supplied prose. No <h2>Course Brochure</h2>
-- tail here (that lives in the _brochure cms/block), so nothing else is lost.
UPDATE catalog_product_entity_text
   SET value = '<p>AI for IT Security Professionals equips participants with practical skills to apply artificial intelligence across security monitoring, threat detection, vulnerability analysis, and incident response. The course explores how AI can analyze large volumes of security data, identify suspicious behaviour, detect potential threats, and support faster and more informed security decisions.</p>
<p>Participants will learn to use AI-assisted workflows to examine system and network logs, identify indicators of compromise, assess security vulnerabilities, summarize threat intelligence, and recommend remediation actions. The course also covers identity and access security, network protection, data security, security controls, risk prioritization, and automation of repetitive security operations.</p>
<p>Through hands-on scenarios, learners will use AI to investigate incidents, generate security reports, develop response plans, and evaluate the effectiveness of security measures. Emphasis is placed on validating AI-generated findings, reducing false positives, protecting confidential information, and maintaining human oversight. Participants will also examine AI-related risks, including prompt injection, adversarial attacks, data leakage, and AI-generated cyber threats. By the end of the course, learners will be able to use AI responsibly to strengthen organizational security and improve cyber resilience.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- -------------------------------------------------- 7. Learning Outcomes block
-- The live block names Azure explicitly ("Perform Azure system administration",
-- "troubleshooting of Azure security software", "Coordinate Azure access control
-- rights"). The supplied LO1-LO4 are the SAME four accredited outcomes with the
-- Azure qualifier removed, so the ICT-OUS-3012-1.1 Security Administration
-- standard still holds and the skills_framework block stays untouched.
UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Administer security programmes and analyze the impact of system updates.</li>
<li>LO2:&nbsp;Perform system administration and configure network device security features.</li>
<li>LO3:&nbsp;Perform troubleshooting of security software and assist users in defining access rights.</li>
<li>LO4:&nbsp;Coordinate access control rights and investigate unauthorized access incidents.</li>
</ul>'
 WHERE identifier = 'course_TGS-2023039344_learning_outcomes';

-- -------------------------------------------------------- 8. Trainer bios
-- Five bios, each two paragraphs: para 1 = career CREDENTIALS -- FACTS, left
-- untouched (Azure/CISSP/Microsoft certifications the trainers actually hold
-- stay accurate). Para 2 = a course-teaching claim, and ALL FIVE open with
-- 'In "Microsoft Azure Security Engineer Associate (AZ-500),"' -- every one is
-- retargeted to the new subject.
-- Single-line REPLACE() on the full paragraph string (a multi-line pattern
-- no-ops against the WYSIWYG blob's CRLF line endings).

-- Sivanesan Sivakaruniam
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Azure Security Engineer Associate (AZ-500),&rdquo; Sivanesan provides learners with deep insights into designing and implementing secure Azure environments. His sessions cover topics such as threat protection, network security, and identity governance. By integrating real-world cybersecurity practices with Azure security capabilities, he enables learners to confidently configure, manage, and monitor cloud security solutions aligned with enterprise and certification standards.',
       'In this course, Sivanesan provides learners with deep insights into applying AI to the design and monitoring of secure IT environments. His sessions cover topics such as AI-assisted threat protection, network security, and identity governance. By integrating real-world cybersecurity practices with AI-driven analysis, he enables learners to confidently detect, investigate, and respond to security incidents while maintaining human oversight of AI-generated findings.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Achim Ludwig Dietzenbach
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Azure Security Engineer Associate (AZ-500),&rdquo; Achim trains participants on implementing and maintaining robust Azure security controls. His sessions emphasize securing virtual networks, managing identities, and automating security responses using Azure Security Center and Sentinel. With a focus on hands-on learning, he guides learners in applying defense-in-depth strategies and modern DevSecOps practices to real-world Azure environments.',
       'In this course, Achim trains participants on implementing and maintaining robust security controls with AI assistance. His sessions emphasize securing networks, managing identities, and automating security responses and repetitive monitoring tasks. With a focus on hands-on learning, he guides learners in applying defense-in-depth strategies and modern DevSecOps practices to real-world enterprise environments.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Agus Salim
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Azure Security Engineer Associate (AZ-500),&rdquo; Agus focuses on building learners&rsquo; proficiency in Azure&rsquo;s security frameworks, including access management, encryption, and workload protection. His sessions combine conceptual understanding with practical demonstrations of threat detection, identity management, and security policy implementation. Through guided exercises, he helps participants develop the hands-on skills needed to design and maintain secure Azure-based solutions.',
       'In this course, Agus focuses on building learners&rsquo; proficiency in AI-assisted security workflows, including access management, encryption, and workload protection. His sessions combine conceptual understanding with practical demonstrations of AI-powered threat detection, identity management, and security policy implementation. Through guided exercises, he helps participants develop the hands-on skills needed to analyze logs, spot indicators of compromise, and maintain secure systems.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Danny Teo Yong Song
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Azure Security Engineer Associate (AZ-500),&rdquo; Danny equips learners with essential skills to protect cloud environments from evolving threats. His sessions cover security monitoring, governance, compliance management, and automation of security operations in Azure. By blending theoretical concepts with real-world simulations, he ensures that participants are fully prepared to safeguard enterprise cloud systems and achieve success in the AZ-500 certification.',
       'In this course, Danny equips learners with essential skills to protect IT environments from evolving threats using AI. His sessions cover AI-assisted security monitoring, governance, compliance management, and the automation of security operations. By blending theoretical concepts with real-world simulations, he ensures that participants can investigate incidents, validate AI-generated findings, and safeguard enterprise systems.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Truman Ng
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Azure Security Engineer Associate (AZ-500),&rdquo; Truman teaches learners how to design and implement enterprise-grade cloud security solutions using Azure tools and best practices. His sessions focus on identity protection, threat mitigation, and automated defense mechanisms. Through case studies and practical labs, he empowers participants to deploy secure Azure infrastructures and effectively manage cloud security operations at scale.',
       'In this course, Truman teaches learners how to apply AI to enterprise-grade security operations and best practices. His sessions focus on identity protection, threat mitigation, risk prioritization, and automated defense mechanisms, including the risks AI itself introduces such as prompt injection and adversarial attacks. Through case studies and practical labs, he empowers participants to manage security operations at scale with AI support.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- ----------------------------------------------------- 9. Category placement
-- The repurpose changes the SUBJECT: the course is no longer about Microsoft
-- Azure and no longer prepares learners for the AZ-500 exam, so drop the six
-- Microsoft/Azure-specific listings:
--    11 "Microsoft"                        135 "Microsoft Certification Exam Prep"
--   185 "Azure"                            358 "Microsoft Certification Exam Prep"
--   411 "Azure Certification"              426 "WSQ Cloud Computing & Networking"
--    87 "Cloud Computing"
-- and join 252 "AI Courses", the master listing every AI course belongs to.
-- The security listings (161, 301, 364, 385, 386), the broad 182 "Certification
-- Exam Prep" parent, the WSQ listings and 3 "All Courses" all stay -- they
-- describe the NEW content correctly.
-- Both sides mirrored into catalog_category_product_index or the storefront
-- listings never change.
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (11, 87, 135, 185, 358, 411, 426) AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (11, 87, 135, 185, 358, 411, 426) AND @e IS NOT NULL;

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
