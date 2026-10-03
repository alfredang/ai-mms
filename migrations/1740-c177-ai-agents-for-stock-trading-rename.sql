-- C177: "AI Agents for Trading" -> "AI Agents for Stock Trading". Already enabled, 1 day / 7.5 h /
-- 1 session / $350 (unchanged - probed on prod 2026-10-04).
--
-- 1. name, url_key/url_path (ai-agents-for-trading -> ai-agents-for-stock-trading), cover alt +
--    gallery label (still "Basic Python Training for Beginners in Singapore" from an earlier life),
--    meta title/description/keywords (no day count).
-- 2. Body copy follows the title (targeted REPLACEs on short_description + topic list); the
--    who-should-attend list was the old Python course's audience -> trading audience.
-- 3. Category: join Investment & Trading 201 (/algorithmic-trading-quantitative-analysis-courses.html)
--    at position 3 - funded IBF/CASL first, then non-WSQ A-Z ("AI Agents..." < "AI for Finance").
--    Existing categories kept. Mirrored into catalog_category_product_index (201 direct, 165
--    Financial Services anchor-inherited).
-- 4. 301s: system rows renamed in place; every old path + legacy RP row 301s one hop to the new
--    bare slug. Search terms c177/c0177 follow the slug; the ten "basic python" terms (which
--    landed on this trading course via the old Python slug) are cleared so Magento search handles them.
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): cover re-render (Agent API regenerate_image), schedule template
-- A19 (gid 79) -> A17 (gid 81) via the controller code path, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C177' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);

SET @new_title := 'AI Agents for Stock Trading';
SET @old_slug  := 'ai-agents-for-trading';
SET @new_slug  := 'ai-agents-for-stock-trading';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');

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

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'AI Agents for Stock Trading in Singapore: use AI agents to research stock ideas, validate market data, backtest rules, size risk and place paper trades with a six-step workflow.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'AI Agents for Stock Trading, AI Agents, Stock Trading, Stock Market, Algorithmic Trading, Backtesting, Market Data, Trading Strategy, Paper Trading, Risk Sizing, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_urlkey, @a_urlpath) AND store_id <> 0;

-- --------------------------------------------------------- body copy -----
UPDATE catalog_product_entity_text
   SET value = REPLACE(REPLACE(value,
       'Put an AI agent to work on your trading research.',
       'Put an AI agent to work on your stock trading research.'),
       'use AI agents to research trading ideas',
       'use AI agents to research stock trading ideas')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_short;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, 'Introduction to AI Agents for Trading', 'Introduction to AI Agents for Stock Trading')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_desc;

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_who, 0, @pid, '<ul><li>Retail Investor</li><li>Stock Trader</li><li>Active Trader</li><li>Investment Analyst</li><li>Equity Research Analyst</li><li>Portfolio Manager</li><li>Quantitative Analyst</li><li>Wealth Manager</li><li>Remisier and Dealer</li><li>Finance Professional</li><li>Data Analyst</li><li>FinTech Professional</li></ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_who, @a_mkey) AND store_id <> 0;

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + every category-prefixed one).
DROP TEMPORARY TABLE IF EXISTS tmp_c177_old;
CREATE TEMPORARY TABLE tmp_c177_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c177_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Rename the system rows in place, so the new slug resolves without a rewrite refresh.
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
  FROM tmp_c177_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c177_old;

-- 5) System row for the new category 201.
INSERT IGNORE INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 201, @pid, CONCAT('product/', @pid, '/201'),
       CONCAT('algorithmic-trading-quantitative-analysis-courses/', @new_slug, '.html'),
       CONCAT('catalog/product/view/id/', @pid, '/category/201'), 1, NULL
  FROM DUAL WHERE @ok;

-- ---------------------------------------------------- search redirects ----
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html');

UPDATE catalogsearch_query
   SET redirect = NULL
 WHERE @ok AND redirect = 'https://www.tertiarycourses.com.sg/basic-python-training-for-beginners.html';

-- ---------------------------------------------------------- categories ----
-- Investment & Trading 201: IBF, CASL, then non-WSQ A-Z -> C177 takes position 3.
SET @in201 := (SELECT COUNT(*) FROM catalog_category_product WHERE category_id = 201 AND product_id = @pid);
UPDATE catalog_category_product SET position = position + 1
 WHERE @ok AND category_id = 201 AND position >= 3 AND product_id <> @pid AND @in201 = 0;
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 201, @pid, 3 FROM DUAL WHERE @ok;

-- ------------------------------------------------ category index mirror ----
UPDATE catalog_category_product_index i
  JOIN catalog_category_product cp ON cp.category_id = i.category_id AND cp.product_id = i.product_id
   SET i.position = cp.position
 WHERE @ok AND i.category_id = 201 AND i.store_id = 1;

SET @pos165 := (SELECT COALESCE(MAX(position), 0) + 1 FROM catalog_category_product_index WHERE category_id = 165 AND store_id = 1 AND product_id <> @pid);
INSERT INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT 201, @pid, 3, 1, 1, 4 FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE position = 3, is_parent = 1;

-- Financial Services 165 (anchor parent): inherited row, appended; the ordering sweep re-seats it.
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT 165, @pid, @pos165, 0, 1, 4 FROM DUAL WHERE @ok;
