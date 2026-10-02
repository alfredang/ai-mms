-- 1695: disable the "Notion" category page, list its courses under
-- Content Management, and 301 the old URL there.
--
-- Requested 2026-10-02: take down
--   90  "Notion"  notion-courses.html   (parent 17 Content Management)
-- Live page lists: WSQ - Mastering Notion for Content, Project, and
-- Database Management.
-- Content Management (content-management-cms-skillsfuture-courses.html) is an anchor parent, so those
-- courses already appear there by inheritance; this gives them DIRECT rows so
-- they stay after the child is disabled.
--
-- Same retire recipe as 1581 / 1591 / 1690 (disable + mmd_retire 301 + chain
-- flatten + category-prefixed course URLs + `-retired` url_key rename so the
-- boot-time flat-URL job never grows a -N suffix ladder), with the destination
-- being the Content Management category page instead of a course.
--
-- Resolved by url_key + name + parent url_key (partner-safe: same category tree
-- on MY/GH; only ENABLED courses are moved). Idempotent.
--
-- AFTER APPLYING ON PROD: reindex catalog_category_flat, catalog_url,
-- catalog_category_product, then flush caches.

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
  WHERE v.value='content-management-cms-skillsfuture-courses' LIMIT 1) r);

SET @cat := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value IN ('notion-courses','notion-courses-retired')
    AND TRIM(n.value)='Notion' AND e.parent_id=@parent LIMIT 1) r);

SET @tgt := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id=@a_uk AND v.store_id=0 AND v.value='content-management-cms-skillsfuture-courses' LIMIT 1);

SET @src := 'notion-courses.html';
SET @dst := (SELECT request_path FROM core_url_rewrite
  WHERE id_path = CONCAT('category/', @tgt) AND store_id = 1 AND is_system = 1 AND options IS NULL LIMIT 1);

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
-- e.g. the old nested adult-training-courses/.../notion-courses.html.

UPDATE core_url_rewrite SET target_path = @dst
 WHERE @ok AND is_system = 0 AND target_path = @src AND request_path <> @src;

-- ------------------------------ category-prefixed course URLs -> flat course URL
-- notion-courses/<course>.html rows: re-point the 301s that
-- target them, then turn each prefixed row itself into a 301 -- to the course's
-- own flat URL when enabled, else @dst.

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
   -- old prefix only: a catalog_url reindex regenerates these rows under -retired/
   AND t.request_path LIKE 'notion-courses/%';

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
-- Anything still aimed at the retired page goes to the destination category.

UPDATE catalogsearch_query SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @dst)
 WHERE @ok AND redirect LIKE CONCAT('%/', @src);

-- ------------------------------------------ non-colliding url_key (as 1563)

UPDATE catalog_category_entity_varchar SET value = 'notion-courses-retired'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id = 0
   AND value = 'notion-courses';

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id <> 0;

UPDATE catalog_category_entity_varchar SET value = 'notion-courses-retired.html'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id = 0;

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id <> 0;

-- Rename any canonical system row in place (no save-history rung).
UPDATE core_url_rewrite SET request_path = 'notion-courses-retired.html'
 WHERE @ok AND category_id = @cat AND is_system = 1 AND product_id IS NULL AND options IS NULL
   AND request_path <> 'notion-courses-retired.html'
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = 'notion-courses-retired.html'
                     AND x.store_id = core_url_rewrite.store_id);

-- ------------------------------------- list the courses under content-management-cms-skillsfuture-courses
-- content-management-cms-skillsfuture-courses is an anchor category, so today it shows these courses only by
-- inheritance from the child being retired. Give every ENABLED course of the
-- retired child(ren) a DIRECT assignment so it stays listed after the child is
-- disabled and reindexed. Funded TGS- courses go above the C- block
-- (MIN-1), C- courses after it (MAX+1); the nightly CategoryOrdering sweep
-- then settles the C- block alphabetically.

SET @a_status := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status');
SET @a_vis    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'visibility');

DROP TEMPORARY TABLE IF EXISTS tmp_retire_move;
CREATE TEMPORARY TABLE tmp_retire_move (product_id INT UNSIGNED PRIMARY KEY, is_tgs TINYINT, vis SMALLINT);
INSERT IGNORE INTO tmp_retire_move
SELECT cp.product_id, e.sku LIKE 'TGS-%', IFNULL(vi.value, 4)
  FROM catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id
  JOIN catalog_product_entity_int st ON st.entity_id = cp.product_id AND st.store_id = 0
   AND st.attribute_id = @a_status AND st.value = 1
  LEFT JOIN catalog_product_entity_int vi ON vi.entity_id = cp.product_id AND vi.store_id = 0 AND vi.attribute_id = @a_vis
 WHERE @tgt IS NOT NULL AND cp.category_id IN (@cat);

SET @minp := (SELECT IFNULL(MIN(position), 1) FROM catalog_category_product WHERE category_id = @tgt);
SET @maxp := (SELECT IFNULL(MAX(position), 0) FROM catalog_category_product WHERE category_id = @tgt);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @tgt, m.product_id, IF(m.is_tgs, @minp - 1, @maxp + 1) FROM tmp_retire_move m;

DROP TEMPORARY TABLE IF EXISTS tmp_retire_idx;
CREATE TEMPORARY TABLE tmp_retire_idx (store_id SMALLINT UNSIGNED PRIMARY KEY, minp INT, maxp INT);
INSERT INTO tmp_retire_idx
SELECT store_id, MIN(position), MAX(position) FROM catalog_category_product_index
 WHERE category_id = @tgt AND is_parent = 1 GROUP BY store_id;

INSERT INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @tgt, m.product_id, IF(m.is_tgs, x.minp - 1, x.maxp + 1), 1, x.store_id, m.vis
  FROM tmp_retire_move m
  JOIN tmp_retire_idx x
  JOIN core_store s ON s.store_id = x.store_id
  JOIN catalog_product_website pw ON pw.product_id = m.product_id AND pw.website_id = s.website_id
 WHERE m.vis IN (2, 4)
ON DUPLICATE KEY UPDATE is_parent = 1, position = VALUES(position);

DROP TEMPORARY TABLE IF EXISTS tmp_retire_idx;
DROP TEMPORARY TABLE IF EXISTS tmp_retire_move;
