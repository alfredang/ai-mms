-- 930: Repurpose CASL course TGS-2026064473 (SKU unchanged)
--   "CASL - Create Social Media Campaigns with Agentic AI"
--   -> "CASL - Agentic AI for Email Marketing Campaign"
-- New About / Learning Outcomes / Course Outline supplied by the admin.
-- Surfaces: name, labels (+ media-gallery label), cover, url_key (+ url_path
-- purge at every scope + 301 from the old slug + legacy alias repoint), SEO
-- meta, short_description, description (LSN_DATA JSON kept in sync),
-- learning_outcomes cms_block, trainerprofile course-mention paragraphs,
-- categories (drop XiaoHongshu/Video Marketing, add Email Marketing),
-- search-term redirects (social-media intent terms retargeted to the live
-- WSQ social-media course, not to this now-email-marketing page).
-- Unchanged on purpose: SKU + funding blocks/validity dates (same TGS code),
-- skills_framework TSC, certification block, brochure block (SKU-keyed; PDF
-- regenerated out-of-band).
-- Partner-safe: TGS- SKUs exist only on SG => @e NULL => guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064473' LIMIT 1);

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_tp    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');

-- ------------------------------------------------------------ 1. name + labels
UPDATE catalog_product_entity_varchar SET value = 'CASL - Agentic AI for Email Marketing Campaign'
  WHERE entity_id = @e AND attribute_id = @a_name AND store_id = 0;

-- Labels are alt text on the cover, which strips the segment prefix itself.
UPDATE catalog_product_entity_varchar SET value = 'Agentic AI for Email Marketing Campaign'
  WHERE entity_id = @e AND attribute_id IN (@a_il, @a_sil, @a_til) AND store_id = 0;

-- Fresh cover rendered 2026-08-12 with the CASL/funding badge chips
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064473-20260812-150348.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label (renders as the zoom-gallery img title/alt)
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'Agentic AI for Email Marketing Campaign'
  WHERE g.entity_id = @e;

-- --------------------------------------------------------------------- 2. URL
UPDATE catalog_product_entity_varchar SET value = 'casl-agentic-ai-for-email-marketing-campaign'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
-- url_path at EVERY scope (store 0 + 1 rows exist) — the URL indexer regenerates
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- 301 from the old bare slug. Drop any non-system squatter first (647: INSERT
-- IGNORE silently no-ops against a stale row). The guarded INSERT lands only
-- once the reindex has moved the system row off the old path; SG's URL indexer
-- also saves rewrite history, so one of the two paths always yields the 301.
DELETE FROM core_url_rewrite
WHERE is_system = 0
  AND request_path = 'casl-create-social-media-campaigns-with-agentic-ai.html'
  AND @e IS NOT NULL;

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('rp_tgs2026064473_social_', s.store_id),
       'casl-create-social-media-campaigns-with-agentic-ai.html',
       'casl-agentic-ai-for-email-marketing-campaign.html', 0, 'RP'
FROM core_store s
WHERE s.store_id > 0 AND @e IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM core_url_rewrite c
    WHERE c.store_id = s.store_id
      AND c.request_path = 'casl-create-social-media-campaigns-with-agentic-ai.html'
      AND c.is_system = 1);

-- Legacy alias 301s that still target the old slug (5 rows on SG prod:
-- deep-learning/xiaohongshu/wsq-* historical renames) — repoint so they don't
-- become a 301 chain through the old path.
UPDATE core_url_rewrite
  SET target_path = 'casl-agentic-ai-for-email-marketing-campaign.html'
  WHERE is_system = 0 AND options = 'RP'
    AND target_path = 'casl-create-social-media-campaigns-with-agentic-ai.html'
    AND @e IS NOT NULL;

-- ---------------------------------------------------------------- 3. SEO meta
-- Plain title only: MMD_Seotitle prepends the funding prefix and appends the
-- brand postfix at render time (baking either duplicates them).
UPDATE catalog_product_entity_varchar SET value = 'Agentic AI for Email Marketing Campaign'
  WHERE entity_id = @e AND attribute_id = @a_mt;

-- meta_description feeds the meta/og/twitter descriptions AND the JSON-LD
UPDATE catalog_product_entity_varchar SET value = 'Learn to plan, automate and optimise email marketing campaigns with agentic AI. Master AI-driven personalisation, campaign analytics and market trend analysis.'
  WHERE entity_id = @e AND attribute_id = @a_md;

UPDATE catalog_product_entity_text SET value = 'Agentic AI for Email Marketing Campaign, agentic AI email marketing, AI email campaigns, email marketing automation, email campaign analytics, personalised email content, lead nurturing automation, A/B testing email campaigns, AI digital marketing course, email marketing course Singapore'
  WHERE entity_id = @e AND attribute_id = @a_mk;

-- --------------------------------------------- 4. About This Course (sdesc)
-- Post-885 block model: short_description is prose only (no section HTML,
-- no SKU deep links) => full replace is safe.
UPDATE catalog_product_entity_text SET value = '<p>Agentic AI for Email Marketing Campaign equips professionals and aspiring digital marketers with practical skills to plan, create, automate and optimise email campaigns using autonomous AI agents. Participants will learn how AI agents can analyse audience data, segment subscribers, generate personalised content and coordinate multi-step campaign workflows with appropriate human oversight.</p>
<p>The course covers AI-assisted creation of subject lines, email copy, calls to action and campaign sequences aligned with brand guidelines and marketing objectives. Learners will explore how agents can manage lead-nurturing journeys, trigger emails based on customer behaviour, conduct A/B testing and recommend suitable delivery schedules. They will also learn to connect AI agents with customer databases, eCommerce platforms and marketing automation tools.</p>
<p>Participants will use AI-driven analytics to monitor open rates, click-through rates, conversions, unsubscribes and other performance indicators. AI agents will support the identification of campaign issues, analysis of customer responses and continuous improvement of content and targeting strategies.</p>
<p>The course also addresses consent management, data privacy, content accuracy, deliverability and responsible AI use. By the end of the course, participants will be able to implement agentic email marketing workflows that improve personalisation, operational efficiency, customer engagement and campaign performance.</p>'
  WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0;

-- ------------------------------------- 5. Course Outline (description + JSON)
UPDATE catalog_product_entity_text SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Implementing Agentic AI Email Marketing Campaigns","subsecs":[]},{"title":"Topic 2: AI-Driven Campaign Performance and Consumer Insights Analysis","subsecs":[]},{"title":"Topic 3: AI Agent Analysis of Market Trends and Customer Feedback","subsecs":[]}] -->
<p><strong>Topic 1: Implementing Agentic AI Email Marketing Campaigns</strong></p>
<p><strong>Topic 2: AI-Driven Campaign Performance and Consumer Insights Analysis</strong></p>
<p><strong>Topic 3: AI Agent Analysis of Market Trends and Customer Feedback</strong></p>'
  WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;

-- --------------------------------- 6. What You'll Learn (cms_block LO list)
UPDATE cms_block SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Implement email marketing campaigns in alignment to strategic marketing objectives.</li>
<li>LO2:&nbsp;Analyse email marketing campaign outcomes using sales performance data and consumer insights.</li>
<li>LO3:&nbsp;Analyse market trends and customer reviews.</li>
</ul>'
  WHERE identifier = 'course_TGS-2026064473_learning_outcomes' AND @e IS NOT NULL;

-- ------------------------------------------- 7. Trainer bios (course mentions)
-- Byte-probed on SG prod 2026-08-12: quote appears 3x, each paragraph target
-- LOCATEs exactly once. Career-history facts (SPH, XiaoHongShu/WeChat platform
-- experience) stay — only the course-teaching claims are retargeted.
UPDATE catalog_product_entity_text SET value = REPLACE(value,
  'In &ldquo;Create Engaging Social E-Commerce Campaigns on XiaoHongShu,&rdquo;',
  'In &ldquo;Agentic AI for Email Marketing Campaign,&rdquo;')
  WHERE entity_id = @e AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text SET value = REPLACE(value,
  'he equips learners with the tools to develop creative, data-driven, and influencer-led marketing campaigns. His teaching emphasizes cultural relevance, brand storytelling, and measurable engagement&mdash;helping businesses connect authentically with audiences on emerging Asian platforms.',
  'he equips learners with the tools to develop creative, data-driven, and AI-assisted email marketing campaigns. His teaching emphasizes audience relevance, brand storytelling, and measurable engagement&mdash;helping businesses connect authentically with their subscribers.')
  WHERE entity_id = @e AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text SET value = REPLACE(value,
  'Janice guides participants through the end-to-end process of building compelling brand narratives and optimizing social selling strategies. Her lessons focus on content marketing, platform analytics, and influencer collaboration&mdash;empowering learners to create authentic and high-performing XiaoHongShu campaigns that resonate with China&rsquo;s digitally savvy consumer base.',
  'Janice guides participants through the end-to-end process of building compelling brand narratives and optimizing email campaign strategies. Her lessons focus on content marketing, campaign analytics, and marketing automation&mdash;empowering learners to create authentic and high-performing email campaigns that resonate with their target audience.')
  WHERE entity_id = @e AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text SET value = REPLACE(value,
  'teach learners how to harness analytics, storytelling, and AI to optimize campaign outcomes. His practical sessions focus on leveraging XiaoHongShu for brand authenticity, user engagement, and conversion',
  'teach learners how to harness analytics, storytelling, and AI agents to optimize email campaign outcomes. His practical sessions focus on personalisation, user engagement, and conversion')
  WHERE entity_id = @e AND attribute_id = @a_tp;

-- -------------------------------------------------------------- 8. Categories
-- Resolve BY NAME (ids differ per instance). Drop the social-media placements;
-- add Email Marketing (mirrors sibling C21 "Agentic AI for Email Marketing").
DELETE cp FROM catalog_category_product cp
  JOIN catalog_category_entity_varchar v ON v.entity_id = cp.category_id AND v.store_id = 0
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'name'
  WHERE cp.product_id = @e AND v.value IN ('XiaoHongshu', 'Video Marketing');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT v.entity_id, @e, 0
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'name'
  WHERE v.store_id = 0 AND v.value = 'Email Marketing' AND @e IS NOT NULL;

-- ---------------------------------------------------- 9. Search-term redirects
-- 15 live rows point at the old slug and are almost all social-media intent
-- (xiaohongshu, "wsq social media", ...). This course is no longer a social
-- media course, so send them to the live WSQ social-media offering instead of
-- letting them 301 into an email-marketing page. The XiaoHongshu category's
-- only other course is disabled, so no better XHS target exists.
UPDATE catalogsearch_query
  SET redirect = 'https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-social-media-marketing.html'
  WHERE redirect LIKE '%tertiarycourses.com.sg/casl-create-social-media-campaigns-with-agentic-ai.html%';

-- Generic "Campaigns" stays with this (campaign) course at its new slug.
UPDATE catalogsearch_query
  SET redirect = 'https://www.tertiarycourses.com.sg/casl-agentic-ai-for-email-marketing-campaign.html'
  WHERE query_text = 'Campaigns'
    AND redirect = 'https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-social-media-marketing.html';
