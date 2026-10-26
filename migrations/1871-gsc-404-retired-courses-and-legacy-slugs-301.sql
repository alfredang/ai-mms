-- 1871: 301 seven retired courses and four legacy slugs that GSC still reports as 404.
--
-- WHY: GSC "Not found (404)" on SG holds 1,914 URLs (validation never started). The
-- 1,000-row export was crawled on 2026-10-26: 888 already 301 to a live page (fixed
-- by 1796/1811/1824/1870), the rest are kids workshops / educational tours / tuition /
-- speed typing (left 404 on purpose, 1796 policy), media/player junk, truncated links
-- (`iot-`, `wsq-agile-`), and the 11 adult slugs below with a live successor.
--   * Seven disabled courses still own their slug (system row -> product view -> 404):
--     C1751, C638, C631, C1152, C1814, C919, TGS-2024049184.
--   * Four slugs have no core_url_rewrite row at all.
-- Targets are the course's own live category (1796 order); every one curl-verified
-- 0 redirects / 200 on prod.
--
-- HOW (the 1869 retire pattern, generalised):
--   1. disabled product url_key/url_path -> '<slug>-retired' so a catalog_url reindex
--      never takes the slug back;
--   2. the row on the dead slug becomes a manual 301 (id_path gsc404-<md5>, store 0+1);
--   3. RP rows and search redirects that pointed at a dead slug go straight to the
--      target (no 2-hop), product_id/category_id NULLed so the reindex keeps them.
-- SG only (@mms_instance + store guard) -> no-op on MY/GH. Idempotent.

SET @ok := (@mms_instance = 'SG' AND (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);
SET @p_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @p_up := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');

DROP TEMPORARY TABLE IF EXISTS tmp_gsc1871;
CREATE TEMPORARY TABLE tmp_gsc1871 (src VARCHAR(255) PRIMARY KEY, dst VARCHAR(255), sku VARCHAR(64)) DEFAULT CHARSET=utf8;
INSERT INTO tmp_gsc1871 (src, dst, sku) VALUES
  ('dp-600-microsoft-certified-fabric-analytics-engineer-associate.html', 'microsoft-fabric-courses.html',                  'C1751'),
  ('fmea-training.html',                                                  'fmea-courses.html',                              'C638'),
  ('neo4j-certified-professional-exam-prep.html',                         'neo4j-certification-exam-prep-courses.html',     'C631'),
  ('network-security-essential-training.html',                            'network-securities-courses.html',                'C1152'),
  ('pearson-vue-certified-it-specialist-cloud-computing.html',            'cloud-computing-courses.html',                   'C1814'),
  ('tableau-certified-data-analyst-exam-prep.html',                       'tableau-certificaitons-exam-prep-courses.html',  'C919'),
  ('wsq-devops-foundation-training.html',                                 'devops-courses.html',                            'TGS-2024049184'),
  ('comptia-practice-exams.html',                                         'comptia-certification-prep-courses.html',        NULL),
  ('comptia-practice-exams-66.html',                                      'comptia-certification-prep-courses.html',        NULL),
  ('data-science-courses-singapore.html',                                 'data-analytics-courses.html',                    NULL),
  ('python-courses-singapore.html',                                       'python-programming.html',                        NULL);

-- 1. Release each slug from its disabled product (status 2 only; never touch a live one).
UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity p ON p.entity_id = v.entity_id
  JOIN tmp_gsc1871 t ON TRIM(p.sku) = t.sku
  JOIN catalog_product_entity_int s ON s.entity_id = p.entity_id AND s.store_id = 0
   AND s.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status')
   SET v.value = CONCAT(SUBSTRING(t.src, 1, CHAR_LENGTH(t.src) - 5), IF(v.attribute_id = @p_up, '-retired.html', '-retired'))
 WHERE @ok AND s.value = 2 AND v.attribute_id IN (@p_uk, @p_up)
   AND v.value IN (SUBSTRING(t.src, 1, CHAR_LENGTH(t.src) - 5), t.src);

-- 2. Replace whatever sits on the dead slug with a manual 301.
DELETE r FROM core_url_rewrite r JOIN tmp_gsc1871 t ON r.request_path = t.src
 WHERE @ok AND r.store_id IN (0, 1) AND r.id_path <> CONCAT('gsc404-', MD5(t.src));

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 0, CONCAT('gsc404-', MD5(t.src)), t.src, t.dst, 0, 'RP' FROM tmp_gsc1871 t
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = t.src AND x.store_id = 0);
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, CONCAT('gsc404-', MD5(t.src)), t.src, t.dst, 0, 'RP' FROM tmp_gsc1871 t
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = t.src AND x.store_id = 1);

-- 3. Flatten legacy RP rows and search redirects that landed on a dead slug.
UPDATE core_url_rewrite r JOIN tmp_gsc1871 t ON r.target_path IN (t.src, CONCAT('https://www.tertiarycourses.com.sg/', t.src))
   SET r.target_path = t.dst, r.product_id = NULL, r.category_id = NULL
 WHERE @ok AND r.store_id IN (0, 1) AND r.options IN ('R', 'RP') AND r.request_path <> t.dst;

UPDATE catalogsearch_query q JOIN tmp_gsc1871 t ON q.redirect = CONCAT('https://www.tertiarycourses.com.sg/', t.src)
   SET q.redirect = CONCAT('https://www.tertiarycourses.com.sg/', t.dst)
 WHERE @ok AND q.store_id = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_gsc1871;
