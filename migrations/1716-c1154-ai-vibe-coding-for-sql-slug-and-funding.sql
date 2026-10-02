-- C1154 "AI Vibe Coding for SQL" (1-day non-WSQ twin of TGS-2021002619 WSQ - AI Vibe Coding for SQL).
-- Name already correct; this changes the slug and the funding link only.
--
-- 1. url_key/url_path: sql-essential-training -> ai-vibe-coding-for-sql.
-- 2. 301s: system rows renamed in place; every old path 301s one hop to the new bare slug;
--    search terms that redirected to the old slug follow it.
-- 3. Funding block linked to the real parent (it pointed at WSQ - AI Vibe Coding for Multi Agents System).
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): schedule template A09 (gid 89) -> A08 (gid 118) to match the
-- parent's (SG) WSQ-A08 (gid 304), then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1154' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2021002619' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @old_slug  := 'sql-essential-training';
SET @new_slug  := 'ai-vibe-coding-for-sql';

SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');

-- ------------------------------------------------------------ slug -----
UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath;

-- ------------------------------------------------------ funding block -----
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\r\n<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-sql.html" title="WSQ - AI Vibe Coding for SQL">WSQ - AI Vibe Coding for SQL</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C1154_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c1154_old;
CREATE TEMPORARY TABLE tmp_c1154_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c1154_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Rename those system rows in place, so the new slug resolves immediately.
UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 3) Legacy RP rows that pointed at any old-slug path -> the new bare slug (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html')
 WHERE @ok AND options = 'RP'
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 4) Every old path 301s to the new bare slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_c1154_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c1154_old;

-- ---------------------------------------------------- search redirects ----
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html');
