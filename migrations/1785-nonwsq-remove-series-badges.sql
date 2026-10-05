-- Non-WSQ (C-prefix) courses carry no badges (owner's rule, 2026-10-05): only WSQ/CASL/IBF (TGS-)
-- courses show badge pills. Prod audit: 36 C-prefix courses held course_series_badge =
-- 'AI Vibe Coding Series' (store 0), several of them wrongly (e.g. C28 AI Agent Security, C169
-- Generative AI for Interviewing, C349 Multi AI Agents System for Digital Marketing, C818 ChatGPT
-- WORK). No C-prefix course has funding-badge tags, so tag_relation is not touched.
--
-- Deletes the attribute value at EVERY store scope for every C-prefix product (enabled or not).
-- view.phtml renders the pill only when course_series_badge is non-empty; it is the only reader.
-- TGS- courses are untouched. Category membership (e.g. ai-vibe-coding-series) is not touched.
-- Supersets 1784-c818-remove-vibe-coding-badge. SG-only (store guard). Idempotent.
-- Post-deploy: flat reindex + cache flush.

SET @sg    := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @badge := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_series_badge');

DELETE v FROM catalog_product_entity_varchar v
  JOIN catalog_product_entity e ON e.entity_id = v.entity_id
 WHERE @sg = 1 AND @badge IS NOT NULL AND v.attribute_id = @badge
   AND TRIM(e.sku) REGEXP '^C[0-9]';
