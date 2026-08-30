-- 1200: Agentic AI Series — put every WSQ/CASL course at the top, in the
-- order pinned by 1188, with the non-WSQ (C-prefix) courses after them.
--
-- Why this is needed after 1188/1192: four WSQ courses that later migrations
-- added to this category (Business Innovation / Business Transformation /
-- Product Development / HR) landed at position 9999 — i.e. BELOW the whole
-- non-WSQ block — and the nightly sweep only preserves TGS relative order,
-- so they stayed at the bottom. This pins all 17 TGS- rows to 1..17.
--
--    1 TGS-2024045801  WSQ - Agentic AI for Business Process Automation
--    2 TGS-2023035977  WSQ - Agentic AI Automation with n8n
--    3 TGS-2026062147  WSQ - No Code and Low Code Agentic AI Applications
--    4 TGS-2025052468  WSQ - Agentic AI Applications with Claude Code
--    5 TGS-2023041081  WSQ - Agentic AI Applications with Codex
--    6 TGS-2022017520  WSQ - Agentic AI for Market Research
--    7 TGS-2025056988  WSQ - Agentic AI for Digital Marketing
--    8 TGS-2026064473  CASL - Agentic AI for Email Marketing Campaign
--    9 TGS-2020505996  WSQ - Agentic AI for Social Media Marketing
--   10 TGS-2023036657  WSQ - Agentic AI for TikTok Marketing
--   11 TGS-2024052081  WSQ - Automate Video and Voice AI Agents with n8n
--   12 TGS-2023036088  WSQ - Agentic AI for Video Creation
--   13 TGS-2025059028  WSQ - Build and Deploy Agentic AI Apps with CrewAI, Autogen, ADK and Streamlit
--   14 TGS-2023037472  WSQ - Business Innovation with Agentic AI and AI Agents
--   15 TGS-2024049182  WSQ - Business Transformation with Agentic AI and AI Agents
--   16 TGS-2024045799  WSQ - Agentic AI for Product Development
--   17 TGS-2024045795  WSQ - Agentic AI for HR
--
-- The two Copilot WSQ courses (TGS-2022017524, TGS-2023036648) and C803 are
-- NOT pinned here: they have no base row in this category and only surface
-- via anchor inheritance from the child category 'Copilot Studio Agents'.
-- They were moved to the Microsoft Copilot Series (1189/1199) and already
-- live there, so their anchor rows are removed instead of re-sorted.
--
-- Non-WSQ rows are shifted clear of 1..17 so the pinned block is contiguous;
-- their relative order is preserved and the nightly sweep re-normalises the
-- tail. Positive positions only (see 1195). Business-key lookups; TGS- SKUs
-- do not exist on partner instances (clean no-op). Idempotent.

SET @agentic := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'agentic-ai-series' LIMIT 1
);
SET @copilot_child := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'microsoft-copilot-studio-agents' LIMIT 1
);

-- ---------------------------------------------------------------------------
-- 1) Drop the anchor-inherited Copilot rows (they belong to the Microsoft
--    Copilot Series now). Removing the child-category assignments stops the
--    inheritance; the index rows go with them.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @copilot_child
  AND p.sku IN ('TGS-2022017524', 'TGS-2023036648', 'C803');

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id IN (@agentic, @copilot_child)
  AND p.sku IN ('TGS-2022017524', 'TGS-2023036648', 'C803');

-- ---------------------------------------------------------------------------
-- 2) Shift every non-TGS row clear of the pinned range (order preserved).
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 17
WHERE cp.category_id = @agentic
  AND p.sku NOT LIKE 'TGS-%'
  AND cp.position <= 17;

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 17
WHERE i.category_id = @agentic
  AND p.sku NOT LIKE 'TGS-%'
  AND i.position <= 17;

-- ---------------------------------------------------------------------------
-- 3) Pin all 17 WSQ/CASL courses to 1..17.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2024045801' THEN 1
  WHEN 'TGS-2023035977' THEN 2
  WHEN 'TGS-2026062147' THEN 3
  WHEN 'TGS-2025052468' THEN 4
  WHEN 'TGS-2023041081' THEN 5
  WHEN 'TGS-2022017520' THEN 6
  WHEN 'TGS-2025056988' THEN 7
  WHEN 'TGS-2026064473' THEN 8
  WHEN 'TGS-2020505996' THEN 9
  WHEN 'TGS-2023036657' THEN 10
  WHEN 'TGS-2024052081' THEN 11
  WHEN 'TGS-2023036088' THEN 12
  WHEN 'TGS-2025059028' THEN 13
  WHEN 'TGS-2023037472' THEN 14
  WHEN 'TGS-2024049182' THEN 15
  WHEN 'TGS-2024045799' THEN 16
  WHEN 'TGS-2024045795' THEN 17
END
WHERE cp.category_id = @agentic
  AND p.sku IN (
    'TGS-2024045801', 'TGS-2023035977', 'TGS-2026062147', 'TGS-2025052468',
    'TGS-2023041081', 'TGS-2022017520', 'TGS-2025056988', 'TGS-2026064473',
    'TGS-2020505996', 'TGS-2023036657', 'TGS-2024052081', 'TGS-2023036088',
    'TGS-2025059028', 'TGS-2023037472', 'TGS-2024049182', 'TGS-2024045799',
    'TGS-2024045795'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2024045801' THEN 1
  WHEN 'TGS-2023035977' THEN 2
  WHEN 'TGS-2026062147' THEN 3
  WHEN 'TGS-2025052468' THEN 4
  WHEN 'TGS-2023041081' THEN 5
  WHEN 'TGS-2022017520' THEN 6
  WHEN 'TGS-2025056988' THEN 7
  WHEN 'TGS-2026064473' THEN 8
  WHEN 'TGS-2020505996' THEN 9
  WHEN 'TGS-2023036657' THEN 10
  WHEN 'TGS-2024052081' THEN 11
  WHEN 'TGS-2023036088' THEN 12
  WHEN 'TGS-2025059028' THEN 13
  WHEN 'TGS-2023037472' THEN 14
  WHEN 'TGS-2024049182' THEN 15
  WHEN 'TGS-2024045799' THEN 16
  WHEN 'TGS-2024045795' THEN 17
END
WHERE i.category_id = @agentic
  AND p.sku IN (
    'TGS-2024045801', 'TGS-2023035977', 'TGS-2026062147', 'TGS-2025052468',
    'TGS-2023041081', 'TGS-2022017520', 'TGS-2025056988', 'TGS-2026064473',
    'TGS-2020505996', 'TGS-2023036657', 'TGS-2024052081', 'TGS-2023036088',
    'TGS-2025059028', 'TGS-2023037472', 'TGS-2024049182', 'TGS-2024045799',
    'TGS-2024045795'
  );
