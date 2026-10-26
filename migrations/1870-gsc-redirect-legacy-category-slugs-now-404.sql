-- 1870: 301 ten legacy category slugs that used to redirect and now 404.
--
-- WHY: crawl (2026-10-26) of the full 1,279-URL GSC "Page with redirect" validation
-- set: 24 URLs that Google last saw redirecting (Nov 2025 - May 2026, before the
-- one-store refactor) now 404 with no core_url_rewrite row at all. They reduce to
-- 16 base slugs; the ?dir=/?SID= variants follow the base 301 (Magento drops the
-- query). Ten have a live successor, mostly the same category without the old
-- "-singapore" / "-in-singapore" suffix; every target curl-verified 0 redirects / 200.
-- Six stay 404 on purpose (no live equivalent; 1796 policy): decorative-gardening-
-- workshops, horticulture-landsacpe-courses, personalisd-training, epub-amazon-kindle-
-- ...-e-publishing, sgtech-star-funded-courses, life-science-courses-training-singapore.
--
-- HOW: manual RP rows (id_path gsc404-<md5>, store 0+1, no product/category tag so a
-- catalog_url reindex keeps them), plus flatten anything that pointed at a dead slug.
-- SG only (@mms_instance + store guard) -> no-op on MY/GH. Idempotent.

SET @ok := (@mms_instance = 'SG' AND (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);

DROP TEMPORARY TABLE IF EXISTS tmp_gsc1870;
CREATE TEMPORARY TABLE tmp_gsc1870 (src VARCHAR(255) PRIMARY KEY, dst VARCHAR(255)) DEFAULT CHARSET=utf8;
INSERT INTO tmp_gsc1870 (src, dst) VALUES
  ('accounting-software-training-singapore.html',                  'accounting-software-training.html'),
  ('cyber-security-digital-forensic-training-courses-singapore.html', 'cyber-security-digital-forensic-training-courses.html'),
  ('digital-media-courses-singapore.html',                         'digital-media-courses.html'),
  ('internet-of-things-iot-training-in-singapore.html',            'internet-of-things-iot-training-in.html'),
  ('iot-robotics-courses-in-singapore.html',                       'iot-robotics-courses-in.html'),
  ('javascript-training-courses-in-singapore.html',                'javascript-training-courses-in.html'),
  ('wordpress-web-deisgn-singapore.html',                          'wordpress-web-deisgn.html'),
  ('infographics.html',                                            'infographics-courses.html'),
  ('it-automation-courses.html',                                   'rpa-api-it-automation-courses.html'),
  ('ibf-sts-infrastructure-architecture-courses.html',             'ibf-sts-funded-courses.html');

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 0, CONCAT('gsc404-', MD5(t.src)), t.src, t.dst, 0, 'RP' FROM tmp_gsc1870 t
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = t.src AND x.store_id = 0);
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, CONCAT('gsc404-', MD5(t.src)), t.src, t.dst, 0, 'RP' FROM tmp_gsc1870 t
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = t.src AND x.store_id = 1);

UPDATE core_url_rewrite r JOIN tmp_gsc1870 t ON r.target_path IN (t.src, CONCAT('https://www.tertiarycourses.com.sg/', t.src))
   SET r.target_path = t.dst
 WHERE @ok AND r.store_id IN (0, 1) AND r.options IN ('R', 'RP') AND r.request_path <> t.dst;

UPDATE catalogsearch_query q JOIN tmp_gsc1870 t ON q.redirect = CONCAT('https://www.tertiarycourses.com.sg/', t.src)
   SET q.redirect = CONCAT('https://www.tertiarycourses.com.sg/', t.dst)
 WHERE @ok AND q.store_id = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_gsc1870;
