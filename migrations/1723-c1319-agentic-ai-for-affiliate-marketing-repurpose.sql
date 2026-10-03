-- C1319: "AI Vibe Coding for Crypto Tokens" -> "Agentic AI for Affiliate Marketing", the 1-day non-WSQ
-- twin of TGS-2025060552 (WSQ - Agentic AI for Affiliate Marketing). Fee $350 / 7.5 h / 1 session
-- were already live; re-asserted here.
--
-- 1. name, url_key/url_path (ai-vibe-coding-for-crypto-tokens -> agentic-ai-for-affiliate-marketing),
--    cover alt/gallery labels, meta title/description/keywords (no day count).
-- 2. About + topics copied from the WSQ parent.
-- 3. Funding block -> the parent's live URL (it pointed at the Multi Agents System WSQ course).
-- 4. Off the crypto/finance categories and the AI Vibe Coding Series (category + red badge);
--    into Digital Marketing, alphabetically among the non-WSQ courses.
-- 5. 301s: system rows renamed in place; every old path 301s one hop to the new bare slug.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): cover re-render (title is baked into the PNG), schedule
-- template -> A12 via the controller, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1319' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025060552' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Agentic AI for Affiliate Marketing';
SET @old_slug  := 'ai-vibe-coding-for-crypto-tokens';
SET @new_slug  := 'agentic-ai-for-affiliate-marketing';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_price   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');
SET @a_series  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_series_badge');
SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

-- ------------------------------------------------------- name / slug -----
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_name;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath;

-- ------------------------------------------------------ image labels -----
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @new_title
 WHERE @ok AND v.entity_id = @pid;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @new_title
 WHERE @ok AND g.entity_id = @pid;

-- --------------------------------------------- fee / duration / sessions ---
UPDATE catalog_product_entity_decimal SET value = 350
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price;

UPDATE catalog_product_entity_varchar SET value = '7.5'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_dur;

UPDATE catalog_product_entity_varchar SET value = '1'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_sess;

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Agentic AI for Affiliate Marketing in Singapore: use Claude Cowork, Claude Skills and MCP tools to research partners, create affiliate content and optimise campaign performance.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Agentic AI for Affiliate Marketing, Affiliate Marketing, Claude Cowork, Claude Skills, MCP Tools, Affiliate Campaign Automation, AI Partner Research, Digital Marketing, Tertiary Courses'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_urlkey, @a_urlpath, @a_dur, @a_sess) AND store_id <> 0;

DELETE FROM catalog_product_entity_decimal
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price AND store_id <> 0;

-- ---------------------------------------------- About + topics (parent) ----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, value
  FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @src AND attribute_id = @a_short AND store_id = 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, value
  FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @src AND attribute_id = @a_desc AND store_id = 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey) AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-affiliate-marketing.html" title="WSQ - Agentic AI for Affiliate Marketing">WSQ - Agentic AI for Affiliate Marketing</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C1319_funding_and_grant';

-- ------------------------------------------- series badge (no longer) -----
DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_series;

-- ------------------------------------------------------- categories -------
-- Off: crypto/blockchain/finance leaves + AI Vibe Coding Series; the anchor parents
-- fintech-courses / logistics-and-manufacturing-courses only held it through those leaves.
DROP TEMPORARY TABLE IF EXISTS tmp_c1319_offcats;
CREATE TEMPORARY TABLE tmp_c1319_offcats (category_id INT UNSIGNED PRIMARY KEY);
INSERT INTO tmp_c1319_offcats
SELECT entity_id FROM catalog_category_entity_varchar
 WHERE @ok AND attribute_id = @a_curlkey AND store_id = 0
   AND value IN ('blockchain-courses', 'cryptocurrencies-courses', 'non-fungible-tokens-nft-courses',
                 'ethereum-blockchain-courses', 'smart-contract-courses', 'defi-courses',
                 'finance-courses', 'ai-for-finance-courses', 'ai-vibe-coding-series',
                 'fintech-courses', 'logistics-and-manufacturing-courses');

DELETE cp FROM catalog_category_product cp JOIN tmp_c1319_offcats t ON t.category_id = cp.category_id
 WHERE cp.product_id = @pid;

DELETE ci FROM catalog_category_product_index ci JOIN tmp_c1319_offcats t ON t.category_id = ci.category_id
 WHERE ci.product_id = @pid;

-- On: Digital Marketing, slotted before the first non-WSQ course whose name sorts after the new title.
SET @dm := (SELECT entity_id FROM catalog_category_entity_varchar
             WHERE @ok AND attribute_id = @a_curlkey AND store_id = 0 AND value = 'digital-marketing-courses-in' LIMIT 1);
SET @dm_need := (@dm IS NOT NULL AND NOT EXISTS (SELECT 1 FROM catalog_category_product WHERE category_id = @dm AND product_id = @pid));
SET @dm_pos := (SELECT MIN(cp.position) FROM catalog_category_product cp
                  JOIN catalog_product_entity e ON e.entity_id = cp.product_id AND e.sku NOT LIKE 'TGS-%'
                  JOIN catalog_product_entity_varchar n ON n.entity_id = e.entity_id AND n.attribute_id = @a_name AND n.store_id = 0
                 WHERE @dm_need AND cp.category_id = @dm AND n.value > @new_title);
SET @dm_pos := IFNULL(@dm_pos, (SELECT IFNULL(MAX(position), 0) + 1 FROM catalog_category_product WHERE category_id = @dm));

UPDATE catalog_category_product SET position = position + 1
 WHERE @dm_need AND category_id = @dm AND position >= @dm_pos;

UPDATE catalog_category_product_index SET position = position + 1
 WHERE @dm_need AND category_id = @dm AND store_id = 1 AND position >= @dm_pos;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @dm, @pid, @dm_pos FROM DUAL WHERE @dm_need;

INSERT INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @dm, @pid, @dm_pos, 1, 1, 4 FROM DUAL WHERE @dm_need
ON DUPLICATE KEY UPDATE position = VALUES(position), is_parent = 1;

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c1319_old;
CREATE TEMPORARY TABLE tmp_c1319_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c1319_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Drop the system rows of the categories it left (their paths 301 via step 5).
DELETE r FROM core_url_rewrite r JOIN tmp_c1319_offcats t ON t.category_id = r.category_id
 WHERE r.product_id = @pid AND r.is_system = 1;

-- 3) Rename the remaining system rows in place, so the new slug resolves immediately.
UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 4) Legacy RP rows that pointed at any old-slug path -> the new bare slug (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html')
 WHERE @ok AND options = 'RP'
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 5) Every old path 301s to the new bare slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_c1319_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c1319_old;
DROP TEMPORARY TABLE IF EXISTS tmp_c1319_offcats;

-- ---------------------------------------------------- search redirects ----
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html');
