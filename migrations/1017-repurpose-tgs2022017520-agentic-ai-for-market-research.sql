-- 1017: Repurpose TGS-2022017520
--   "WSQ - Unlocking the Power of Google Analytics (GA4) for Advanced Web Analytics"
--     -> "WSQ - Agentic AI for Market Research"
--
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA / UTAP deep link is keyed
-- on it). Admin-supplied content 2026-08-14: 4 LOs, 4 topics, About narrative.
--
-- Surfaces touched, from the mandatory pre-write EAV sweep of BOTH value tables
-- (memory feedback_tgs_course_rename_checklist -- the sweep is what found these,
-- not an enumerated checklist):
--   name, url_key (+ url_path DELETE at every scope), meta_title, meta_description,
--   meta_keyword, image_label/small_image_label/thumbnail_label, media-gallery
--   label, short_description (About narrative), description (Course Outline /
--   LSN_DATA + rendered topics), whoshouldattend (job roles named the OLD tool),
--   prerequisite (the Minimum Software section linked the OLD TOOL),
--   trainerprofile (course-teaching paragraph only), the learning_outcomes
--   cms_block, a 301 for the old bare slug, and category placement.
--
-- THE ACCREDITED TSC IS UNCHANGED AND IS THE POINT OF THIS REPURPOSE (memory
-- feedback_repurpose_realigns_to_own_accredited_tsc). The skills_framework block
-- reads "Market Research ICT-SNM-3007-1.1 TSC under ICT Skills Framework" -- the
-- new title aligns the course back to its own registered competency. The
-- admin-supplied LOs are the live SSG LOs with ONLY the Google Analytics product
-- wording removed:
--   LO1 "using Google Analytics analytical tool" -> "using analytical tool"
--   LO2 "using Google Analytics reports"         -> "using reports"
--   LO3 / LO4 byte-identical apart from case.
-- MARKET RESEARCH, trend analysis, customer-behaviour analysis, forecasting and
-- marketing-effectiveness evaluation ALL REMAIN in scope -- what retires is the
-- GA4 PRODUCT, not the market-research competency. This is why the analytics /
-- marketing categories are KEPT below and only the Google-product ones dropped.
--
-- NEW-TITLE COLLISION CHECK (memory
-- feedback_repurpose_target_name_may_already_exist_as_live_twin -- probe name AND
-- url_key, not just url_key):
--   * name LIKE '%Market Research%' / '%Agentic AI for Market%': ZERO rows. No
--     live non-WSQ twin owns this title.
--   * url_key LIKE '%market-research%': ZERO rows. The slug is free.
--   The standard wsq--prefixed form is therefore used (no disambiguating suffix),
--   consistent with every other WSQ - Agentic AI sibling.
--
-- meta_title: PLAIN title -- NO leading "WSQ", NO "| Tertiary Courses Singapore"
-- suffix. MMD_Seotitle composes <title> at render time (prepends "WSQ funded" for
-- SG TGS- SKUs and appends the brand postfix). The OLD value baked in BOTH
-- ("WSQ Market Research Using Google Analytics 4 (GA4) - Data-Driven Insights |
-- Tertiary Courses Singapore") -- the 853 bug -- so this migration cleans that up.
--
-- short_description: FULL REPLACE is correct here, not a splice. This course is
-- post-885: its sections live in cms_block rows (brochure / learning_outcomes /
-- certification / skills_framework / funding_and_grant, all confirmed present)
-- and the sdesc holds ONLY the two intro paragraphs -- there is no
-- "<h2>Course Brochure</h2>" tail to preserve. Surface 12 checked: the whole blob
-- was dumped and read first -- no ad-hoc inline vendor / exam-voucher section.
--
-- TRAINER BIOS -- surgical, not wholesale. All 3 bios split cleanly:
--   * para 1 = career CREDENTIALS (real SEO/SEM, digital-marketing and
--     e-commerce history, SPH/iClick/Creative Technology track records, ACLP
--     certifications). TRUE and LEFT ALONE -- rewriting would falsify a real
--     person's bio. Residual "Google Analytics"/"analytics" mentions in para 1
--     are genuine career facts; after applying, every remaining old-tool hit in
--     trainerprofile should sit in para 1 -- that is the PASS condition, not zero
--     hits (memory feedback_tgs_course_rename_checklist, trainer-bio split).
--   * para 2 = a COURSE-TEACHING claim scoped to GA4. Retargeted to the agentic
--     market-research delivery.
-- One exact single-line REPLACE() per bio -- a multi-line REPLACE() silently
-- no-ops on these CRLF WYSIWYG blobs (memory
-- feedback_multiline_replace_fails_on_crlf_blobs). Byte-probed with LOCATE()
-- before writing; CRLF confirmed present at offset 606.
--
-- prerequisite: NOT rewritten wholesale -- it holds the ENTIRE funding apparatus
-- (PWM, Funding Eligibility table, SkillsFuture/PSEA/SFEC/UTAP deep links, Appeal
-- Process). Only the two <li> rows in "Minimum Software/Hardware Requirement"
-- that link the OLD TOOL are REPLACE()d (byte-probed at offsets 848 / 984).
-- Deep-link counts that MUST survive: myskillsfuture.gov.sg = 4, ntuc.org.sg = 2,
-- mom.gov.sg = 1.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * sku, duration (16), sessions (2) -- accredited course params.
--   * course_TGS-2022017520_skills_framework -- the TSC the new title realigns
--     to; must NOT change (memory feedback_repurpose_realigns_to_own_accredited_tsc
--     step 3).
--   * _certification / _brochure / _funding_and_grant -- keyed on the unchanged
--     SKU; WSQ accreditation, fee table and OpenCerts wording are unaffected by a
--     title change. Grepped all five course_TGS-2022017520_* blocks for the old
--     title (memory feedback_repurpose_away_from_certification_brand surface 3):
--     no stray old-title line.
--   * badge tags (WSQ, SkillsFuture Credit, PSEA, UTAP, SFEC, MCES, Absentee
--     Payroll) -- funding eligibility unchanged.
--   * image/small_image/thumbnail PATHS (/w/s/wsq-unlocking-the-power-...jpg) --
--     filesystem paths, not display text; renaming them 404s the file. The
--     storefront renders course_image_url. Only the LABELS (alt text) change
--     here; the R2 cover PNG still bakes the old title and is re-rendered
--     separately.
--   * catalogsearch_query -- the anchored sweep on the FULL old filename
--     ('%wsq-unlocking-the-power-of-google-analytics%') returned ZERO rows, and
--     the only row for the bare course code (query_id 58511, 'TGS-2022017520')
--     has an EMPTY redirect. An empty redirect is NOT a TODO -- surface 7 only
--     applies to rows whose redirect points at the OLD SLUG (memory
--     feedback_repurpose_target_name_may_already_exist_as_live_twin). Search
--     redirects are DATA and are applied live, never via a migration.
--
-- CATEGORY PLACEMENT: the repurpose retires the GOOGLE ANALYTICS PRODUCT, not the
-- market-research subject, so the split follows that axis exactly:
--   DROP  67 "Google" (30 members, pure Google-product listing) and
--         239 "Google Analytics" (5 members: GTM, GA4 and vibe-coding titles --
--         a pure GA-product listing). Mirrored into
--         catalog_category_product_index or the storefront listing never changes
--         (memory feedback_category_swap_needs_index_mirror).
--   KEEP  8 Digital Marketing, 126 Marketing Analytics, 307 WSQ Data Analytics &
--         Data Visualization, 308 WSQ Digital Marketing Courses, 72 WSQ Media &
--         Marketing Courses, 3/15/53/292/293/301 -- the course still teaches
--         market research, analytics and marketing evaluation.
--   ADD   252 "AI Courses" (the master AI listing EVERY "WSQ - Agentic AI"
--         sibling belongs to -- measured across all 11 siblings), 189 "Agentic AI
--         Series", 196 "WSQ Agentic AI Courses", 325 "WSQ AI Courses" and 281
--         "Claude AI Series" (the course is built on Claude Cowork + MCP +
--         Claude Skills). Inserted at MAX(position)+1 so the category-ordering
--         sweep can renumber later.
--
-- PARTNER SAFETY: TGS- SKUs are Singapore WSQ courses; MY/GH partner DBs have no
-- such SKU, so @e is NULL there and every statement matches zero rows (clean
-- no-op). All INSERTs are guarded on @e IS NOT NULL so apply.php cannot abort on
-- a NOT-NULL entity_id (memory feedback_sku_migrations_hit_partners_irreversibly).
--
-- IDEMPOTENCY: every statement either sets a full target value or REPLACE()s an
-- exact old string that no longer exists after the first run. Re-running converges.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2022017520');

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
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='whoshouldattend');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='prerequisite');
SET @a_trainer := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='trainerprofile');

-- ---------------------------------------------------------------------------
-- 1. name  (keep the "WSQ - " prefix -- the storefront H1 wants it)
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'WSQ - Agentic AI for Market Research'
WHERE entity_id = @e AND attribute_id = @a_name;

-- ---------------------------------------------------------------------------
-- 2. url_key + url_path
--    Delete url_path at EVERY scope (store 0 AND store 1 both hold the old
--    value) so the URL Rewrites indexer regenerates.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'wsq-agentic-ai-for-market-research'
WHERE entity_id = @e AND attribute_id = @a_urlkey;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND attribute_id = @a_urlpath;

-- Drop any is_system = 0 squatter on the NEW path first: INSERT IGNORE silently
-- no-ops against a stale row (the 647 trap).
DELETE FROM core_url_rewrite
WHERE request_path = 'wsq-agentic-ai-for-market-research.html' AND is_system = 0;

-- 301 for the old BARE slug. The old path is held by the product's own
-- is_system = 1 rewrite (url_rewrite_id 1014849, id_path 'product/1092'), so an
-- INSERT IGNORE would hit the unique key on (request_path, store_id) and
-- SILENTLY NO-OP -- deleting is_system = 0 squatters does not help.
-- Convert the system row IN PLACE instead (memory
-- feedback_rename_301_vs_system_rewrite_suffix_trap, stage 1). The indexer
-- auto-301s the ~20 category paths from its rewrite history.
UPDATE core_url_rewrite
SET target_path = 'wsq-agentic-ai-for-market-research.html',
    is_system   = 0,
    options     = 'RP',
    description = 'Repurpose 1017: old GA4 slug -> Agentic AI for Market Research'
WHERE request_path = 'wsq-unlocking-the-power-of-google-analytics-ga4-for-advanced-web-analytics.html'
  AND target_path <> 'wsq-agentic-ai-for-market-research.html';

-- ---------------------------------------------------------------------------
-- 3. meta_title / meta_description / meta_keyword
--    meta_title is the PLAIN title: MMD_Seotitle adds "WSQ funded" + the brand
--    suffix at render time. The old value baked in both (the 853 bug).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'Agentic AI for Market Research'
WHERE entity_id = @e AND attribute_id = @a_mtitle;

UPDATE catalog_product_entity_varchar
SET value = 'WSQ course on Agentic AI for Market Research. Use Claude Cowork, MCP tools and custom Claude Skills to analyse market trends, customer behaviour and marketing effectiveness. Up to 70% WSQ funding subsidy.'
WHERE entity_id = @e AND attribute_id = @a_mdesc;

UPDATE catalog_product_entity_text
SET value = 'Agentic AI, Market Research, Claude Cowork, Claude Skills, MCP, WSQ Funding, Competitor Analysis, Customer Personas, Market Trends, Forecasting'
WHERE entity_id = @e AND attribute_id = @a_mkey;

-- ---------------------------------------------------------------------------
-- 4. Alt-text labels + media-gallery label. These carry the PLAIN title (the
--    cover renderer itself strips the "WSQ - " prefix). The R2 cover PNG is
--    re-rendered separately.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'Agentic AI for Market Research'
WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'Agentic AI for Market Research'
WHERE g.entity_id = @e;

-- ---------------------------------------------------------------------------
-- 5. short_description -- the "About This Course" narrative (admin-supplied).
--    Full replace: sections live in cms_block rows, sdesc is prose only.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<p>This course equips participants with practical skills to use Claude Cowork and agentic AI to conduct efficient, structured, and insight-driven market research. Learners will use Claude Cowork to define research objectives, formulate research questions, identify reliable information sources, analyse competitors, explore industry trends, and understand customer needs and behaviours.</p>
<p>Participants will learn how to connect Claude Cowork with relevant documents, datasets, business applications, and research sources through Model Context Protocol (MCP) tools. These integrations enable AI-assisted workflows for gathering, organising, comparing, and synthesising information from multiple sources while maintaining human oversight and verifying the reliability of findings.</p>
<p>The course also guides learners in creating custom Claude Skills from real-world market research processes. These reusable skills can support activities such as developing customer personas, analysing survey responses, conducting competitor comparisons, evaluating market opportunities, identifying emerging trends, and producing structured research reports. Participants will learn to incorporate research frameworks, templates, evaluation criteria, and reporting standards into repeatable workflows.</p>
<p>Through hands-on activities and practical business scenarios, learners will use Claude Cowork to transform complex information into clear findings, visual summaries, and actionable recommendations. By the end of the course, participants will be able to build an agentic market research workflow that improves research efficiency, strengthens evidence-based decision-making, and supports the development of effective marketing and business strategies.</p>'
WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- ---------------------------------------------------------------------------
-- 6. description -- the Course Outline. Both the LSN_DATA JSON comment (which
--    drives the structured outline) and the rendered markup must agree; the
--    storefront reads LSN_DATA when present. 4 admin-supplied topics.
--    NOTE the live value used <h3 class="course-topic-h3"> + <ul> sub-bullets;
--    the sub-bullets were GA4 report names (Acquisition/Monetization reports,
--    Funnel Visualization) and do not survive the repurpose. Topics-only is the
--    current house shape (cf. 967 / 997 / 999).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Identifying Market Research Data and Sources with Claude Cowork","subsecs":[]},{"title":"Topic 2: Analysing Market Trends and Industry Developments","subsecs":[]},{"title":"Topic 3: Customer Behaviour Analysis, Market Dynamics and Forecasting","subsecs":[]},{"title":"Topic 4: Evaluating Marketing Effectiveness with Agentic AI Models and Indicators","subsecs":[]}] -->
<p><strong>Topic 1: Identifying Market Research Data and Sources with Claude Cowork</strong></p>
<p><strong>Topic 2: Analysing Market Trends and Industry Developments</strong></p>
<p><strong>Topic 3: Customer Behaviour Analysis, Market Dynamics and Forecasting</strong></p>
<p><strong>Topic 4: Evaluating Marketing Effectiveness with Agentic AI Models and Indicators</strong></p>'
WHERE entity_id = @e AND attribute_id = @a_desc;

-- ---------------------------------------------------------------------------
-- 7. whoshouldattend -- the job-role list named the OLD TOOL ("Web Analyst",
--    "SEO Strategist", "SEM Manager" are GA4-console roles). Re-pointed at
--    market-research / insights roles; genuinely generic marketing roles
--    (Market Research Analyst, Product Manager, Brand Strategist ...) are kept.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<ul>
<li>Market Research Analyst</li>
<li>Market Intelligence Specialist</li>
<li>Consumer Insights Analyst</li>
<li>Competitive Intelligence Analyst</li>
<li>Digital Marketing Specialist</li>
<li>Content Marketing Manager</li>
<li>E-commerce Manager</li>
<li>User Experience (UX) Researcher</li>
<li>Business Analyst</li>
<li>Strategy and Planning Executive</li>
<li>Product Manager</li>
<li>Brand Strategist</li>
<li>Customer Acquisition Specialist</li>
<li>Media Planner</li>
<li>Business Owner or Entrepreneur conducting market research</li>
</ul>'
WHERE entity_id = @e AND attribute_id = @a_who;

-- ---------------------------------------------------------------------------
-- 8. prerequisite -- ONLY the two Minimum Software <li> rows that link the OLD
--    TOOL. The rest of this 12KB blob is the funding apparatus and must survive
--    byte-identical (deep-link counts: myskillsfuture=4, ntuc=2, mom=1).
--    Exact strings byte-probed with LOCATE() at offsets 848 and 984.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      '<li><a href="https://analytics.google.com/" target="_blank"><span style="text-decoration: underline;">Google Analytics</span></a></li>',
      '<li><a href="https://claude.ai/" target="_blank"><span style="text-decoration: underline;">Claude</span></a></li>'
    )
WHERE entity_id = @e AND attribute_id = @a_prereq;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      '<li><a href="https://datastudio.google.com/" target="_blank"><span style="text-decoration: underline;">Google Data Studio</span></a></li>',
      '<li><a href="https://modelcontextprotocol.io/" target="_blank"><span style="text-decoration: underline;">Model Context Protocol (MCP)</span></a></li>'
    )
WHERE entity_id = @e AND attribute_id = @a_prereq;

-- ---------------------------------------------------------------------------
-- 9. trainerprofile -- retarget the COURSE-TEACHING sentences only (the tail of
--    each bio). Career-history / credential text is left factual.
--    One exact single-line REPLACE() per bio (CRLF-safe).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'Her hands-on expertise in website development, SEO, and Google Analytics allows her to guide learners in applying advanced GA4 techniques to optimize digital presence and improve ROI.',
      'Her hands-on expertise in digital marketing, customer insights, and market analysis allows her to guide learners in applying agentic AI techniques to research markets, understand customers, and improve ROI.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'Her ability to bridge strategic marketing with analytics-driven insights ensures participants gain not only technical GA4 skills but also practical business applications to elevate their organizations&rsquo; digital performance.',
      'Her ability to bridge strategic marketing with insight-driven research ensures participants gain not only technical agentic AI skills but also practical business applications to elevate their organizations&rsquo; market understanding.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'With deep expertise in GA4, digital advertising, and marketing channel performance, Raymond equips learners with advanced techniques to analyze user behavior, optimize campaigns, and unlock business value through data-driven decision-making.',
      'With deep expertise in market intelligence, digital advertising, and marketing channel performance, Raymond equips learners with agentic AI techniques to research market trends, analyze customer behaviour, and unlock business value through evidence-based decision-making.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'With a strong focus on marketing analytics, CRM, and automation, Allen integrates tools such as Google Analytics and AI-powered insights to design high-performing, customer-centric strategies.',
      'With a strong focus on market research, CRM, and automation, Allen integrates agentic AI tools and AI-powered insights to design high-performing, customer-centric strategies.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'Learners in his GA4 sessions benefit from his hands-on approach to unlocking deeper insights, applying advanced reporting, and turning analytics into actionable business outcomes.',
      'Learners in his agentic AI sessions benefit from his hands-on approach to unlocking deeper market insights, building reusable research workflows, and turning findings into actionable business outcomes.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

-- ---------------------------------------------------------------------------
-- 10. learning_outcomes cms_block -- the What You'll Learn card. The
--     admin-supplied LOs are the live SSG-registered LOs with only the Google
--     Analytics product wording removed. The block EXISTS (block_id 1814,
--     verified), so a plain UPDATE is safe; no guarded INSERT needed
--     (contrast: memory feedback_tgs_course_rename_checklist surface 6b).
-- ---------------------------------------------------------------------------
UPDATE cms_block
SET content = '<p>By the end of the course, learners will be able to&nbsp;</p>
<ul>
<li>LO1: Determine data types and identify data sources using analytical tool.</li>
<li>LO2:&nbsp;Analyze market trends using reports to gather data and determine variables.</li>
<li>LO3:&nbsp;Analyze customer behavior and dynamics using explorations and forecasting techniques.</li>
<li>LO4:&nbsp;Evaluate the effectiveness of marketing efforts using modeling techniques, indicators, events and conversions.</li>
</ul>'
WHERE identifier = 'course_TGS-2022017520_learning_outcomes';

-- ---------------------------------------------------------------------------
-- 11. Category placement.
--     DROP the two Google-PRODUCT listings, mirrored into
--     catalog_category_product_index or the storefront listing never changes.
-- ---------------------------------------------------------------------------
DELETE FROM catalog_category_product       WHERE product_id = @e AND category_id IN (67, 239);
DELETE FROM catalog_category_product_index WHERE product_id = @e AND category_id IN (67, 239);

--     ADD the AI / agentic listings every "WSQ - Agentic AI" sibling belongs to,
--     plus the Claude series (the course is built on Claude Cowork).
--     Guarded on @e IS NOT NULL so partner DBs no-op cleanly.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.category_id, @e,
       COALESCE((SELECT MAX(x.position) + 1
                   FROM (SELECT * FROM catalog_category_product) x
                  WHERE x.category_id = c.category_id), 1)
  FROM (SELECT 252 AS category_id UNION ALL SELECT 189 UNION ALL SELECT 196
        UNION ALL SELECT 325 UNION ALL SELECT 281) c
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity ce WHERE ce.entity_id = c.category_id);

--     Mirror the ADDs into catalog_category_product_index too. The DELETEs above
--     are mirrored, and the index mirror is just as necessary in the INSERT
--     direction: without it the five new listings show the course only after a
--     catalog_category_product reindex, which the deploy does NOT run (memory
--     feedback_category_swap_needs_index_mirror +
--     feedback_reindex_api_prod_flat_stale). Verified live: the rows were absent
--     from the index until reindexEverything() ran.
--     Copies the position just written, per (store, visibility) shape already
--     present for this product, so it matches what the indexer would produce.
INSERT IGNORE INTO catalog_category_product_index
    (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, s.store_id, i.value
  FROM catalog_category_product cp
  CROSS JOIN (SELECT store_id FROM core_store WHERE store_id > 0) s
  JOIN catalog_product_entity_int i
    ON i.entity_id = cp.product_id
   AND i.store_id = 0
   AND i.attribute_id = (SELECT attribute_id FROM eav_attribute
                          WHERE entity_type_id = 4 AND attribute_code = 'visibility')
 WHERE cp.product_id = @e
   AND cp.category_id IN (252, 189, 196, 325, 281)
   AND @e IS NOT NULL;
