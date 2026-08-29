-- 1188: Agentic AI Series curation.
--
-- 1) Move CASL - AI Agents with Gemini Spark (TGS-2026064173) out of the
--    Agentic AI Series and into the AI Agents Series (it was already added
--    there by migration 1186; the INSERT below is a defensive no-op).
--
-- 2) Pin the requested WSQ/CASL order at the top of the Agentic AI Series:
--     1. TGS-2024045801  WSQ - Agentic AI for Business Process Automation
--     2. TGS-2023035977  WSQ - Agentic AI Automation with n8n
--     3. TGS-2026062147  WSQ - No Code and Low Code Agentic AI Applications
--     4. TGS-2025052468  WSQ - Agentic AI Applications with Claude Code
--     5. TGS-2023041081  WSQ - Agentic AI Applications with Codex
--     6. TGS-2022017520  WSQ - Agentic AI for Market Research
--     7. TGS-2025056988  WSQ - Agentic AI for Digital Marketing
--     8. TGS-2026064473  CASL - Agentic AI for Email Marketing Campaign
--     9. TGS-2020505996  WSQ - Agentic AI for Social Media Marketing
--    10. TGS-2023036657  WSQ - Agentic AI for TikTok Marketing
--    11. TGS-2024052081  WSQ - Automate Video and Voice AI Agents with n8n
--    12. TGS-2023036088  WSQ - Agentic AI for Video Creation
--    13. TGS-2025059028  WSQ - Build and Deploy Agentic AI Apps with CrewAI, Autogen, ADK and Streamlit
--
-- All pinned SKUs are TGS-, so the nightly CategoryOrdering sweep preserves
-- their relative order; remaining TGS- courses keep their relative order after
-- this block, and non-WSQ C-prefix stay alphabetical below. Business-key
-- lookups only; TGS- SKUs do not exist on partner instances (clean no-op).
-- Idempotent.

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

-- ---------------------------------------------------------------------------
-- 1) Gemini Spark: out of Agentic AI Series, into AI Agents Series.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @agentic
  AND p.sku = 'TGS-2026064173';

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @agentic
  AND p.sku = 'TGS-2026064173';

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @agents, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @agents IS NOT NULL
  AND p.sku = 'TGS-2026064173';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @agents, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @agents IS NOT NULL
  AND p.sku = 'TGS-2026064173'
GROUP BY p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 2) Pin the requested order (base + index).
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2024045801' THEN -13
  WHEN 'TGS-2023035977' THEN -12
  WHEN 'TGS-2026062147' THEN -11
  WHEN 'TGS-2025052468' THEN -10
  WHEN 'TGS-2023041081' THEN -9
  WHEN 'TGS-2022017520' THEN -8
  WHEN 'TGS-2025056988' THEN -7
  WHEN 'TGS-2026064473' THEN -6
  WHEN 'TGS-2020505996' THEN -5
  WHEN 'TGS-2023036657' THEN -4
  WHEN 'TGS-2024052081' THEN -3
  WHEN 'TGS-2023036088' THEN -2
  WHEN 'TGS-2025059028' THEN -1
END
WHERE cp.category_id = @agentic
  AND p.sku IN (
    'TGS-2024045801', 'TGS-2023035977', 'TGS-2026062147', 'TGS-2025052468',
    'TGS-2023041081', 'TGS-2022017520', 'TGS-2025056988', 'TGS-2026064473',
    'TGS-2020505996', 'TGS-2023036657', 'TGS-2024052081', 'TGS-2023036088',
    'TGS-2025059028'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2024045801' THEN -13
  WHEN 'TGS-2023035977' THEN -12
  WHEN 'TGS-2026062147' THEN -11
  WHEN 'TGS-2025052468' THEN -10
  WHEN 'TGS-2023041081' THEN -9
  WHEN 'TGS-2022017520' THEN -8
  WHEN 'TGS-2025056988' THEN -7
  WHEN 'TGS-2026064473' THEN -6
  WHEN 'TGS-2020505996' THEN -5
  WHEN 'TGS-2023036657' THEN -4
  WHEN 'TGS-2024052081' THEN -3
  WHEN 'TGS-2023036088' THEN -2
  WHEN 'TGS-2025059028' THEN -1
END
WHERE i.category_id = @agentic
  AND p.sku IN (
    'TGS-2024045801', 'TGS-2023035977', 'TGS-2026062147', 'TGS-2025052468',
    'TGS-2023041081', 'TGS-2022017520', 'TGS-2025056988', 'TGS-2026064473',
    'TGS-2020505996', 'TGS-2023036657', 'TGS-2024052081', 'TGS-2023036088',
    'TGS-2025059028'
  );
