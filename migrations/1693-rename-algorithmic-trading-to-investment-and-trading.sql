-- 1693: rename the "Algorithmic Trading" category to "Investment & Trading"
-- and rewrite its description + meta title/description to match.
--
-- Requested 2026-10-02 (Financial Services menu: Accounting / Finance /
-- Algorithmic Trading). The url_key algorithmic-trading-quantitative-analysis-
-- courses is deliberately UNCHANGED, so no 301 work is needed.
--
-- SG only (the copy names IBF / CASL funding): resolved by url_key and gated
-- on the singapore store, so it is a clean no-op on MY/GH. EAV only -- the storefront picks it up on the
-- catalog_category_flat reindex. Idempotent.

SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'algorithmic-trading-quantitative-analysis-courses'
    AND EXISTS (SELECT 1 FROM core_store WHERE store_id = 1 AND code = 'singapore') LIMIT 1);

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @a_title := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description');
SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_description');

SET @name  := 'Investment & Trading';
SET @title := 'Investment and Trading Courses in Singapore - AI, Python and Algorithmic Trading';
SET @mdesc := 'Investment and trading courses in Singapore: use AI, Python and machine learning to analyse markets, build and back-test algorithmic strategies and manage risk. Funded IBF and CASL options available.';
SET @desc  := CONCAT(
  '<p>Investing and trading today run on data. Whether you manage your own portfolio or work in a bank, fund or fintech, ',
  'the edge comes from analysing markets with the right tools, testing ideas before risking capital, and managing risk with discipline.</p>\n',
  '<p>Our Investment &amp; Trading courses teach you to use Python, machine learning and AI to analyse financial data, ',
  'build and back-test trading strategies, and automate their execution. Topics range from financial data analysis and ',
  'portfolio thinking to algorithmic and quantitative trading, AI agents for market research, and vibe coding your own trading tools.</p>\n',
  '<p>The courses are hands-on and suit investors, traders, analysts and finance professionals. Funded IBF and CASL options ',
  'are available for eligible Singaporeans and PRs.</p>');

-- name / meta_title (varchar): drop store overrides so store 0 wins.
UPDATE catalog_category_entity_varchar SET value = @name
 WHERE @cat IS NOT NULL AND entity_id = @cat AND attribute_id = @a_name AND store_id = 0;
UPDATE catalog_category_entity_varchar SET value = @title
 WHERE @cat IS NOT NULL AND entity_id = @cat AND attribute_id = @a_title AND store_id = 0;
INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_title, 0, @cat, @title FROM DUAL
 WHERE @cat IS NOT NULL AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_entity_varchar) x
   WHERE x.entity_id = @cat AND x.attribute_id = @a_title AND x.store_id = 0);
DELETE FROM catalog_category_entity_varchar
 WHERE @cat IS NOT NULL AND entity_id = @cat AND attribute_id IN (@a_name, @a_title) AND store_id <> 0;

-- description / meta_description (text).
UPDATE catalog_category_entity_text SET value = @desc
 WHERE @cat IS NOT NULL AND entity_id = @cat AND attribute_id = @a_desc AND store_id = 0;
UPDATE catalog_category_entity_text SET value = @mdesc
 WHERE @cat IS NOT NULL AND entity_id = @cat AND attribute_id = @a_mdesc AND store_id = 0;
INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat, IF(a.attribute_id = @a_desc, @desc, @mdesc)
  FROM eav_attribute a
 WHERE @cat IS NOT NULL AND a.attribute_id IN (@a_desc, @a_mdesc)
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_entity_text) x
     WHERE x.entity_id = @cat AND x.attribute_id = a.attribute_id AND x.store_id = 0);
DELETE FROM catalog_category_entity_text
 WHERE @cat IS NOT NULL AND entity_id = @cat AND attribute_id IN (@a_desc, @a_mdesc) AND store_id <> 0;
