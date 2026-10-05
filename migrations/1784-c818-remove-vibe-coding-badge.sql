-- C818 "ChatGPT WORK for Digital Marketing" is a Codex AI Series course (direct member of
-- codex-ai-series since 1212, pinned in 1558), not an AI Vibe Coding Series course, but it still
-- carried the red "AI Vibe Coding Series" pill set by 342. Clear the badge value at every scope;
-- view.phtml renders the pill only when course_series_badge is non-empty. Category membership is
-- already correct on prod and is not touched.
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent.
-- Post-deploy: flat reindex + cache flush.

SET @sg    := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid   := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C818' LIMIT 1);
SET @badge := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_series_badge');

UPDATE catalog_product_entity_varchar SET value = ''
 WHERE @sg = 1 AND @pid IS NOT NULL AND @badge IS NOT NULL
   AND entity_id = @pid AND attribute_id = @badge AND value = 'AI Vibe Coding Series';
