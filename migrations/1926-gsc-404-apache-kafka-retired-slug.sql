-- 1926: GSC "Not found (404)" sixth pass - retire the disabled Apache Kafka course slug.
--
-- WHY: the 404 bucket export of 2026-11-12 (999 rows, re-crawled the same day):
-- 886 already resolve 200, and of the 113 still 404 almost all are kids workshops,
-- educational tours, tuition, junk *.mp4 / player URLs and truncated paths (left 404
-- on purpose, 1796 policy). The other 42 adult 404s were WSQ courses hidden by the TMS
-- availability sync (visibility 1); that is a code fix in
-- MMD_Courses_Helper_Catalog_Product, not data.
-- The one adult slug left: C990 "Apache Kafka Essential Training" is disabled but still
-- owns apache-kafka-training.html (system row -> product view -> 404). The currency
-- switcher URLs Google crawled also 302 to it.
-- Target: the course's own live category (data-engineering-big-data-courses.html,
-- curl-verified 200 with 0 redirects on prod).
--
-- SG only (@mms_instance + store guard) -> no-op on MY/GH. Idempotent.

SET @ok := (@mms_instance = 'SG' AND (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);
SET @p_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @p_up := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @src := 'apache-kafka-training.html';
SET @dst := 'data-engineering-big-data-courses.html';
SET @idp := CONCAT('gsc404-', MD5(@src));

-- 1. Release the slug from the disabled product (status 2 only; never a live one).
UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity p ON p.entity_id = v.entity_id
  JOIN catalog_product_entity_int s ON s.entity_id = p.entity_id AND s.store_id = 0
   AND s.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status')
   SET v.value = IF(v.attribute_id = @p_up, 'apache-kafka-training-retired.html', 'apache-kafka-training-retired')
 WHERE @ok AND TRIM(p.sku) = 'C990' AND s.value = 2 AND v.attribute_id IN (@p_uk, @p_up)
   AND v.value IN ('apache-kafka-training', 'apache-kafka-training.html');

-- 2. Replace whatever sits on the dead slug with a manual 301.
DELETE FROM core_url_rewrite
 WHERE @ok AND request_path = @src AND store_id IN (0, 1) AND id_path <> @idp;

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 0, @idp, @src, @dst, 0, 'RP' FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = @src AND x.store_id = 0);
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, @idp, @src, @dst, 0, 'RP' FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = @src AND x.store_id = 1);

-- 3. Flatten RP rows and search redirects that land on the dead slug.
UPDATE core_url_rewrite
   SET target_path = @dst, product_id = NULL, category_id = NULL
 WHERE @ok AND store_id IN (0, 1) AND options IN ('R', 'RP') AND request_path <> @dst
   AND target_path IN (@src, CONCAT('https://www.tertiarycourses.com.sg/', @src));

UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @dst)
 WHERE @ok AND store_id = 1 AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @src);
