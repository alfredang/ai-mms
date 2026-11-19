-- 1943: Disable the expired WSQ course TGS-2024047021
--       "WSQ - Microsoft Identity and Access Administrator (SC-300)" and 301 its URLs.
--
-- WHY: SkillsFuture support ended 2026-06-24 and the course is not being renewed
-- (admin, 2026-11-19). Since 1922 the availability sync only hid it (visibility 1);
-- the product stayed Enabled and its page still returned 200 with a "funding period
-- has expired" notice. No renewal -> disable it outright.
-- (TGS-2024049184 DevOps Foundation, same request, was already disabled and 301ed
-- by 1871.)
--
-- Target: microsoft-certifications-exams.html, the course's own live Microsoft
-- certification category. There is no live SC-300 successor (C591 is disabled too).
--
-- HOW (the 1869 / 1871 retire pattern):
--   0. status -> 2 (store 0 plus any store override);
--   1. url_key/url_path -> '<slug>-retired' so a catalog_url reindex never takes the
--      slug back;
--   2. the flat slug AND every category-path URL of the product become manual 301s
--      (id_path gsc404-<md5>);
--   3. legacy RP rows that landed on any of those URLs go straight to the target,
--      product_id/category_id NULLed so the reindex keeps them;
--   4. search terms: SC-300 / identity terms -> the category; the "Microsoft Access"
--      (database) terms were a wrong match for this course, so they are cleared and
--      the runtime matcher picks a target.
-- SG only (@mms_instance + store guard) -> no-op on MY/GH. Idempotent.

SET @ok := (@mms_instance = 'SG' AND (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);

SET @key  := 'wsq-microsoft-identity-and-access-administrator-sc-300';
SET @src  := CONCAT(@key, '.html');
SET @dst  := 'microsoft-certifications-exams.html';
SET @pid  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024047021' LIMIT 1);
SET @p_st := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status');
SET @p_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @p_up := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');

-- 0. Disable.
UPDATE catalog_product_entity_int SET value = 2
 WHERE @ok AND entity_id = @pid AND attribute_id = @p_st AND value <> 2;

-- 1. Release the slug from the disabled product.
UPDATE catalog_product_entity_varchar SET value = CONCAT(@key, '-retired')
 WHERE @ok AND entity_id = @pid AND attribute_id = @p_uk AND value = @key;
UPDATE catalog_product_entity_varchar SET value = CONCAT(@key, '-retired.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @p_up AND value = @src;

-- 2. Every URL the product answered on: the flat slug plus its category paths.
DROP TEMPORARY TABLE IF EXISTS tmp_dead1943;
CREATE TEMPORARY TABLE tmp_dead1943 (src VARCHAR(255) PRIMARY KEY) DEFAULT CHARSET=utf8;
INSERT IGNORE INTO tmp_dead1943 (src) SELECT @src FROM DUAL WHERE @ok;
INSERT IGNORE INTO tmp_dead1943 (src)
SELECT r.request_path FROM core_url_rewrite r
 WHERE @ok AND r.product_id = @pid AND r.is_system = 1 AND r.request_path LIKE CONCAT('%/', @src);

DELETE r FROM core_url_rewrite r JOIN tmp_dead1943 t ON r.request_path = t.src
 WHERE @ok AND r.store_id IN (0, 1) AND r.id_path <> CONCAT('gsc404-', MD5(t.src));

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 0, CONCAT('gsc404-', MD5(t.src)), t.src, @dst, 0, 'RP' FROM tmp_dead1943 t
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = t.src AND x.store_id = 0);
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, CONCAT('gsc404-', MD5(t.src)), t.src, @dst, 0, 'RP' FROM tmp_dead1943 t
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = t.src AND x.store_id = 1);

DROP TEMPORARY TABLE IF EXISTS tmp_dead1943;

-- 3. Flatten the legacy aliases that landed on the slug or one of its category paths.
UPDATE core_url_rewrite
   SET target_path = @dst, product_id = NULL, category_id = NULL
 WHERE @ok AND store_id IN (0, 1) AND options IN ('R', 'RP')
   AND (target_path IN (@src, CONCAT('https://www.tertiarycourses.com.sg/', @src))
        OR target_path LIKE CONCAT('%/', @src))
   AND request_path <> @dst;

-- 4. Search terms that pointed at the course.
UPDATE catalogsearch_query
   SET redirect = NULL
 WHERE @ok AND store_id = 1
   AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @src)
   AND query_text NOT LIKE '%identi%' AND query_text NOT LIKE '%SC-300%'
   AND query_text NOT LIKE '%TGS-2024047021%';

UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @dst)
 WHERE @ok AND store_id = 1
   AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @src);
