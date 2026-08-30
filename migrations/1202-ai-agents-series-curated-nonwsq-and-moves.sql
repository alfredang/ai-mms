-- 1202: AI Agents Series — curated non-WSQ order + non-WSQ moves out.
--
-- A) Add 'ai-agents-series' to mmd/category_ordering/curated_url_keys so the
--    nightly sweep (and the post-reindex repair) keep the curated non-WSQ
--    order instead of re-alphabetising it. WSQ-first is still enforced.
--
-- B) Move these non-WSQ courses OUT of the AI Agents Series:
--      -> Agentic AI Series       : C500  (Voice and Video Agents with n8n)
--      -> Multi AI Agents Series  : C20, C349, C1164, C1034, C765, C829, C991
--      -> AI Vibe Coding Series   : C349  (also, as requested)
--      -> Microsoft Copilot Series: C814  (Copilot Studio chatbots)
--    Each destination appends AFTER its existing rows, which already sit
--    below that category's WSQ/CASL block (the sweep sorts TGS- first
--    regardless of position), so WSQ/CASL/IBF stay on top there.
--
-- C) Pin the requested 9-course non-WSQ order at positions 101..109 — after
--    every TGS- course (the WSQ/CASL block is pinned 1..16 by 1189).
--    AB-620 (C1760) stays here per this request; it also remains in the
--    Microsoft Copilot Series where 1201 placed it.
--
-- Positive positions only (negative pins die — see 1195). Business-key
-- lookups; SG-only SKUs/url_keys (clean partner no-op). Idempotent.

SET @agents := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-agents-series' LIMIT 1
);

-- ===== A: extend the curated-order exemption =====

UPDATE core_config_data
SET value = CONCAT(value, ',ai-agents-series')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%ai-agents-series%';

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'default', 0, 'mmd/category_ordering/curated_url_keys', 'ai-agents-series'
FROM dual
WHERE NOT EXISTS (
  SELECT 1 FROM (SELECT * FROM core_config_data) c
  WHERE c.path = 'mmd/category_ordering/curated_url_keys'
    AND c.scope = 'default' AND c.scope_id = 0
);

-- ===== B: remove the moved courses from this series =====

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @agents
  AND p.sku IN (
    'C1034',
    'C1164',
    'C20',
    'C349',
    'C500',
    'C765',
    'C814',
    'C829',
    'C991'
  );

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @agents
  AND p.sku IN (
    'C1034',
    'C1164',
    'C20',
    'C349',
    'C500',
    'C765',
    'C814',
    'C829',
    'C991'
  );

SET @t_agentic_ai_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'agentic-ai-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_agentic_ai_series, p.entity_id,
       COALESCE((SELECT MAX(cp2.position) FROM (SELECT * FROM catalog_category_product) cp2
                 WHERE cp2.category_id = @t_agentic_ai_series), 0) + 1
FROM catalog_product_entity p
WHERE @t_agentic_ai_series IS NOT NULL
  AND p.sku IN (
    'C500'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_agentic_ai_series, p.entity_id,
       COALESCE((SELECT MAX(i2.position) FROM (SELECT * FROM catalog_category_product_index) i2
                 WHERE i2.category_id = @t_agentic_ai_series AND i2.store_id = s.store_id), 0) + 1,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_agentic_ai_series IS NOT NULL
  AND p.sku IN (
    'C500'
  )
GROUP BY p.entity_id, s.store_id;

SET @t_multi_agents_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'multi-agents-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_multi_agents_series, p.entity_id,
       COALESCE((SELECT MAX(cp2.position) FROM (SELECT * FROM catalog_category_product) cp2
                 WHERE cp2.category_id = @t_multi_agents_series), 0) + 1
FROM catalog_product_entity p
WHERE @t_multi_agents_series IS NOT NULL
  AND p.sku IN (
    'C20',
    'C349',
    'C1164',
    'C1034',
    'C765',
    'C829',
    'C991'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_multi_agents_series, p.entity_id,
       COALESCE((SELECT MAX(i2.position) FROM (SELECT * FROM catalog_category_product_index) i2
                 WHERE i2.category_id = @t_multi_agents_series AND i2.store_id = s.store_id), 0) + 1,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_multi_agents_series IS NOT NULL
  AND p.sku IN (
    'C20',
    'C349',
    'C1164',
    'C1034',
    'C765',
    'C829',
    'C991'
  )
GROUP BY p.entity_id, s.store_id;

SET @t_ai_vibe_coding_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-vibe-coding-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_ai_vibe_coding_series, p.entity_id,
       COALESCE((SELECT MAX(cp2.position) FROM (SELECT * FROM catalog_category_product) cp2
                 WHERE cp2.category_id = @t_ai_vibe_coding_series), 0) + 1
FROM catalog_product_entity p
WHERE @t_ai_vibe_coding_series IS NOT NULL
  AND p.sku IN (
    'C349'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_ai_vibe_coding_series, p.entity_id,
       COALESCE((SELECT MAX(i2.position) FROM (SELECT * FROM catalog_category_product_index) i2
                 WHERE i2.category_id = @t_ai_vibe_coding_series AND i2.store_id = s.store_id), 0) + 1,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_ai_vibe_coding_series IS NOT NULL
  AND p.sku IN (
    'C349'
  )
GROUP BY p.entity_id, s.store_id;

SET @t_microsoft_copilot_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'microsoft-copilot-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_microsoft_copilot_series, p.entity_id,
       COALESCE((SELECT MAX(cp2.position) FROM (SELECT * FROM catalog_category_product) cp2
                 WHERE cp2.category_id = @t_microsoft_copilot_series), 0) + 1
FROM catalog_product_entity p
WHERE @t_microsoft_copilot_series IS NOT NULL
  AND p.sku IN (
    'C814'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_microsoft_copilot_series, p.entity_id,
       COALESCE((SELECT MAX(i2.position) FROM (SELECT * FROM catalog_category_product_index) i2
                 WHERE i2.category_id = @t_microsoft_copilot_series AND i2.store_id = s.store_id), 0) + 1,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_microsoft_copilot_series IS NOT NULL
  AND p.sku IN (
    'C814'
  )
GROUP BY p.entity_id, s.store_id;

-- ===== C: pin the curated non-WSQ order (101..109) =====

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C690' THEN 101
  WHEN 'C1871' THEN 102
  WHEN 'C1434' THEN 103
  WHEN 'C691' THEN 104
  WHEN 'C1259' THEN 105
  WHEN 'C177' THEN 106
  WHEN 'C1440' THEN 107
  WHEN 'C1760' THEN 108
  WHEN 'C926' THEN 109
END
WHERE cp.category_id = @agents
  AND p.sku IN (
    'C690',
    'C1871',
    'C1434',
    'C691',
    'C1259',
    'C177',
    'C1440',
    'C1760',
    'C926'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C690' THEN 101
  WHEN 'C1871' THEN 102
  WHEN 'C1434' THEN 103
  WHEN 'C691' THEN 104
  WHEN 'C1259' THEN 105
  WHEN 'C177' THEN 106
  WHEN 'C1440' THEN 107
  WHEN 'C1760' THEN 108
  WHEN 'C926' THEN 109
END
WHERE i.category_id = @agents
  AND p.sku IN (
    'C690',
    'C1871',
    'C1434',
    'C691',
    'C1259',
    'C177',
    'C1440',
    'C1760',
    'C926'
  );

