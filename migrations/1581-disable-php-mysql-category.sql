-- 1581: disable the "PHP & MYSQL" category page and 301 it to its parent.
--
-- Requested 2026-09-28: take down
--   34  "PHP & MYSQL"  php-mysql-training-courses.html   (parent 31 "Programming")
-- It is a real indexed landing page, so the old URL 301s to the live parent
-- programming-courses.html instead of dead-ending.
--
-- VERIFIED ON SG PROD BEFORE WRITING: the two courses in it (C024, C1170) each
-- sit in 3+ other categories and both are already DISABLED (status=2), so the
-- page is effectively empty and nothing drops off the storefront. Their
-- category-prefixed URLs (php-mysql-training-courses/<course>.html), and the
-- legacy 301s that pointed at them, now 301 to Programming instead of 404ing.
--
-- Same recipe as 1421 (disable + mmd_retire 301 + chain flatten + clear search
-- redirects) plus 1563's `-retired` url_key rename, so the boot-time flat-URL
-- job never starts a -N suffix 301 ladder on this category
-- (feedback_retired_category_suffix_ladder_grows_every_boot). 1563 has already
-- run, so its derived set would not pick this category up -- done inline here.
--
-- id_path is set explicitly to 'mmd_retire/<id>' on the UPDATE and the INSERT
-- (UNIQUE(id_path,is_system,store_id) -- feedback_category_301_needs_explicit_id_path_unique_key).
--
-- Resolved by url_key + name + parent url_key: identical tree on MY/GH (catalog
-- parity), clean no-op anywhere it differs. Idempotent.
--
-- AFTER APPLYING ON PROD: reindex catalog_category_flat, catalog_url,
-- catalog_category_product, then RE-RUN this file (a catalog_url reindex
-- regenerates a disabled category's rewrite), then flush caches.

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name');
SET @a_uk     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_key');
SET @a_up     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_path');
SET @a_active := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='is_active');
SET @a_menu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='include_in_menu');

-- ---------------------------------------------------------------- resolve ids
-- Matches the original key or the already-renamed `-retired` key, so a re-run
-- after the rename still resolves.

SET @prog := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value='programming-courses' AND TRIM(n.value)='Programming' LIMIT 1) r);

SET @php := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value IN ('php-mysql-training-courses','php-mysql-training-courses-retired')
    AND TRIM(n.value)='PHP & MYSQL' AND e.parent_id=@prog LIMIT 1) r);

SET @src := 'php-mysql-training-courses.html';
SET @dst := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@prog AND attribute_id=@a_uk AND store_id=0 LIMIT 1);

SET @ok := (@php IS NOT NULL AND @prog IS NOT NULL AND @dst IS NOT NULL AND @dst <> @src);

-- ------------------------------------------------------- disable + de-menu
-- Every scope row, so a store-level is_active=1 can't keep the page alive.

UPDATE catalog_category_entity_int SET value = 0
 WHERE @ok AND entity_id = @php AND attribute_id IN (@a_active, @a_menu);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @php, 0
  FROM eav_attribute a
 WHERE @ok AND a.attribute_id IN (@a_active, @a_menu)
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_entity_int) x
                   WHERE x.entity_id = @php AND x.attribute_id = a.attribute_id AND x.store_id = 0);

-- --------------------------------------------------------------- 301 the URL
-- Matches BOTH the id-path target a catalog_url reindex regenerates and an
-- already-corrected row, so re-running after a reindex restores the 301.

UPDATE core_url_rewrite
   SET target_path = @dst, options = 'RP', is_system = 0, category_id = NULL,
       id_path = CONCAT('mmd_retire/', @php)
 WHERE @ok AND request_path = @src
   AND (target_path = CONCAT('catalog/category/view/id/', @php) OR target_path = @dst);

INSERT INTO core_url_rewrite (store_id, category_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, NULL, CONCAT('mmd_retire/', @php), @src, @dst, 0, 'RP' FROM core_store s
 WHERE @ok AND s.store_id > 0
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = @src AND x.store_id = s.store_id);

-- ------------------------------------------------------- flatten 301 chains
-- e.g. the old nested adult-training-courses/.../php-mysql-training-courses.html.

UPDATE core_url_rewrite SET target_path = @dst
 WHERE @ok AND is_system = 0 AND target_path = @src AND request_path <> @src;

-- ------------------------------ category-prefixed course URLs -> flat course URL
-- php-mysql-training-courses/<course>.html system rows move once the url_key is
-- renamed below, and ~20 legacy 301s target them. Re-point those 301s, then
-- turn each prefixed row itself into a 301, to: the course's own flat URL when
-- the course is enabled, else (both are disabled on SG and already 404) the
-- Programming successor -- same rule as 1562
-- (feedback_repurpose_must_flatten_category_prefixed_301_targets).

DROP TEMPORARY TABLE IF EXISTS tmp_php_prod;
CREATE TEMPORARY TABLE tmp_php_prod (
  url_rewrite_id INT UNSIGNED PRIMARY KEY, store_id SMALLINT UNSIGNED, product_id INT UNSIGNED,
  old_path VARCHAR(255), flat_path VARCHAR(255));
INSERT INTO tmp_php_prod
SELECT t.url_rewrite_id, t.store_id, t.product_id, t.request_path,
       IF(st.value_id IS NOT NULL AND p.request_path IS NOT NULL, p.request_path, @dst)
  FROM core_url_rewrite t
  LEFT JOIN core_url_rewrite p ON p.id_path = CONCAT('product/', t.product_id) AND p.store_id = t.store_id AND p.options IS NULL
  LEFT JOIN catalog_product_entity_int st ON st.entity_id = t.product_id AND st.store_id = 0 AND st.value = 1
   AND st.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'status' AND entity_type_id = 4)
 WHERE @ok AND t.category_id = @php AND t.product_id IS NOT NULL AND t.options IS NULL
   -- old prefix only: a catalog_url reindex regenerates these rows under
   -- -retired/, and converting those again collides on mmd_retire/<cat>/<pid>.
   AND t.request_path LIKE 'php-mysql-training-courses/%';

UPDATE core_url_rewrite a
  JOIN tmp_php_prod m ON m.old_path = a.target_path AND m.store_id = a.store_id
   SET a.target_path = m.flat_path
 WHERE a.options IN ('R','RP') AND a.request_path <> m.flat_path;

UPDATE core_url_rewrite a
  JOIN tmp_php_prod m ON m.url_rewrite_id = a.url_rewrite_id
   SET a.target_path = m.flat_path, a.options = 'RP', a.is_system = 0,
       a.category_id = NULL, a.product_id = NULL,
       a.id_path = CONCAT('mmd_retire/', @php, '/', m.product_id);

DROP TEMPORARY TABLE IF EXISTS tmp_php_prod;

-- ------------------------------------------------- clear dead search redirects
-- "Php" / "php wsq" pointed at this page; blank them so search lists the live
-- PHP courses instead of redirecting into a redirect.

UPDATE catalogsearch_query SET redirect = ''
 WHERE @ok AND redirect LIKE CONCAT('%/', @src);

-- ------------------------------------------ non-colliding url_key (as 1563)

UPDATE catalog_category_entity_varchar SET value = 'php-mysql-training-courses-retired'
 WHERE @ok AND entity_id = @php AND attribute_id = @a_uk AND store_id = 0
   AND value = 'php-mysql-training-courses';

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @php AND attribute_id = @a_uk AND store_id <> 0;

UPDATE catalog_category_entity_varchar SET value = 'php-mysql-training-courses-retired.html'
 WHERE @ok AND entity_id = @php AND attribute_id = @a_up AND store_id = 0;

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @php AND attribute_id = @a_up AND store_id <> 0;

-- Rename any canonical system row in place (no save-history rung).
UPDATE core_url_rewrite SET request_path = 'php-mysql-training-courses-retired.html'
 WHERE @ok AND category_id = @php AND is_system = 1 AND product_id IS NULL AND options IS NULL
   AND request_path <> 'php-mysql-training-courses-retired.html'
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = 'php-mysql-training-courses-retired.html'
                     AND x.store_id = core_url_rewrite.store_id);
