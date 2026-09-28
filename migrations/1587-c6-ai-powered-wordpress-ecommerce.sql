-- 1587: C6 "Setup Professional Business Website Using WordPress" -> "AI Powered Wordpress eCommerce"
--
-- C6 becomes the non-WSQ twin of TGS-2026064474 "CASL - AI for eCommerce"
-- (the courseware is duplicated from that course), so:
--   * name / meta_title / url_key / url_path / cover-alt labels -> new title,
--     slug ai-powered-wordpress-ecommerce, with a permanent 301 from every old
--     path (bare + category-prefixed) and legacy 301s flattened to one hop;
--   * short_description (About) + description (topics) copied VERBATIM from the
--     parent (asserted free of any day count / WSQ / funding wording); new
--     meta_description + meta_keyword; duration 7.5 / sessions 1 already match
--     the one-day parent and are NOT touched;
--   * re-rendered cover PNG (title is baked in) - guarded on the old R2 URL;
--   * on-site search redirects that pointed at the old slug: eCommerce-intent
--     terms follow the course, business-website terms go to the WSQ WordPress
--     website course (the subject the old C6 taught); empty "wordpress
--     ecommerce" rows filled with the new slug;
--   * Funding block -> the CASL twin (target verified HTTP 200 directly);
--   * C6 listed under "e-Commerce" (cat 21) and "AI for Retail" (cat 436), at
--     the head of each category's C block (alphabetical, after the TGS block).
--     The CASL parent is already in both.
--
-- Keyed by SKU / url_key / identifier - partner sites (C-catalog parity, no
-- TGS- courses) pick up the C6 rename; the category adds no-op where the
-- category url_key is absent. Idempotent.
--
-- Post-deploy on prod: refreshProductRewrite(C6) + reindex + flush, or the
-- new slug 404s (the indexer, not this SQL, mints the canonical system row).

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C6' LIMIT 1);
SET @pet := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @cet := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category');

-- ---------- name / meta_title / url_key / url_path / labels ----------
UPDATE catalog_product_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = CASE a.attribute_code
      WHEN 'url_key'          THEN 'ai-powered-wordpress-ecommerce'
      WHEN 'url_path'         THEN 'ai-powered-wordpress-ecommerce.html'
      WHEN 'meta_description' THEN 'Use AI with WordPress and WooCommerce to set up, manage and optimise an online store - product content, payments, shipping, promotions and AI-assisted eCommerce analytics.'
      ELSE 'AI Powered Wordpress eCommerce'
    END
WHERE v.entity_id = @pid AND @pid IS NOT NULL
  AND a.attribute_code IN ('name','meta_title','meta_description','url_key','url_path',
                           'image_label','small_image_label','thumbnail_label');

-- media-gallery label = the alt text the product page actually renders
UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'AI Powered Wordpress eCommerce'
WHERE g.entity_id = @pid AND @pid IS NOT NULL;

-- ---------- About / topics / keywords (copied from TGS-2026064474) ----------
UPDATE catalog_product_entity_text v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = CASE a.attribute_code
      WHEN 'short_description' THEN '<p>AI for eCommerce equips participants with practical skills to use artificial intelligence to create, manage and optimise online retail operations. Learners will explore how AI can support product research, generate compelling product descriptions and visual content, personalise customer experiences, automate routine tasks and improve store performance.</p><p>The course covers essential eCommerce functions, including product catalogue management, inventory, payment gateways, shipping options, order fulfilment and search engine optimisation. Participants will apply generative AI to develop marketing content, customer communications, promotional campaigns and personalised product recommendations. They will also learn to use AI-powered chatbots and automation tools to respond to enquiries, support customers and streamline order-related workflows.</p><p>Participants will analyse sales trends, customer behaviour and key performance indicators using AI-assisted analytics. These insights will help them identify opportunities, forecast demand and make data-driven decisions to improve conversions and customer retention. Responsible AI practices, including data privacy, content accuracy and human review, are also addressed.</p><p>By the end of the course, participants will be able to integrate AI into key eCommerce processes, enhance customer engagement, improve operational efficiency and develop effective strategies for sustainable online business growth.</p>'
      WHEN 'description'       THEN '<!-- LSN_DATA: [{"title":"Topic 1: AI-Enabled eCommerce Store Setup and Content Management","subsecs":[]},{"title":"Topic 2: AI-Assisted Product Catalogue and Web Content Management","subsecs":[]},{"title":"Topic 3: Payment, Shipping and Customer Experience Optimisation","subsecs":[]},{"title":"Topic 4: AI-Powered Sales, Order and Promotion Management","subsecs":[]},{"title":"Topic 5: eCommerce Analytics and Performance Optimisation","subsecs":[]}] -->\n<p><strong>Topic 1: AI-Enabled eCommerce Store Setup and Content Management</strong></p>\n<p><strong>Topic 2: AI-Assisted Product Catalogue and Web Content Management</strong></p>\n<p><strong>Topic 3: Payment, Shipping and Customer Experience Optimisation</strong></p>\n<p><strong>Topic 4: AI-Powered Sales, Order and Promotion Management</strong></p>\n<p><strong>Topic 5: eCommerce Analytics and Performance Optimisation</strong></p>\n'
      ELSE 'AI WordPress eCommerce, WooCommerce course, AI for eCommerce, online store setup, AI product content, eCommerce analytics, WordPress eCommerce training Singapore'
    END
WHERE v.entity_id = @pid AND @pid IS NOT NULL AND v.store_id = 0
  AND a.attribute_code IN ('short_description','description','meta_keyword');

-- ---------- cover (SG render only) ----------
UPDATE catalog_product_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C6-20260928-070437.png'
WHERE v.entity_id = @pid AND @pid IS NOT NULL
  AND a.attribute_code = 'course_image_url'
  AND v.value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C6-20260717-162905.png';

-- ---------- 301s ----------
-- Every old system path (bare + category-prefixed) becomes a custom 301 to the
-- flat new slug, under its OWN id_path. The system rows are deleted first: a
-- 301 left on id_path product/<id> blocks the indexer from minting the new row.
DROP TEMPORARY TABLE IF EXISTS tmp_c6_old;
CREATE TEMPORARY TABLE tmp_c6_old AS
SELECT store_id, request_path FROM core_url_rewrite
WHERE @pid IS NOT NULL AND is_system = 1 AND product_id = @pid
  AND (request_path = 'wordpress-business-website-training.html'
       OR request_path LIKE '%/wordpress-business-website-training.html');

DELETE r FROM core_url_rewrite r
JOIN tmp_c6_old t ON t.store_id = r.store_id AND t.request_path = r.request_path;

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT t.store_id,
       CONCAT('custom/c6-wordpress-business-website-', LEFT(MD5(t.request_path), 10)),
       t.request_path, 'ai-powered-wordpress-ecommerce.html', 0, 'RP',
       '1587: C6 renamed to AI Powered Wordpress eCommerce'
FROM tmp_c6_old t
ON DUPLICATE KEY UPDATE target_path = VALUES(target_path), options = 'RP', is_system = 0;

DROP TEMPORARY TABLE IF EXISTS tmp_c6_old;

-- flatten every legacy 301 that pointed at an old path, so all resolve in one hop
UPDATE core_url_rewrite
SET target_path = 'ai-powered-wordpress-ecommerce.html', options = 'RP'
WHERE is_system = 0
  AND (target_path = 'wordpress-business-website-training.html'
       OR target_path LIKE '%/wordpress-business-website-training.html');

-- ---------- on-site search redirects ----------
-- eCommerce-intent terms follow the course (path swap keeps each site's domain)
UPDATE catalogsearch_query
SET redirect = REPLACE(redirect, '/wordpress-business-website-training.html', '/ai-powered-wordpress-ecommerce.html')
WHERE redirect LIKE '%/wordpress-business-website-training.html'
  AND (query_text LIKE '%commer%' OR query_text LIKE '%woo%');

-- business-website terms -> the WSQ WordPress website course (SG only; verified 200)
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/wsq-building-professional-websites-with-wordpress.html'
WHERE redirect = 'https://www.tertiarycourses.com.sg/wordpress-business-website-training.html';

-- anything left on the old slug (partner domains) follows the course
UPDATE catalogsearch_query
SET redirect = REPLACE(redirect, '/wordpress-business-website-training.html', '/ai-powered-wordpress-ecommerce.html')
WHERE redirect LIKE '%/wordpress-business-website-training.html';

-- fill empty WordPress-eCommerce searches (SG only; never overwrite a set redirect)
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/ai-powered-wordpress-ecommerce.html'
WHERE query_text IN ('wordpress ecommerce','wordpress ecommerse')
  AND (redirect IS NULL OR redirect = '')
  AND EXISTS (SELECT 1 FROM core_store WHERE code = 'singapore');

-- ---------- Funding block -> CASL twin ----------
-- Content-only UPDATE. NEVER ->save() a cms/block model (wipes cms_block_store).
UPDATE cms_block
   SET content = CONCAT(
     '<p>No funding is available for this course</p> ',
     '<p>For CASL funding, please checkout the details at&nbsp;',
     '<span style="text-decoration: underline;">',
     '<a href="https://www.tertiarycourses.com.sg/casl-ai-for-ecommerce.html" ',
     'title="CASL - AI for eCommerce" target="_blank">',
     'CASL - AI for eCommerce</a></span></p>')
 WHERE identifier = 'course_C6_funding_and_grant'
   AND EXISTS (SELECT 1 FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064474');

-- ---------- category membership: e-Commerce + AI for Retail ----------
-- Slot C6 at the head of each category's C block (right after the last TGS-
-- member), shifting the rest down one. Only on first run (@need).
SET @cat_ec := (SELECT v.entity_id FROM catalog_category_entity_varchar v
                JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @cet
                WHERE a.attribute_code = 'url_key' AND v.store_id = 0
                  AND v.value = 'ecommerce-training-courses' LIMIT 1);
SET @cat_ret := (SELECT v.entity_id FROM catalog_category_entity_varchar v
                 JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @cet
                 WHERE a.attribute_code = 'url_key' AND v.store_id = 0
                   AND v.value = 'ai-for-retail-courses' LIMIT 1);

-- e-Commerce
SET @cat := @cat_ec;
SET @need := (SELECT @pid IS NOT NULL AND @cat IS NOT NULL AND NOT EXISTS
              (SELECT 1 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid));
SET @slot := (SELECT COALESCE(MAX(cp.position), 0) + 1 FROM catalog_category_product cp
              JOIN catalog_product_entity p ON p.entity_id = cp.product_id
              WHERE cp.category_id = @cat AND p.sku LIKE 'TGS-%');
UPDATE catalog_category_product SET position = position + 1
 WHERE @need AND category_id = @cat AND position >= @slot;
UPDATE catalog_category_product_index SET position = position + 1
 WHERE @need AND category_id = @cat AND position >= @slot;
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @need;

-- AI for Retail
SET @cat := @cat_ret;
SET @need := (SELECT @pid IS NOT NULL AND @cat IS NOT NULL AND NOT EXISTS
              (SELECT 1 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid));
SET @slot := (SELECT COALESCE(MAX(cp.position), 0) + 1 FROM catalog_category_product cp
              JOIN catalog_product_entity p ON p.entity_id = cp.product_id
              WHERE cp.category_id = @cat AND p.sku LIKE 'TGS-%');
UPDATE catalog_category_product SET position = position + 1
 WHERE @need AND category_id = @cat AND position >= @slot;
UPDATE catalog_category_product_index SET position = position + 1
 WHERE @need AND category_id = @cat AND position >= @slot;
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @need;

-- mirror into the index the storefront reads (visibility from the product's own rows)
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product cp
JOIN catalog_category_product_index i ON i.product_id = cp.product_id AND i.store_id > 0
WHERE cp.product_id = @pid AND @pid IS NOT NULL AND cp.category_id IN (@cat_ec, @cat_ret)
GROUP BY cp.category_id, cp.product_id, cp.position, i.store_id;
