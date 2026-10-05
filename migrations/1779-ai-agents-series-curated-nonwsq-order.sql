-- 1779: Curated non-WSQ (C-prefix) order in the AI Agents Series category
-- (url_key ai-agents-series), per the owner's requested sequence:
--   101. C690 — AI Agents for SMEs
--   102. C997 — Business Transformation with AI Agents
--   103. C691 — Business Transformation with OpenClaw Digital Employees
--   104. C814 — Creating AI Agents and Chatbots with Microsoft Copilot Studio
--   105. C1871 — AI Agent with Hermes Agent
--   106. C1434 — AI Agent with Openclaw
--   107. C1259 — AI Agents with Gemini Spark
--   108. C177 — AI Agents for Stock Trading
--   109. C28 — AI Agent Security
--   110. C1440 — AI Security and Governance
--   111. C926 — AI-103 Microsoft Certified Azure AI Apps and Agents Developer Associate
--   112. C1760 — AB-620 Microsoft Certified AI Agent Builder Associate
--   113. C711 — AB-731 Microsoft Certified AI Transformation Leader
--
-- ai-agents-series is already listed in mmd/category_ordering/curated_url_keys,
-- so the daily sweep keeps these rows in their written position order (and
-- still keeps the TGS- block, pinned 1..21 by 1778, above them). All 13 have
-- direct base rows on this category (verified on SG prod 2026-10-05). Positive
-- positions 101+ in both tables. Business-key lookups; no-op where the
-- category or a SKU is absent. Idempotent.

SET @ai_agents_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'ai-agents-series'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE TRIM(p.sku)
  WHEN 'C690' THEN 101
  WHEN 'C997' THEN 102
  WHEN 'C691' THEN 103
  WHEN 'C814' THEN 104
  WHEN 'C1871' THEN 105
  WHEN 'C1434' THEN 106
  WHEN 'C1259' THEN 107
  WHEN 'C177' THEN 108
  WHEN 'C28' THEN 109
  WHEN 'C1440' THEN 110
  WHEN 'C926' THEN 111
  WHEN 'C1760' THEN 112
  WHEN 'C711' THEN 113
END
WHERE cp.category_id = @ai_agents_category
  AND TRIM(p.sku) IN (
    'C690',
    'C997',
    'C691',
    'C814',
    'C1871',
    'C1434',
    'C1259',
    'C177',
    'C28',
    'C1440',
    'C926',
    'C1760',
    'C711'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE TRIM(p.sku)
  WHEN 'C690' THEN 101
  WHEN 'C997' THEN 102
  WHEN 'C691' THEN 103
  WHEN 'C814' THEN 104
  WHEN 'C1871' THEN 105
  WHEN 'C1434' THEN 106
  WHEN 'C1259' THEN 107
  WHEN 'C177' THEN 108
  WHEN 'C28' THEN 109
  WHEN 'C1440' THEN 110
  WHEN 'C926' THEN 111
  WHEN 'C1760' THEN 112
  WHEN 'C711' THEN 113
END
WHERE i.category_id = @ai_agents_category
  AND TRIM(p.sku) IN (
    'C690',
    'C997',
    'C691',
    'C814',
    'C1871',
    'C1434',
    'C1259',
    'C177',
    'C28',
    'C1440',
    'C926',
    'C1760',
    'C711'
  );
