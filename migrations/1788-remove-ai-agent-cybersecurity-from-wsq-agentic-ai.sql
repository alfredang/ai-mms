-- 1788: Remove TGS-2025053228 "WSQ - AI Agent Cybersecurity" from the
-- WSQ Agentic AI Courses listing (url_key 'wsq-agentic-ai-courses').
--
-- The course stays listed on AI Agents Series ('ai-agents-series') and
-- AI Security Series ('ai-security-series'): it is already a direct member of
-- both (verified on SG prod 2026-10-06), so nothing is inserted there.
-- It was never on Agentic AI Series ('agentic-ai-series') or its children.
--
-- Parent anchor 'WSQ AI' (325) keeps the course legitimately via
-- WSQ AI Agents Courses (194), so its rows there are left alone.
-- The index row is deleted alongside the base row so the listing changes
-- without a full Category Products reindex. Business-key lookups; no-ops on
-- sites without this SKU or category. Idempotent.

SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-agentic-ai-courses' LIMIT 1);
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2025053228' LIMIT 1);

DELETE FROM catalog_category_product WHERE category_id=@cat AND product_id=@pid;
DELETE FROM catalog_category_product_index WHERE category_id=@cat AND product_id=@pid;
