-- 1594: C398 "AI for Retail" -> "AI for Shopify eCommerce"
--
-- C398 becomes the non-WSQ twin of TGS-2026064175 "CASL - AI for Shopify
-- eCommerce Store" (the courseware is duplicated from that course), so:
--   * name / meta_title / url_key / url_path / cover-alt labels -> new title,
--     slug ai-for-shopify-ecommerce, with a permanent 301 from every old path (bare +
--     category-prefixed) and the legacy R-course 301s flattened to one hop;
--   * short_description (About) + description (topics) copied VERBATIM from the
--     parent (asserted free of any day count / WSQ / funding wording); new
--     meta_description + meta_keyword; duration 7.5 / sessions 1 / $350 stay -
--     the non-WSQ twin runs ONE day (the parent is 2);
--   * prerequisite: the stale "Basic R Programming / R Studio" copy from the
--     entity's earlier life is replaced (guarded on that text) with a plain
--     prerequisite + the parent's Software/Hardware section (no WSQ sections);
--   * re-rendered cover PNG (title is baked in) - guarded on the old R2 URL;
--   * search terms c398 / c0398 follow the course;
--   * Funding block -> the CASL twin (target verified HTTP 200 directly);
--   * C398 listed under "e-Commerce" (cat 21) at the head of its C block, and
--     re-ordered ahead of C6 in "AI for Retail" (cat 436) - alphabetical C block.
--
-- Keyed by SKU / url_key / identifier - partner sites (C-catalog parity, no
-- TGS- courses) pick up the rename; the funding + category steps no-op where
-- the parent / category is absent. Idempotent.
--
-- Post-deploy on prod: refreshProductRewrite(C398) + flat + flush, or the new
-- slug 404s (the indexer, not this SQL, mints the canonical system row).

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C398' LIMIT 1);
SET @pet := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @cet := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category');

-- ---------- name / meta_title / url_key / url_path / labels ----------
UPDATE catalog_product_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = CASE a.attribute_code
      WHEN 'url_key'          THEN 'ai-for-shopify-ecommerce'
      WHEN 'url_path'         THEN 'ai-for-shopify-ecommerce.html'
      WHEN 'meta_description' THEN 'Use AI to build and run a Shopify eCommerce store - storefront setup, product and web content, theme customisation, orders, payments, shipping and AI-assisted marketing.'
      ELSE 'AI for Shopify eCommerce'
    END
WHERE v.entity_id = @pid AND @pid IS NOT NULL
  AND a.attribute_code IN ('name','meta_title','meta_description','url_key','url_path',
                           'image_label','small_image_label','thumbnail_label');

-- media-gallery label = the alt text the product page actually renders
-- (still "R Data Visualization Training in Singapore" from an earlier life)
UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'AI for Shopify eCommerce'
WHERE g.entity_id = @pid AND @pid IS NOT NULL;

-- ---------- About / topics / keywords (copied from TGS-2026064175) ----------
UPDATE catalog_product_entity_text v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = CASE a.attribute_code
      WHEN 'short_description' THEN '<p>This course equips participants with practical skills to build, manage, and enhance a Shopify eCommerce store using Artificial Intelligence (AI). Learners will explore how AI tools can support key stages of eCommerce development, from setting up the storefront and creating product content to improving customer experience and streamlining day-to-day store operations.</p><p>Participants will learn to configure Shopify themes, product catalogues, collections, inventory, orders, customers, discounts, and essential store settings. They will use AI to generate and refine product titles, descriptions, images, promotional content, SEO keywords, and marketing materials. The course also explores how AI can support personalised customer experiences, customer enquiries, product recommendations, and eCommerce marketing activities.</p><p>Learners will gain hands-on experience using Shopify\'s built-in features and AI capabilities to optimise store content, improve search visibility, analyse sales and customer data, and identify opportunities for business improvement. Key considerations such as payment setup, shipping, store security, testing, and publishing will also be covered.</p><p>By the end of the course, participants will be able to create and manage a professional Shopify eCommerce store and apply AI effectively to improve content creation, marketing, customer engagement, operational efficiency, and data-driven decision-making to support eCommerce business growth.</p>'
      WHEN 'description'       THEN '<!-- LSN_DATA: [{"title":"Topic 1: AI Vibe Coding for eCommerce Store Setup and CMS","subsecs":[]},{"title":"Topic 2: Product Catalogue and Web Content Management","subsecs":[]},{"title":"Topic 3: AI-Assisted Storefront and Customer Experience Customisation","subsecs":[]},{"title":"Topic 4: Shopping Cart, Checkout and Order Management","subsecs":[]},{"title":"Topic 5: Payment, Tax, Shipping and Fulfilment Integration","subsecs":[]}] -->\r\n<p><strong>Topic 1: AI Vibe Coding for eCommerce Store Setup and CMS</strong></p>\r\n<p><strong>Topic 2: Product Catalogue and Web Content Management</strong></p>\r\n<p><strong>Topic 3: AI-Assisted Storefront and Customer Experience Customisation</strong></p>\r\n<p><strong>Topic 4: Shopping Cart, Checkout and Order Management</strong></p>\r\n<p><strong>Topic 5: Payment, Tax, Shipping and Fulfilment Integration</strong></p>\r\n'
      ELSE 'AI for Shopify eCommerce, Shopify course Singapore, AI Shopify store, Shopify training, AI product content, Shopify theme customisation, Shopify order management, eCommerce AI course'
    END
WHERE v.entity_id = @pid AND @pid IS NOT NULL AND v.store_id = 0
  AND a.attribute_code IN ('short_description','description','meta_keyword');

-- ---------- prerequisite (only while it still holds the R-course copy) ----------
UPDATE catalog_product_entity_text v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = '<h2>Prerequisite</h2><p>No prior eCommerce or coding experience is required. Participants should be comfortable using a computer and a web browser.</p><h2>Minimum Software/Hardware Requirement</h2><p><strong>Software:</strong></p><p>You can download and install the following software:</p><ul><li><u><a href="https://shopify.pxf.io/c/3509899/1424185/13624" rel="noopener noreferrer" target="_blank">Shopify</a></u></li></ul><p><strong>Hardware:</strong> Windows and Mac Laptops</p>'
WHERE v.entity_id = @pid AND @pid IS NOT NULL AND v.store_id = 0
  AND a.attribute_code = 'prerequisite'
  AND v.value LIKE '%Basic R Programming%';

-- ---------- cover (SG render only) ----------
UPDATE catalog_product_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C398-20260928-211338.png'
WHERE v.entity_id = @pid AND @pid IS NOT NULL
  AND a.attribute_code = 'course_image_url'
  AND v.value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C398-20260717-162845.png';

-- ---------- 301s ----------
-- Every old system path (bare + category-prefixed) becomes a custom 301 to the
-- flat new slug, under its OWN id_path. The system rows are deleted first: a
-- 301 left on id_path product/<id> blocks the indexer from minting the new row.
-- ('%/ai-for-retail.html' never matches the category page ai-for-retail-courses.html.)
DROP TEMPORARY TABLE IF EXISTS tmp_c398_old;
CREATE TEMPORARY TABLE tmp_c398_old AS
SELECT store_id, request_path FROM core_url_rewrite
WHERE @pid IS NOT NULL AND is_system = 1 AND product_id = @pid
  AND (request_path = 'ai-for-retail.html'
       OR request_path LIKE '%/ai-for-retail.html');

DELETE r FROM core_url_rewrite r
JOIN tmp_c398_old t ON t.store_id = r.store_id AND t.request_path = r.request_path;

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT t.store_id,
       CONCAT('custom/c398-ai-for-retail-', LEFT(MD5(t.request_path), 10)),
       t.request_path, 'ai-for-shopify-ecommerce.html', 0, 'RP',
       '1594: C398 renamed to AI for Shopify eCommerce'
FROM tmp_c398_old t
ON DUPLICATE KEY UPDATE target_path = VALUES(target_path), options = 'RP', is_system = 0;

DROP TEMPORARY TABLE IF EXISTS tmp_c398_old;

-- flatten every legacy 301 that pointed at an old path, so all resolve in one hop
UPDATE core_url_rewrite
SET target_path = 'ai-for-shopify-ecommerce.html', options = 'RP'
WHERE is_system = 0
  AND (target_path = 'ai-for-retail.html'
       OR target_path LIKE '%/ai-for-retail.html');

-- ---------- on-site search redirects (c398 / c0398) ----------
-- path swap keeps each site's own domain
UPDATE catalogsearch_query
SET redirect = REPLACE(redirect, '/ai-for-retail.html', '/ai-for-shopify-ecommerce.html')
WHERE redirect LIKE '%/ai-for-retail.html';

-- ---------- Funding block -> CASL twin ----------
-- Content-only UPDATE. NEVER ->save() a cms/block model (wipes cms_block_store).
UPDATE cms_block
   SET content = CONCAT(
     '<h2>Funding and Grant Applications</h2>\n',
     '<p>No funding is available for this course</p>\n',
     '<p>For CASL funding, please checkout the details at&nbsp;',
     '<span style="text-decoration: underline;">',
     '<a href="https://www.tertiarycourses.com.sg/casl-ai-for-shopify-ecommerce-store.html" ',
     'title="CASL - AI for Shopify eCommerce Store" target="_blank">',
     'CASL - AI for Shopify eCommerce Store</a></span></p>')
 WHERE identifier = 'course_C398_funding_and_grant'
   AND EXISTS (SELECT 1 FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064175');

-- ---------- category membership ----------
SET @cat_ec := (SELECT v.entity_id FROM catalog_category_entity_varchar v
                JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @cet
                WHERE a.attribute_code = 'url_key' AND v.store_id = 0
                  AND v.value = 'ecommerce-training-courses' LIMIT 1);
SET @cat_ret := (SELECT v.entity_id FROM catalog_category_entity_varchar v
                 JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @cet
                 WHERE a.attribute_code = 'url_key' AND v.store_id = 0
                   AND v.value = 'ai-for-retail-courses' LIMIT 1);

-- e-Commerce: slot C398 at the head of the C block (right after the last TGS-
-- member; "AI for Shopify..." sorts first), shifting the rest down one.
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

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product cp
JOIN catalog_category_product_index i ON i.product_id = cp.product_id AND i.store_id > 0
WHERE cp.product_id = @pid AND @pid IS NOT NULL AND cp.category_id = @cat_ec
GROUP BY cp.category_id, cp.product_id, cp.position, i.store_id;

-- AI for Retail: C398 already listed; swap it ahead of C6 (alphabetical C block)
SET @p_c6 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C6' LIMIT 1);
SET @pos_c6 := (SELECT position FROM catalog_category_product WHERE category_id = @cat_ret AND product_id = @p_c6);
SET @pos_me := (SELECT position FROM catalog_category_product WHERE category_id = @cat_ret AND product_id = @pid);
SET @swap := (@pos_c6 IS NOT NULL AND @pos_me IS NOT NULL AND @pos_me > @pos_c6);
UPDATE catalog_category_product
   SET position = CASE product_id WHEN @pid THEN @pos_c6 ELSE @pos_me END
 WHERE @swap AND category_id = @cat_ret AND product_id IN (@pid, @p_c6);
UPDATE catalog_category_product_index
   SET position = CASE product_id WHEN @pid THEN @pos_c6 ELSE @pos_me END
 WHERE @swap AND category_id = @cat_ret AND product_id IN (@pid, @p_c6);
