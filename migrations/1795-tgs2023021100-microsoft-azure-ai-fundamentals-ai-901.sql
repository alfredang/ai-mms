-- 1795: TGS-2023021100 "WSQ - Microsoft Azure AI Fundamentals (AI-900)"
--       -> "WSQ - Microsoft Azure AI Fundamentals (AI-901)"
--
-- Microsoft retired exam AI-900 on 30 June 2026; AI-901 "Microsoft Azure AI
-- Fundamentals" replaces it (the azure-ai-fundamentals credential page now
-- lists AI-901). Exam-version rename in place (entity 1378), mig 1566 pattern.
-- SKU unchanged, stays WSQ: the WSQ prefix, the seven funding tags, price,
-- duration (16h / 2 sessions), schedule options, trainers, all 20 categories
-- (still prepares for a Microsoft certification exam) and the funding /
-- skills_framework / certification / brochure cms_blocks are left alone.
--
-- PROBED on SG prod before writing. Surfaces rewritten here:
--   * name, url_key, url_path, meta_title (plain -- MMD_Seotitle adds "WSQ funded"
--     + the brand at render time; the stored "WSQ AI-900 ... Tertiary Courses
--     Singapore" baked both in), meta_description, meta_keyword
--   * short_description (the supplied 3-paragraph About; the old copy listed
--     the AI-900 exam domains as LO1-LO5)
--   * description (the supplied 4-topic outline, topics only + LSN_DATA marker)
--   * trainerprofile: "apply AI-900 fundamentals" / "In this AI-900 course" ->
--     AI-901 (single-token REPLACE, CRLF-safe), and Dwight's teaching line
--     "Azure Cognitive Services" -> "Azure AI services" (Microsoft's rename).
--     Career-history text stays.
--   * image/small_image/thumbnail labels + media-gallery label (alt text);
--     image PATHS untouched (filesystem paths)
--   * course_image_url -> new R2 cover, rendered on prod with the existing badge
--     set, HTTP 200, 177185 bytes:
--       course-covers/TGS-2023021100-20261006-183654.png
--   * cms_block course_TGS-2023021100_certification_exam: link title "AZ-900"
--     -> "AI-901" (the URL itself already serves the AI-901 credential)
--   * cms_block course_C1071_funding_and_grant: the non-WSQ AI-901 twin's
--     "For WSQ funding" link named + linked the old title/slug
--   * URL rewrites: system rows renamed in place (no refreshProductRewrite
--     needed, mig 1620 pattern); every old path 301s to the new bare slug;
--     existing 301s (incl. legacy wsq-ai-900-azure-ai-fundamentals) flattened
--     to one hop.
--   * search redirects: the 64 rows on the old slug + the bare course-code row
--     (on the legacy wsq-ai-900 slug) -> new slug. The "...exam-prep" rows
--     belong to twin C1071 and are left alone.
--
-- Not touched: learning_outcomes cms_block (the supplied LO1-LO4 are already
-- live -- SSG-registered against the unchanged SKU), whoshouldattend (Azure AI
-- roles still apply), prerequisite (Azure account; holds the funding
-- apparatus), the brochure PDF (regenerate separately).
--
-- SG only: keyed by SKU, no-ops where the SKU is absent. Idempotent.

SET @e  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023021100' LIMIT 1);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @old_slug := 'wsq-microsoft-azure-ai-fundamentals-ai-900';
SET @new_slug := 'wsq-microsoft-azure-ai-fundamentals-ai-901';

-- ---------------------------------------------------------------- varchar attrs
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name'             AND entity_type_id=@et);
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key'          AND entity_type_id=@et);
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path'         AND entity_type_id=@et);
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title'       AND entity_type_id=@et);
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@et);
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' AND entity_type_id=@et);

UPDATE catalog_product_entity_varchar SET value = 'WSQ - Microsoft Azure AI Fundamentals (AI-901)'
 WHERE attribute_id = @a_name AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE attribute_id = @a_url AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE attribute_id = @a_upath AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar SET value = 'Microsoft Azure AI Fundamentals (AI-901)'
 WHERE attribute_id = @a_mt AND entity_id = @e AND @e IS NOT NULL;

-- varchar(255): 226 chars.
UPDATE catalog_product_entity_varchar
   SET value = 'Learn AI fundamentals on Microsoft Azure: machine learning, computer vision, NLP, generative AI with Azure AI Foundry and responsible AI. Prepares you for the Microsoft AI-901 Azure AI Fundamentals exam. Up to 70% WSQ funding.'
 WHERE attribute_id = @a_md AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   SET v.value = 'Microsoft Azure AI Fundamentals (AI-901)'
 WHERE v.entity_id = @e AND @e IS NOT NULL AND a.entity_type_id = @et
   AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label');

UPDATE catalog_product_entity_media_gallery_value g
  JOIN catalog_product_entity_media_gallery m ON m.value_id = g.value_id
   SET g.label = 'Microsoft Azure AI Fundamentals (AI-901)'
 WHERE m.entity_id = @e AND @e IS NOT NULL;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @e,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023021100-20261006-183654.png'
 WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------- text attrs
SET @a_mk   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword'      AND entity_type_id=@et);
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='description'       AND entity_type_id=@et);
SET @a_tp   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='trainerprofile'    AND entity_type_id=@et);

UPDATE catalog_product_entity_text
   SET value = 'AI-901, Microsoft Azure AI Fundamentals, Azure AI Fundamentals exam, Azure AI Foundry, generative AI on Azure, machine learning, computer vision, natural language processing, responsible AI, WSQ Azure AI course'
 WHERE attribute_id = @a_mk AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<p>This Microsoft Azure AI Fundamentals (AI-901) course provides learners with a foundational understanding of artificial intelligence (AI) concepts and how AI solutions can be implemented using Microsoft Azure. Designed for learners with both technical and non-technical backgrounds, the course introduces the core principles, services, and practical applications of AI in a cloud environment.</p>\n',
     '<p>Learners will explore key areas of AI, including machine learning, computer vision, natural language processing, generative AI, and AI-powered applications. The course introduces Microsoft Azure AI services and tools for building solutions that can analyse data, understand language, recognise and process visual information, and generate intelligent responses and content.</p>\n',
     '<p>Participants will also learn about generative AI and large language models, including the capabilities of Microsoft Azure AI Foundry and related Azure AI services. Emphasis is placed on responsible AI principles, including fairness, reliability, privacy, security, inclusiveness, transparency, and accountability.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @e AND @e IS NOT NULL;

-- LSN_DATA marker (admin Lesson editor) + the HTML the storefront renders,
-- generated together from the same four topics (topics only, no sub-items).
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<!-- LSN_DATA: [',
       '{"title":"Topic 1: AI Applications with Microsoft Azure Services","subsecs":[]},',
       '{"title":"Topic 2: AI Workflows and Machine Learning on Azure","subsecs":[]},',
       '{"title":"Topic 3: Anomaly Detection and AI Solution Monitoring","subsecs":[]},',
       '{"title":"Topic 4: Azure Knowledge Mining and Data Preparation","subsecs":[]}] -->\n',
     '<p><strong>Topic 1: AI Applications with Microsoft Azure Services</strong></p>\n',
     '<p><strong>Topic 2: AI Workflows and Machine Learning on Azure</strong></p>\n',
     '<p><strong>Topic 3: Anomaly Detection and AI Solution Monitoring</strong></p>\n',
     '<p><strong>Topic 4: Azure Knowledge Mining and Data Preparation</strong></p>\n')
 WHERE attribute_id = @a_desc AND entity_id = @e AND @e IS NOT NULL;

-- store-0 copy is what every scope serves
DELETE FROM catalog_product_entity_text
 WHERE entity_id = @e AND @e IS NOT NULL
   AND attribute_id IN (@a_sd, @a_desc, @a_mk) AND store_id <> 0;

UPDATE catalog_product_entity_text
   SET value = REPLACE(REPLACE(value, 'AI-900', 'AI-901'),
       'hands-on exploration of Azure Cognitive Services,', 'hands-on exploration of Azure AI services,')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------- cms blocks
UPDATE cms_block
   SET content = REPLACE(content, 'title="AZ-900"', 'title="AI-901"')
 WHERE identifier = 'course_TGS-2023021100_certification_exam' AND @e IS NOT NULL;

UPDATE cms_block
   SET content = REPLACE(REPLACE(content,
       CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html'),
       CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')),
       'WSQ - Microsoft Azure AI Fundamentals (AI-900)', 'WSQ - Microsoft Azure AI Fundamentals (AI-901)')
 WHERE identifier = 'course_C1071_funding_and_grant' AND @e IS NOT NULL;

-- ---------------------------------------------------------------- URL rewrites
DROP TEMPORARY TABLE IF EXISTS tmp_1378_old;
CREATE TEMPORARY TABLE tmp_1378_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_1378_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1 AND @e IS NOT NULL
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- Free the new paths of any non-system squatter, then rename system rows in place.
DELETE FROM core_url_rewrite
 WHERE is_system = 0 AND @e IS NOT NULL
   AND (request_path = CONCAT(@new_slug, '.html') OR request_path LIKE CONCAT('%/', @new_slug, '.html'));

UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE product_id = @e AND is_system = 1 AND @e IS NOT NULL
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- Legacy 301s that pointed at any old-slug path -> the new bare slug (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html')
 WHERE options = 'RP' AND @e IS NOT NULL
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- Every old system path 301s to the new bare slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_1378_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_1378_old;

-- ---------------------------------------------------------------- search redirects
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE redirect IN (CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html'),
                    'https://www.tertiarycourses.com.sg/wsq-ai-900-azure-ai-fundamentals.html')
   AND @e IS NOT NULL;
