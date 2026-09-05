-- 1321 : Repurpose TGS-2026064178 (product 593)
--        "CASL - Infographics and Data Visualization with PowerPoint"
--     -> "Create Powerpoint Infographics with AI"
--
-- SKU UNCHANGED, so every SkillsFuture / SFEC / SFC / PSEA / UTAP deep link and
-- the funding_and_grant / certification / skills_framework blocks (registered
-- against this SKU) stay valid and are NOT touched.
--
-- The CASL - segment prefix is dropped from `name` at the admin's explicit
-- request (2026-09-05); the CASL tag, funding badges and the accredited
-- Tourism Skills Framework competency (TOU-DAT-4004-1.1-1) are unchanged.
--
-- Surfaces touched: name, url_key/url_path + 301, meta_title/description/keyword,
-- image/small_image/thumbnail LABELS, media-gallery label, short_description,
-- description (course outline: 3 topics, AI-angled), trainerprofile
-- course-teaching claims, search redirects, cover image URL.
--
-- Deliberately NOT touched (probed on prod 2026-09-05):
--  * learning_outcomes cms_block - the supplied LO1-LO3 are BYTE-IDENTICAL to
--    the live block. They are the accredited outcomes registered against the
--    unchanged SKU; the new AI-assisted topics deliver those same outcomes.
--  * certification / skills_framework / funding_and_grant / brochure blocks
--    - keyed on the unchanged SKU.
--  * prerequisite - probed: 0 hits for "Infographic"/"PowerPoint"; it holds the
--    whole funding apparatus (PWM, eligibility table, SkillsFuture/PSEA/SFEC/
--    UTAP deep links). Never rewrite wholesale.
--  * whoshouldattend - the 20 job roles are tool-neutral (Data Analyst,
--    Marketing Coordinator, ...); still correct for the AI angle.
--  * image / small_image / thumbnail - filesystem paths, renaming 404s them.
--  * categories - the course still teaches PowerPoint infographics and data
--    visualisation; every one of its 15 placements still describes it.
--  * review_detail rows - genuine learner testimonials; titles are generic
--    ("Recommended", "Average Rating: n/5"), no old-topic leak.
--
-- SG-only. Partner sites (MY/GH) never held this TGS- SKU; @is_sg makes this a
-- no-op there.

SET @is_sg := (SELECT COUNT(*) FROM core_config_data
               WHERE path = 'web/unsecure/base_url' AND value LIKE '%tertiarycourses.com.sg%');

SET @e  := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064178');
SET @et := 4;

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='meta_description');
SET @a_mkw     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='meta_keyword');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='thumbnail_label');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='description');
SET @a_trainer := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='trainerprofile');

SET @newname := 'Create Powerpoint Infographics with AI';
SET @newslug := 'create-powerpoint-infographics-with-ai';
SET @oldslug := 'casl-infographics-and-data-visualization-with-powerpoint';
SET @oldname := 'CASL - Infographics and Data Visualization with PowerPoint';

-- ------------------------------------------------------------------- 1. name
UPDATE catalog_product_entity_varchar
   SET value = @newname
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_name;

-- ------------------------------------- 2. alt-text labels (cover alt text)
UPDATE catalog_product_entity_varchar
   SET value = @newname
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e
   AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

-- Media-gallery per-image label is the REAL alt text rendered on the cover.
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @newname
 WHERE @is_sg > 0 AND @e IS NOT NULL AND g.entity_id = @e;

-- ------------------------- 3. meta_title (PLAIN - MMD_Seotitle adds prefix+brand)
UPDATE catalog_product_entity_varchar
   SET value = 'Create Powerpoint Infographics with AI'
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mtitle;

-- --------------------------------------------- 4. meta_description (<= 255 chars)
UPDATE catalog_product_entity_varchar
   SET value = 'Use AI with PowerPoint to turn data and ideas into clear, professional infographics. Learn visual hierarchy, layout, colour, typography and storytelling. Up to 70% SkillsFuture funding subsidy.'
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mdesc;

-- ------------------------------------------------------------- 5. meta_keyword
UPDATE catalog_product_entity_text
   SET value = 'AI PowerPoint infographics, AI infographic design, PowerPoint infographics course, data visualization training, AI-assisted presentation design, visual storytelling, business infographics Singapore'
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mkw;

-- --------------------------------------------------- 6. url_key + drop url_path
-- Dropping url_path at EVERY scope lets the URL Rewrites indexer regenerate.
UPDATE catalog_product_entity_varchar
   SET value = @newslug
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_urlkey;
DELETE FROM catalog_product_entity_varchar
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_urlpath;

-- ------------------------------------------------------ 7. short_description
-- Probed on prod: prose-only (the Brochure / Skills Framework / Certification /
-- Funding sections were extracted to cms_blocks by 885-891), so a full replace
-- is correct here - there is no <h2>Course Brochure</h2> tail to preserve.
UPDATE catalog_product_entity_text
   SET value = '<p>This course equips learners with practical skills to create professional and visually engaging <strong>PowerPoint infographics using Artificial Intelligence (AI)</strong>. Participants will learn how to transform ideas, data, and complex information into clear visual stories by combining Microsoft PowerPoint with AI-assisted content creation and design techniques.</p><p>Through hands-on activities, learners will use AI to generate and refine infographic concepts, summarize information, structure content, develop visual narratives, and recommend suitable layouts. They will then translate these ideas into PowerPoint using shapes, icons, SmartArt, charts, diagrams, typography, and other visual elements to create polished infographics.</p><p>The course covers key principles of <strong>information visualization, visual hierarchy, layout, colour, typography, and storytelling</strong>. Learners will explore different types of infographics, including process diagrams, timelines, comparisons, statistical infographics, business dashboards, organisational charts, and data-driven presentations.</p><p>Participants will also learn how AI can accelerate the design workflow by helping generate content, simplify complex information, suggest visual structures, improve presentation messaging, and refine infographic designs. Practical exercises will focus on turning real-world business information and data into effective visual communication.</p><p>By the end of the course, learners will be able to use <strong>AI and PowerPoint together to efficiently create clear, attractive, and professional infographics</strong> for business presentations, reports, training materials, marketing communications, and other workplace applications.</p>'
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_sdesc;

-- --------------------------------------------------- 8. description (outline)
-- Topics-only shape (no sub-bullets), matching 967/999/1007. The LSN_DATA JSON
-- comment drives the outline widget and must stay in sync with the markup.
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<!-- LSN_DATA: [{"title":"Topic 1: AI-Assisted Infographic Planning and Data Insights","subsecs":[]},',
'{"title":"Topic 2: Creating PowerPoint Infographics with AI","subsecs":[]},',
'{"title":"Topic 3: Evaluating and Presenting Infographics for Business Impact","subsecs":[]}] -->\n',
'<p><strong>Topic 1: AI-Assisted Infographic Planning and Data Insights</strong></p>\n',
'<p><strong>Topic 2: Creating PowerPoint Infographics with AI</strong></p>\n',
'<p><strong>Topic 3: Evaluating and Presenting Infographics for Business Impact</strong></p>\n')
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_desc;

-- ---------------------------------------------------- 9. trainerprofile claims
-- Retarget only the course-TEACHING sentences that name the old course title.
-- Career-history credentials (real PowerPoint / design expertise) stay as facts.
UPDATE catalog_product_entity_text
   SET value = REPLACE(REPLACE(value, @oldname, @newname),
                       'Infographics and Data Visualization with PowerPoint', @newname)
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_trainer;

-- ------------------------------------------------------------ 10. cover image
-- Re-rendered on prod 2026-09-05 from the new title with the same badge set
-- (CASL, SkillsFuture Credit, UTAP, SFEC, Absentee Payroll, MCES). The PNG bakes
-- the title, so the migration cannot render it - it only pins the resulting URL
-- so a rebuilt DB converges to the same cover.
SET @a_cover := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=@et AND attribute_code='course_image_url');
UPDATE catalog_product_entity_varchar
   SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064178-20260905-045619.png'
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_cover AND store_id = 0;
DELETE FROM catalog_product_entity_varchar
 WHERE @is_sg > 0 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_cover AND store_id <> 0;

-- ------------------------------------------------ 11. URL rewrites: 301 old->new
-- The is_system=1 row still occupies the OLD bare slug; INSERT IGNORE would
-- silently no-op against it, so delete it FIRST (trap from migration 647).
DELETE FROM core_url_rewrite
 WHERE @is_sg > 0 AND @e IS NOT NULL
   AND request_path = CONCAT(@oldslug, '.html')
   AND is_system = 1;

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5(CONCAT(@oldslug, '.html')), '-', s.store_id),
       CONCAT(@oldslug, '.html'),
       CONCAT(@newslug, '.html'),
       0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @is_sg > 0 AND @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT store_id, request_path FROM core_url_rewrite) x
                   WHERE x.request_path = CONCAT(@oldslug, '.html') AND x.store_id = s.store_id);

-- Force any surviving row on the old path to a permanent manual 301.
UPDATE core_url_rewrite
   SET target_path = CONCAT(@newslug, '.html'), options = 'RP', is_system = 0
 WHERE @is_sg > 0 AND @e IS NOT NULL
   AND request_path = CONCAT(@oldslug, '.html');

-- Chain-flatten: alias rows that 301 INTO the old bare slug take one hop now.
-- Anchored on the FULL old filename so the non-WSQ twin
-- (create-infographics-with-powerpoint.html, a different stem) is never swept in.
UPDATE core_url_rewrite
   SET target_path = CONCAT(@newslug, '.html')
 WHERE @is_sg > 0 AND @e IS NOT NULL
   AND target_path = CONCAT(@oldslug, '.html')
   AND request_path <> CONCAT(@newslug, '.html');

-- --------------------------------------------------------- 12. search redirects
-- Retarget ONLY rows already pointing at this course's old slug. The 5 rows on
-- create-infographics-with-powerpoint.html belong to the live non-WSQ twin and
-- are deliberately left alone.
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @newslug, '.html')
 WHERE @is_sg > 0 AND @e IS NOT NULL
   AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @oldslug, '.html');
