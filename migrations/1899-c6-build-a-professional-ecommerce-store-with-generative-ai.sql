-- C6: "AI Powered Wordpress eCommerce" -> "Build a Professional eCommerce Store with Generative AI",
-- the 1-day non-WSQ twin of TGS-2026064474 (CASL - AI for eCommerce).
--
-- 1. name, url_key/url_path (ai-powered-wordpress-ecommerce ->
--    build-a-professional-ecommerce-store-with-generative-ai), cover alt/gallery labels, meta title (bare),
--    meta description/keywords.
-- 2. "What's This Course About" follows the CASL parent (its 4 About paragraphs), with the opener naming
--    this course. ASCII literal, not a parent join. No day count anywhere. The 5 course topics already
--    match the parent byte-for-byte and are left as they are.
-- 3. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 4. 301s: the product's system rows are renamed in place to the new slug; every old path, bare or
--    category-prefixed, 301s one hop to the new BARE slug; legacy RP rows (the WordPress Essential
--    Training / WordPress Business Website lives) are flattened onto it and untagged from product/category
--    so a catalog_url reindex cannot prune them.
-- Fee, duration (7.5) and sessions (1) are unchanged. The Funding block already links to the CASL twin.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C6' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064474' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Build a Professional eCommerce Store with Generative AI';
SET @old_slug  := 'ai-powered-wordpress-ecommerce';
SET @new_slug  := 'build-a-professional-ecommerce-store-with-generative-ai';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

-- ------------------------------------------------------- name / slug -----
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_name;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath;

-- ------------------------------------------------------ image labels -----
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @new_title
 WHERE @ok AND v.entity_id = @pid;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @new_title
 WHERE @ok AND g.entity_id = @pid;

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'eCommerce store course: build a WooCommerce store with Generative AI, create product photos and copy, set up payments and shipping, and grow sales with AI SEO.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'eCommerce store course, eCommerce training Singapore, Generative AI for eCommerce, WooCommerce store setup, AI product photos and copy, AI SEO for online stores, WordPress eCommerce'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------- About from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p><strong>Build a Professional eCommerce Store with Generative AI</strong> equips participants with practical skills to use artificial intelligence to create, manage and optimise online retail operations. Learners will explore how AI can support product research, generate compelling product descriptions and visual content, personalise customer experiences, automate routine tasks and improve store performance.</p><p>The course covers essential eCommerce functions, including <strong>product catalogue</strong> management, inventory, payment gateways, shipping options, order fulfilment and search engine optimisation. Participants will apply generative AI to develop marketing content, customer communications, promotional campaigns and personalised product recommendations. They will also learn to use AI-powered chatbots and automation tools to respond to enquiries, support customers and streamline order-related workflows.</p><p>Participants will analyse sales trends, customer behaviour and key performance indicators using AI-assisted analytics. These insights will help them identify opportunities, forecast demand and make data-driven decisions to improve conversions and customer retention. Responsible AI practices, including data privacy, content accuracy and human review, are also addressed.</p><p>By the end of the course, participants will be able to integrate AI into key eCommerce processes, enhance customer engagement, improve operational efficiency and develop effective strategies for sustainable online business growth.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C6-20261104-010625.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c6_old;
CREATE TEMPORARY TABLE tmp_c6_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c6_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Rename those system rows in place, so the new slug resolves immediately.
UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 3) Legacy RP rows that pointed at any old-slug path -> the new bare slug (one hop), untagged so a
--    catalog_url reindex never deletes them.
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html'), product_id = NULL, category_id = NULL
 WHERE @ok AND options = 'RP' AND is_system = 0
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 4) Every old path 301s to the new bare slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_c6_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c6_old;

-- 5) On-site search terms that sent people to the old slug.
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
