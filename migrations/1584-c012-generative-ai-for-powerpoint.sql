-- 1584: C012 "Powerpoint Essential Training" -> "Generative AI for Powerpoint"
--
-- C012 becomes the non-WSQ twin of TGS-2026064178 "CASL - Create Powerpoint
-- Infographics with AI" (the courseware is duplicated from that course), so:
--   * name / meta_title / url_key / url_path / cover-alt labels -> new title,
--     slug generative-ai-for-powerpoint, with a permanent 301 from every old
--     path (bare + category-prefixed) and legacy 301s flattened to one hop;
--   * short_description (About) + description (topics) copied VERBATIM from the
--     parent (asserted free of any day count / WSQ / funding wording); new
--     meta_description + meta_keyword; duration 7.5 / sessions 1 / price 350
--     already match the one-day parent and are NOT touched;
--   * re-rendered cover PNG (title is baked in) - guarded on the old R2 URL;
--   * on-site search redirects repointed to the new slug;
--   * Funding block -> the CASL twin (target verified HTTP 200 directly);
--   * both PowerPoint courses added to "Microsoft Copilot Series"
--     (url_key microsoft-copilot-series, curated non-WSQ order): the CASL
--     course at the end of the TGS block, C012 at the end of the C block.
--
-- Keyed by SKU / url_key / identifier - partner sites (C-catalog parity, no
-- TGS- courses) pick up the C012 rename + category add and no-op the rest.
-- Idempotent.
--
-- Post-deploy on prod: refreshProductRewrite(C012) + reindex + flush, or the
-- new slug 404s (the indexer, not this SQL, mints the canonical system row).

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C012' LIMIT 1);
SET @wsq := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064178' LIMIT 1);
SET @pet := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------- name / meta_title / url_key / url_path / labels ----------
UPDATE catalog_product_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = CASE a.attribute_code
      WHEN 'url_key'          THEN 'generative-ai-for-powerpoint'
      WHEN 'url_path'         THEN 'generative-ai-for-powerpoint.html'
      WHEN 'meta_description' THEN 'Use Generative AI with PowerPoint to turn data and ideas into clear, professional infographics. Learn visual hierarchy, layout, colour, typography and data storytelling for business presentations.'
      ELSE 'Generative AI for Powerpoint'
    END
WHERE v.entity_id = @pid AND @pid IS NOT NULL
  AND a.attribute_code IN ('name','meta_title','meta_description','url_key','url_path',
                           'image_label','small_image_label','thumbnail_label');

-- media-gallery label = the alt text the product page actually renders
UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'Generative AI for Powerpoint'
WHERE g.entity_id = @pid AND @pid IS NOT NULL;

-- ---------- About / topics / keywords (copied from TGS-2026064178) ----------
UPDATE catalog_product_entity_text v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = CASE a.attribute_code
      WHEN 'short_description' THEN '<p>This course equips learners with practical skills to create professional and visually engaging <strong>PowerPoint infographics using Artificial Intelligence (AI)</strong>. Participants will learn how to transform ideas, data, and complex information into clear visual stories by combining Microsoft PowerPoint with AI-assisted content creation and design techniques.</p><p>Through hands-on activities, learners will use AI to generate and refine infographic concepts, summarize information, structure content, develop visual narratives, and recommend suitable layouts. They will then translate these ideas into PowerPoint using shapes, icons, SmartArt, charts, diagrams, typography, and other visual elements to create polished infographics.</p><p>The course covers key principles of <strong>information visualization, visual hierarchy, layout, colour, typography, and storytelling</strong>. Learners will explore different types of infographics, including process diagrams, timelines, comparisons, statistical infographics, business dashboards, organisational charts, and data-driven presentations.</p><p>Participants will also learn how AI can accelerate the design workflow by helping generate content, simplify complex information, suggest visual structures, improve presentation messaging, and refine infographic designs. Practical exercises will focus on turning real-world business information and data into effective visual communication.</p><p>By the end of the course, learners will be able to use <strong>AI and PowerPoint together to efficiently create clear, attractive, and professional infographics</strong> for business presentations, reports, training materials, marketing communications, and other workplace applications.</p>'
      WHEN 'description'       THEN '<!-- LSN_DATA: [{"title":"Topic 1: AI-Assisted Infographic Planning and Data Insights","subsecs":[]},{"title":"Topic 2: Creating PowerPoint Infographics with AI","subsecs":[]},{"title":"Topic 3: Evaluating and Presenting Infographics for Business Impact","subsecs":[]}] -->\n<p><strong>Topic 1: AI-Assisted Infographic Planning and Data Insights</strong></p>\n<p><strong>Topic 2: Creating PowerPoint Infographics with AI</strong></p>\n<p><strong>Topic 3: Evaluating and Presenting Infographics for Business Impact</strong></p>\n'
      ELSE 'AI PowerPoint infographics, AI infographic design, PowerPoint infographics course, data visualization training, AI-assisted presentation design, visual storytelling, business infographics Singapore'
    END
WHERE v.entity_id = @pid AND @pid IS NOT NULL AND v.store_id = 0
  AND a.attribute_code IN ('short_description','description','meta_keyword');

-- ---------- cover (SG render only) ----------
UPDATE catalog_product_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C012-20260928-064045.png'
WHERE v.entity_id = @pid AND @pid IS NOT NULL
  AND a.attribute_code = 'course_image_url'
  AND v.value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C012-20260717-162733.png';

-- ---------- 301s ----------
-- Every old system path (bare + category-prefixed) becomes a custom 301 to the
-- flat new slug, under its OWN id_path. The system rows are deleted first: a
-- 301 left on id_path product/<id> blocks the indexer from minting the new row.
DROP TEMPORARY TABLE IF EXISTS tmp_c012_old;
CREATE TEMPORARY TABLE tmp_c012_old AS
SELECT store_id, request_path FROM core_url_rewrite
WHERE @pid IS NOT NULL AND is_system = 1 AND product_id = @pid
  AND (request_path = 'powerpoint-essential-training.html'
       OR request_path LIKE '%/powerpoint-essential-training.html');

DELETE r FROM core_url_rewrite r
JOIN tmp_c012_old t ON t.store_id = r.store_id AND t.request_path = r.request_path;

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT t.store_id,
       CONCAT('custom/c012-powerpoint-essential-training-', LEFT(MD5(t.request_path), 10)),
       t.request_path, 'generative-ai-for-powerpoint.html', 0, 'RP',
       '1584: C012 renamed to Generative AI for Powerpoint'
FROM tmp_c012_old t
ON DUPLICATE KEY UPDATE target_path = VALUES(target_path), options = 'RP', is_system = 0;

DROP TEMPORARY TABLE IF EXISTS tmp_c012_old;

-- flatten every legacy 301 that pointed at an old path, so all resolve in one hop
UPDATE core_url_rewrite
SET target_path = 'generative-ai-for-powerpoint.html', options = 'RP'
WHERE is_system = 0
  AND (target_path = 'powerpoint-essential-training.html'
       OR target_path LIKE '%/powerpoint-essential-training.html');

-- on-site search redirects - path swap keeps each site's own domain
UPDATE catalogsearch_query
SET redirect = REPLACE(redirect, '/powerpoint-essential-training.html', '/generative-ai-for-powerpoint.html')
WHERE redirect LIKE '%/powerpoint-essential-training.html';

-- ---------- Funding block -> CASL twin ----------
-- Content-only UPDATE. NEVER ->save() a cms/block model (wipes cms_block_store).
UPDATE cms_block
   SET content = CONCAT(
     '<p>No funding is available for this course</p> ',
     '<p>For WSQ funding, please checkout the details at&nbsp;',
     '<span style="text-decoration: underline;">',
     '<a href="https://www.tertiarycourses.com.sg/casl-create-powerpoint-infographics-with-ai.html" ',
     'title="CASL - Create Powerpoint Infographics with AI" target="_blank">',
     'CASL - Create Powerpoint Infographics with AI</a></span></p>')
 WHERE identifier = 'course_C012_funding_and_grant';

-- ---------- Microsoft Copilot Series membership ----------
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
             JOIN eav_attribute a ON a.attribute_id = v.attribute_id
             WHERE a.attribute_code = 'url_key' AND a.entity_type_id =
                   (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category')
               AND v.store_id = 0 AND v.value = 'microsoft-copilot-series' LIMIT 1);

-- CASL course: slot in right after the last TGS- member (only on first run).
SET @need := (SELECT @wsq IS NOT NULL AND @cat IS NOT NULL AND NOT EXISTS
              (SELECT 1 FROM catalog_category_product WHERE category_id = @cat AND product_id = @wsq));
SET @slot := (SELECT COALESCE(MAX(cp.position), 0) + 1 FROM catalog_category_product cp
              JOIN catalog_product_entity p ON p.entity_id = cp.product_id
              WHERE cp.category_id = @cat AND p.sku LIKE 'TGS-%');

UPDATE catalog_category_product SET position = position + 1
 WHERE @need AND category_id = @cat AND position >= @slot;
UPDATE catalog_category_product_index SET position = position + 1
 WHERE @need AND category_id = @cat AND position >= @slot;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @wsq, @slot FROM DUAL WHERE @need;

-- C012: append after the last member (curated order keeps it at the end).
SET @last := (SELECT COALESCE(MAX(position), 0) + 1 FROM catalog_category_product WHERE category_id = @cat);
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @last FROM DUAL WHERE @pid IS NOT NULL AND @cat IS NOT NULL;

-- mirror into the index the storefront reads (visibility from the product's own rows)
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product cp
JOIN catalog_category_product_index i ON i.product_id = cp.product_id AND i.store_id > 0
WHERE cp.category_id = @cat AND @cat IS NOT NULL AND cp.product_id IN (@pid, @wsq)
GROUP BY cp.category_id, cp.product_id, cp.position, i.store_id;
