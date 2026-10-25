-- C728 is no longer a vibe-coding course (renamed AI Powered Quantitative Trading Fundamentals in 1848,
-- now a low-code quant trading course), so it leaves the AI Vibe Coding Series category (414).
-- 414 is a leaf under anchor 252 (AI Courses); C728 is a DIRECT member of 252, so it stays in the
-- AI Courses listing. Its category-prefixed URL under 414 becomes a 301 to the bare product slug.
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent. Post-deploy: cache flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C728' LIMIT 1);
SET @cat := (SELECT entity_id FROM catalog_category_entity WHERE entity_id = 414 AND path = '1/2/252/414');
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @cat IS NOT NULL);

DELETE FROM catalog_category_product WHERE @ok AND category_id = @cat AND product_id = @pid;
DELETE FROM catalog_category_product_index WHERE @ok AND category_id = @cat AND product_id = @pid;

UPDATE core_url_rewrite
   SET target_path = 'ai-powered-quantitative-trading-fundamentals.html', options = 'RP', is_system = 0,
       product_id = NULL, category_id = NULL,
       id_path = CONCAT('manual-301-', MD5(request_path), '-', store_id)
 WHERE @ok AND request_path = 'ai-vibe-coding-series/ai-powered-quantitative-trading-fundamentals.html';
