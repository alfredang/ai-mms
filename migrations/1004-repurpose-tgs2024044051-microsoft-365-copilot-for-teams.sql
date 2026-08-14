-- 1004: Repurpose TGS-2024044051
--   "WSQ - Microsoft Teams Administrator Associate (MS-700)"
--     -> "WSQ - Microsoft 365 Copilot for Teams"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-14: pivot from the Microsoft MS-700 Teams
-- ADMINISTRATION certification track to using Microsoft 365 Copilot inside Teams
-- as an END USER (meetings, chats, channels, summaries, action items).
--
-- Same shape as 957 (TGS-2024042588).
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope, INCLUDING
-- the store-1 row), meta_title / meta_description / meta_keyword,
-- short_description (full replace -- see note 6), description (the 4 MS-700
-- admin topics + their 31 <li> subsections -> the 4 supplied topics, LSN_DATA
-- JSON kept in sync), trainerprofile (all five bios name MS-700 in their
-- teaching paragraph), whoshouldattend (20 job roles, 9 of them
-- administration-specific), image/small_image/thumbnail labels, media-gallery
-- label, course_image_url (fresh R2 cover), a 301 for the old bare slug, and
-- category placement, mirrored into catalog_category_product_index.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * course_TGS-2024044051_learning_outcomes -- the four supplied LOs are
--     BYTE-IDENTICAL to the live block (the admin re-stated the same accredited
--     outcomes; they are registered against the UNCHANGED SKU and are
--     deliberately Teams-generic: "technology implementation plans ... for
--     Microsoft Teams" is satisfied by a Copilot-for-Teams delivery). The
--     What You'll Learn card legitimately still says "Microsoft Teams" 4x --
--     that is the accredited wording, NOT a leak. Nothing to write.
--   * course_TGS-2024044051_skills_framework -- Technology and Systems
--     Application EPW-TEM-4023-1.1 is tool-agnostic ("apply technology and
--     systems to improve business operations") and still describes the course.
--   * course_TGS-2024044051_certification / _funding_and_grant / _brochure --
--     keyed on the SKU; the fee table and OpenCerts wording are unaffected.
--     (The _certification block is the WSQ Statement of Achievement, NOT the
--     Microsoft exam -- unaffected by dropping the Pearson VUE prep.)
--   * prerequisite -- SWEPT AND CLEAN: zero Microsoft/Teams/MS-700 hits. It
--     holds ONLY the funding apparatus (PWM, Funding Eligibility table,
--     SkillsFuture/PSEA/SFEC/UTAP deep links, Appeal Process): 4x
--     myskillsfuture.gov.sg, 2x ntuc.org.sg, 1x mom.gov.sg. NOT rewritten --
--     nothing to fix, and a wholesale edit would destroy the deep links.
--   * additional_note (bring-your-own-laptop) / assessment_methods (450,451) --
--     logistics + assessment mode, unchanged by a content pivot.
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url.
--   * catalogsearch_query -- the 8 rows matching the old title / MS-700 / the
--     bare course code ALL have an EMPTY redirect (verified), so there is
--     nothing to retarget and the "only fill redirect IS NULL/''" rule plus
--     MS-700 search INTENT (no live SG course still teaches MS-700
--     administration) means they are deliberately left empty for Magento
--     search rather than pointed at a course that no longer matches.
--   * badge tags (WSQ / SkillsFuture Credit / PSEA / UTAP / SFEC / MCES /
--     Absentee Payroll) -- funding eligibility is unchanged by a content pivot.
--   * Categories 3 (All Courses), 15 (WSQ and IBF courses), 72/292/293/301/
--     323/345 (the WSQ listings) -- they describe the NEW content correctly.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024044051' LIMIT 1);

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
SET @a_cimg   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_ilab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------- 1. Title
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Microsoft 365 Copilot for Teams'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. SEO meta
-- meta_title: plain title. MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs
-- and appends the brand postfix at render time -- baking either in duplicates it.
-- The live value was ALREADY wrong on both counts ("WSQ Microsoft Teams
-- Administrator Associate Exam Prep | Tertiary Courses Singapore"); the rename
-- is the moment to fix it. Not scoped to store 0 in case a store-1 override
-- exists that would shadow it.
UPDATE catalog_product_entity_varchar
   SET value = 'Microsoft 365 Copilot for Teams'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Learn to use Microsoft 365 Copilot in Teams to prepare meetings, summarise discussions, extract action items and draft messages. Covers prompting, chats, channels, responsible AI and data security. Enjoy up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'Microsoft 365 Copilot, Copilot for Teams, Microsoft Teams, AI meeting summaries, action items, meeting recap, prompting techniques, AI collaboration, chats and channels, responsible AI, data security, workflow optimization, workplace productivity, WSQ Copilot course'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. URL key
-- New slug checked for collision first: the 10 live Microsoft-365-Copilot
-- courses (C027, C1177, C1194, C1768, C180, C34, C627, C856, C998, and the
-- WSQ twin TGS-2024043856 "WSQ - Enhance Work Productivity with Microsoft 365
-- Copilot") own DIFFERENT slugs -- none holds
-- 'wsq-microsoft-365-copilot-for-teams'. No twin to hijack.
-- Delete url_path at EVERY scope (there IS a store-1 row here) so the Catalog
-- URL Rewrites indexer regenerates it; a surviving store-scoped row shadows the
-- new URL.
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-microsoft-365-copilot-for-teams'
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Remove any non-system squatter on the new path before inserting the 301,
-- so the INSERT IGNORE below cannot silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-microsoft-365-copilot-for-teams.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the category paths).
-- NOTE: the old bare slug is held by this product's SYSTEM rewrite
-- (url_rewrite_id 5608260, id_path 'product/1345', is_system = 1), so a plain
-- INSERT IGNORE silently no-ops against the unique key on
-- (request_path, store_id). Convert that row in place into a permanent redirect
-- instead; the indexer then mints a fresh system row for the NEW slug.
UPDATE core_url_rewrite
   SET target_path = 'wsq-microsoft-365-copilot-for-teams.html',
       is_system   = 0,
       options     = 'RP'
 WHERE request_path = 'wsq-microsoft-teams-administrator-associate-ms-700.html'
   AND id_path = CONCAT('product/', @e)
   AND @e IS NOT NULL;

-- Belt-and-braces for any store that had no system row on the old slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('TGS-2024044051-rp-1004-', s.store_id),
       'wsq-microsoft-teams-administrator-associate-ms-700.html',
       'wsq-microsoft-365-copilot-for-teams.html',
       0, 'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- ------------------------------------------------- 4. Image alt text
-- Plain title (no "WSQ - " prefix): the cover itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'Microsoft 365 Copilot for Teams'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Microsoft 365 Copilot for Teams'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- The storefront renders course_image_url (an R2 PNG rendered from the title),
-- NOT the image/small_image filesystem paths -- so a repurpose that skips this
-- leaves the OLD branded cover under the NEW title. Re-rendered from the local
-- container with the product's own badge tags (WSQ / SkillsFuture Credit / PSEA
-- / UTAP / SFEC / Absentee Payroll / MCES) and uploaded to the shared R2 bucket;
-- verified HTTP 200 before baking the URL in here.
UPDATE catalog_product_entity_varchar
   SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024044051-20260814-130449.png'
 WHERE entity_id = @e AND attribute_id = @a_cimg AND @e IS NOT NULL;

-- ------------------------------------ 5. Topics Covered (description + JSON)
-- The visible <p><strong>Topic N</strong></p> markup and the LSN_DATA JSON
-- comment must stay in sync. The four MS-700 administration topics (Explore /
-- Plan and deploy / Lifecycle management and governance / Monitor your Teams
-- environment) and their 31 <li> subsections are replaced wholesale by the four
-- supplied topics -- topic-level only, so subsecs are empty. Four topics --
-- matches LO1-LO4.
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Getting Started with Microsoft 365 Copilot in Teams","subsecs":[]},{"title":"Topic 2: AI-Powered Chats, Channels and Team Collaboration","subsecs":[]},{"title":"Topic 3: Copilot for Meetings, Summaries and Action Items","subsecs":[]},{"title":"Topic 4: Responsible AI, Data Security and Workflow Optimization","subsecs":[]}] -->
<p><strong>Topic 1: Getting Started with Microsoft 365 Copilot in Teams</strong></p>
<p><strong>Topic 2: AI-Powered Chats, Channels and Team Collaboration</strong></p>
<p><strong>Topic 3: Copilot for Meetings, Summaries and Action Items</strong></p>
<p><strong>Topic 4: Responsible AI, Data Security and Workflow Optimization</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 6. About This Course (sdesc)
-- FULL REPLACE, deliberately. The live short_description was dumped and read in
-- full before choosing replace-over-splice (surface 12): besides the two intro
-- paragraphs it carries THREE inline Microsoft-certification sections --
-- <h2>Microsoft Learning Partner</h2> (Org ID 5238476), <h2>Certification Exam
-- at Pearson Vue</h2> with a live deep link to the MS-700 credential page, and
-- an exam-voucher cross-sell linking a SEPARATE sellable product
-- (microsoft-role-based-certification-exam-vouchers.html). All three are dead
-- once the course stops preparing learners for the MS-700 exam -- advertising
-- the voucher under the new title would misrepresent the course -- so the whole
-- attribute is replaced with the supplied prose. There is NO
-- <h2>Course Brochure</h2> / Skills Framework / Funding tail in this attribute
-- (those live in the cms/blocks), so nothing else is lost.
UPDATE catalog_product_entity_text
   SET value = '<p>Microsoft 365 Copilot for Teams equips participants with practical skills to use AI to improve communication, collaboration, and productivity within Microsoft Teams. Participants will learn how Copilot can assist with preparing meetings, summarizing discussions, identifying key decisions, extracting action items, and reviewing conversations they may have missed.</p>
<p>The course explores how to use natural-language prompts to draft messages, refine responses, generate meeting agendas, organize ideas, and transform Teams discussions into structured notes and follow-up plans. Participants will also learn to apply Copilot across chats, channels, meetings, and shared workplace content to locate information and coordinate work more effectively.</p>
<p>Through hands-on workplace scenarios, learners will practise prompting techniques, verify AI-generated outputs, manage tasks arising from meetings, and improve collaboration across teams. The course also addresses responsible AI usage, data privacy, information security, permissions, and appropriate human oversight. By the end of the course, participants will be able to use Microsoft 365 Copilot for Teams to reduce administrative work, improve meeting outcomes, and support faster, more informed teamwork.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- -------------------------------------------------- 7. Learning Outcomes
-- INTENTIONALLY NOT WRITTEN. The supplied LO1-LO4 are byte-identical to the
-- live course_TGS-2024044051_learning_outcomes block. The accredited outcomes
-- are unchanged by this content pivot, which is why the EPW-TEM-4023-1.1
-- Technology and Systems Application standard also stays.

-- -------------------------------------------------------- 8. Trainer bios
-- Five bios, each two paragraphs: para 1 = career CREDENTIALS -- FACTS, left
-- untouched (the Microsoft 365 / MCT / CCNP / ACLP certifications the trainers
-- actually hold, and their real Teams/Exchange/Azure deployment history, stay
-- accurate -- rewriting them would falsify a bio). Para 2 = a course-teaching
-- claim, and ALL FIVE open with 'In "Microsoft Teams Administrator Associate
-- (MS-700),"' -- every one is retargeted from ADMINISTERING Teams to USING
-- Copilot inside Teams.
-- Single-line REPLACE() on the full paragraph string (a multi-line pattern
-- no-ops against the WYSIWYG blob's CRLF line endings). Each pattern below was
-- LOCATE()-probed against live data before writing.
-- NOTE: para 1 of every bio still mentions Microsoft 365 / Teams after this
-- migration -- that is the PASS condition, not a leak.

-- Sanjiv Venkatram
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Teams Administrator Associate (MS-700),&rdquo; Sanjiv brings a strategic perspective to managing enterprise Teams environments. His sessions focus on governance, security, compliance, and automation within Microsoft Teams and Microsoft 365. Through a balance of technical configuration and real-world deployment scenarios, he helps learners master the skills needed to manage Teams policies, integrate collaboration tools, and support scalable, secure communication infrastructure across organizations.',
       'In this course, Sanjiv brings a strategic perspective to adopting AI inside enterprise Teams environments. His sessions focus on prompting techniques, meeting preparation, and responsible AI use within Microsoft Teams and Microsoft 365. Through a balance of hands-on practice and real-world workplace scenarios, he helps learners master the skills needed to summarise discussions, extract action items, and coordinate work more effectively across organizations.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Agus Salim
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Teams Administrator Associate (MS-700),&rdquo; Agus guides learners through the full lifecycle of Teams administration&mdash;from setup and configuration to user management and troubleshooting. His practical sessions cover advanced features such as compliance management, meeting policies, and Teams integration with Power Platform. Drawing on his technical experience, he ensures participants gain the hands-on expertise needed to effectively deploy and manage Microsoft Teams in real-world enterprise environments.',
       'In this course, Agus guides learners through the full Copilot workflow in Teams&mdash;from writing effective prompts to drafting messages, recapping meetings and following up on actions. His practical sessions cover working across chats, channels and shared workplace content, and verifying AI-generated output before acting on it. Drawing on his technical experience, he ensures participants gain the hands-on expertise needed to apply Microsoft 365 Copilot in real-world enterprise environments.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Kishan Raaj
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Teams Administrator Associate (MS-700),&rdquo; Kishan focuses on the technical architecture and security foundations of Teams administration. His lessons explore identity management, PowerShell automation, and cross-service integration within Microsoft 365. With a strong emphasis on hands-on labs and real-world configurations, he equips learners to manage Teams environments effectively, ensuring reliability, compliance, and scalability in modern workplace ecosystems.',
       'In this course, Kishan focuses on the data-security and privacy foundations of using Copilot at work. His lessons explore permissions, information boundaries, and how Copilot draws on content across Microsoft 365. With a strong emphasis on hands-on practice and real-world scenarios, he equips learners to use Copilot in Teams effectively, ensuring responsible, compliant, and trustworthy AI use in modern workplace ecosystems.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Alec Tan Chee Wee
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Teams Administrator Associate (MS-700),&rdquo; Alec provides learners with an in-depth understanding of Teams infrastructure, security, and integration with Microsoft 365 services. His training emphasizes governance, compliance, and automation to ensure seamless user experience and system reliability. Leveraging his extensive consulting experience, Alec helps participants build the technical confidence to administer and secure Microsoft Teams environments for large-scale enterprises.',
       'In this course, Alec provides learners with an in-depth understanding of how Copilot works across Teams meetings, chats and Microsoft 365 content. His training emphasizes practical prompting, human oversight, and verifying AI output to ensure a reliable user experience. Leveraging his extensive consulting experience, Alec helps participants build the confidence to apply Microsoft 365 Copilot to everyday collaboration in large-scale enterprises.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- Bernard Peh
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In &ldquo;Microsoft Teams Administrator Associate (MS-700),&rdquo; Bernard teaches participants how to manage enterprise collaboration systems efficiently and securely. His sessions cover Teams deployment, governance, and troubleshooting in hybrid environments. By integrating real-world administrative practices with Microsoft best practices, he equips professionals to optimize Teams functionality, enhance cross-departmental collaboration, and maintain compliance in dynamic digital workplaces.',
       'In this course, Bernard teaches participants how to use AI to work through enterprise collaboration efficiently and securely. His sessions cover meeting recaps, action-item tracking, and workflow optimization in hybrid environments. By integrating real-world workplace practices with Microsoft best practices, he equips professionals to reduce administrative work, enhance cross-departmental collaboration, and maintain compliance in dynamic digital workplaces.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- ----------------------------------------------------- 8b. Who Should Attend
-- The 20-role list is written for Teams ADMINISTRATORS. Nine roles are
-- administration/infrastructure-specific and no longer describe the audience
-- for an end-user Copilot course; each is re-pointed at its collaboration /
-- knowledge-worker equivalent via a targeted <li>-level REPLACE(). The eleven
-- generic roles (IT Project Manager, Technology Integration Specialist,
-- Business Continuity Planner, Disaster Recovery Coordinator, IT Risk Manager,
-- Systems Integration Analyst, Corporate Communications Specialist, IT Service
-- Delivery Manager, Technical Operations Officer, Operations Project
-- Consultant, Information Systems Manager) still fit and are left alone.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value, '<li>Microsoft Teams Administrator</li>', '<li>Microsoft 365 Copilot User</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, '<li>Unified Communications Manager</li>', '<li>Team Collaboration Lead</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, '<li>Network Operations Administrator</li>', '<li>Digital Workplace Specialist</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, '<li>IT Support Technician</li>', '<li>Business Operations Executive</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, '<li>Collaboration Solutions Architect</li>', '<li>Productivity and Automation Champion</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, '<li>Cloud Solutions Engineer</li>', '<li>Knowledge Management Executive</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, '<li>IT Infrastructure Coordinator</li>', '<li>Project Coordinator</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, '<li>Technical Support Specialist</li>', '<li>Meeting and Programme Coordinator</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, '<li>Enterprise Systems Administrator</li>', '<li>Administrative and Executive Support Professional</li>')
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

-- ----------------------------------------------------- 9. Category placement
-- The repurpose changes the SUBJECT: the course no longer prepares learners for
-- the MS-700 exam, so drop the four certification/exam-prep listings.
-- Measured membership before choosing (the checklist's "resolve exam-prep cats
-- by measuring, don't trust one id" rule -- 135 and 358 are BOTH literally
-- named "Microsoft Certification Exam Prep", the same duplicated-listing trap
-- as SG 30+407):
--   135 "Microsoft Certification Exam Prep" (206 products)
--   358 "Microsoft Certification Exam Prep" (130 products)  <- duplicate listing
--   182 "Certification Exam Prep"           (357 products)
--   417 "Microsoft 365 Certification"        (16 products)
-- 182 is dropped too: unlike 957 (which kept it) this course carries NO
-- vendor-certification prep at all after the Pearson VUE / exam-voucher
-- sections are removed from short_description -- the only certificate left is
-- the WSQ Statement of Achievement, which cat 345 "WSQ Certification Courses"
-- already covers.
-- and join 252 "AI Courses", the master listing every AI course belongs to.
-- The WSQ listings (15, 72, 292, 293, 301, 323, 345) and 3 "All Courses" all
-- stay -- they describe the NEW content correctly.
-- Both sides mirrored into catalog_category_product_index or the storefront
-- listings never change.
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (135, 182, 358, 417) AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (135, 182, 358, 417) AND @e IS NOT NULL;

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
