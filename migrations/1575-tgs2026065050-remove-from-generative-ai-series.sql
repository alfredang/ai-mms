-- 1575: TGS-2026065050 'CASL - Microsoft Copilot for Finance' -- take it off
-- the Generative AI Series page (SG cat 433, url_key 'generative-ai-series').
--
-- Destinations need no change: the course is ALREADY a direct member (base +
-- index) of 357 Microsoft Copilot Series, 204 Finance and 230 AI for Finance,
-- and renders on all three pages. The work is removal only.
--
-- Cat 433 is an ANCHOR; its child 200 'GenAI Content Creation'
-- (include_in_menu=0 grouping bucket) also holds the course, so deleting the
-- 433 row alone would be undone by the next full reindex (anchor inheritance).
-- Remove it from BOTH 433 and 200, base + index. The course is in no other
-- child of 433 (111, 188).
--
-- The two now-dead category-path system rewrites
-- (generative-ai-series/<slug>.html, chatgpt-and-generative-ai-courses/<slug>.html)
-- are converted into 301s to the bare product URL so they don't 404.
--
-- Partner-safe: TGS- SKUs exist only on SG; categories are matched by id AND
-- url_key, so a partner DB with different ids no-ops.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026065050' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS tmp_1575_cats;
CREATE TEMPORARY TABLE tmp_1575_cats (category_id INT UNSIGNED PRIMARY KEY);
INSERT INTO tmp_1575_cats (category_id)
SELECT v.entity_id FROM catalog_category_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'url_key' AND a.entity_type_id = 3
WHERE v.store_id = 0
  AND ((v.entity_id = 433 AND v.value = 'generative-ai-series')
    OR (v.entity_id = 200 AND v.value = 'chatgpt-and-generative-ai-courses'));

DELETE FROM catalog_category_product
WHERE product_id = @pid AND category_id IN (SELECT category_id FROM tmp_1575_cats);

DELETE FROM catalog_category_product_index
WHERE product_id = @pid AND category_id IN (SELECT category_id FROM tmp_1575_cats);

UPDATE core_url_rewrite r
JOIN catalog_product_entity_varchar pv ON pv.entity_id = r.product_id AND pv.store_id = 0
JOIN eav_attribute a ON a.attribute_id = pv.attribute_id AND a.attribute_code = 'url_key' AND a.entity_type_id = 4
SET r.id_path = CONCAT('mmd/1575/', r.url_rewrite_id),
    r.target_path = CONCAT(pv.value, '.html'),
    r.is_system = 0,
    r.options = 'RP',
    r.category_id = NULL
WHERE r.product_id = @pid
  AND r.is_system = 1
  AND r.category_id IN (SELECT category_id FROM tmp_1575_cats);

DROP TEMPORARY TABLE IF EXISTS tmp_1575_cats;
