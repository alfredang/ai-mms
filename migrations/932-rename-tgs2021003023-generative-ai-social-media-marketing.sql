-- 932: Rename TGS-2021003023
--        "WSQ - Driving Brand Engagement with Proven Instagram Social Media Marketing Strategies"
--      -> "WSQ - Generative AI for Social Media Marketing"
--      + Learning Outcomes / Course Outline / About This Course converted from the
--        Instagram-specific copy to the generative-AI-for-social-media angle.
--
-- Course code (SKU) is UNCHANGED - TGS-2021003023 stays, so every funding /
-- SkillsFuture deep link keyed on the course code remains correct. Follows the
-- 851/853/855/930 TGS- rename playbook (8 surfaces).
--
-- Scope of this file:
--   1. name / meta_title / meta_description / image labels -> new title
--   2. url_key -> wsq-generative-ai-for-social-media-marketing ; url_path deleted
--      at every scope so the Catalog URL Rewrites indexer regenerates it
--   3. 301 the old slug at the new one (repoint the pre-reindex system row +
--      INSERT IGNORE fallback, both scopes), and repoint the two legacy alias
--      rewrites that 301 INTO the old slug (wsq-social-media-marketing-instagram,
--      wsq-social-media-marketing-facebook-1171) so inbound links take one hop
--   4. description -> the new 4-topic Course Outline (same campaign-lifecycle
--      structure, Instagram-specific items -> generative AI)
--   5. short_description -> new About This Course. FULL REPLACE, not a splice:
--      this course's sections were stripped to cms/block rows on 2026-07-21, so
--      short_description is ONLY the two intro paragraphs (no <h2> tail).
--   6. meta_keyword refreshed to lead with the new course name
--   7. media gallery per-image label
--   8. cms_block course_TGS-2021003023_learning_outcomes: LO3/LO4 said
--      "Instagram" -> generative AI (LO1/LO2 kept verbatim)
--   9. trainerprofile: all four trainer bios' second paragraph pitched the
--      Instagram training specifically - rewritten to the generative-AI angle
--      (career-history paragraphs untouched; platform mentions there are fine)
--  10. whoshouldattend: three Instagram-specific roles generalised
--  11. prerequisite: ChatGPT added to the software list (Instagram kept -
--      campaigns still deploy on social platforms)
--  12. search-term redirects: retarget live rows pointing at the old slug AND
--      at the legacy alias wsq-social-media-marketing-instagram.html straight
--      to the new slug (single hop); also applied live on prod per
--      feedback_search_redirects_always_apply_live
--
-- meta_title deliberately omits BOTH the leading "WSQ" and the
-- "| Tertiary Courses Singapore" suffix: MMD_Seotitle composes the <title> at
-- render time (Block/Html/Head.php), prepending the funding prefix for any SG
-- TGS- SKU and appending the brand postfix. The OLD meta_title had both baked
-- in - this also cleans that up.
--
-- NOT rewritten (verified against prod 2026-08-12 before authoring):
--   - cms_block _brochure / _certification / _skills_framework /
--     _funding_and_grant: keyed on the unchanged SKU, no old-title mention
--     (skills framework TSC "Social Media Marketing RET-OTO-4007-1.1" still fits)
--   - Funding-badge tags (WSQ/SFC/PSEA/UTAP/SFEC/AP/MCES): unchanged
--   - news_from/to_date Funding Validity window: unchanged registration
--
-- The cover PNG and brochure PDF bake the old title - regenerate both on prod
-- after this applies (MMD_CourseImage strips the "WSQ - " prefix at render).
--
-- Partner-safe: every statement guarded on @e (TGS- SKUs only exist on SG; on
-- MY/GH @e IS NULL and the whole file no-ops); rewrite/search statements are
-- additionally guarded on the SG store. Idempotent - re-runnable.

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021003023' LIMIT 1);
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'name');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_title');
SET @a_md   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_description');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_key');
SET @a_up   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_path');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'thumbnail_label');
SET @a_mk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_keyword');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'description');
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'short_description');
SET @a_tp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'trainerprofile');
SET @a_wsa  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'whoshouldattend');
SET @a_pre  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'prerequisite');

-- ---------------------------------------------------------------- 1. varchars

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_name, 0, @e, 'WSQ - Generative AI for Social Media Marketing' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- No WSQ prefix and no brand suffix - MMD_Seotitle supplies both (see header).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mt, 0, @e, 'Generative AI for Social Media Marketing Training' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_md, 0, @e, 'Generative AI for Social Media Marketing training in Singapore. Learn to plan, create and optimize AI-powered social media campaigns and content. Enjoy up to 70% WSQ funding subsidy.' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_uk, 0, @e, 'wsq-generative-ai-for-social-media-marketing' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image labels carry the plain title (no "WSQ - " prefix) - they are alt text
-- on the course cover, which itself renders without the prefix.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_il, 0, @e, 'Generative AI for Social Media Marketing' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sil, 0, @e, 'Generative AI for Social Media Marketing' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_til, 0, @e, 'Generative AI for Social Media Marketing' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear any store-scoped overrides so store 0 wins for the renamed attrs.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0
  AND attribute_id IN (@a_name, @a_mt, @a_md, @a_uk, @a_il, @a_sil, @a_til);

-- ------------------------------------------------- 2. url_path at all scopes
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_up;

-- --------------------------------------------------- 3. 301 from the old slug
-- Repoint the existing rewrite row (the system row still holds the old
-- request_path until reindex) and force it permanent + manual; create the row
-- where none exists (both scopes).
UPDATE core_url_rewrite
  SET target_path = 'wsq-generative-ai-for-social-media-marketing.html',
      options = 'RP', is_system = 0
  WHERE @sg = 1 AND @e IS NOT NULL
    AND request_path = 'wsq-driving-brand-engagement-with-proven-instagram-social-media-marketing-strategies.html'
    AND store_id IN (0, 1);

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5('wsq-driving-brand-engagement-with-proven-instagram-social-media-marketing-strategies.html'), '-', s.store_id),
       'wsq-driving-brand-engagement-with-proven-instagram-social-media-marketing-strategies.html',
       'wsq-generative-ai-for-social-media-marketing.html', 0, 'RP'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @sg = 1 AND @e IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.request_path = 'wsq-driving-brand-engagement-with-proven-instagram-social-media-marketing-strategies.html'
                    AND x.store_id = s.store_id);

-- Legacy alias rewrites that 301 INTO the old slug - repoint straight at the
-- new slug so inbound links take one hop, not a chain.
UPDATE core_url_rewrite
  SET target_path = 'wsq-generative-ai-for-social-media-marketing.html'
  WHERE @sg = 1 AND @e IS NOT NULL
    AND target_path = 'wsq-driving-brand-engagement-with-proven-instagram-social-media-marketing-strategies.html'
    AND request_path <> 'wsq-driving-brand-engagement-with-proven-instagram-social-media-marketing-strategies.html';

-- --------------------------------------------- 4. description (Course Outline)
-- Same campaign-lifecycle structure as the Instagram outline, converted to the
-- generative-AI angle. Bare <h3 class="course-topic-h3"> rows match the
-- existing storefront format.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Plan a Social Media Marketing Campaign with Generative AI</h3><ul><li>Overview of generative AI tools for social media marketing</li><li>Examples of AI-generated social media advertisements</li><li>Map out customer journey using AI-assisted customer persona tools</li><li>Competitive and audience analysis using AI-powered audience insights</li><li>Develop a social media marketing plan with generative AI</li></ul><h3 class="course-topic-h3">Topic 2: Evaluate Social Media Marketing Opportunities and Platforms</h3><ul><li>Social media competitive and audience evaluation using AI-powered audience insights</li><li>Feasibility and comparison of using various social media platforms</li><li>Advantages of applying generative AI across social media platforms</li></ul><h3 class="course-topic-h3">Topic 3: Create a Social Media Marketing Campaign with Generative AI</h3><ul><li>Market penetration potential of AI-driven social media marketing in the local context</li><li>Create social media photo and video posts with generative AI</li><li>AI-assisted captions, hashtags and location tagging</li><li>Anatomy of an AI-optimized social media ads campaign structure</li><li>Privacy, copyright and responsible AI considerations</li></ul><h3 class="course-topic-h3">Topic 4: Evaluate Social Media Marketing Performance with Generative AI</h3><ul><li>Create and install tracking pixels to collect performance data</li><li>Understand key social media performance and advertising ROI metrics</li><li>Set up custom and automated reporting with generative AI</li><li>Manage consumer reviews and user-generated content with AI</li><li>Audience, budget, scheduling and placement optimization using AI</li><li>AI tools for social media scheduling</li><li>Retargeting strategies</li></ul>' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_desc;

-- ---------------------------------- 5. short_description (About This Course)
-- FULL REPLACE: this course's sections live in cms/block rows (2026-07-21
-- strip), so short_description is only the intro copy - no <h2> tail to keep.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sd, 0, @e, '<p>Are you ready to supercharge your brand''s online presence with the power of AI? Dive into Generative AI for Social Media Marketing, where you''ll discover how tools like ChatGPT and AI image and video generators can transform the way you plan, create and run social media campaigns. In this comprehensive course, we''ll equip you with the knowledge and skills to develop a data-driven social media marketing plan, evaluate the right platforms for your business, and produce engaging AI-generated posts, visuals and ad copy in a fraction of the time.</p><p>By the end of this course, you''ll be able to build a complete AI-powered social media campaign, from audience analysis and content creation to performance tracking and optimization, and evaluate its impact on your organization. Plus, with up to 70% WSQ funding subsidy available, this is an opportunity you can''t afford to miss. Join us today and take your brand''s social media presence to the next level!</p>' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_sd;

-- ------------------------------------------------------------ 6. meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mk, 0, @e, 'generative AI social media marketing, AI social media marketing course, generative AI marketing course Singapore, AI content creation for social media, ChatGPT marketing course, AI social media campaign, WSQ social media marketing, AI marketing training Singapore' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_mk;

-- ------------------------------------------------ 7. media gallery image label
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Generative AI for Social Media Marketing'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------- 8. Learning Outcomes cms/block (LO3/LO4)
UPDATE cms_block
  SET content = '<p>By the end of the course, learners will be able to&nbsp;</p><ul><li>LO1: Develop a plan and objectives for social marketing campaign</li><li>LO2:&nbsp;Evaluate social market opportunities and the feasibility of various social media platforms</li><li>LO3:&nbsp;Create a social media marketing campaign using generative AI and monitor its outcome.</li><li>LO4:&nbsp;Evaluate the usage of generative AI social media campaigns and its impact on the organization</li></ul>'
  WHERE @e IS NOT NULL AND identifier = 'course_TGS-2021003023_learning_outcomes';

-- ------------------------------------------- 9. trainerprofile (4 x paragraph 2)
-- Each trainer's second paragraph pitched the Instagram training specifically,
-- so it is rewritten to the generative-AI angle. Career paragraphs untouched.
-- REPLACE() is byte-exact against the prod values dumped 2026-08-12; a re-run
-- (or an already-edited bio) simply no-ops.
UPDATE catalog_product_entity_text
  SET value = REPLACE(value,
    '<p>In his Instagram marketing training, Ray focuses on combining content creation, analytics, and engagement strategies to help learners build impactful campaigns. He emphasizes how Instagram can be used to strengthen brand identity, increase customer loyalty, and generate leads. With his wealth of industry leadership and digital expertise, Ray equips participants with the skills to design and execute high-impact Instagram strategies.</p>',
    '<p>In his generative AI marketing training, Ray focuses on combining AI-assisted content creation, analytics, and engagement strategies to help learners build impactful social media campaigns. He emphasizes how generative AI can be used to strengthen brand identity, increase customer loyalty, and generate leads. With his wealth of industry leadership and digital expertise, Ray equips participants with the skills to design and execute high-impact AI-powered social media strategies.</p>')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_tp AND store_id = 0;

UPDATE catalog_product_entity_text
  SET value = REPLACE(value,
    '<p>In his Instagram-focused training, Allen emphasizes actionable strategies for running high-conversion campaigns. His sessions cover influencer marketing, ad optimization, and Instagram analytics, equipping learners with practical knowledge to maximize reach and ROI. By combining entrepreneurial success with digital strategy expertise, he empowers participants to confidently use Instagram as a growth engine for their businesses.</p>',
    '<p>In his generative AI-focused training, Allen emphasizes actionable strategies for running high-conversion social media campaigns. His sessions cover AI-assisted content creation, ad optimization, and campaign analytics, equipping learners with practical knowledge to maximize reach and ROI. By combining entrepreneurial success with digital strategy expertise, he empowers participants to confidently use generative AI as a growth engine for their businesses.</p>')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_tp AND store_id = 0;

UPDATE catalog_product_entity_text
  SET value = REPLACE(value,
    '<p>In his Instagram marketing training, Patrick emphasizes how small businesses and professionals can use Instagram to tell their brand stories effectively. His sessions guide learners through optimizing profiles, creating engaging content, and using Instagram&rsquo;s tools to drive lead generation. By blending practical training with a business-focused approach, Patrick ensures participants gain confidence in applying Instagram strategies to grow their reach and customer base.</p>',
    '<p>In his generative AI marketing training, Patrick emphasizes how small businesses and professionals can use AI tools to tell their brand stories effectively across social media. His sessions guide learners through optimizing profiles, creating engaging AI-generated content, and using generative AI tools to drive lead generation. By blending practical training with a business-focused approach, Patrick ensures participants gain confidence in applying AI-powered social media strategies to grow their reach and customer base.</p>')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_tp AND store_id = 0;

UPDATE catalog_product_entity_text
  SET value = REPLACE(value,
    '<p>In her Instagram training, Janice focuses on equipping learners with practical techniques to create customer-focused campaigns. Her sessions cover Instagram content strategies, community engagement, and analytics interpretation to ensure businesses can attract and retain loyal audiences. By combining technical know-how with commercial insights, she helps learners build Instagram campaigns that translate into tangible business results.</p>',
    '<p>In her generative AI training, Janice focuses on equipping learners with practical techniques to create customer-focused social media campaigns. Her sessions cover AI-driven content strategies, community engagement, and analytics interpretation to ensure businesses can attract and retain loyal audiences. By combining technical know-how with commercial insights, she helps learners build AI-powered social media campaigns that translate into tangible business results.</p>')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_tp AND store_id = 0;

-- --------------------------------------------- 10. whoshouldattend (3 roles)
UPDATE catalog_product_entity_text
  SET value = REPLACE(REPLACE(REPLACE(value,
    '<li>Instagram Marketing Specialist</li>', '<li>Social Media Marketing Specialist</li>'),
    '<li>Ad Campaign Manager (Instagram focus)</li>', '<li>Ad Campaign Manager</li>'),
    '<li>Event Promoter (leveraging Instagram).</li>', '<li>Event Promoter (leveraging social media).</li>')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_wsa AND store_id = 0;

-- ---------------------------------- 11. prerequisite software list (+ ChatGPT)
-- Guarded on the new URL so a re-run cannot duplicate the bullet.
UPDATE catalog_product_entity_text
  SET value = REPLACE(value,
    '<li><a href="https://www.instagram.com/" target="_blank"><span style="text-decoration: underline;">Instagram</span></a></li>',
    '<li><a href="https://chatgpt.com/" target="_blank"><span style="text-decoration: underline;">ChatGPT</span></a></li><li><a href="https://www.instagram.com/" target="_blank"><span style="text-decoration: underline;">Instagram</span></a></li>')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_pre AND store_id = 0
    AND LOCATE('chatgpt.com', value) = 0;

-- ------------------------------------------- 12. search-term redirects
-- Retarget every live row pointing at the old slug (incl. the old-title queries)
-- and at the legacy alias, straight to the new slug. REPLACE on the full
-- SG-domain URL - partner-safe. (Rows pointing at the Instagram category page
-- or at other courses are deliberately left alone.)
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect, 'https://www.tertiarycourses.com.sg/wsq-driving-brand-engagement-with-proven-instagram-social-media-marketing-strategies.html', 'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-social-media-marketing.html')
  WHERE redirect LIKE '%wsq-driving-brand-engagement-with-proven-instagram-social-media-marketing-strategies.html%';

UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect, 'https://www.tertiarycourses.com.sg/wsq-social-media-marketing-instagram.html', 'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-social-media-marketing.html')
  WHERE redirect LIKE '%/wsq-social-media-marketing-instagram.html%';
