-- 1811: second pass on the GSC "Not found (404)" bucket for www.tertiarycourses.com.sg.
--
-- WHY: GSC reported validation of 'Not found (404)' FAILED on 2026-10-12 (1,906 URLs,
-- data as of 2026-10-09). The 1,000-row export was re-crawled on prod on 2026-10-12:
-- 857 already 301 -> 200 thanks to 1796 (Google validated before that deploy took
-- effect). The remainder that still deserve a live page are below: courses retired
-- after 1796 shipped (C1000 DP-203, C1231 FastMCP, C178 Job Redesign), system rewrites
-- left on two deleted products (ids 1533 MD-100, 1553 AI-102), inactive category 321
-- (specialisation-courses), and old slugs with no DB trace. Targets prefer a successor
-- exam (DP-203 -> DP-700, MD-100 -> MD-102), then the retired course's own category.
-- Every target was curl-verified '0 200' on prod before shipping.
-- ai-vibe-coding-for-cpp.html already 301'd to job-redesign (now dead), so it is
-- re-pointed at the Vibe Coding series instead of being flattened to AI-for-HR.
-- Still 404 on purpose (no equivalent page): kids workshops, educational tours,
-- tuition, escape rooms, speed typing, the retired Tertiary Courses GPT page, and
-- junk inbound links (/assets/video/*.mp4, /player?id=..., truncated slugs).
--
-- HOW: same mechanism as 1796 (retire url_key -> '<slug>-retired', replace the row
-- on the slug with a manual RP 301, flatten inbound redirects + search terms).
-- SG only (@mms_instance + store guard) -> no-op on MY/GH. Idempotent.

SET @ok := (@mms_instance = 'SG' AND (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);

DROP TEMPORARY TABLE IF EXISTS tmp_gsc404;
CREATE TEMPORARY TABLE tmp_gsc404 (
  src VARCHAR(255) NOT NULL PRIMARY KEY,
  dst VARCHAR(255) NOT NULL,
  k   VARCHAR(255) NOT NULL DEFAULT ''
) DEFAULT CHARSET=utf8;

INSERT INTO tmp_gsc404 (src, dst) VALUES
('dp-203-microsoft-certified-azure-data-engineer-associate-exam-prep.html','dp-700-microsoft-certified-fabric-data-engineer-associate-exam-prep.html'),
('md-100-windows-client-certification-practice-test.html','wsq-microsoft-certified-endpoint-administrator-associate-md-102.html'),
('ai-102-designing-and-implementing-an-azure-ai-solution-microsoft-certification-practice-test.html','microsoft-certifications-exams.html'),
('build-mcp-tools-with-fastmcp-and-vibe-coding.html','ai-vibe-coding-series.html'),
('ai-vibe-coding-for-cpp.html','ai-vibe-coding-series.html'),
('job-redesign-for-managing-ai-agents.html','ai-for-hr-courses.html'),
('specialisation-courses.html','computer-programming-and-infocomm-courses.html'),
('business-analysis-courses-singapore.html','wsq-business-courses.html'),
('business-analysis-courses-in-singapore.html','wsq-business-courses.html'),
('comptia-practice-exams-44.html','comptia-certification-prep-courses.html'),
('comptia-practice-exams-45.html','comptia-certification-prep-courses.html'),
('comptia-practice-exams-46.html','comptia-certification-prep-courses.html'),
('comptia-practice-exams-47.html','comptia-certification-prep-courses.html'),
('comptia-practice-exams-48.html','comptia-certification-prep-courses.html'),
('comptia-practice-exams-50.html','comptia-certification-prep-courses.html'),
('wsq-manufacturing-courses-229.html','logistics-and-manufacturing-courses.html'),
('PSG-SFTS.html','wsq-funded-courses.html'),
('arduino-complete-in.html','arduino-courses-in.html'),
('organic-farming.html','wsq-agriculture-courses.html');

UPDATE tmp_gsc404 SET k = LEFT(src, CHAR_LENGTH(src) - 5) WHERE src LIKE '%.html' AND src NOT LIKE '%/%';
DELETE FROM tmp_gsc404 WHERE @ok IS NULL OR @ok <> 1;

SET @pet := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @cet := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category');
SET @p_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @pet AND attribute_code = 'url_key');
SET @p_up := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @pet AND attribute_code = 'url_path');
SET @p_st := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @pet AND attribute_code = 'status');
SET @c_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @cet AND attribute_code = 'url_key');
SET @c_up := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @cet AND attribute_code = 'url_path');
SET @c_ac := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @cet AND attribute_code = 'is_active');

-- 1a. Disabled products (effective SG status = 2) that still own a dead slug.
DROP TEMPORARY TABLE IF EXISTS tmp_gsc404_p;
CREATE TEMPORARY TABLE tmp_gsc404_p (entity_id INT UNSIGNED PRIMARY KEY, k VARCHAR(255)) DEFAULT CHARSET=utf8;
INSERT IGNORE INTO tmp_gsc404_p (entity_id, k)
SELECT v.entity_id, t.k
  FROM tmp_gsc404 t
  JOIN catalog_product_entity_varchar v ON v.attribute_id = @p_uk AND v.value = t.k
 WHERE t.k <> ''
   AND COALESCE((SELECT s.value FROM catalog_product_entity_int s WHERE s.entity_id = v.entity_id AND s.attribute_id = @p_st AND s.store_id = 1),
                (SELECT s.value FROM catalog_product_entity_int s WHERE s.entity_id = v.entity_id AND s.attribute_id = @p_st AND s.store_id = 0)) = 2
   AND NOT EXISTS (SELECT 1 FROM catalog_product_entity_varchar x WHERE x.attribute_id = @p_uk AND x.value = CONCAT(t.k, '-retired'));

UPDATE catalog_product_entity_varchar v JOIN tmp_gsc404_p p ON p.entity_id = v.entity_id
   SET v.value = CONCAT(p.k, '-retired')
 WHERE v.attribute_id = @p_uk AND v.value = p.k;
UPDATE catalog_product_entity_varchar v JOIN tmp_gsc404_p p ON p.entity_id = v.entity_id
   SET v.value = CONCAT(p.k, '-retired.html')
 WHERE v.attribute_id = @p_up AND v.value = CONCAT(p.k, '.html');

-- 1b. Inactive categories (effective SG is_active = 0) that still own a dead slug.
DROP TEMPORARY TABLE IF EXISTS tmp_gsc404_c;
CREATE TEMPORARY TABLE tmp_gsc404_c (entity_id INT UNSIGNED PRIMARY KEY, k VARCHAR(255)) DEFAULT CHARSET=utf8;
INSERT IGNORE INTO tmp_gsc404_c (entity_id, k)
SELECT v.entity_id, t.k
  FROM tmp_gsc404 t
  JOIN catalog_category_entity_varchar v ON v.attribute_id = @c_uk AND v.value = t.k
 WHERE t.k <> ''
   AND COALESCE((SELECT a.value FROM catalog_category_entity_int a WHERE a.entity_id = v.entity_id AND a.attribute_id = @c_ac AND a.store_id = 1),
                (SELECT a.value FROM catalog_category_entity_int a WHERE a.entity_id = v.entity_id AND a.attribute_id = @c_ac AND a.store_id = 0)) = 0
   AND NOT EXISTS (SELECT 1 FROM catalog_category_entity_varchar x WHERE x.attribute_id = @c_uk AND x.value = CONCAT(t.k, '-retired'));

UPDATE catalog_category_entity_varchar v JOIN tmp_gsc404_c c ON c.entity_id = v.entity_id
   SET v.value = CONCAT(c.k, '-retired')
 WHERE v.attribute_id = @c_uk AND v.value = c.k;
UPDATE catalog_category_entity_varchar v JOIN tmp_gsc404_c c ON c.entity_id = v.entity_id
   SET v.value = CONCAT(c.k, '-retired.html')
 WHERE v.attribute_id = @c_up AND v.value = CONCAT(c.k, '.html');

-- 2. Replace whatever row sits on each dead slug with a manual 301.
DELETE r FROM core_url_rewrite r JOIN tmp_gsc404 t ON t.src = r.request_path
 WHERE r.store_id IN (0, 1) AND r.id_path NOT LIKE 'gsc404-%';

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 0, CONCAT('gsc404-', MD5(t.src)), t.src, t.dst, 0, 'RP' FROM tmp_gsc404 t
 WHERE NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = t.src AND x.store_id = 0);
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, CONCAT('gsc404-', MD5(t.src)), t.src, t.dst, 0, 'RP' FROM tmp_gsc404 t
 WHERE NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = t.src AND x.store_id = 1);

UPDATE core_url_rewrite r JOIN tmp_gsc404 t ON t.src = r.request_path
   SET r.target_path = t.dst, r.options = 'RP'
 WHERE r.store_id IN (0, 1) AND r.id_path LIKE 'gsc404-%' AND r.target_path <> t.dst;

-- 3. Flatten chains: redirects and search terms that pointed at a dead slug.
UPDATE core_url_rewrite r JOIN tmp_gsc404 t ON r.target_path IN (t.src, CONCAT('https://www.tertiarycourses.com.sg/', t.src))
   SET r.target_path = t.dst
 WHERE r.store_id IN (0, 1) AND r.options IN ('R', 'RP') AND r.request_path <> t.dst;

UPDATE catalogsearch_query q JOIN tmp_gsc404 t ON q.redirect = CONCAT('https://www.tertiarycourses.com.sg/', t.src)
   SET q.redirect = CONCAT('https://www.tertiarycourses.com.sg/', t.dst)
 WHERE q.store_id = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_gsc404_p;
DROP TEMPORARY TABLE IF EXISTS tmp_gsc404_c;
DROP TEMPORARY TABLE IF EXISTS tmp_gsc404;
