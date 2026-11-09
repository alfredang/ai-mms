-- 1916: GSC "Not found (404)" fifth pass + drop two dead entries from sitemap.xml.
--
-- WHY: GSC validation of the SG 404 bucket (1,951 URLs) failed again on 2026-11-09.
-- The 999-row export re-crawled the same day: 875 already 301/302 to a live page
-- (1796/1811/1871), 59 are kids workshops / educational tours / junk *.mp4 and
-- truncated paths (left 404 on purpose, 1796 policy), and the 10 adult slugs below
-- still 404:
--   * four disabled courses still own their slug (system row -> product view -> 404):
--     C1392, C1403, C173, C496;
--   * six slugs have no core_url_rewrite row at all (old Pearson VUE course, and the
--     -NNN collision ladder of the retired wsq-manufacturing-courses category; -151
--     already 301s to the same target).
-- Targets: same-name successor (C1392 -> its WSQ twin), else the course's own live
-- category. Every target curl-verified 200 with 0 redirects on prod.
--
-- Sitemap: two URLs in sitemap.xml do not return 200, so Google keeps re-reporting them:
--   * CMS page 14 `tests` ("Our Training Providers") - /tests is 404'd by the security
--     rule in .htaccess (RedirectMatch 404 ^/tests), so the page is unreachable anyway;
--   * category 264 `feedback` - .htaccess 301s /feedback.html to the Google Form; the
--     category has no children, no products and is not in the menu.
-- Deactivating both removes them from the sitemap; what visitors see is unchanged.
--
-- SG only (@mms_instance + store guard) -> no-op on MY/GH. Idempotent.

SET @ok := (@mms_instance = 'SG' AND (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);
SET @p_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @p_up := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');

DROP TEMPORARY TABLE IF EXISTS tmp_gsc1916;
CREATE TEMPORARY TABLE tmp_gsc1916 (src VARCHAR(255) PRIMARY KEY, dst VARCHAR(255), sku VARCHAR(64)) DEFAULT CHARSET=utf8;
INSERT INTO tmp_gsc1916 (src, dst, sku) VALUES
  ('aws-certified-sysops-administrator-exam-prep.html',                       'wsq-aws-certified-sysops-administrator-associate-training.html', 'C1392'),
  ('microsoft-365-fundamentals-ms-900-exam-prep.html',                        'microsoft-certifications-exams.html',                            'C1403'),
  ('swift-programming-training.html',                                         'ios-xcode-swift-programming-courses.html',                       'C173'),
  ('visual-storytelling-with-powerpoint.html',                                'microsoft-powerpoint-training.html',                             'C496'),
  ('pearson-vue-certified-it-specialist-html5-application-development.html',  'html-css-training-courses.html',                                 NULL),
  ('wsq-manufacturing-courses-256.html',                                      'logistics-and-manufacturing-courses.html',                       NULL),
  ('wsq-manufacturing-courses-281.html',                                      'logistics-and-manufacturing-courses.html',                       NULL),
  ('wsq-manufacturing-courses-316.html',                                      'logistics-and-manufacturing-courses.html',                       NULL),
  ('wsq-manufacturing-courses-327.html',                                      'logistics-and-manufacturing-courses.html',                       NULL);

-- 1. Release each slug from its disabled product (status 2 only; never touch a live one).
UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity p ON p.entity_id = v.entity_id
  JOIN tmp_gsc1916 t ON TRIM(p.sku) = t.sku
  JOIN catalog_product_entity_int s ON s.entity_id = p.entity_id AND s.store_id = 0
   AND s.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status')
   SET v.value = CONCAT(SUBSTRING(t.src, 1, CHAR_LENGTH(t.src) - 5), IF(v.attribute_id = @p_up, '-retired.html', '-retired'))
 WHERE @ok AND s.value = 2 AND v.attribute_id IN (@p_uk, @p_up)
   AND v.value IN (SUBSTRING(t.src, 1, CHAR_LENGTH(t.src) - 5), t.src);

-- 2. Replace whatever sits on the dead slug with a manual 301.
DELETE r FROM core_url_rewrite r JOIN tmp_gsc1916 t ON r.request_path = t.src
 WHERE @ok AND r.store_id IN (0, 1) AND r.id_path <> CONCAT('gsc404-', MD5(t.src));

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 0, CONCAT('gsc404-', MD5(t.src)), t.src, t.dst, 0, 'RP' FROM tmp_gsc1916 t
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = t.src AND x.store_id = 0);
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, CONCAT('gsc404-', MD5(t.src)), t.src, t.dst, 0, 'RP' FROM tmp_gsc1916 t
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = t.src AND x.store_id = 1);

-- 3. Flatten legacy RP rows and search redirects that landed on a dead slug.
UPDATE core_url_rewrite r JOIN tmp_gsc1916 t ON r.target_path IN (t.src, CONCAT('https://www.tertiarycourses.com.sg/', t.src))
   SET r.target_path = t.dst, r.product_id = NULL, r.category_id = NULL
 WHERE @ok AND r.store_id IN (0, 1) AND r.options IN ('R', 'RP') AND r.request_path <> t.dst;

UPDATE catalogsearch_query q JOIN tmp_gsc1916 t ON q.redirect = CONCAT('https://www.tertiarycourses.com.sg/', t.src)
   SET q.redirect = CONCAT('https://www.tertiarycourses.com.sg/', t.dst)
 WHERE @ok AND q.store_id = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_gsc1916;

-- 4. Sitemap dead entries: deactivate CMS page `tests` and the empty `feedback` category.
UPDATE cms_page SET is_active = 0
 WHERE @ok AND identifier = 'tests' AND title = 'Our Training Providers';

UPDATE catalog_category_entity_int i
  JOIN catalog_category_entity_varchar k ON k.entity_id = i.entity_id AND k.store_id = 0
   AND k.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key')
   SET i.value = 0
 WHERE @ok AND i.entity_id = 264 AND k.value = 'feedback'
   AND i.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_active')
   AND NOT EXISTS (SELECT 1 FROM catalog_category_product cp WHERE cp.category_id = 264);
