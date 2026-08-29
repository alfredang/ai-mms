-- 1190: Pin the requested WSQ course order in the Microsoft Copilot Series:
--   1. TGS-2024043856  WSQ - Enhance Work Productivity with Microsoft 365 Copilot
--   2. TGS-2022017524  WSQ - Business Process Automation with Power Automate and Copilot Studio Agents
--   3. TGS-2023036648  WSQ - Create Intelligent Power Apps and Power Automate Workflows with Copilot
--
-- All TGS-, so the nightly CategoryOrdering sweep preserves the relative
-- order. The category exists only on SG (created by 1187); the url_key lookup
-- makes this a clean no-op on partner instances. Idempotent.

SET @copilot := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'microsoft-copilot-series' LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2024043856' THEN -3
  WHEN 'TGS-2022017524' THEN -2
  WHEN 'TGS-2023036648' THEN -1
END
WHERE cp.category_id = @copilot
  AND p.sku IN ('TGS-2024043856', 'TGS-2022017524', 'TGS-2023036648');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2024043856' THEN -3
  WHEN 'TGS-2022017524' THEN -2
  WHEN 'TGS-2023036648' THEN -1
END
WHERE i.category_id = @copilot
  AND p.sku IN ('TGS-2024043856', 'TGS-2022017524', 'TGS-2023036648');
