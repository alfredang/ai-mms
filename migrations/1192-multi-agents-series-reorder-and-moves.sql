-- 1192: Multi AI Agents Series curation.
--
-- 1) Moves out of the Multi AI Agents Series:
--    -> AI Applications Series : TGS-2025059025 (Generative AI Model Development and Fine Tuning)
--    -> Agentic AI Series      : TGS-2024045799 (Agentic AI for Product Development — already there via 1186)
--    -> AI Agents Series       : TGS-2023018987 (AI Agents for Business — already there, pinned by 1189)
--                                TGS-2024042309 (Develop AI Agents with OpenAI Agent Development Kit)
--                                TGS-2024042961 (Develop Multi AI Agent Applications with Gemini Agent ADK)
--    -> AI Vibe Coding Series  : TGS-2024045802 (AI Vibe Coding for Data Mining and Modeling — already there via 1186)
--
-- 2) Pin the requested WSQ order at the top of the Multi AI Agents Series:
--    1. TGS-2023036153  WSQ - Multi AI Agents Workflow for Content Creation
--    2. TGS-2023036646  WSQ - Manage AI Agents with Paperclip
--    3. TGS-2020503207  WSQ - AI Vibe Coding for Multi Agents System
--    4. TGS-2024043854  WSQ - Build a Human-AI Workforce with Autonomous AI Agents
--    5. TGS-2024045806  WSQ - Develop Multi-Agent AI Applications with AutoGen
--    6. TGS-2025059028  WSQ - Build and Deploy Agentic AI Apps with CrewAI, Autogen, ADK and Streamlit
--
-- All TGS-, so the nightly CategoryOrdering sweep preserves the relative
-- order. Business-key lookups only; TGS- SKUs do not exist on partner
-- instances (clean no-op). Idempotent.

SET @multi := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'multi-agents-series' LIMIT 1
);
SET @apps := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1
);
SET @agentic := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'agentic-ai-series' LIMIT 1
);
SET @agents := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-agents-series' LIMIT 1
);
SET @vibe := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-vibe-coding-series' LIMIT 1
);

-- ---------------------------------------------------------------------------
-- 1) Remove the six moved courses from the Multi AI Agents Series.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @multi
  AND p.sku IN (
    'TGS-2025059025', 'TGS-2024045799', 'TGS-2023018987',
    'TGS-2024042309', 'TGS-2024042961', 'TGS-2024045802'
  );

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @multi
  AND p.sku IN (
    'TGS-2025059025', 'TGS-2024045799', 'TGS-2023018987',
    'TGS-2024042309', 'TGS-2024042961', 'TGS-2024045802'
  );

-- ---------------------------------------------------------------------------
-- 2) Attach them to their target series (base + index mirror; INSERT IGNORE
--    is a no-op where already assigned). Position 9999 = end of list; the
--    nightly ordering sweep renumbers.
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @apps, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @apps IS NOT NULL
  AND p.sku = 'TGS-2025059025';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @apps, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @apps IS NOT NULL
  AND p.sku = 'TGS-2025059025'
GROUP BY p.entity_id, s.store_id;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @agentic, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @agentic IS NOT NULL
  AND p.sku = 'TGS-2024045799';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @agentic, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @agentic IS NOT NULL
  AND p.sku = 'TGS-2024045799'
GROUP BY p.entity_id, s.store_id;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @agents, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @agents IS NOT NULL
  AND p.sku IN ('TGS-2023018987', 'TGS-2024042309', 'TGS-2024042961');

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @agents, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @agents IS NOT NULL
  AND p.sku IN ('TGS-2023018987', 'TGS-2024042309', 'TGS-2024042961')
GROUP BY p.entity_id, s.store_id;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @vibe, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @vibe IS NOT NULL
  AND p.sku = 'TGS-2024045802';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @vibe, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @vibe IS NOT NULL
  AND p.sku = 'TGS-2024045802'
GROUP BY p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 3) Pin the requested order (base + index).
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2023036153' THEN -6
  WHEN 'TGS-2023036646' THEN -5
  WHEN 'TGS-2020503207' THEN -4
  WHEN 'TGS-2024043854' THEN -3
  WHEN 'TGS-2024045806' THEN -2
  WHEN 'TGS-2025059028' THEN -1
END
WHERE cp.category_id = @multi
  AND p.sku IN (
    'TGS-2023036153', 'TGS-2023036646', 'TGS-2020503207',
    'TGS-2024043854', 'TGS-2024045806', 'TGS-2025059028'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2023036153' THEN -6
  WHEN 'TGS-2023036646' THEN -5
  WHEN 'TGS-2020503207' THEN -4
  WHEN 'TGS-2024043854' THEN -3
  WHEN 'TGS-2024045806' THEN -2
  WHEN 'TGS-2025059028' THEN -1
END
WHERE i.category_id = @multi
  AND p.sku IN (
    'TGS-2023036153', 'TGS-2023036646', 'TGS-2020503207',
    'TGS-2024043854', 'TGS-2024045806', 'TGS-2025059028'
  );
