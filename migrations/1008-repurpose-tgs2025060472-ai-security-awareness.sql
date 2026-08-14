-- 1008: Repurpose TGS-2025060472
--   "WSQ - Responsible Generative AI Basics"  ->  "WSQ - AI Security Awareness"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-14: widen from generative-AI ethics/privacy
-- basics to security awareness for Generative AI *and agentic AI* -- AI threats
-- (prompt injection, deepfakes, data exposure, excessive agent permissions),
-- data privacy + access control, and AI governance / risk management.
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope), meta_title
-- (also FIXES a pre-existing bug -- see below), meta_description, meta_keyword,
-- short_description, description (3 LUs with 12 sub-topics -> the 3 supplied
-- topics; LSN_DATA JSON kept in sync with the visible markup), trainerprofile
-- (the single bio's closing teaching claim names the old title), whoshouldattend
-- (two generative-AI-specific roles), image/small_image/thumbnail labels,
-- media-gallery label, and a 301 for the old bare slug.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * course_TGS-2025060472_learning_outcomes -- the live block ALREADY holds the
--     supplied LO1-LO3 byte-for-byte. These are the SSG-accredited outcomes
--     registered against the unchanged SKU; the new topics are delivered against
--     these same outcomes. Do not "fix" the remaining "generative AI" wording.
--   * course_TGS-2025060472_skills_framework -- ICT-BAS-0055-1.1 "Responsible AI
--     and Generative AI Practices" + MED-ACE-2018-1.1. The LOs are unchanged, so
--     the accredited standard still holds.
--   * course_TGS-2025060472_certification / _funding_and_grant / _brochure --
--     keyed on the SKU; OpenCerts wording and the fee table are unaffected.
--   * prerequisite -- entry requirements + funding apparatus. Its "Minimum
--     Software/Hardware Requirement" is "TBD" (no old-tool link to retarget).
--   * additional_note -- bring-your-own-laptop logistics.
--   * badge tags (WSQ, SkillsFuture Credit, PSEA, SFEC, MCES, Absentee Payroll) --
--     funding eligibility is unchanged by the content pivot.
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url.
--   * cover PNG (course_image_url) -- re-rendered out of band from the admin.
--   * CATEGORIES -- all eight already describe the new content: 214 "AI Security
--     Series", 301 "WSQ IT & Security Courses", 252 "AI Courses", 55 "Infocomm
--     Technology", 433 "Generative AI Series" (the course still centres on
--     Generative AI, now its security dimension), 15/292 (WSQ listings), 3 (All
--     Courses). Nothing to drop, nothing to add -- no catalog_category_product /
--     _index churn on this repurpose.
--   * catalogsearch_query -- probed: ZERO rows redirect at the old slug or the
--     bare course code, so checklist surface 7 is a genuine no-op here. The ~20
--     live "Cyber Security Awareness" queries belong to the DISTINCT CASL course
--     TGS-2026064533 (slug casl-cyber-security-awareness-course-for-personal-and-
--     businesses) and all have redirect IS NULL -- filling them toward this page
--     would hijack that course's intent.
--
-- NAME/SLUG COLLISION CHECK: no live product owns "AI Security Awareness" or a
-- *-security-awareness slug other than the CASL course above (different stem,
-- different page). The plain wsq- prefixed slug is free.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025060472' LIMIT 1);

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
   SET value = 'WSQ - AI Security Awareness'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. SEO meta
-- meta_title: plain title. MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs
-- and appends the brand postfix at render time -- baking either in duplicates it.
-- The live value did BOTH ("WSQ Basic Practices ... | Tertiary Courses Singapore"),
-- so this rename is also the fix for that pre-existing double-prefix bug.
UPDATE catalog_product_entity_varchar
   SET value = 'AI Security Awareness'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Learn to use Generative AI and agentic AI securely at work. Covers AI threats such as prompt injection, deepfakes and data exposure, plus data privacy, access control, AI governance and incident response. Enjoy up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'AI security awareness course, generative AI security risks, agentic AI security, prompt injection, deepfake detection, AI data privacy, AI access control, confidential data exposure, AI governance, AI risk management, AI acceptable use policy, AI incident response, human oversight AI, WSQ AI security course Singapore'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. URL key
-- Delete url_path at EVERY scope so the Catalog URL Rewrites indexer regenerates
-- it; a surviving store-scoped row shadows the new URL. (Live rows exist at
-- store 0 AND store 1 here.)
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-ai-security-awareness'
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Remove any non-system squatter on the NEW path before inserting the 301,
-- so the INSERT IGNORE below cannot silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-ai-security-awareness.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the category paths).
-- NOTE: the old bare slug is held by this product's SYSTEM rewrite
-- (id_path 'product/<e>', is_system = 1 -- confirmed row 10392447 at store 1), so
-- a plain INSERT IGNORE silently no-ops against the unique key on
-- (request_path, store_id). Convert that row in place into a permanent redirect;
-- the indexer then mints a fresh system row for the NEW slug.
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-security-awareness.html',
       is_system   = 0,
       options     = 'RP'
 WHERE request_path = 'wsq-responsible-generative-ai-basics.html'
   AND id_path = CONCAT('product/', @e)
   AND @e IS NOT NULL;

-- Belt-and-braces for any store that had no system row on the old slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('TGS-2025060472-rp-1008-', s.store_id),
       'wsq-responsible-generative-ai-basics.html',
       'wsq-ai-security-awareness.html',
       0, 'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- Re-point the earlier renames' 301 chains at the new slug so the old URLs
-- resolve in ONE hop instead of 301-chaining through a now-redirecting path.
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-security-awareness.html'
 WHERE is_system = 0
   AND target_path = 'wsq-responsible-generative-ai-basics.html'
   AND request_path <> 'wsq-ai-security-awareness.html'
   AND @e IS NOT NULL;

UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path,
                             '/wsq-responsible-generative-ai-basics.html',
                             '/wsq-ai-security-awareness.html')
 WHERE is_system = 0
   AND target_path LIKE '%/wsq-responsible-generative-ai-basics.html'
   AND @e IS NOT NULL;

-- ------------------------------------------------- 4. Image alt text
-- Plain title (no "WSQ - " prefix): the cover itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'AI Security Awareness'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'AI Security Awareness'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------ 5. Course Outline (description + JSON)
-- The visible markup and the LSN_DATA JSON comment must stay in sync. The three
-- LUs (12 <em> sub-topics) are replaced wholesale by the three supplied topics --
-- topic-level only, so subsecs are empty. Three topics -- matches LO1-LO3.
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Security Threats and Responsible Use of Generative and Agentic AI","subsecs":[]},{"title":"Topic 2: AI Data Privacy, Access Control and Information Protection","subsecs":[]},{"title":"Topic 3: AI Governance, Ethical Compliance and Risk Management","subsecs":[]}] -->
<p><strong>Topic 1: Security Threats and Responsible Use of Generative and Agentic AI</strong></p>
<p><strong>Topic 2: AI Data Privacy, Access Control and Information Protection</strong></p>
<p><strong>Topic 3: AI Governance, Ethical Compliance and Risk Management</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 6. About This Course (sdesc)
-- Full replace. Verified first (checklist surface 12): the live short_description
-- is prose ONLY -- no <h2>Course Brochure</h2> tail and no ad-hoc inline
-- certification-vendor sections -- so nothing is silently destroyed. All five
-- standard sections live in the course_TGS-2025060472_* cms blocks.
UPDATE catalog_product_entity_text
   SET value = '<p>This course equips learners with essential security awareness for the responsible use of Generative AI and agentic AI in the workplace. Participants will explore how these technologies create new security, privacy, ethical, and operational risks when handling organisational data, generating content, connecting to external systems, or performing tasks with limited human intervention.</p>
<p>Learners will examine common AI-related threats, including confidential data exposure, malicious instructions, prompt injection, inaccurate outputs, identity impersonation, deepfakes, excessive agent permissions, unsafe tool access, and unauthorised actions. They will learn practical safeguards such as verifying AI-generated information, protecting sensitive data, controlling system access, reviewing agent activities, and escalating suspected security incidents.</p>
<p>The course also introduces AI governance principles for managing AI tools and agents throughout their lifecycle. Participants will learn how organisational policies, acceptable-use guidelines, risk assessments, human oversight, access controls, audit trails, incident response procedures, and ongoing monitoring support the secure and accountable adoption of AI.</p>
<p>Through practical scenarios, learners will evaluate AI risks, recognise warning signs, respond appropriately to security incidents, and recommend preventive measures. The course also addresses privacy, intellectual property, bias, transparency, accountability, and regulatory compliance.</p>
<p>By the end of the course, participants will be able to use Generative AI and agentic AI more securely, comply with organisational governance requirements, and contribute to a responsible AI culture. This course is suitable for beginner and intermediate learners who use, manage, or support AI technologies in the workplace.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- -------------------------------------------------------- 7. Trainer bio
-- One bio (Dr. Alfred Ang), two paragraphs. Para 1 = career CREDENTIALS -- FACTS,
-- left untouched (the SCS Certified Senior AI Ethics Professional credential and
-- the responsible-workflow project history remain accurate and are, if anything,
-- MORE relevant to AI security awareness). Para 2 closes with a course-teaching
-- claim scoped to the OLD title -- that one sentence fragment is retargeted.
-- Single-line REPLACE() on the exact string (a multi-line pattern no-ops against
-- the WYSIWYG blob's line endings).
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'Dr. Ang is well positioned to guide learners in understanding and applying basic practices for responsible generative AI workflows, ensuring that innovation is deployed with integrity and societal benefit in mind',
       'Dr. Ang is well positioned to guide learners in recognising and mitigating the security, privacy and governance risks of Generative AI and agentic AI, ensuring that innovation is deployed securely, accountably and with societal benefit in mind')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------ 8. Who Should Attend
-- 20 roles. 18 are generic business / IT / compliance titles that fit an AI
-- security-awareness course unchanged. Two name the retired framing and are
-- retargeted rather than dropped (keeps the list at 20).
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li>Junior AI Compliance Analyst</li>',
       '<li>Junior AI Governance Analyst</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li>AI Project Coordinator</li>',
       '<li>Information Security Coordinator</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;
