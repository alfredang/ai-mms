-- 1761: move C1756 out of "Microsoft Dynamics Certification" and retire that
-- category page, 301-ing its URL to the parent "Microsoft Certification Exam
-- Prep" (instructor-led-microsoft-exam-prep.html).
--
-- Requested 2026-10-04. After 1754 the page listed only AB-100 (C1756) and
-- WSQ MB-910 (TGS-2023040481); every MB-xxx non-WSQ course is disabled. Both
-- enabled courses already have DIRECT rows in the parent, so they stay listed
-- there. Course status / visibility are untouched.
--
-- Same retire recipe as 1694 (disable + mmd_retire 301 + chain flatten +
-- category-prefixed course URLs -> flat course URL + `-retired` url_key so the
-- boot-time flat-URL job never grows a -N ladder). Search terms aimed at the
-- page ("dynamics", "dynamics 365", ...) go to the MB-910 course page instead.
--
-- Resolved by url_key + name + parent url_key; no-op where absent. Idempotent.
-- AFTER APPLYING ON PROD: reindex catalog_category_flat, then flush
-- block_html / full_page / collections.

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name');
SET @a_uk     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_key');
SET @a_up     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_path');
SET @a_active := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='is_active');
SET @a_menu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='include_in_menu');

-- ---------------------------------------------------------------- resolve ids

SET @parent := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  WHERE v.value='instructor-led-microsoft-exam-prep' LIMIT 1) r);

SET @cat := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value IN ('microsoft-dynamics-certification-courses','microsoft-dynamics-certification-courses-retired')
    AND TRIM(n.value)='Microsoft Dynamics Certification' AND e.parent_id=@parent LIMIT 1) r);

SET @src := 'microsoft-dynamics-certification-courses.html';
SET @dst := (SELECT request_path FROM core_url_rewrite
  WHERE id_path = CONCAT('category/', @parent) AND store_id = 1 AND is_system = 1 AND options IS NULL LIMIT 1);

SET @ok := (@cat IS NOT NULL AND @dst IS NOT NULL AND @dst <> @src);

-- ------------------------------------------------- C1756 out of the category

DELETE cp FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
 WHERE @ok AND cp.category_id = @cat AND TRIM(p.sku) = 'C1756';

DELETE i FROM catalog_category_product_index i
  JOIN catalog_product_entity p ON p.entity_id = i.product_id
 WHERE @ok AND i.category_id = @cat AND TRIM(p.sku) = 'C1756';

-- ------------------------------------------------------- disable + de-menu

UPDATE catalog_category_entity_int SET value = 0
 WHERE @ok AND entity_id = @cat AND attribute_id IN (@a_active, @a_menu);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat, 0
  FROM eav_attribute a
 WHERE @ok AND a.attribute_id IN (@a_active, @a_menu)
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_entity_int) x
                   WHERE x.entity_id = @cat AND x.attribute_id = a.attribute_id AND x.store_id = 0);

-- --------------------------------------------------------------- 301 the URL

UPDATE core_url_rewrite
   SET target_path = @dst, options = 'RP', is_system = 0, category_id = NULL,
       id_path = CONCAT('mmd_retire/', @cat)
 WHERE @ok AND request_path = @src
   AND (target_path = CONCAT('catalog/category/view/id/', @cat) OR target_path = @dst);

INSERT INTO core_url_rewrite (store_id, category_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, NULL, CONCAT('mmd_retire/', @cat), @src, @dst, 0, 'RP' FROM core_store s
 WHERE @ok AND s.store_id > 0
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = @src AND x.store_id = s.store_id);

-- ------------------------------------------------------- flatten 301 chains

UPDATE core_url_rewrite SET target_path = @dst
 WHERE @ok AND is_system = 0 AND target_path = @src AND request_path <> @src;

-- ------------------------------ category-prefixed course URLs -> flat course URL

DROP TEMPORARY TABLE IF EXISTS tmp_retire_prod;
CREATE TEMPORARY TABLE tmp_retire_prod (
  url_rewrite_id INT UNSIGNED PRIMARY KEY, store_id SMALLINT UNSIGNED, product_id INT UNSIGNED,
  old_path VARCHAR(255), flat_path VARCHAR(255));
INSERT INTO tmp_retire_prod
SELECT t.url_rewrite_id, t.store_id, t.product_id, t.request_path,
       IF(st.value_id IS NOT NULL AND p.request_path IS NOT NULL, p.request_path, @dst)
  FROM core_url_rewrite t
  LEFT JOIN core_url_rewrite p ON p.id_path = CONCAT('product/', t.product_id) AND p.store_id = t.store_id AND p.options IS NULL
  LEFT JOIN catalog_product_entity_int st ON st.entity_id = t.product_id AND st.store_id = 0 AND st.value = 1
   AND st.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'status' AND entity_type_id = 4)
 WHERE @ok AND t.category_id = @cat AND t.product_id IS NOT NULL AND t.options IS NULL
   AND t.request_path LIKE 'microsoft-dynamics-certification-courses/%';

UPDATE core_url_rewrite a
  JOIN tmp_retire_prod m ON m.old_path = a.target_path AND m.store_id = a.store_id
   SET a.target_path = m.flat_path
 WHERE a.options IN ('R','RP') AND a.request_path <> m.flat_path;

UPDATE core_url_rewrite a
  JOIN tmp_retire_prod m ON m.url_rewrite_id = a.url_rewrite_id
   SET a.target_path = m.flat_path, a.options = 'RP', a.is_system = 0,
       a.category_id = NULL, a.product_id = NULL,
       a.id_path = CONCAT('mmd_retire/', @cat, '/', m.product_id);

DROP TEMPORARY TABLE IF EXISTS tmp_retire_prod;

-- ------------------------------------------------- search redirects
-- Point at the MB-910 course page when it is live, else the parent category.

SET @mb910 := (SELECT r.request_path FROM core_url_rewrite r
  JOIN catalog_product_entity p ON p.entity_id = r.product_id AND TRIM(p.sku) = 'TGS-2023040481'
  JOIN catalog_product_entity_int st ON st.entity_id = p.entity_id AND st.store_id = 0 AND st.value = 1
   AND st.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'status' AND entity_type_id = 4)
 WHERE r.id_path = CONCAT('product/', p.entity_id) AND r.store_id = 1 AND r.options IS NULL LIMIT 1);

UPDATE catalogsearch_query SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', IFNULL(@mb910, @dst))
 WHERE @ok AND redirect LIKE CONCAT('%/', @src);

-- ------------------------------------------ non-colliding url_key (as 1563)

UPDATE catalog_category_entity_varchar SET value = 'microsoft-dynamics-certification-courses-retired'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id = 0
   AND value = 'microsoft-dynamics-certification-courses';

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id <> 0;

UPDATE catalog_category_entity_varchar SET value = 'microsoft-dynamics-certification-courses-retired.html'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id = 0;

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id <> 0;

UPDATE core_url_rewrite SET request_path = 'microsoft-dynamics-certification-courses-retired.html'
 WHERE @ok AND category_id = @cat AND is_system = 1 AND product_id IS NULL AND options IS NULL
   AND request_path <> 'microsoft-dynamics-certification-courses-retired.html'
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = 'microsoft-dynamics-certification-courses-retired.html'
                     AND x.store_id = core_url_rewrite.store_id);

