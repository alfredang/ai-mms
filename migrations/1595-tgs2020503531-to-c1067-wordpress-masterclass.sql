-- 1595: TGS-2020503531 "WSQ - Building Professional Websites with WordPress"
--       -> C1067 "WordPress Masterclass" (unfunded, non-WSQ)
--
-- The WSQ course itself becomes a non-WSQ course (SKU = 'C' + entity_id):
--   * sku TGS-2020503531 -> C1067 (historical order items keep the old code);
--   * name / meta / url_key / url_path / cover-alt labels -> new title, slug
--     wordpress-masterclass, permanent 301 from every old path (bare +
--     category-prefixed) and every legacy 301 flattened to one hop;
--   * About copy and prerequisite rewritten without WSQ / funding / PWM /
--     entry-requirement sections; duration 8 -> 7.5 (non-WSQ day);
--   * all funding removed: the 7 funding badge tags, enable_sg_funding = 0,
--     the Funding Validity window (news_from/to_date), assessment fields, and
--     the 7 WSQ-only categories;
--   * the five per-SKU cms_blocks move to course_C1067_*; funding_and_grant and
--     skills_framework (WSQ TSC) are deactivated so no funding card renders;
--     certification loses the OpenCerts bullet;
--   * the WSQ Drive brochure is unlinked (no non-WSQ brochure yet);
--   * search rows follow the course to the new slug.
--
-- Keyed on the TGS- SKU, which exists on SG only - partner sites no-op.
-- Idempotent: once the SKU has flipped, @pid is NULL and every step no-ops.
--
-- Post-deploy on prod: re-render cover (title baked in), refreshProductRewrite,
-- flat product reindex, category-ordering sweep, cache flush; switch the
-- schedule template "(SG) WSQ-A06" (carries the WSQ "Funding Eligibility"
-- option) -> non-WSQ "A06 Mon/Sun 2nd wk" via the Switch Template code path.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2020503531' LIMIT 1);
SET @new := CONCAT('C', @pid);
SET @pet := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @cet := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category');
-- never collide with an existing C-code
SET @pid := IF(EXISTS (SELECT 1 FROM catalog_product_entity WHERE TRIM(sku) = @new), NULL, @pid);

-- ---------- per-SKU cms_blocks (resolved from the LIVE sku at render time) ----------
UPDATE cms_block
   SET identifier = REPLACE(identifier, 'TGS-2020503531', @new),
       title      = REPLACE(title, 'TGS-2020503531', @new)
 WHERE @pid IS NOT NULL AND identifier LIKE 'course\_TGS-2020503531\_%';

UPDATE cms_block SET is_active = 0
 WHERE @pid IS NOT NULL
   AND identifier IN (CONCAT('course_', @new, '_funding_and_grant'),
                      CONCAT('course_', @new, '_skills_framework'),
                      CONCAT('course_', @new, '_brochure'));

UPDATE cms_block
   SET content = '<ul class="cert-bullets"><li><strong>Certificate of Achievement from Tertiary Infotech Academy Pte Ltd</strong> - Upon meeting at least 75% attendance, participants will receive a Certificate of Achievement from Tertiary Infotech Academy Pte Ltd.</li></ul>'
 WHERE @pid IS NOT NULL AND identifier = CONCAT('course_', @new, '_certification');

-- WSQ brochure on Drive no longer describes this course
UPDATE course_courseware SET brochure_link = ''
 WHERE @pid IS NOT NULL AND product_id = @pid;

-- ---------- name / meta_title / meta_description / url / labels ----------
UPDATE catalog_product_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = CASE a.attribute_code
      WHEN 'url_key'          THEN 'wordpress-masterclass'
      WHEN 'url_path'         THEN 'wordpress-masterclass.html'
      WHEN 'meta_description' THEN 'Build and manage professional websites with WordPress - posts and pages, multimedia content, site settings, plugins, widgets, themes and CSS customisation.'
      WHEN 'duration'         THEN '7.5'
      ELSE 'WordPress Masterclass'
    END
WHERE v.entity_id = @pid AND @pid IS NOT NULL
  AND a.attribute_code IN ('name','meta_title','meta_description','url_key','url_path',
                           'image_label','small_image_label','thumbnail_label','duration');

UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'WordPress Masterclass'
WHERE g.entity_id = @pid AND @pid IS NOT NULL;

-- ---------- About / keywords / prerequisite ----------
UPDATE catalog_product_entity_text v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = CASE a.attribute_code
      WHEN 'short_description' THEN '<p>Unleash your creative potential and become proficient in content management with our WordPress Masterclass. Designed for all skill levels, this course walks you through the essentials of WordPress - from setting up a website to customising themes and plugins. You will gain the expertise needed to manage and optimise content across various types of websites, be it a personal blog or a corporate site.</p><p>This comprehensive course covers a wide range of topics including website building, SEO optimisation, and data analytics for better user engagement. Whether you are a business owner looking to enhance your online presence or an individual interested in web development, this course offers a strong foundation in content management using WordPress. Equip yourself with the skills to make your mark in the digital world.</p>'
      WHEN 'prerequisite'      THEN '<h2>Prerequisite</h2><p>No prior web development experience is required. Participants should be comfortable using a computer and a web browser.</p><h2>Minimum Software/Hardware Requirement</h2><p><strong>Software:</strong></p><p>You can download and install the following software:</p><ul><li><u><a href="https://wordpress.org/" rel="noopener noreferrer" target="_blank">WordPress</a></u></li></ul><p><strong>Hardware:</strong> Windows and Mac Laptops</p>'
      WHEN 'assessment_methods' THEN NULL
      ELSE 'WordPress Masterclass, WordPress course Singapore, WordPress training, content management, CMS, web development, WordPress themes, WordPress plugins'
    END
WHERE v.entity_id = @pid AND @pid IS NOT NULL
  AND a.attribute_code IN ('short_description','prerequisite','assessment_methods','meta_keyword');

-- ---------- funding flags / validity window / assessment ----------
UPDATE catalog_product_entity_int v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
SET v.value = 0
WHERE v.entity_id = @pid AND @pid IS NOT NULL AND a.attribute_code = 'enable_sg_funding';

DELETE v FROM catalog_product_entity_int v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
WHERE v.entity_id = @pid AND @pid IS NOT NULL AND a.attribute_code = 'assessment_duration';

DELETE v FROM catalog_product_entity_datetime v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @pet
WHERE v.entity_id = @pid AND @pid IS NOT NULL
  AND a.attribute_code IN ('news_from_date','news_to_date');

-- funding badge chips (tags)
DELETE r FROM tag_relation r
JOIN tag t ON t.tag_id = r.tag_id
WHERE r.product_id = @pid AND @pid IS NOT NULL
  AND t.name IN ('WSQ','SkillsFuture Credit','PSEA','UTAP','IBF','HRDF','SFEC','Absentee Payroll','MCES');

-- ---------- WSQ-only categories ----------
DROP TEMPORARY TABLE IF EXISTS tmp_c1067_wsq_cats;
CREATE TEMPORARY TABLE tmp_c1067_wsq_cats (category_id INT PRIMARY KEY);
INSERT IGNORE INTO tmp_c1067_wsq_cats (category_id)
SELECT v.entity_id FROM catalog_category_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @cet
WHERE a.attribute_code = 'url_key' AND v.store_id = 0
  AND v.value IN ('latest-courses','wsq-media-marketing-courses','wsq-funded-courses',
                  'wsq-finance-mfg-green-courses','wsq-it-security-courses',
                  'wsq-e-commerce-cms-courses','wsq-web-design-cms-courses');

DELETE cp FROM catalog_category_product cp
JOIN tmp_c1067_wsq_cats t ON t.category_id = cp.category_id
WHERE cp.product_id = @pid AND @pid IS NOT NULL;
DELETE i FROM catalog_category_product_index i
JOIN tmp_c1067_wsq_cats t ON t.category_id = i.category_id
WHERE i.product_id = @pid AND @pid IS NOT NULL;

-- ---------- 301s ----------
-- Old system paths become custom 301s under their own id_path; the system rows
-- are deleted first so the indexer can mint the new canonical row unsuffixed.
DROP TEMPORARY TABLE IF EXISTS tmp_c1067_old;
CREATE TEMPORARY TABLE tmp_c1067_old AS
SELECT store_id, request_path FROM core_url_rewrite
WHERE @pid IS NOT NULL AND is_system = 1 AND product_id = @pid
  AND (request_path = 'wsq-building-professional-websites-with-wordpress.html'
       OR request_path LIKE '%/wsq-building-professional-websites-with-wordpress.html');

DELETE r FROM core_url_rewrite r
JOIN tmp_c1067_old t ON t.store_id = r.store_id AND t.request_path = r.request_path;

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT t.store_id,
       CONCAT('custom/c1067-wsq-wordpress-', LEFT(MD5(t.request_path), 10)),
       t.request_path, 'wordpress-masterclass.html', 0, 'RP',
       '1595: TGS-2020503531 converted to C1067 WordPress Masterclass'
FROM tmp_c1067_old t
ON DUPLICATE KEY UPDATE target_path = VALUES(target_path), options = 'RP', is_system = 0;

DROP TEMPORARY TABLE IF EXISTS tmp_c1067_old;

UPDATE core_url_rewrite
SET target_path = 'wordpress-masterclass.html', options = 'RP'
WHERE @pid IS NOT NULL AND is_system = 0
  AND (target_path = 'wsq-building-professional-websites-with-wordpress.html'
       OR target_path LIKE '%/wsq-building-professional-websites-with-wordpress.html');

-- ---------- on-site search redirects ----------
UPDATE catalogsearch_query
SET redirect = REPLACE(redirect, '/wsq-building-professional-websites-with-wordpress.html', '/wordpress-masterclass.html')
WHERE @pid IS NOT NULL AND redirect LIKE '%/wsq-building-professional-websites-with-wordpress.html';

-- ---------- SKU flip (last: every step above keys on @pid) ----------
UPDATE catalog_product_entity SET sku = @new
WHERE entity_id = @pid AND @pid IS NOT NULL;
