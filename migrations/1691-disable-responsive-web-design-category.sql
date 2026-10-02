-- 1691: disable the "Responsive Web Design" category page and 301 it to its
-- only enabled course.
--
-- Requested 2026-10-02: take down
--   97  "Responsive Web Design"  responsive-web-design-training-in.html
--       (parent 4 Web Development)
-- The old URL 301s to WSQ - Build Your Online Presence and Website with Wix
-- for Beginners (TGS-2023018262).
--
-- Checked before writing: the live page lists only that course (C214 / C603 /
-- C858 are already disabled), it has no subcategories, and the course sits in
-- 12 other live categories, so nothing drops off the storefront.
--
-- Same recipe as 1581 / 1591 / 1690 (disable + mmd_retire 301 + chain flatten
-- + category-prefixed course URLs + `-retired` url_key rename so the boot-time
-- flat-URL job never grows a -N suffix ladder).
--
-- Resolved by url_key + name + parent url_key, and the destination by SKU:
-- clean no-op on MY/GH (no TGS- course there). Idempotent.
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

SET @parent := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  WHERE v.value='web-design-courses' LIMIT 1) r);

SET @cat := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value IN ('responsive-web-design-training-in','responsive-web-design-training-in-retired')
    AND TRIM(n.value)='Responsive Web Design' AND e.parent_id=@parent LIMIT 1) r);

SET @course := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023018262' LIMIT 1);

SET @src := 'responsive-web-design-training-in.html';
SET @dst := (SELECT request_path FROM core_url_rewrite
  WHERE id_path = CONCAT('product/', @course) AND store_id = 1 AND is_system = 1 AND options IS NULL LIMIT 1);

SET @ok := (@cat IS NOT NULL AND @dst IS NOT NULL AND @dst <> @src);

-- ------------------------------------------------------- disable + de-menu
-- Every scope row, so a store-level is_active=1 can't keep the page alive.

UPDATE catalog_category_entity_int SET value = 0
 WHERE @ok AND entity_id = @cat AND attribute_id IN (@a_active, @a_menu);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat, 0
  FROM eav_attribute a
 WHERE @ok AND a.attribute_id IN (@a_active, @a_menu)
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_entity_int) x
                   WHERE x.entity_id = @cat AND x.attribute_id = a.attribute_id AND x.store_id = 0);

-- --------------------------------------------------------------- 301 the URL
-- Matches BOTH the id-path target a catalog_url reindex regenerates and an
-- already-corrected row, so re-running after a reindex restores the 301.

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
-- e.g. the old nested adult-training-courses/.../responsive-web-design-training-in.html.

UPDATE core_url_rewrite SET target_path = @dst
 WHERE @ok AND is_system = 0 AND target_path = @src AND request_path <> @src;

-- ------------------------------ category-prefixed course URLs -> flat course URL
-- responsive-web-design-training-in/<course>.html rows: re-point the 301s that
-- target them, then turn each prefixed row itself into a 301 -- to the course's
-- own flat URL when enabled, else @dst.

DROP TEMPORARY TABLE IF EXISTS tmp_rwd_prod;
CREATE TEMPORARY TABLE tmp_rwd_prod (
  url_rewrite_id INT UNSIGNED PRIMARY KEY, store_id SMALLINT UNSIGNED, product_id INT UNSIGNED,
  old_path VARCHAR(255), flat_path VARCHAR(255));
INSERT INTO tmp_rwd_prod
SELECT t.url_rewrite_id, t.store_id, t.product_id, t.request_path,
       IF(st.value_id IS NOT NULL AND p.request_path IS NOT NULL, p.request_path, @dst)
  FROM core_url_rewrite t
  LEFT JOIN core_url_rewrite p ON p.id_path = CONCAT('product/', t.product_id) AND p.store_id = t.store_id AND p.options IS NULL
  LEFT JOIN catalog_product_entity_int st ON st.entity_id = t.product_id AND st.store_id = 0 AND st.value = 1
   AND st.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'status' AND entity_type_id = 4)
 WHERE @ok AND t.category_id = @cat AND t.product_id IS NOT NULL AND t.options IS NULL
   -- old prefix only: a catalog_url reindex regenerates these rows under -retired/
   AND t.request_path LIKE 'responsive-web-design-training-in/%';

UPDATE core_url_rewrite a
  JOIN tmp_rwd_prod m ON m.old_path = a.target_path AND m.store_id = a.store_id
   SET a.target_path = m.flat_path
 WHERE a.options IN ('R','RP') AND a.request_path <> m.flat_path;

UPDATE core_url_rewrite a
  JOIN tmp_rwd_prod m ON m.url_rewrite_id = a.url_rewrite_id
   SET a.target_path = m.flat_path, a.options = 'RP', a.is_system = 0,
       a.category_id = NULL, a.product_id = NULL,
       a.id_path = CONCAT('mmd_retire/', @cat, '/', m.product_id);

DROP TEMPORARY TABLE IF EXISTS tmp_rwd_prod;

-- ------------------------------------------------- search redirects
-- Anything still aimed at the retired page goes to the course directly.

UPDATE catalogsearch_query SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @dst)
 WHERE @ok AND redirect LIKE CONCAT('%/', @src);

-- ------------------------------------------ non-colliding url_key (as 1563)

UPDATE catalog_category_entity_varchar SET value = 'responsive-web-design-training-in-retired'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id = 0
   AND value = 'responsive-web-design-training-in';

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id <> 0;

UPDATE catalog_category_entity_varchar SET value = 'responsive-web-design-training-in-retired.html'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id = 0;

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id <> 0;

-- Rename any canonical system row in place (no save-history rung).
UPDATE core_url_rewrite SET request_path = 'responsive-web-design-training-in-retired.html'
 WHERE @ok AND category_id = @cat AND is_system = 1 AND product_id IS NULL AND options IS NULL
   AND request_path <> 'responsive-web-design-training-in-retired.html'
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = 'responsive-web-design-training-in-retired.html'
                     AND x.store_id = core_url_rewrite.store_id);
