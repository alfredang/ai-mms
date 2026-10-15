-- 1825: two leftovers from the 1824 recrawl (2026-10-16). Both are old RP aliases whose
-- target was later retired, so they 301 -> 404: advanced-r-data-analysis-training ->
-- (repurposed) develop-child-creativity-with-generative-ai, and the Python CertPrep -1796
-- alias -> -1816. Re-point them at the live topic category. Same mechanism as 1824;
-- targets curl-verified '0 200'. SG only, idempotent.

SET @ok := (@mms_instance = 'SG' AND (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);

DROP TEMPORARY TABLE IF EXISTS tmp_gsc404;
CREATE TEMPORARY TABLE tmp_gsc404 (
  src VARCHAR(255) NOT NULL PRIMARY KEY,
  dst VARCHAR(255) NOT NULL,
  k   VARCHAR(255) NOT NULL DEFAULT ''
) DEFAULT CHARSET=utf8;

INSERT INTO tmp_gsc404 (src, dst) VALUES
('advanced-r-data-analysis-training.html','r-programming-courses-in.html'),
('certprep-courseware-it-specialist-python-self-paced-1796.html','python-programming.html'),
('certprep-courseware-it-specialist-python-self-paced-1816.html','python-programming.html');

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
