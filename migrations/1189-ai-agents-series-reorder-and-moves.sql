-- 1189: AI Agents Series curation.
--
-- 1) Moves out of the AI Agents Series:
--    -> Agentic AI Series        : TGS-2024052081 (Automate Video and Voice AI Agents with n8n
--                                  — already pinned there by 1188; INSERT is defensive)
--    -> Microsoft Copilot Series : TGS-2022017524 (Business Process Automation with Power
--                                  Automate and Copilot Studio Agents — already there via 1187)
--
-- 2) ALSO add to the AI Security Series (they stay in the AI Agents Series):
--    TGS-2025053228 (AI Agent Cybersecurity)
--    TGS-2024042604 (Security Operations for Autonomous AI Agents)
--
-- 3) Pin the requested WSQ/CASL order at the top of the AI Agents Series:
--     1. TGS-2025054471  WSQ - Autonomous AI Agents
--     2. TGS-2020503395  WSQ - Business Innovation with AI Agents
--     3. TGS-2023018987  WSQ - AI Agents for Business
--     4. TGS-2026064176  CASL - AI Agent with Hermes Agent
--     5. TGS-2026064859  CASL - Autonomous AI Agents with OpenClaw
--     6. TGS-2023036646  WSQ - Manage AI Agents with Paperclip
--     7. TGS-2023036153  WSQ - Multi AI Agents Workflow for Content Creation
--     8. TGS-2024043854  WSQ - Build a Human-AI Workforce with Autonomous AI Agents
--     9. TGS-2025053228  WSQ - AI Agent Cybersecurity
--    10. TGS-2024042604  WSQ - Security Operations for Autonomous AI Agents
--
-- All pinned SKUs are TGS-, so the nightly CategoryOrdering sweep preserves
-- their relative order. Business-key lookups only; TGS- SKUs do not exist on
-- partner instances (clean no-op). Idempotent.

SET @agents := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-agents-series' LIMIT 1
);
SET @agentic := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'agentic-ai-series' LIMIT 1
);
SET @copilot := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'microsoft-copilot-series' LIMIT 1
);
SET @security := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-security-series' LIMIT 1
);

-- ---------------------------------------------------------------------------
-- 1) Remove the two moved courses from the AI Agents Series (base + index),
--    then make sure they sit in their target series.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @agents
  AND p.sku IN ('TGS-2024052081', 'TGS-2022017524');

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @agents
  AND p.sku IN ('TGS-2024052081', 'TGS-2022017524');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @agentic, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @agentic IS NOT NULL
  AND p.sku = 'TGS-2024052081';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @agentic, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @agentic IS NOT NULL
  AND p.sku = 'TGS-2024052081'
GROUP BY p.entity_id, s.store_id;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @copilot, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @copilot IS NOT NULL
  AND p.sku = 'TGS-2022017524';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @copilot, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @copilot IS NOT NULL
  AND p.sku = 'TGS-2022017524'
GROUP BY p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 2) Also add the two security courses to the AI Security Series.
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @security, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @security IS NOT NULL
  AND p.sku IN ('TGS-2025053228', 'TGS-2024042604');

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @security, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @security IS NOT NULL
  AND p.sku IN ('TGS-2025053228', 'TGS-2024042604')
GROUP BY p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 3) Pin the requested order (base + index).
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2025054471' THEN -10
  WHEN 'TGS-2020503395' THEN -9
  WHEN 'TGS-2023018987' THEN -8
  WHEN 'TGS-2026064176' THEN -7
  WHEN 'TGS-2026064859' THEN -6
  WHEN 'TGS-2023036646' THEN -5
  WHEN 'TGS-2023036153' THEN -4
  WHEN 'TGS-2024043854' THEN -3
  WHEN 'TGS-2025053228' THEN -2
  WHEN 'TGS-2024042604' THEN -1
END
WHERE cp.category_id = @agents
  AND p.sku IN (
    'TGS-2025054471', 'TGS-2020503395', 'TGS-2023018987', 'TGS-2026064176',
    'TGS-2026064859', 'TGS-2023036646', 'TGS-2023036153', 'TGS-2024043854',
    'TGS-2025053228', 'TGS-2024042604'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2025054471' THEN -10
  WHEN 'TGS-2020503395' THEN -9
  WHEN 'TGS-2023018987' THEN -8
  WHEN 'TGS-2026064176' THEN -7
  WHEN 'TGS-2026064859' THEN -6
  WHEN 'TGS-2023036646' THEN -5
  WHEN 'TGS-2023036153' THEN -4
  WHEN 'TGS-2024043854' THEN -3
  WHEN 'TGS-2025053228' THEN -2
  WHEN 'TGS-2024042604' THEN -1
END
WHERE i.category_id = @agents
  AND p.sku IN (
    'TGS-2025054471', 'TGS-2020503395', 'TGS-2023018987', 'TGS-2026064176',
    'TGS-2026064859', 'TGS-2023036646', 'TGS-2023036153', 'TGS-2024043854',
    'TGS-2025053228', 'TGS-2024042604'
  );
