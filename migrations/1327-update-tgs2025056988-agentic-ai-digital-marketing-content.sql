-- 1327: Content update for TGS-2025056988
--   "WSQ - Agentic AI for Digital Marketing"
--   https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-digital-marketing.html
--
-- NOT a repurpose, NOT a rename. The SKU, course name, url_key, price,
-- duration, categories, funding apparatus and every SkillsFuture/SFEC/SFC/PSEA
-- deep link are keyed on an UNCHANGED course identity. The course REMAINS WSQ
-- (TGS- SKU, "WSQ - " name prefix) exactly as before -- nothing in this file
-- touches WSQ status, funding tags or the accreditation surfaces.
--
-- This migration rewrites TWO content surfaces only, from admin-supplied copy
-- (2026-09-05). The delivery tooling narrative moves from n8n to Claude Cowork
-- / agentic + generative AI, which is why both the outline and the About text
-- are restated in full:
--
--   1. catalog_product_entity_text.description -- the Course Outline. The live
--      value held three n8n-centric topics ("...with n8n", "Governed
--      Multi-Channel Content Automation and Human Approval", "Social
--      Publishing, Performance Attribution and Optimisation with n8n");
--      replaced with the three supplied topics. The LSN_DATA JSON marker is
--      updated IN SYNC with the visible markup -- see the note at section 1.
--   2. catalog_product_entity_text.short_description -- the "What's This Course
--      About" narrative, replaced with the supplied five-paragraph text.
--
-- Deliberately UNCHANGED (each verified against live SG data before writing):
--   * course_TGS-2025056988_learning_outcomes (cms_block) -- the live block
--     ALREADY carries the supplied LO1/LO2/LO3 verbatim, so there is no update
--     to make. Re-stating it would be a no-op write; omitted on purpose.
--   * sku / name / url_key -- course identity unchanged, so there is NO rename,
--     NO 301 and no search-redirect retarget. The course-url-change checklist
--     does not apply here.
--   * course_TGS-2025056988_funding_and_grant / _brochure / _skills_framework
--     -- all keyed on the unchanged SKU; WSQ funding wording is unaffected.
--   * meta_title / meta_description -- BOTH still name n8n and are therefore
--     now INCONSISTENT with the rewritten content above. Verified on live SG
--     (both are `varchar` backend_type, store_id = 0; there is no meta_keyword
--     row):
--       meta_title       = "Agentic AI for Digital Marketing with n8n Automation"
--       meta_description = "Build governed n8n marketing automations from
--                           research and content creation to human approval,
--                           social publishing, ROI measurement and
--                           optimisation. Up to 70% WSQ funding subsidy."
--     meta_description also feeds the schema.org/Course JSON-LD on the product
--     page, so the n8n wording reaches Google's snippet and structured data.
--     LEFT UNCHANGED ON PURPOSE: the admin supplied replacement copy for the
--     outline and the About narrative ONLY, and inventing SEO/meta copy is not
--     this migration's job. FLAGGED TO THE ADMIN (2026-09-05) -- if new meta
--     copy is supplied, ship it as its own follow-up migration.
--   * price / duration / sessions / whoshouldattend / prerequisite /
--     additional_note / assessment_methods / trainerprofile.
--   * image/small_image/thumbnail paths, media-gallery labels, the rendered
--     cover PNG, and all category placements.
--
-- IDEMPOTENCY: both statements set the FULL target value (never a REPLACE()
-- over a fragment) and are guarded on the SKU, so re-running is a no-op.
-- Full-value SET is also what keeps this safe regardless of line endings -- a
-- multi-line REPLACE() would silently no-op on a CRLF blob (memory
-- feedback_multiline_replace_fails_on_crlf_blobs). Live values were verified
-- LF-only and pure ASCII (LENGTH = CHAR_LENGTH), and only store_id = 0 rows
-- exist for these two attributes, so a single unscoped UPDATE covers the
-- storefront completely.
--
-- PARTNER SAFETY: TGS- SKUs are Singapore WSQ courses. MY/GH partner DBs have
-- no such SKU, so every statement below matches zero rows there and the
-- migration is a clean no-op on those servers. No @is_sg guard is needed (and
-- none is used -- the SKU match is the guard).

-- ---------------------------------------------------------------------------
-- 1. Course Outline -> description ("What You'll Learn" card)
--
-- The leading <!-- LSN_DATA: [...] --> comment is NOT decoration: the admin
-- Lesson panel parses it to build the collapsible topic cards
-- (dashboard/index.phtml:3865, :6397, :6907 and course-topics-tools.js). It
-- MUST stay in sync with the visible <p><strong>Topic N</strong></p> markup
-- below or the admin view and the storefront disagree. Topic-level only, so
-- every "subsecs" array is empty -- the supplied outline gives topic titles
-- with no subtopics. Three topics, matching LO1-LO3.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text v
JOIN catalog_product_entity e ON e.entity_id = v.entity_id
JOIN eav_attribute a          ON a.attribute_id = v.attribute_id
                             AND a.attribute_code = 'description'
SET v.value = '<!-- LSN_DATA: [{"title":"Topic 1: Digital Marketing Research and Campaign Planning with Agentic AI","subsecs":[]},{"title":"Topic 2: Creating Multi-Channel Marketing Content with Generative AI","subsecs":[]},{"title":"Topic 3: Integrating Tools and Analysing Digital Marketing Performance","subsecs":[]}] -->
<p><strong>Topic 1: Digital Marketing Research and Campaign Planning with Agentic AI</strong></p>
<p><strong>Topic 2: Creating Multi-Channel Marketing Content with Generative AI</strong></p>
<p><strong>Topic 3: Integrating Tools and Analysing Digital Marketing Performance</strong></p>'
WHERE e.sku = 'TGS-2025056988';

-- ---------------------------------------------------------------------------
-- 2. About This Course -> short_description ("What's This Course About" card)
--
-- The live short_description carries the narrative ONLY -- Learning Outcomes,
-- Brochure, Funding and Skills Framework all live in their own cms/blocks
-- (verified: the live value contains no <h2> section heading for
-- view.phtml::$_extractSection to strip). Replacing the whole value therefore
-- cannot destroy a carded section (memory
-- feedback_conversion_drops_legacy_funding_fallback).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text v
JOIN catalog_product_entity e ON e.entity_id = v.entity_id
JOIN eav_attribute a          ON a.attribute_id = v.attribute_id
                             AND a.attribute_code = 'short_description'
SET v.value = '<p>This course equips learners with practical skills to use generative ai and agentic AI to plan, create, manage, and optimise digital marketing activities across multiple channels. Participants will learn how to use agentic ai and generative ai as an intelligent marketing workspace for conducting market research, understanding target audiences, developing campaign strategies, coordinating tasks, and producing consistent, brand-aligned marketing content.</p>
<p>Learners will explore how tools can connect Claude Cowork with relevant business applications, documents, data sources, content repositories, and marketing platforms. These integrations enable Claude Cowork to retrieve information, work across systems, and support end-to-end digital marketing workflows with appropriate human oversight.</p>
<p>The course also guides participants in creating custom Claude Skills from real-world marketing processes. Learners will transform repeatable tasks, brand guidelines, templates, and quality standards into reusable skills for campaign planning, content creation, review, reporting, and optimisation. They will apply these skills to produce channel-specific content for websites, blogs, search engines, email campaigns, social media, online advertisements, and other digital touchpoints.</p>
<p>Participants will also use Claude Cowork to analyse campaign results, compare performance against marketing objectives and KPIs, identify trends, evaluate return on investment, and generate actionable recommendations. By the end of the course, learners will be able to build integrated, AI-assisted digital marketing workflows that improve productivity, content consistency, audience engagement, and data-driven decision-making.</p>
<p>This course is suitable for beginner and intermediate learners who have a basic understanding of digital marketing and want to apply agentic ai and generative ai skills in practical marketing environments.</p>'
WHERE e.sku = 'TGS-2025056988';
