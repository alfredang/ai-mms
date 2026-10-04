-- 1765: Microsoft Certification Exam Prep (microsoft-certifications-exams.html)
-- becomes a single flat page. Requested 2026-10-04:
--   1. DP-100 (TGS-2023036642) and DP-700 (TGS-2024042602) out of Power
--      Platform Certification (DP-300 already removed by 1747).
--   2. Deactivate every sub-page under it:
--        Azure Certification              azure-certification-exam-prep
--        Power Platform Certification     microsoft-power-platform-certification-courses
--        Microsoft 365 Certification      microsoft-365-certification
--        Microsoft Certification Exam Prep (inner) instructor-led-microsoft-exam-prep
--        Github Certification Prep        github-certification-prep-courses
--      (Microsoft Dynamics Certification was already retired by 1761; its 301
--      pointed at the inner page and is re-pointed here by the chain flatten.)
--   3. Every Microsoft certification course listed directly on the top page.
--      On SG all enabled courses of the sub-pages ALREADY have direct rows on
--      it (verified on prod 2026-10-04); the move block is the safety net that
--      keeps them listed after the children are disabled and reindexed.
--
-- Per sub-page: the 1694/1761 retire recipe (direct parent rows + disable +
-- de-menu + mmd_retire 301 + chain flatten + category-prefixed course URLs ->
-- flat course URL + search redirects + `-retired` url_key). Grandchildren are
-- retired before the inner page so every 301 lands on the top page directly.
-- Course status / visibility are untouched.
--
-- Same category tree on SG/MY/GH (catalog parity): resolved by url_key + name +
-- parent url_key, no-op where absent. Idempotent.
-- AFTER APPLYING ON PROD: reindex catalog_category_flat, then flush
-- block_html / full_page / collections.

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name');
SET @a_uk     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_key');
SET @a_up     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_path');
SET @a_active := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='is_active');
SET @a_menu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='include_in_menu');
SET @a_status := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='status');
SET @a_vis    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='visibility');

-- Top page = the destination of everything below.
SET @tgt := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id=@a_uk AND v.store_id=0 AND v.value='microsoft-certifications-exams' LIMIT 1);
SET @dst := (SELECT request_path FROM core_url_rewrite
  WHERE id_path = CONCAT('category/', @tgt) AND store_id = 1 AND is_system = 1 AND options IS NULL LIMIT 1);

-- ------------------------------------- 1. DP-100 / DP-700 out of Power Platform

SET @pp := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id=@a_uk AND v.store_id=0
    AND v.value IN ('microsoft-power-platform-certification-courses','microsoft-power-platform-certification-courses-retired') LIMIT 1);

DELETE cp FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
 WHERE cp.category_id = @pp AND @pp IS NOT NULL AND TRIM(p.sku) IN ('TGS-2023036642','TGS-2024042602');

DELETE i FROM catalog_category_product_index i
  JOIN catalog_product_entity p ON p.entity_id = i.product_id
 WHERE i.category_id = @pp AND @pp IS NOT NULL AND TRIM(p.sku) IN ('TGS-2023036642','TGS-2024042602');

-- ============================================================ retire: Azure Certification (azure-certification-exam-prep)

SET @parent := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  WHERE v.value IN ('instructor-led-microsoft-exam-prep','instructor-led-microsoft-exam-prep-retired') LIMIT 1) r);

SET @cat := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value IN ('azure-certification-exam-prep','azure-certification-exam-prep-retired')
    AND TRIM(n.value)='Azure Certification' AND e.parent_id=@parent LIMIT 1) r);

SET @src := 'azure-certification-exam-prep.html';
SET @ok := (@cat IS NOT NULL AND @tgt IS NOT NULL AND @dst IS NOT NULL AND @dst <> @src);

-- Every ENABLED course of the page keeps a DIRECT row on the top page (TGS- above
-- the C- block at MIN-1, others at MAX+1; the nightly sweep settles the order).
DROP TEMPORARY TABLE IF EXISTS tmp_retire_move;
CREATE TEMPORARY TABLE tmp_retire_move (product_id INT UNSIGNED PRIMARY KEY, is_tgs TINYINT, vis SMALLINT);
INSERT IGNORE INTO tmp_retire_move
SELECT cp.product_id, TRIM(e.sku) LIKE 'TGS-%', IFNULL(vi.value, 4)
  FROM catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id
  JOIN catalog_product_entity_int st ON st.entity_id = cp.product_id AND st.store_id = 0
   AND st.attribute_id = @a_status AND st.value = 1
  LEFT JOIN catalog_product_entity_int vi ON vi.entity_id = cp.product_id AND vi.store_id = 0 AND vi.attribute_id = @a_vis
 WHERE @ok AND cp.category_id = @cat;

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
ON DUPLICATE KEY UPDATE is_parent = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_retire_idx;
DROP TEMPORARY TABLE IF EXISTS tmp_retire_move;

-- Disable + de-menu (every scope row, so a store-level is_active=1 can't revive it).
UPDATE catalog_category_entity_int SET value = 0
 WHERE @ok AND entity_id = @cat AND attribute_id IN (@a_active, @a_menu);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat, 0
  FROM eav_attribute a
 WHERE @ok AND a.attribute_id IN (@a_active, @a_menu)
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_entity_int) x
                   WHERE x.entity_id = @cat AND x.attribute_id = a.attribute_id AND x.store_id = 0);

-- 301 the page URL to the top page (matches the reindex-regenerated id-path
-- target AND an already-corrected row, so a re-run restores the 301).
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

-- Flatten 301 chains that ended at this page (incl. 1761's Dynamics 301).
UPDATE core_url_rewrite SET target_path = @dst
 WHERE @ok AND is_system = 0 AND target_path = @src AND request_path <> @src;

-- Category-prefixed course URLs (azure-certification-exam-prep/<course>.html) -> the course's flat URL
-- when enabled, else the top page.
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
   AND st.attribute_id = @a_status
 WHERE @ok AND t.category_id = @cat AND t.product_id IS NOT NULL AND t.options IS NULL
   AND t.request_path LIKE 'azure-certification-exam-prep/%';

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

-- Search terms aimed at the page go to the top page.
UPDATE catalogsearch_query SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @dst)
 WHERE @ok AND redirect LIKE CONCAT('%/', @src);

-- Non-colliding url_key (as 1563) so the boot-time flat-URL job never grows a -N ladder.
UPDATE catalog_category_entity_varchar SET value = 'azure-certification-exam-prep-retired'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id = 0 AND value = 'azure-certification-exam-prep';

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id <> 0;

UPDATE catalog_category_entity_varchar SET value = 'azure-certification-exam-prep-retired.html'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id = 0;

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id <> 0;

UPDATE core_url_rewrite SET request_path = 'azure-certification-exam-prep-retired.html'
 WHERE @ok AND category_id = @cat AND is_system = 1 AND product_id IS NULL AND options IS NULL
   AND request_path <> 'azure-certification-exam-prep-retired.html'
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = 'azure-certification-exam-prep-retired.html'
                     AND x.store_id = core_url_rewrite.store_id);

-- ============================================================ retire: Power Platform Certification (microsoft-power-platform-certification-courses)

SET @parent := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  WHERE v.value IN ('instructor-led-microsoft-exam-prep','instructor-led-microsoft-exam-prep-retired') LIMIT 1) r);

SET @cat := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value IN ('microsoft-power-platform-certification-courses','microsoft-power-platform-certification-courses-retired')
    AND TRIM(n.value)='Power Platform Certification' AND e.parent_id=@parent LIMIT 1) r);

SET @src := 'microsoft-power-platform-certification-courses.html';
SET @ok := (@cat IS NOT NULL AND @tgt IS NOT NULL AND @dst IS NOT NULL AND @dst <> @src);

-- Every ENABLED course of the page keeps a DIRECT row on the top page (TGS- above
-- the C- block at MIN-1, others at MAX+1; the nightly sweep settles the order).
DROP TEMPORARY TABLE IF EXISTS tmp_retire_move;
CREATE TEMPORARY TABLE tmp_retire_move (product_id INT UNSIGNED PRIMARY KEY, is_tgs TINYINT, vis SMALLINT);
INSERT IGNORE INTO tmp_retire_move
SELECT cp.product_id, TRIM(e.sku) LIKE 'TGS-%', IFNULL(vi.value, 4)
  FROM catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id
  JOIN catalog_product_entity_int st ON st.entity_id = cp.product_id AND st.store_id = 0
   AND st.attribute_id = @a_status AND st.value = 1
  LEFT JOIN catalog_product_entity_int vi ON vi.entity_id = cp.product_id AND vi.store_id = 0 AND vi.attribute_id = @a_vis
 WHERE @ok AND cp.category_id = @cat;

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
ON DUPLICATE KEY UPDATE is_parent = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_retire_idx;
DROP TEMPORARY TABLE IF EXISTS tmp_retire_move;

-- Disable + de-menu (every scope row, so a store-level is_active=1 can't revive it).
UPDATE catalog_category_entity_int SET value = 0
 WHERE @ok AND entity_id = @cat AND attribute_id IN (@a_active, @a_menu);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat, 0
  FROM eav_attribute a
 WHERE @ok AND a.attribute_id IN (@a_active, @a_menu)
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_entity_int) x
                   WHERE x.entity_id = @cat AND x.attribute_id = a.attribute_id AND x.store_id = 0);

-- 301 the page URL to the top page (matches the reindex-regenerated id-path
-- target AND an already-corrected row, so a re-run restores the 301).
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

-- Flatten 301 chains that ended at this page (incl. 1761's Dynamics 301).
UPDATE core_url_rewrite SET target_path = @dst
 WHERE @ok AND is_system = 0 AND target_path = @src AND request_path <> @src;

-- Category-prefixed course URLs (microsoft-power-platform-certification-courses/<course>.html) -> the course's flat URL
-- when enabled, else the top page.
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
   AND st.attribute_id = @a_status
 WHERE @ok AND t.category_id = @cat AND t.product_id IS NOT NULL AND t.options IS NULL
   AND t.request_path LIKE 'microsoft-power-platform-certification-courses/%';

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

-- Search terms aimed at the page go to the top page.
UPDATE catalogsearch_query SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @dst)
 WHERE @ok AND redirect LIKE CONCAT('%/', @src);

-- Non-colliding url_key (as 1563) so the boot-time flat-URL job never grows a -N ladder.
UPDATE catalog_category_entity_varchar SET value = 'microsoft-power-platform-certification-courses-retired'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id = 0 AND value = 'microsoft-power-platform-certification-courses';

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id <> 0;

UPDATE catalog_category_entity_varchar SET value = 'microsoft-power-platform-certification-courses-retired.html'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id = 0;

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id <> 0;

UPDATE core_url_rewrite SET request_path = 'microsoft-power-platform-certification-courses-retired.html'
 WHERE @ok AND category_id = @cat AND is_system = 1 AND product_id IS NULL AND options IS NULL
   AND request_path <> 'microsoft-power-platform-certification-courses-retired.html'
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = 'microsoft-power-platform-certification-courses-retired.html'
                     AND x.store_id = core_url_rewrite.store_id);

-- ============================================================ retire: Microsoft 365 Certification (microsoft-365-certification)

SET @parent := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  WHERE v.value IN ('instructor-led-microsoft-exam-prep','instructor-led-microsoft-exam-prep-retired') LIMIT 1) r);

SET @cat := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value IN ('microsoft-365-certification','microsoft-365-certification-retired')
    AND TRIM(n.value)='Microsoft 365 Certification' AND e.parent_id=@parent LIMIT 1) r);

SET @src := 'microsoft-365-certification.html';
SET @ok := (@cat IS NOT NULL AND @tgt IS NOT NULL AND @dst IS NOT NULL AND @dst <> @src);

-- Every ENABLED course of the page keeps a DIRECT row on the top page (TGS- above
-- the C- block at MIN-1, others at MAX+1; the nightly sweep settles the order).
DROP TEMPORARY TABLE IF EXISTS tmp_retire_move;
CREATE TEMPORARY TABLE tmp_retire_move (product_id INT UNSIGNED PRIMARY KEY, is_tgs TINYINT, vis SMALLINT);
INSERT IGNORE INTO tmp_retire_move
SELECT cp.product_id, TRIM(e.sku) LIKE 'TGS-%', IFNULL(vi.value, 4)
  FROM catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id
  JOIN catalog_product_entity_int st ON st.entity_id = cp.product_id AND st.store_id = 0
   AND st.attribute_id = @a_status AND st.value = 1
  LEFT JOIN catalog_product_entity_int vi ON vi.entity_id = cp.product_id AND vi.store_id = 0 AND vi.attribute_id = @a_vis
 WHERE @ok AND cp.category_id = @cat;

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
ON DUPLICATE KEY UPDATE is_parent = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_retire_idx;
DROP TEMPORARY TABLE IF EXISTS tmp_retire_move;

-- Disable + de-menu (every scope row, so a store-level is_active=1 can't revive it).
UPDATE catalog_category_entity_int SET value = 0
 WHERE @ok AND entity_id = @cat AND attribute_id IN (@a_active, @a_menu);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat, 0
  FROM eav_attribute a
 WHERE @ok AND a.attribute_id IN (@a_active, @a_menu)
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_entity_int) x
                   WHERE x.entity_id = @cat AND x.attribute_id = a.attribute_id AND x.store_id = 0);

-- 301 the page URL to the top page (matches the reindex-regenerated id-path
-- target AND an already-corrected row, so a re-run restores the 301).
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

-- Flatten 301 chains that ended at this page (incl. 1761's Dynamics 301).
UPDATE core_url_rewrite SET target_path = @dst
 WHERE @ok AND is_system = 0 AND target_path = @src AND request_path <> @src;

-- Category-prefixed course URLs (microsoft-365-certification/<course>.html) -> the course's flat URL
-- when enabled, else the top page.
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
   AND st.attribute_id = @a_status
 WHERE @ok AND t.category_id = @cat AND t.product_id IS NOT NULL AND t.options IS NULL
   AND t.request_path LIKE 'microsoft-365-certification/%';

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

-- Search terms aimed at the page go to the top page.
UPDATE catalogsearch_query SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @dst)
 WHERE @ok AND redirect LIKE CONCAT('%/', @src);

-- Non-colliding url_key (as 1563) so the boot-time flat-URL job never grows a -N ladder.
UPDATE catalog_category_entity_varchar SET value = 'microsoft-365-certification-retired'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id = 0 AND value = 'microsoft-365-certification';

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id <> 0;

UPDATE catalog_category_entity_varchar SET value = 'microsoft-365-certification-retired.html'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id = 0;

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id <> 0;

UPDATE core_url_rewrite SET request_path = 'microsoft-365-certification-retired.html'
 WHERE @ok AND category_id = @cat AND is_system = 1 AND product_id IS NULL AND options IS NULL
   AND request_path <> 'microsoft-365-certification-retired.html'
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = 'microsoft-365-certification-retired.html'
                     AND x.store_id = core_url_rewrite.store_id);

-- ============================================================ retire: Microsoft Certification Exam Prep (instructor-led-microsoft-exam-prep)

SET @parent := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  WHERE v.value IN ('microsoft-certifications-exams','microsoft-certifications-exams-retired') LIMIT 1) r);

SET @cat := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value IN ('instructor-led-microsoft-exam-prep','instructor-led-microsoft-exam-prep-retired')
    AND TRIM(n.value)='Microsoft Certification Exam Prep' AND e.parent_id=@parent LIMIT 1) r);

SET @src := 'instructor-led-microsoft-exam-prep.html';
SET @ok := (@cat IS NOT NULL AND @tgt IS NOT NULL AND @dst IS NOT NULL AND @dst <> @src);

-- Every ENABLED course of the page keeps a DIRECT row on the top page (TGS- above
-- the C- block at MIN-1, others at MAX+1; the nightly sweep settles the order).
DROP TEMPORARY TABLE IF EXISTS tmp_retire_move;
CREATE TEMPORARY TABLE tmp_retire_move (product_id INT UNSIGNED PRIMARY KEY, is_tgs TINYINT, vis SMALLINT);
INSERT IGNORE INTO tmp_retire_move
SELECT cp.product_id, TRIM(e.sku) LIKE 'TGS-%', IFNULL(vi.value, 4)
  FROM catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id
  JOIN catalog_product_entity_int st ON st.entity_id = cp.product_id AND st.store_id = 0
   AND st.attribute_id = @a_status AND st.value = 1
  LEFT JOIN catalog_product_entity_int vi ON vi.entity_id = cp.product_id AND vi.store_id = 0 AND vi.attribute_id = @a_vis
 WHERE @ok AND cp.category_id = @cat;

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
ON DUPLICATE KEY UPDATE is_parent = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_retire_idx;
DROP TEMPORARY TABLE IF EXISTS tmp_retire_move;

-- Disable + de-menu (every scope row, so a store-level is_active=1 can't revive it).
UPDATE catalog_category_entity_int SET value = 0
 WHERE @ok AND entity_id = @cat AND attribute_id IN (@a_active, @a_menu);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat, 0
  FROM eav_attribute a
 WHERE @ok AND a.attribute_id IN (@a_active, @a_menu)
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_entity_int) x
                   WHERE x.entity_id = @cat AND x.attribute_id = a.attribute_id AND x.store_id = 0);

-- 301 the page URL to the top page (matches the reindex-regenerated id-path
-- target AND an already-corrected row, so a re-run restores the 301).
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

-- Flatten 301 chains that ended at this page (incl. 1761's Dynamics 301).
UPDATE core_url_rewrite SET target_path = @dst
 WHERE @ok AND is_system = 0 AND target_path = @src AND request_path <> @src;

-- Category-prefixed course URLs (instructor-led-microsoft-exam-prep/<course>.html) -> the course's flat URL
-- when enabled, else the top page.
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
   AND st.attribute_id = @a_status
 WHERE @ok AND t.category_id = @cat AND t.product_id IS NOT NULL AND t.options IS NULL
   AND t.request_path LIKE 'instructor-led-microsoft-exam-prep/%';

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

-- Search terms aimed at the page go to the top page.
UPDATE catalogsearch_query SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @dst)
 WHERE @ok AND redirect LIKE CONCAT('%/', @src);

-- Non-colliding url_key (as 1563) so the boot-time flat-URL job never grows a -N ladder.
UPDATE catalog_category_entity_varchar SET value = 'instructor-led-microsoft-exam-prep-retired'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id = 0 AND value = 'instructor-led-microsoft-exam-prep';

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id <> 0;

UPDATE catalog_category_entity_varchar SET value = 'instructor-led-microsoft-exam-prep-retired.html'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id = 0;

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id <> 0;

UPDATE core_url_rewrite SET request_path = 'instructor-led-microsoft-exam-prep-retired.html'
 WHERE @ok AND category_id = @cat AND is_system = 1 AND product_id IS NULL AND options IS NULL
   AND request_path <> 'instructor-led-microsoft-exam-prep-retired.html'
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = 'instructor-led-microsoft-exam-prep-retired.html'
                     AND x.store_id = core_url_rewrite.store_id);

-- ============================================================ retire: Github Certification Prep (github-certification-prep-courses)

SET @parent := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  WHERE v.value IN ('microsoft-certifications-exams','microsoft-certifications-exams-retired') LIMIT 1) r);

SET @cat := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value IN ('github-certification-prep-courses','github-certification-prep-courses-retired')
    AND TRIM(n.value)='Github Certification Prep' AND e.parent_id=@parent LIMIT 1) r);

SET @src := 'github-certification-prep-courses.html';
SET @ok := (@cat IS NOT NULL AND @tgt IS NOT NULL AND @dst IS NOT NULL AND @dst <> @src);

-- Every ENABLED course of the page keeps a DIRECT row on the top page (TGS- above
-- the C- block at MIN-1, others at MAX+1; the nightly sweep settles the order).
DROP TEMPORARY TABLE IF EXISTS tmp_retire_move;
CREATE TEMPORARY TABLE tmp_retire_move (product_id INT UNSIGNED PRIMARY KEY, is_tgs TINYINT, vis SMALLINT);
INSERT IGNORE INTO tmp_retire_move
SELECT cp.product_id, TRIM(e.sku) LIKE 'TGS-%', IFNULL(vi.value, 4)
  FROM catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id
  JOIN catalog_product_entity_int st ON st.entity_id = cp.product_id AND st.store_id = 0
   AND st.attribute_id = @a_status AND st.value = 1
  LEFT JOIN catalog_product_entity_int vi ON vi.entity_id = cp.product_id AND vi.store_id = 0 AND vi.attribute_id = @a_vis
 WHERE @ok AND cp.category_id = @cat;

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
ON DUPLICATE KEY UPDATE is_parent = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_retire_idx;
DROP TEMPORARY TABLE IF EXISTS tmp_retire_move;

-- Disable + de-menu (every scope row, so a store-level is_active=1 can't revive it).
UPDATE catalog_category_entity_int SET value = 0
 WHERE @ok AND entity_id = @cat AND attribute_id IN (@a_active, @a_menu);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat, 0
  FROM eav_attribute a
 WHERE @ok AND a.attribute_id IN (@a_active, @a_menu)
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_entity_int) x
                   WHERE x.entity_id = @cat AND x.attribute_id = a.attribute_id AND x.store_id = 0);

-- 301 the page URL to the top page (matches the reindex-regenerated id-path
-- target AND an already-corrected row, so a re-run restores the 301).
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

-- Flatten 301 chains that ended at this page (incl. 1761's Dynamics 301).
UPDATE core_url_rewrite SET target_path = @dst
 WHERE @ok AND is_system = 0 AND target_path = @src AND request_path <> @src;

-- Category-prefixed course URLs (github-certification-prep-courses/<course>.html) -> the course's flat URL
-- when enabled, else the top page.
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
   AND st.attribute_id = @a_status
 WHERE @ok AND t.category_id = @cat AND t.product_id IS NOT NULL AND t.options IS NULL
   AND t.request_path LIKE 'github-certification-prep-courses/%';

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

-- Search terms aimed at the page go to the top page.
UPDATE catalogsearch_query SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @dst)
 WHERE @ok AND redirect LIKE CONCAT('%/', @src);

-- Non-colliding url_key (as 1563) so the boot-time flat-URL job never grows a -N ladder.
UPDATE catalog_category_entity_varchar SET value = 'github-certification-prep-courses-retired'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id = 0 AND value = 'github-certification-prep-courses';

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_uk AND store_id <> 0;

UPDATE catalog_category_entity_varchar SET value = 'github-certification-prep-courses-retired.html'
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id = 0;

DELETE FROM catalog_category_entity_varchar
 WHERE @ok AND entity_id = @cat AND attribute_id = @a_up AND store_id <> 0;

UPDATE core_url_rewrite SET request_path = 'github-certification-prep-courses-retired.html'
 WHERE @ok AND category_id = @cat AND is_system = 1 AND product_id IS NULL AND options IS NULL
   AND request_path <> 'github-certification-prep-courses-retired.html'
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = 'github-certification-prep-courses-retired.html'
                     AND x.store_id = core_url_rewrite.store_id);
