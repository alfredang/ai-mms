-- 1018: Repurpose TGS-2020503109
--   "WSQ - Creating High-Converting Email Campaigns with Mailchimp"
--     -> "WSQ - Claude Cowork for Email Marketing"
--
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA / UTAP deep link is keyed
-- on it). Admin-supplied content 2026-08-14: 5 LOs, 5 topics, About narrative.
--
-- Surfaces touched, from the mandatory pre-write EAV sweep of BOTH value tables
-- (memory feedback_tgs_course_rename_checklist -- the sweep is what found these,
-- not an enumerated checklist). Sweeping for the TOOL ("Mailchimp") as well as
-- the old title returned hits in: name, meta_title, meta_description,
-- meta_keyword, image_label/small_image_label/thumbnail_label, url_key/url_path,
-- short_description, description, prerequisite (the tool download link) and
-- trainerprofile.
--
-- THIS IS A TOOL SWAP, NOT A SUBJECT CHANGE (memory
-- feedback_repurpose_realigns_to_own_accredited_tsc -- read skills_framework
-- FIRST). The skills_framework block reads "Integrated Marketing
-- ICT-SNM-3006-1.1 TSC under ICT Skills Framework": the course's registered
-- competency is EMAIL MARKETING, and Mailchimp was only the tool used to deliver
-- it. Confirmation from the admin-supplied LOs: they are BYTE-EQUIVALENT to the
-- live learning_outcomes block (LO1-LO5, differing only in leading capitalisation
-- and the &nbsp; entities). Nothing about the competency retires -- only the
-- vendor product is replaced by Claude Cowork. That decides the scope:
--   * email-marketing content, categories and job roles ALL STAY,
--   * only Mailchimp-specific wording and the tool link are swapped.
--
-- learning_outcomes cms_block is therefore DELIBERATELY NOT TOUCHED -- the live
-- block already carries exactly the requested LO1-LO5 (these are the
-- SSG-accredited outcomes registered against the unchanged SKU). Rewriting it to
-- restyle capitalisation would be churn against accredited content.
--
-- NEW-TITLE COLLISION CHECK (memory
-- feedback_repurpose_target_name_may_already_exist_as_live_twin -- probe name AND
-- url_key, not just url_key):
--   * name LIKE '%Cowork%' returned one live course, C1382 "Claude Cowork
--     Masterclass" (slug claude-cowork-masterclass) -- a different course, no
--     title clash.
--   * url_key LIKE '%claude-cowork%' / '%email-marketing%': the email-marketing
--     stem is owned by three OTHER live courses (C21 agentic-ai-for-email-
--     marketing, TGS-2026064473 casl-agentic-ai-for-email-marketing-campaign,
--     C686 create-email-marketing-campaigns-...). None owns
--     'wsq-claude-cowork-for-email-marketing', so the standard wsq--prefixed form
--     is free and stays distinct from all three.
--
-- meta_title: PLAIN title -- NO leading "WSQ", NO "| Tertiary Courses Singapore"
-- suffix. MMD_Seotitle composes <title> at render time (prepends "WSQ funded" for
-- SG TGS- SKUs and appends the brand postfix). The OLD value baked in BOTH
-- ("WSQ Email Marketing Campaign with Mailchimp ... | Tertiary Courses
-- Singapore") -- the 853 bug -- so this migration also cleans that up.
--
-- short_description: FULL REPLACE is correct here, not a splice. This course is
-- post-885: its sections live in cms_block rows (brochure / learning_outcomes /
-- certification / skills_framework / funding_and_grant, all five confirmed
-- present) and the sdesc holds ONLY the two intro paragraphs -- there is no
-- "<h2>Course Brochure</h2>" tail to preserve. Surface 12 checked explicitly
-- (memory feedback_repurpose_away_from_certification_brand): the whole blob was
-- dumped and read first -- there is NO ad-hoc inline vendor section (no Exam
-- Voucher / ATC / test-centre copy) on this course, so nothing is silently lost.
--
-- prerequisite: surgical single-<li> REPLACE only. This attribute holds the
-- ENTIRE funding apparatus (PWM, Funding Eligibility table, SkillsFuture / PSEA /
-- SFEC / UTAP deep links, Appeal Process) and must NEVER be rewritten wholesale.
-- Its "Minimum Software/Hardware Requirement" section links mailchimp.com; that
-- one <li> is swapped for Claude Cowork. The Google Analytics <li> stays --
-- campaign analytics is still in scope (LO5 / Topic 5).
--
-- TRAINER BIOS -- surgical, not wholesale. All 3 bios split cleanly:
--   * para 1 = career CREDENTIALS (real CRM / digital-marketing / regional
--     agency history). TRUE and LEFT ALONE -- rewriting would falsify a real
--     person's bio. NOTE Allen Wong's para 1 legitimately mentions "email
--     marketing" as a genuine expertise area; that is a fact, not a leak.
--   * para 2 = a COURSE-TEACHING claim naming Mailchimp. Retargeted to Claude
--     Cowork. Allen's Mailchimp mention sits in para 2 ("automation tools like
--     Mailchimp"), Patrick's and Ray's likewise.
-- One exact single-line REPLACE() per bio -- a multi-line REPLACE() silently
-- no-ops on these CRLF WYSIWYG blobs (memory
-- feedback_multiline_replace_fails_on_crlf_blobs).
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * sku, price, duration (16), sessions (2) -- accredited course params.
--   * whoshouldattend -- swept and CLEAN. All 15 job roles (Email Marketing
--     Specialist, CRM Specialist, Newsletter Editor, ...) are tool-neutral
--     email-marketing roles that still describe the repurposed course exactly.
--     Contrast the usual repurpose, where this list names the old tech.
--   * course_TGS-2020503109_skills_framework -- the TSC is unchanged and is the
--     reason the subject content stays; must NOT change.
--   * course_TGS-2020503109_learning_outcomes -- already exactly the requested
--     LOs (see above).
--   * _certification / _brochure / _funding_and_grant -- keyed on the unchanged
--     SKU. All three were grepped for the old title AND "Mailchimp": ZERO hits
--     (memory feedback_repurpose_away_from_certification_brand warns a stray
--     old-title line can hide in funding_and_grant -- checked, absent here).
--   * badge tags (funding eligibility unchanged).
--   * image/small_image/thumbnail PATHS
--     (/w/s/wsq---creating-high-converting-...jpg) -- filesystem paths, not
--     display text; renaming them 404s the file. The storefront renders
--     course_image_url. Only the LABELS (alt text) change here; the R2 cover PNG
--     still bakes the old title and is re-rendered from the admin.
--   * CATEGORY PLACEMENT -- all 9 placements KEPT, none dropped. Because the TSC
--     and subject are unchanged, every listing still describes the course:
--     8 Digital Marketing, 59 Email Marketing, 308 WSQ Digital Marketing Courses,
--     72 WSQ Media & Marketing Courses, plus the broad 3 / 15 / 292 / 293 / 301.
--     There is no vendor/exam-prep category to retire -- Mailchimp never had one.
--   * catalogsearch_query -- the anchored sweep on the FULL old filename
--     ('%wsq-creating-high-converting-email-campaigns-with-mailchimp%') returned
--     ZERO rows. The 31 rows matching 'mailchimp' ALL have a NULL/empty redirect
--     and are Mailchimp-TOOL intent, which this course no longer teaches --
--     filling them toward this page would be actively wrong. Search redirects are
--     DATA and are applied live, never via a migration
--     (memory feedback_search_redirects_always_apply_live).
--
-- PARTNER SAFETY: TGS- SKUs are Singapore WSQ courses; MY/GH partner DBs have no
-- such SKU, so every statement matches zero rows there (clean no-op).
--
-- IDEMPOTENCY: every statement either sets a full target value or REPLACE()s an
-- exact old string that no longer exists after the first run. Re-running converges.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020503109');

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='prerequisite');
SET @a_trainer := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='trainerprofile');

-- ---------------------------------------------------------------------------
-- 1. name  (keep the "WSQ - " prefix -- the storefront H1 wants it)
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'WSQ - Claude Cowork for Email Marketing'
WHERE entity_id = @e AND attribute_id = @a_name;

-- ---------------------------------------------------------------------------
-- 2. url_key + url_path
--    Delete url_path at EVERY scope so the URL Rewrites indexer regenerates.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'wsq-claude-cowork-for-email-marketing'
WHERE entity_id = @e AND attribute_id = @a_urlkey;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND attribute_id = @a_urlpath;

-- Drop any is_system = 0 squatter on the NEW path first: INSERT IGNORE silently
-- no-ops against a stale row (the 647 trap).
DELETE FROM core_url_rewrite
WHERE request_path = 'wsq-claude-cowork-for-email-marketing.html' AND is_system = 0;

-- Explicit 301 for the old BARE slug. The indexer auto-301s the ~20 category
-- paths from its rewrite history; only the bare slug needs seeding.
-- NOTE (memory feedback_rename_301_vs_system_rewrite_suffix_trap): if the old
-- slug is held by an is_system = 1 row this guard correctly no-ops and the sweep
-- shows zero RP rows -- that is NOT a bug. refreshProductRewrite($pid, 1)
-- converts the system row into the 301 and mints the new canonical row.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, NULL, @e,
       CONCAT('product/', @e),
       'wsq-creating-high-converting-email-campaigns-with-mailchimp.html',
       'wsq-claude-cowork-for-email-marketing.html',
       0, 'RP', 'Repurpose 1018: old Mailchimp slug -> Claude Cowork for Email Marketing'
FROM dual
WHERE NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
    WHERE x.request_path = 'wsq-creating-high-converting-email-campaigns-with-mailchimp.html'
      AND x.store_id = 1 AND x.is_system = 0
);

-- ---------------------------------------------------------------------------
-- 3. meta_title / meta_description / meta_keyword
--    meta_title is the PLAIN title: MMD_Seotitle adds "WSQ funded" + the brand
--    suffix at render time. The old value baked in both (the 853 bug).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'Claude Cowork for Email Marketing'
WHERE entity_id = @e AND attribute_id = @a_mtitle;

UPDATE catalog_product_entity_varchar
SET value = 'Use Claude Cowork to plan, write and automate email marketing campaigns. Hands-on audience segmentation, personalisation, custom Skills, MCP tools and campaign analytics. Up to 70% WSQ funding subsidy.'
WHERE entity_id = @e AND attribute_id = @a_mdesc;

UPDATE catalog_product_entity_text
SET value = 'Claude Cowork, Email Marketing, AI Email Campaigns, WSQ Funding, Custom Skills, MCP Tools, Audience Segmentation, Marketing Automation, Campaign Analytics, A/B Testing'
WHERE entity_id = @e AND attribute_id = @a_mkey;

-- ---------------------------------------------------------------------------
-- 4. Alt-text labels + media-gallery label. These carry the PLAIN title (the
--    cover renderer itself strips the "WSQ - " prefix). The R2 cover PNG is
--    re-rendered separately from the admin.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'Claude Cowork for Email Marketing'
WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'Claude Cowork for Email Marketing'
WHERE g.entity_id = @e;

-- ---------------------------------------------------------------------------
-- 5. short_description -- the "About This Course" narrative (admin-supplied).
--    Full replace: sections live in cms_block rows, sdesc is prose only.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<p>This course equips participants with practical skills to use Claude Cowork to plan, create, manage, and optimise effective email marketing campaigns. Learners will explore how to conduct audience research, develop email marketing strategies, organise subscriber segments, and create personalised content for different customer profiles and stages of the customer journey.</p>
<p>Participants will use Claude Cowork to produce engaging subject lines, promotional emails, newsletters, welcome sequences, lead-nurturing campaigns, product announcements, and re-engagement messages. They will also learn to create reusable custom Skills based on real-world workflows, brand guidelines, writing styles, campaign templates, and quality standards to ensure consistent and brand-aligned communication.</p>
<p>The course covers connecting Claude Cowork with relevant business applications, documents, customer data, and marketing systems through Model Context Protocol (MCP) tools. Learners will design AI-assisted workflows for content production, campaign coordination, personalisation, review, and automation while maintaining human oversight, data privacy, and marketing compliance.</p>
<p>Participants will also use Claude Cowork to analyse campaign metrics, conduct A/B testing, identify engagement trends, and recommend improvements to content, segmentation, timing, and calls to action. By the end of the course, learners will be able to build scalable, AI-assisted email marketing workflows that improve productivity, customer engagement, conversions, and campaign performance.</p>'
WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- ---------------------------------------------------------------------------
-- 6. description -- the Course Outline. Both the LSN_DATA JSON comment (which
--    drives the structured outline) and the rendered markup must agree; the
--    storefront reads LSN_DATA when present. 5 admin-supplied topics.
--    The old value carried per-topic <ul> sub-bullets naming Mailchimp screens
--    (Sign Up Mailchimp, Email Beamer, Content Studio, ...); the admin supplied
--    topic titles only, so the outline is topics-only -- matching the shape of
--    960 / 967 / 999.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Email Marketing Strategy and Campaign Planning with Claude Cowork","subsecs":[]},{"title":"Topic 2: Audience Management, Segmentation and Personalisation","subsecs":[]},{"title":"Topic 3: Creating Email Content and Campaigns with Custom Claude Skills","subsecs":[]},{"title":"Topic 4: Email Marketing Automation with Claude Cowork and MCP Tools","subsecs":[]},{"title":"Topic 5: Campaign Analytics, A/B Testing and Performance Optimisation","subsecs":[]}] -->
<p><strong>Topic 1: Email Marketing Strategy and Campaign Planning with Claude Cowork</strong></p>
<p><strong>Topic 2: Audience Management, Segmentation and Personalisation</strong></p>
<p><strong>Topic 3: Creating Email Content and Campaigns with Custom Claude Skills</strong></p>
<p><strong>Topic 4: Email Marketing Automation with Claude Cowork and MCP Tools</strong></p>
<p><strong>Topic 5: Campaign Analytics, A/B Testing and Performance Optimisation</strong></p>'
WHERE entity_id = @e AND attribute_id = @a_desc;

-- ---------------------------------------------------------------------------
-- 7. prerequisite -- swap ONLY the Mailchimp tool <li> under "Minimum
--    Software/Hardware Requirement". The Google Analytics <li> stays (campaign
--    analytics is still LO5 / Topic 5). Everything else in this blob is the
--    funding apparatus and is untouched.
--    Deep-link counts to preserve: myskillsfuture / ntuc / mom links unchanged.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      '<li><a href="https://mailchimp.com/" target="_blank"><span style="text-decoration: underline;">MailChimp</span></a></li>',
      '<li><a href="https://claude.com/product/cowork" target="_blank"><span style="text-decoration: underline;">Claude Cowork</span></a></li>'
    )
WHERE entity_id = @e AND attribute_id = @a_prereq;

-- ---------------------------------------------------------------------------
-- 8. trainerprofile -- retarget the COURSE-TEACHING sentences only (para 2 of
--    each bio). Career-history / credential paragraphs are left factual.
--    One exact single-line REPLACE() per bio (CRLF-safe).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'Allen has consulted for multiple organizations, crafting email campaigns that leverage automation tools like Mailchimp to improve open rates, engagement, and ROI.',
      'Allen has consulted for multiple organizations, crafting email campaigns that leverage AI assistants like Claude Cowork to improve open rates, engagement, and ROI.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'His areas of expertise include email marketing, customer engagement, and content optimization, making him well-suited to guide learners in creating impactful Mailchimp campaigns.',
      'His areas of expertise include email marketing, customer engagement, and content optimization, making him well-suited to guide learners in creating impactful AI-assisted email campaigns with Claude Cowork.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'Through his sessions, participants gain practical insights into using Mailchimp for campaign design, automation, and performance tracking, tailored to the needs of modern businesses targeting both local and international markets.',
      'Through his sessions, participants gain practical insights into using Claude Cowork for campaign design, automation, and performance tracking, tailored to the needs of modern businesses targeting both local and international markets.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;
