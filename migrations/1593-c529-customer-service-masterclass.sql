-- 1593: C529 "Increase Your Business with Excellent Customer Service" -> "Customer Service Masterclass"
--
-- C529 becomes the non-WSQ twin of TGS-2025056191 "WSQ - Improve Your Business
-- with Excellent Customer Service" (courseware duplicated from that course):
--   * name / meta_title / url_key / url_path / cover-alt labels -> new title,
--     slug customer-service-masterclass, with a permanent 301 from every old
--     path (bare + category-prefixed) and legacy 301s flattened to one hop;
--   * short_description (About) + description (topics) copied from the parent
--     (curly quote / en dash written as HTML entities so the file is ASCII;
--     asserted free of any day count / WSQ / funding wording); new
--     meta_description + meta_keyword; duration 7.5 / sessions 1 already match
--     the one-day parent and are NOT touched;
--   * re-rendered cover PNG (title is baked in) - guarded on the old R2 URL;
--   * on-site search redirects on the old slug follow the course, except the
--     "Improve ..." (WSQ-title) terms, which go to the WSQ parent; the empty
--     WSQ-title row is filled with the parent;
--   * Funding block -> the parent's canonical URL (old link 301-hopped via
--     /improve-your-business-with-excellent-customer-service.html).
--   Category membership unchanged (already in the parent's non-WSQ cats; in
--   Customer Service (424) the new name keeps the same alphabetical slot).
--
-- Keyed by SKU / url_key / identifier - partner sites (C-catalog parity, no
-- TGS- courses) pick up the C529 rename; parent-dependent bits are SG-guarded.
-- Idempotent.
--
-- Post-deploy on prod: refreshProductRewrite(C529) + reindex + flush, or the
-- new slug 404s (the indexer, not this SQL, mints the canonical system row).

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C529' LIMIT 1);
SET @pet := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------- name / meta_title / url_key / url_path / labels ----------
UPDATE catalog_product_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = CASE a.attribute_code
      WHEN 'url_key'          THEN 'customer-service-masterclass'
      WHEN 'url_path'         THEN 'customer-service-masterclass.html'
      WHEN 'meta_description' THEN 'Assess customer needs, analyse feedback and deliver excellent service in person, by phone and by email. Handle difficult customers, know when to escalate and win return business.'
      ELSE 'Customer Service Masterclass'
    END
WHERE v.entity_id = @pid AND @pid IS NOT NULL
  AND a.attribute_code IN ('name','meta_title','meta_description','url_key','url_path',
                           'image_label','small_image_label','thumbnail_label');

-- media-gallery label = the alt text the product page actually renders
UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'Customer Service Masterclass'
WHERE g.entity_id = @pid AND @pid IS NOT NULL;

-- ---------- About / topics / keywords (copied from TGS-2025056191) ----------
UPDATE catalog_product_entity_text v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = CASE a.attribute_code
      WHEN 'short_description' THEN '<p>This course equips participants with the skills to assess and address customer needs by effectively collecting and analyzing customer feedback. Learners will develop an understanding of customer expectations, explore various communication channels such as phone and email, and identify opportunities to enhance service quality. Through practical scenarios, participants will strengthen their ability to deliver exceptional customer service, ensuring a positive customer experience.</p>\n<p>Additionally, learners will gain insights into managing difficult customers and knowing when to escalate concerns for resolution. The course also emphasizes strategies to generate return business by improving customer satisfaction and leveraging operational feedback. By the end of the course, participants will be able to implement service improvements that drive business growth.</p>'
      WHEN 'description'       THEN '<!-- LSN_DATA: [{"title":"Topic 1: Who We Are and What We Do - Understanding Customers & Customer Service","subsecs":[{"title":"Who Are Customers? (internal/external)","links":[]},{"title":"What is Customer Service?","links":[]},{"title":"Who Are Customer Service Providers?","links":[]}]},{"title":"Topic 2: Establishing Your Attitude","subsecs":[{"title":"Appearance Counts!","links":[]},{"title":"The Power of a Smile","links":[]},{"title":"Staying Energized","links":[]},{"title":"Staying Positive","links":[]}]},{"title":"Topic 3: Identifying and Addressing The Customer''s Needs","subsecs":[{"title":"Understanding the Customer''s Problem","links":[]},{"title":"Staying Outside the Box","links":[]},{"title":"Meeting Basic Needs","links":[]},{"title":"Going the Extra Mile","links":[]}]},{"title":"Topic 4: In-Person Customer Service (Face to Face)","subsecs":[{"title":"Dealing With At-Your-Desk Requests","links":[]},{"title":"The Advantages and Disadvantages of In-Person Communication","links":[]},{"title":"Using Body Language to Your Advantage","links":[]}]},{"title":"Topic 5: Giving Customer Service over the Phone","subsecs":[{"title":"The Advantages and Disadvantages of Telephone Communication","links":[]},{"title":"Telephone Etiquette","links":[]},{"title":"Tips and Tricks","links":[]}]},{"title":"Topic 6: Providing Customer Service via Email","subsecs":[{"title":"The Advantages and Disadvantages of Email Communication","links":[]},{"title":"Understanding Netiquette","links":[]},{"title":"Tips and Tricks","links":[]},{"title":"Examples: Chat or e-mail","links":[]}]},{"title":"Topic 7: Generating Return Business with Better Customer Service","subsecs":[{"title":"Following Up from Customer Feedback","links":[]},{"title":"Addressing Customer Complaints","links":[]},{"title":"Turning Difficult Customers Around","links":[]}]},{"title":"Topic 8: Recovering Difficult Customers","subsecs":[{"title":"De-Escalating Anger","links":[]},{"title":"Establishing Common Ground","links":[]},{"title":"Setting Your Limits","links":[]},{"title":"Managing Your Own Emotions","links":[]}]},{"title":"Topic 9: Understanding When to Escalate","subsecs":[{"title":"Dealing with Vulgarity","links":[]},{"title":"Coping with Insults","links":[]},{"title":"Dealing with Legal and Physical Threats","links":[]}]}] -->\n<p><strong>Topic 1: Who We Are and What We Do &ndash; Understanding Customers &amp; Customer Service</strong></p>\n<p><em>Who Are Customers? (internal/external)</em></p>\n<p><em>What is Customer Service?</em></p>\n<p><em>Who Are Customer Service Providers?</em></p>\n<p><strong>Topic 2: Establishing Your Attitude</strong></p>\n<p><em>Appearance Counts!</em></p>\n<p><em>The Power of a Smile</em></p>\n<p><em>Staying Energized</em></p>\n<p><em>Staying Positive</em></p>\n<p><strong>Topic 3: Identifying and Addressing The Customer&rsquo;s Needs</strong></p>\n<p><em>Understanding the Customer&rsquo;s Problem</em></p>\n<p><em>Staying Outside the Box</em></p>\n<p><em>Meeting Basic Needs</em></p>\n<p><em>Going the Extra Mile</em></p>\n<p><strong>Topic 4: In-Person Customer Service (Face to Face)</strong></p>\n<p><em>Dealing With At-Your-Desk Requests</em></p>\n<p><em>The Advantages and Disadvantages of In-Person Communication</em></p>\n<p><em>Using Body Language to Your Advantage</em></p>\n<p><strong>Topic 5: Giving Customer Service over the Phone</strong></p>\n<p><em>The Advantages and Disadvantages of Telephone Communication</em></p>\n<p><em>Telephone Etiquette</em></p>\n<p><em>Tips and Tricks</em></p>\n<p><strong>Topic 6: Providing Customer Service via Email</strong></p>\n<p><em>The Advantages and Disadvantages of Email Communication</em></p>\n<p><em>Understanding Netiquette</em></p>\n<p><em>Tips and Tricks</em></p>\n<p><em>Examples: Chat or e-mail</em></p>\n<p><strong>Topic 7: Generating Return Business with Better Customer Service</strong></p>\n<p><em>Following Up from Customer Feedback</em></p>\n<p><em>Addressing Customer Complaints</em></p>\n<p><em>Turning Difficult Customers Around</em></p>\n<p><strong>Topic 8: Recovering Difficult Customers</strong></p>\n<p><em>De-Escalating Anger</em></p>\n<p><em>Establishing Common Ground</em></p>\n<p><em>Setting Your Limits</em></p>\n<p><em>Managing Your Own Emotions</em></p>\n<p><strong>Topic 9: Understanding When to Escalate</strong></p>\n<p><em>Dealing with Vulgarity</em></p>\n<p><em>Coping with Insults</em></p>\n<p><em>Dealing with Legal and Physical Threats</em></p>\n'
      ELSE 'customer service masterclass, customer service training, customer feedback analysis, handle difficult customers, phone and email customer service, service excellence, return business, customer service course Singapore'
    END
WHERE v.entity_id = @pid AND @pid IS NOT NULL AND v.store_id = 0
  AND a.attribute_code IN ('short_description','description','meta_keyword');

-- ---------- cover (SG render only) ----------
UPDATE catalog_product_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C529-20260928-202459.png'
WHERE v.entity_id = @pid AND @pid IS NOT NULL
  AND a.attribute_code = 'course_image_url'
  AND v.value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C529-20260717-162901.png';

-- ---------- 301s ----------
-- Every old system path (bare + category-prefixed) becomes a custom 301 to the
-- flat new slug, under its OWN id_path. The system rows are deleted first: a
-- 301 left on id_path product/<id> blocks the indexer from minting the new row.
DROP TEMPORARY TABLE IF EXISTS tmp_c529_old;
CREATE TEMPORARY TABLE tmp_c529_old AS
SELECT store_id, request_path FROM core_url_rewrite
WHERE @pid IS NOT NULL AND is_system = 1 AND product_id = @pid
  AND (request_path = 'increase-your-business-customer-service.html'
       OR request_path LIKE '%/increase-your-business-customer-service.html');

DELETE r FROM core_url_rewrite r
JOIN tmp_c529_old t ON t.store_id = r.store_id AND t.request_path = r.request_path;

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT t.store_id,
       CONCAT('custom/c529-increase-your-business-', LEFT(MD5(t.request_path), 10)),
       t.request_path, 'customer-service-masterclass.html', 0, 'RP',
       '1593: C529 renamed to Customer Service Masterclass'
FROM tmp_c529_old t
ON DUPLICATE KEY UPDATE target_path = VALUES(target_path), options = 'RP', is_system = 0;

DROP TEMPORARY TABLE IF EXISTS tmp_c529_old;

-- flatten every legacy 301 that pointed at an old path, so all resolve in one hop
UPDATE core_url_rewrite
SET target_path = 'customer-service-masterclass.html', options = 'RP'
WHERE is_system = 0
  AND (target_path = 'increase-your-business-customer-service.html'
       OR target_path LIKE '%/increase-your-business-customer-service.html');

-- ---------- on-site search redirects ----------
-- WSQ-title ("Improve ...") terms -> the WSQ parent (SG only; verified 200)
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/wsq-improve-your-business-with-excellent-customer-service.html'
WHERE redirect = 'https://www.tertiarycourses.com.sg/increase-your-business-customer-service.html'
  AND query_text LIKE 'improve %'
  AND EXISTS (SELECT 1 FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025056191');

UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/wsq-improve-your-business-with-excellent-customer-service.html'
WHERE query_text = 'WSQ - Improve Your Business with Excellent Customer Service'
  AND (redirect IS NULL OR redirect = '')
  AND EXISTS (SELECT 1 FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025056191');

-- everything else on the old slug follows the course (path swap keeps each site's domain)
UPDATE catalogsearch_query
SET redirect = REPLACE(redirect, '/increase-your-business-customer-service.html', '/customer-service-masterclass.html')
WHERE redirect LIKE '%/increase-your-business-customer-service.html';

-- ---------- Funding block -> WSQ parent (canonical URL) ----------
-- Content-only UPDATE. NEVER ->save() a cms/block model (wipes cms_block_store).
UPDATE cms_block
   SET content = CONCAT(
     '<p>No funding is available for this course.</p> ',
     '<p>For WSQ funding, please checkout the details at&nbsp;',
     '<span style="text-decoration: underline;">',
     '<a href="https://www.tertiarycourses.com.sg/wsq-improve-your-business-with-excellent-customer-service.html" ',
     'title="WSQ - Improve Your Business with Excellent Customer Service" target="_blank">',
     'WSQ - Improve Your Business with Excellent Customer Service</a></span></p>')
 WHERE identifier = 'course_C529_funding_and_grant'
   AND EXISTS (SELECT 1 FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025056191');
