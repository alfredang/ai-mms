-- 1867: C207 "AI for Finance" — remove from Investment & Trading
-- (url_key 'algorithmic-trading-quantitative-analysis-courses'), keep it in
-- Finance (url_key 'finance-courses').
--
-- Applies identically on SG, MY and GH (same C-catalog + category tree), so it is
-- keyed by SKU + url_key only — category/product ids differ per site
-- (SG 201/204/pid 207, MY+GH 108/30/pid 214). C207 was ALREADY a direct member of
-- Finance on every site; the INSERT IGNOREs are only a safety net. Investment &
-- Trading has no child categories, so the delete is not undone by anchor
-- inheritance; the Fintech parent keeps C207 through Finance.
--
-- Rewrites: the old 'algorithmic-trading-.../ai-for-finance.html' system row and the
-- legacy 301s landing on it go to the flat 'ai-for-finance.html', detached from the
-- (product, category) pair — the Catalog URL reindex deletes every row still tagged
-- with a membership that no longer exists (see 1809).
-- Idempotent.

SET @p := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C207' LIMIT 1);
SET @it := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='algorithmic-trading-quantitative-analysis-courses' LIMIT 1);
SET @fin := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='finance-courses' LIMIT 1);
SET @vis := (SELECT i.value FROM catalog_product_entity_int i
  JOIN eav_attribute a ON a.attribute_id=i.attribute_id AND a.entity_type_id=4 AND a.attribute_code='visibility'
  WHERE i.entity_id=@p AND i.store_id=0 LIMIT 1);

-- 1. Safety net: C207 in Finance ---------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @fin, @p, (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @fin)
FROM DUAL WHERE @p IS NOT NULL AND @fin IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @fin, @p, cp.position, 1, s.store_id, COALESCE(@vis, 4)
FROM catalog_category_product cp
JOIN core_store s ON s.store_id > 0
WHERE cp.category_id = @fin AND cp.product_id = @p;

-- 2. Remove C207 from Investment & Trading -----------------------------------

DELETE FROM catalog_category_product
WHERE category_id = @it AND product_id = @p AND @it IS NOT NULL AND @p IS NOT NULL;

DELETE FROM catalog_category_product_index
WHERE category_id = @it AND product_id = @p AND @it IS NOT NULL AND @p IS NOT NULL;

-- 3. Rewrites -----------------------------------------------------------------

SET @old_path := 'algorithmic-trading-quantitative-analysis-courses/ai-for-finance.html';
SET @prod_path := 'ai-for-finance.html';

UPDATE core_url_rewrite
SET target_path = @prod_path, category_id = NULL, product_id = NULL
WHERE @p IS NOT NULL AND is_system = 0 AND target_path = @old_path;

UPDATE core_url_rewrite
SET target_path = @prod_path, is_system = 0, options = 'RP',
    category_id = NULL, product_id = NULL,
    id_path = CONCAT('mmd-c207-it-301-', MD5(request_path))
WHERE @p IS NOT NULL AND request_path = @old_path AND is_system = 1;
