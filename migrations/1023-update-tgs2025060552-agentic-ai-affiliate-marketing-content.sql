-- 1021: Content update for TGS-2025060552 "WSQ - Agentic AI for Affiliate Marketing"
--
-- TWO DISTINCT JOBS IN ONE MIGRATION (both keyed on the same entity):
--   (A) Apply the admin-supplied 2026-08-14 content: About narrative + 3-topic
--       Course Outline rebuilt around Claude Cowork / agentic AI.
--   (B) Finish an EARLIER, PARTIAL rename. `name` and `url_key` were already
--       moved to "Agentic AI for Affiliate Marketing" (and all 301s exist -- see
--       the rewrite note below), but FIVE surfaces were left carrying the dead
--       title "WSQ - Building Targeted Lead Lists for Affiliate Marketing
--       Growth": meta_title, image_label, small_image_label, thumbnail_label and
--       the media_gallery label. The pre-write sweep of BOTH EAV value tables
--       (memory feedback_tgs_course_rename_checklist) is what surfaced them.
--
-- SKU unchanged -- every SkillsFuture / SFEC / SFC / PSEA / UTAP deep link is
-- keyed on it.
--
-- THIS IS A DELIVERY-METHOD UPDATE, NOT A SUBJECT CHANGE (memory
-- feedback_repurpose_realigns_to_own_accredited_tsc -- read skills_framework
-- FIRST). Two independent confirmations that the accredited competency is
-- untouched:
--   * course_TGS-2025060552_skills_framework reads "Affiliate Marketing-2
--     RET-OTO-2001-1.1 TSC under Retail Skills Framework". The registered
--     competency is AFFILIATE MARKETING; agentic AI is the new delivery vehicle.
--   * The admin-supplied LO1-LO3 are BYTE-EQUIVALENT to the live
--     course_TGS-2025060552_learning_outcomes block (identical wording; the
--     supplied text merely omits the space after "LO2:"/"LO3:").
-- That decides the scope: affiliate-marketing content, categories, job roles and
-- the retail/hospitality framing ALL STAY. Only the Course Outline and the About
-- narrative are rewritten to describe the Claude Cowork delivery.
--
-- learning_outcomes cms_block DELIBERATELY NOT TOUCHED -- it already carries
-- exactly the requested LOs, and these are the SSG-accredited outcomes
-- registered against the unchanged SKU. Rewriting to restyle the colon spacing
-- would be churn against accredited content.
--
-- description: the OLD outline was the SSG LU/T structure (LU1-LU3, each with
-- 4-5 T-items) mirroring the three LOs. The admin supplied THREE topics with no
-- sub-bullets, so the outline becomes topics-only -- matching the shape of
-- 960 / 967 / 999. Both the LSN_DATA JSON comment (which drives the structured
-- outline) and the rendered markup are rewritten together; the storefront reads
-- LSN_DATA when present, so leaving one behind would desync the page.
--
-- meta_title: PLAIN title -- NO leading "WSQ", NO "| Tertiary Courses Singapore"
-- suffix. MMD_Seotitle composes <title> at render time (prepends "WSQ funded"
-- for SG TGS- SKUs and appends the brand postfix). The stale value baked in BOTH
-- ("WSQ Building Targeted Lead Lists ... | Tertiary Courses Singapore") -- the
-- 853 bug -- so this cleans that up while retitling.
--
-- meta_description: 168 chars, under the varchar(255) cap (memory
-- feedback_meta_description_255_char_cap).
--
-- short_description: FULL REPLACE is correct, not a splice. This course is
-- post-885: its sections live in cms_block rows (brochure / learning_outcomes /
-- skills_framework / funding_and_grant, all four confirmed present) and the
-- sdesc holds ONLY the prose paragraphs -- there is no "<h2>Course Brochure</h2>"
-- tail to preserve. Surface 12 checked explicitly (memory
-- feedback_repurpose_away_from_certification_brand): the whole blob was dumped
-- and read first -- there is NO ad-hoc inline vendor section (no Exam Voucher /
-- ATC / test-centre copy), so nothing is silently lost.
--
-- prerequisite: its "Minimum Software/Hardware Requirement" section reads
-- "Software: TBD" -- there is no old tool link to swap, so the Claude Cowork
-- link is INSERTED via an exact-string REPLACE() on that TBD marker. The rest of
-- this blob is the funding apparatus (Promotion Code, Minimum Entry Requirement,
-- age group) and is NEVER rewritten wholesale.
--
-- trainerprofile: surgical, single-line REPLACE() per sentence -- a multi-line
-- REPLACE() silently no-ops on these CRLF WYSIWYG blobs (memory
-- feedback_multiline_replace_fails_on_crlf_blobs). Allen Wong's bio splits
-- cleanly:
--   * para 1 = career CREDENTIALS (Medistation CEO, $5M revenue, CRM/analytics
--     history). TRUE and LEFT ALONE -- rewriting would falsify a real person's
--     bio. Only its trailing COURSE-TEACHING claim ("master the art of building
--     targeted lead lists") is retargeted, since it names the dead course title.
--   * para 2 = a second teaching claim ("harness digital tools to accelerate
--     affiliate marketing growth") -- retargeted to agentic AI / Claude Cowork.
--   Both source sentences end WITHOUT a full stop in the live data; the
--   REPLACE() strings reproduce that exactly or they no-op.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * sku, price, duration, sessions -- accredited course params.
--   * url_key / url_path -- ALREADY 'wsq-agentic-ai-for-affiliate-marketing'.
--   * core_url_rewrite -- the earlier rename already seeded the full 301 set:
--     the bare old slug plus all 9 category-path variants
--     (adult-training-courses/, digital-marketing-courses-in/, latest-courses/,
--     wsq-media-marketing-courses/, wsq-digital-marketing-courses/,
--     wsq-it-security-courses/, wsq-ibf-skillsfuture-utap-funded-courses/ and
--     two nested forms) all point at the new path with is_system = 0. Nothing to
--     add; seeding again would be a no-op at best and a duplicate at worst.
--   * whoshouldattend -- swept and CLEAN. All 20 job roles (Affiliate Marketing
--     Manager, Partnership Development Executive, Retail Marketing Specialist,
--     Hospitality Marketing Manager, ...) are tool-neutral affiliate-marketing
--     roles that still describe the updated course exactly.
--   * course_TGS-2025060552_skills_framework -- the TSC is unchanged and is the
--     reason the subject content stays; must NOT change.
--   * _brochure / _funding_and_grant -- keyed on the unchanged SKU. Both grepped
--     for the old title: ZERO hits (memory
--     feedback_repurpose_away_from_certification_brand warns a stray old-title
--     line can hide in funding_and_grant -- checked, absent here).
--   * badge tags (funding eligibility unchanged).
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. Only the LABELS (alt text) change here
--     (memory feedback_media_gallery_label_is_the_real_alt_text). The R2 cover
--     PNG still bakes the old title and is re-rendered from the admin.
--   * CATEGORY PLACEMENT -- all placements KEPT. Because the TSC and subject are
--     unchanged, every listing still describes the course.
--   * catalogsearch_query -- search redirects are DATA and are applied live,
--     never via a migration (memory feedback_search_redirects_always_apply_live).
--
-- PARTNER SAFETY: TGS- SKUs are Singapore WSQ courses; MY/GH partner DBs have no
-- such SKU, so @e resolves NULL and every statement matches zero rows there
-- (clean no-op).
--
-- IDEMPOTENCY: every statement either sets a full target value or REPLACE()s an
-- exact old string that no longer exists after the first run. Re-running
-- converges.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025060552');

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
-- 1. meta_title / meta_description / meta_keyword
--    (B) meta_title still held the dead title AND the double-baked prefix+suffix.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'Agentic AI for Affiliate Marketing'
WHERE entity_id = @e AND attribute_id = @a_mtitle;

UPDATE catalog_product_entity_varchar
SET value = 'Use Claude Cowork and agentic AI to plan, run and optimise affiliate marketing campaigns for retail and hospitality. Enjoy up to 70% WSQ funding subsidy.'
WHERE entity_id = @e AND attribute_id = @a_mdesc;

UPDATE catalog_product_entity_text
SET value = 'Agentic AI affiliate marketing, Claude Cowork, WSQ affiliate marketing course, affiliate campaign automation, AI partner research, MCP tools, Claude Skills, affiliate performance analysis, WSQ digital marketing, affiliate marketing for retail and hospitality'
WHERE entity_id = @e AND attribute_id = @a_mkey;

-- ---------------------------------------------------------------------------
-- 2. (B) Alt-text labels + media-gallery label -- all four still carried the
--    dead title. These take the PLAIN title (the cover renderer itself strips
--    the "WSQ - " prefix).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'Agentic AI for Affiliate Marketing'
WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'Agentic AI for Affiliate Marketing'
WHERE g.entity_id = @e;

-- ---------------------------------------------------------------------------
-- 3. short_description -- the "About This Course" narrative (admin-supplied).
--    Full replace: sections live in cms_block rows, sdesc is prose only.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<p>This course equips participants with the practical skills to use Claude Cowork and agentic AI workflows to plan, execute, and optimise affiliate marketing programmes. Learners will explore how Claude Cowork can support affiliate research, partner discovery, competitor analysis, audience profiling, offer evaluation, campaign planning, and the creation of promotional content across websites, email, social media, and other digital channels.</p>
<p>Participants will learn to connect Claude Cowork with relevant data sources and marketing systems using Model Context Protocol (MCP) tools. They will create reusable Claude Skills based on real-world affiliate marketing processes, such as reviewing potential partners, generating campaign briefs, producing brand-aligned content, managing affiliate communications, and preparing performance reports. These repeatable workflows help improve consistency, reduce manual work, and enable marketing activities to scale more effectively.</p>
<p>The course also covers the use of agentic AI to monitor key metrics such as traffic, clicks, conversions, conversion rates, commissions, revenue, and return on investment. Learners will use Claude Cowork to consolidate campaign information, identify performance trends, compare affiliates and offers, detect potential issues, and recommend data-driven improvements while maintaining human oversight and compliance with marketing policies.</p>
<p>Through practical activities and real-world scenarios, participants will develop an AI-assisted affiliate marketing system that supports faster content production, stronger partner coordination, and continuous campaign optimisation. This course is suitable for beginner and intermediate learners who have foundational digital marketing knowledge and want to apply Claude Cowork and agentic AI to affiliate programme management.</p>'
WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- ---------------------------------------------------------------------------
-- 4. description -- the Course Outline. LSN_DATA JSON and the rendered markup
--    must agree; the storefront reads LSN_DATA when present. 3 admin-supplied
--    topics, no sub-bullets (replacing the old LU1-LU3 / T-item structure).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Affiliate Research and Campaign Planning with Claude Cowork","subsecs":[]},{"title":"Topic 2: Creating Affiliate Content and Automated Workflows with Claude Skills and MCP Tools","subsecs":[]},{"title":"Topic 3: Affiliate Performance Analysis and Campaign Optimisation with Agentic AI","subsecs":[]}] -->
<p><strong>Topic 1: Affiliate Research and Campaign Planning with Claude Cowork</strong></p>
<p><strong>Topic 2: Creating Affiliate Content and Automated Workflows with Claude Skills and MCP Tools</strong></p>
<p><strong>Topic 3: Affiliate Performance Analysis and Campaign Optimisation with Agentic AI</strong></p>'
WHERE entity_id = @e AND attribute_id = @a_desc;

-- ---------------------------------------------------------------------------
-- 5. prerequisite -- fill the "Software: TBD" placeholder with the Claude Cowork
--    tool link. Surgical exact-string REPLACE(); the surrounding funding
--    apparatus is untouched.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      '<p><strong>Software:</strong></p><p>TBD</p>',
      '<p><strong>Software:</strong></p><ul><li><a href="https://claude.com/product/cowork" target="_blank"><span style="text-decoration: underline;">Claude Cowork</span></a></li></ul>'
    )
WHERE entity_id = @e AND attribute_id = @a_prereq;

-- ---------------------------------------------------------------------------
-- 6. trainerprofile -- retarget the two COURSE-TEACHING sentences only. Career
--    credentials stay factual. Note both source strings end WITHOUT a full stop,
--    matching the live data exactly.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'positions him as a key trainer to help participants master the art of building targeted lead lists to drive affiliate marketing success',
      'positions him as a key trainer to help participants apply Claude Cowork and agentic AI workflows to drive affiliate marketing success'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'guiding learners to identify high-value prospects, apply segmentation techniques, and harness digital tools to accelerate affiliate marketing growth',
      'guiding learners to identify high-value affiliate partners, build reusable Claude Skills, and harness agentic AI to accelerate affiliate marketing growth'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;
