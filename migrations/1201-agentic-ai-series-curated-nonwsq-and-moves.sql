-- 1201: Agentic AI Series — curated non-WSQ order + non-WSQ moves out.
--
-- A) Add 'agentic-ai-series' to mmd/category_ordering/curated_url_keys so the
--    nightly sweep stops re-alphabetising its non-WSQ rows (WSQ-first is
--    still enforced). Appends to the existing value rather than replacing it.
--
-- B) Move these non-WSQ courses OUT of the Agentic AI Series:
--      -> AI Agents Series        : C690, C814, C1760
--      -> Multi AI Agents Series  : C20, C765
--      -> AI Applications Series  : C1018, C817, C155
--      -> Microsoft Copilot Series: C590, C814, C1768, C1760
--      -> Claude AI Series        : C1382, C1417
--      -> Codex AI Series         : C427
--    (C814 and C1760 go to TWO destinations each, as requested. C1756
--    AB-100 explicitly STAYS in the Agentic AI Series.)
--    C1018 'AI for Healthcare' is also added to the AI for Healthcare
--    subcategory.
--
--    In every destination the moved course is appended AFTER the existing
--    rows, which already sit after that category's WSQ/CASL block — the
--    sweep sorts TGS- first regardless of position, so WSQ/CASL/IBF stay on
--    top there.
--
-- C) Pin the requested 14-course non-WSQ order in the Agentic AI Series at
--    positions 101..114 — after all 17 TGS- rows (pinned 1..17 by 1200).
--
-- Positive positions only (negative pins die — see 1195). Business-key
-- lookups; these SKUs/url_keys are SG-only (clean partner no-op). Idempotent.

SET @agentic := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'agentic-ai-series' LIMIT 1
);
SET @agentic_child := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'n8n-ai-automations-courses' LIMIT 1
);

-- ===== A: extend the curated-order exemption to this category =====

UPDATE core_config_data
SET value = CONCAT(value, ',agentic-ai-series')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%agentic-ai-series%';

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'default', 0, 'mmd/category_ordering/curated_url_keys', 'agentic-ai-series'
FROM dual
WHERE NOT EXISTS (
  SELECT 1 FROM (SELECT * FROM core_config_data) c
  WHERE c.path = 'mmd/category_ordering/curated_url_keys'
    AND c.scope = 'default' AND c.scope_id = 0
);

-- ===== B: remove the moved courses from the series + its child category =====

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id IN (@agentic, @agentic_child)
  AND p.sku IN (
    'C1018',
    'C1382',
    'C1417',
    'C155',
    'C1760',
    'C1768',
    'C20',
    'C427',
    'C590',
    'C690',
    'C765',
    'C814',
    'C817'
  );

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id IN (@agentic, @agentic_child)
  AND p.sku IN (
    'C1018',
    'C1382',
    'C1417',
    'C155',
    'C1760',
    'C1768',
    'C20',
    'C427',
    'C590',
    'C690',
    'C765',
    'C814',
    'C817'
  );

SET @t_ai_agents_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-agents-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_ai_agents_series, p.entity_id,
       COALESCE((SELECT MAX(cp2.position) FROM (SELECT * FROM catalog_category_product) cp2
                 WHERE cp2.category_id = @t_ai_agents_series), 0) + 1
FROM catalog_product_entity p
WHERE @t_ai_agents_series IS NOT NULL
  AND p.sku IN (
    'C690',
    'C814',
    'C1760'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_ai_agents_series, p.entity_id,
       COALESCE((SELECT MAX(i2.position) FROM (SELECT * FROM catalog_category_product_index) i2
                 WHERE i2.category_id = @t_ai_agents_series AND i2.store_id = s.store_id), 0) + 1,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_ai_agents_series IS NOT NULL
  AND p.sku IN (
    'C690',
    'C814',
    'C1760'
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
    'C765'
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
    'C765'
  )
GROUP BY p.entity_id, s.store_id;

SET @t_ai_applications_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_ai_applications_series, p.entity_id,
       COALESCE((SELECT MAX(cp2.position) FROM (SELECT * FROM catalog_category_product) cp2
                 WHERE cp2.category_id = @t_ai_applications_series), 0) + 1
FROM catalog_product_entity p
WHERE @t_ai_applications_series IS NOT NULL
  AND p.sku IN (
    'C1018',
    'C817',
    'C155'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_ai_applications_series, p.entity_id,
       COALESCE((SELECT MAX(i2.position) FROM (SELECT * FROM catalog_category_product_index) i2
                 WHERE i2.category_id = @t_ai_applications_series AND i2.store_id = s.store_id), 0) + 1,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_ai_applications_series IS NOT NULL
  AND p.sku IN (
    'C1018',
    'C817',
    'C155'
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
    'C590',
    'C814',
    'C1768',
    'C1760'
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
    'C590',
    'C814',
    'C1768',
    'C1760'
  )
GROUP BY p.entity_id, s.store_id;

SET @t_claude_ai_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'claude-ai-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_claude_ai_series, p.entity_id,
       COALESCE((SELECT MAX(cp2.position) FROM (SELECT * FROM catalog_category_product) cp2
                 WHERE cp2.category_id = @t_claude_ai_series), 0) + 1
FROM catalog_product_entity p
WHERE @t_claude_ai_series IS NOT NULL
  AND p.sku IN (
    'C1382',
    'C1417'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_claude_ai_series, p.entity_id,
       COALESCE((SELECT MAX(i2.position) FROM (SELECT * FROM catalog_category_product_index) i2
                 WHERE i2.category_id = @t_claude_ai_series AND i2.store_id = s.store_id), 0) + 1,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_claude_ai_series IS NOT NULL
  AND p.sku IN (
    'C1382',
    'C1417'
  )
GROUP BY p.entity_id, s.store_id;

SET @t_codex_ai_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'codex-ai-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_codex_ai_series, p.entity_id,
       COALESCE((SELECT MAX(cp2.position) FROM (SELECT * FROM catalog_category_product) cp2
                 WHERE cp2.category_id = @t_codex_ai_series), 0) + 1
FROM catalog_product_entity p
WHERE @t_codex_ai_series IS NOT NULL
  AND p.sku IN (
    'C427'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_codex_ai_series, p.entity_id,
       COALESCE((SELECT MAX(i2.position) FROM (SELECT * FROM catalog_category_product_index) i2
                 WHERE i2.category_id = @t_codex_ai_series AND i2.store_id = s.store_id), 0) + 1,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_codex_ai_series IS NOT NULL
  AND p.sku IN (
    'C427'
  )
GROUP BY p.entity_id, s.store_id;

SET @t_ai_for_healthcare_courses := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-for-healthcare-courses' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_ai_for_healthcare_courses, p.entity_id,
       COALESCE((SELECT MAX(cp2.position) FROM (SELECT * FROM catalog_category_product) cp2
                 WHERE cp2.category_id = @t_ai_for_healthcare_courses), 0) + 1
FROM catalog_product_entity p
WHERE @t_ai_for_healthcare_courses IS NOT NULL
  AND p.sku IN (
    'C1018'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_ai_for_healthcare_courses, p.entity_id,
       COALESCE((SELECT MAX(i2.position) FROM (SELECT * FROM catalog_category_product_index) i2
                 WHERE i2.category_id = @t_ai_for_healthcare_courses AND i2.store_id = s.store_id), 0) + 1,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_ai_for_healthcare_courses IS NOT NULL
  AND p.sku IN (
    'C1018'
  )
GROUP BY p.entity_id, s.store_id;

-- ===== C: pin the curated non-WSQ order (101..114), after the TGS block =====

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C209' THEN 101
  WHEN 'C735' THEN 102
  WHEN 'C978' THEN 103
  WHEN 'C1798' THEN 104
  WHEN 'C21' THEN 105
  WHEN 'C526' THEN 106
  WHEN 'C695' THEN 107
  WHEN 'C386' THEN 108
  WHEN 'C355' THEN 109
  WHEN 'C436' THEN 110
  WHEN 'C500' THEN 111
  WHEN 'C057' THEN 112
  WHEN 'C852' THEN 113
  WHEN 'C1756' THEN 114
END
WHERE cp.category_id = @agentic
  AND p.sku IN (
    'C209',
    'C735',
    'C978',
    'C1798',
    'C21',
    'C526',
    'C695',
    'C386',
    'C355',
    'C436',
    'C500',
    'C057',
    'C852',
    'C1756'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C209' THEN 101
  WHEN 'C735' THEN 102
  WHEN 'C978' THEN 103
  WHEN 'C1798' THEN 104
  WHEN 'C21' THEN 105
  WHEN 'C526' THEN 106
  WHEN 'C695' THEN 107
  WHEN 'C386' THEN 108
  WHEN 'C355' THEN 109
  WHEN 'C436' THEN 110
  WHEN 'C500' THEN 111
  WHEN 'C057' THEN 112
  WHEN 'C852' THEN 113
  WHEN 'C1756' THEN 114
END
WHERE i.category_id = @agentic
  AND p.sku IN (
    'C209',
    'C735',
    'C978',
    'C1798',
    'C21',
    'C526',
    'C695',
    'C386',
    'C355',
    'C436',
    'C500',
    'C057',
    'C852',
    'C1756'
  );

