-- 1199: Generative AI Series — curated non-WSQ order + non-WSQ moves.
--
-- A) Seed mmd/category_ordering/curated_url_keys so the nightly
--    CategoryOrdering sweep stops re-alphabetising this category's non-WSQ
--    rows (WSQ-first is still enforced; see the matching cron change in
--    MMD_RoleManager_Model_Cron_CategoryOrdering). Without this the curated
--    C-order below is flattened back to alphabetical within a day.
--
-- B) Move these non-WSQ courses out of the Generative AI Series (and out of
--    its child categories, which anchor-feed the listing):
--      -> Agentic AI Series       : C978, C436, C057, C155, C817
--      -> AI Agents Series        : C1259
--      -> AI Applications Series  : C820, C057
--      -> Microsoft Copilot Series: C027, C34, C734, C590, C803, C1768, C811, C903
--      -> Claude AI Series        : C197, C201
--    (C057 goes to BOTH Agentic AI and AI Applications, as requested.)
--
-- C) Pin the requested 17-course non-WSQ order AFTER every TGS- course:
--    positions 101..117, above the TGS block's 1..N but below nothing else —
--    the sweep sorts TGS- first regardless of position, then honours these
--    positions for the curated non-WSQ rows.
--
-- Positive positions only (negative pins die — see 1195). Business-key
-- lookups; these SKUs/url_keys are SG-only (clean partner no-op). Idempotent.

SET @gen := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'generative-ai-series' LIMIT 1
);
SET @ch_chatgpt_and_generative_a := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'chatgpt-and-generative-ai-courses' LIMIT 1
);
SET @ch_genai_video_creation := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'genai-video-creation' LIMIT 1
);
SET @ch_prompt_engineering_cours := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'prompt-engineering-courses' LIMIT 1
);

-- ===== A: curated-order exemption for this category =====

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'default', 0, 'mmd/category_ordering/curated_url_keys', 'generative-ai-series'
FROM dual
WHERE NOT EXISTS (
  SELECT 1 FROM (SELECT * FROM core_config_data) c
  WHERE c.path = 'mmd/category_ordering/curated_url_keys'
    AND c.scope = 'default' AND c.scope_id = 0
);

UPDATE core_config_data
SET value = 'generative-ai-series'
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND (value IS NULL OR value = '');

-- ===== B: remove the moved non-WSQ courses from the series + its children =====

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id IN (@gen, @ch_chatgpt_and_generative_a, @ch_genai_video_creation, @ch_prompt_engineering_cours)
  AND p.sku IN (
    'C027',
    'C057',
    'C1259',
    'C155',
    'C1768',
    'C197',
    'C201',
    'C34',
    'C436',
    'C590',
    'C734',
    'C803',
    'C811',
    'C817',
    'C820',
    'C903',
    'C978'
  );

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id IN (@gen, @ch_chatgpt_and_generative_a, @ch_genai_video_creation, @ch_prompt_engineering_cours)
  AND p.sku IN (
    'C027',
    'C057',
    'C1259',
    'C155',
    'C1768',
    'C197',
    'C201',
    'C34',
    'C436',
    'C590',
    'C734',
    'C803',
    'C811',
    'C817',
    'C820',
    'C903',
    'C978'
  );

SET @t_agentic_ai_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'agentic-ai-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_agentic_ai_series, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @t_agentic_ai_series IS NOT NULL
  AND p.sku IN (
    'C978',
    'C436',
    'C057',
    'C155',
    'C817'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_agentic_ai_series, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_agentic_ai_series IS NOT NULL
  AND p.sku IN (
    'C978',
    'C436',
    'C057',
    'C155',
    'C817'
  )
GROUP BY p.entity_id, s.store_id;

SET @t_ai_agents_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-agents-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_ai_agents_series, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @t_ai_agents_series IS NOT NULL
  AND p.sku IN (
    'C1259'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_ai_agents_series, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_ai_agents_series IS NOT NULL
  AND p.sku IN (
    'C1259'
  )
GROUP BY p.entity_id, s.store_id;

SET @t_ai_applications_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_ai_applications_series, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @t_ai_applications_series IS NOT NULL
  AND p.sku IN (
    'C820',
    'C057'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_ai_applications_series, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_ai_applications_series IS NOT NULL
  AND p.sku IN (
    'C820',
    'C057'
  )
GROUP BY p.entity_id, s.store_id;

SET @t_microsoft_copilot_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'microsoft-copilot-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_microsoft_copilot_series, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @t_microsoft_copilot_series IS NOT NULL
  AND p.sku IN (
    'C027',
    'C34',
    'C734',
    'C590',
    'C803',
    'C1768',
    'C811',
    'C903'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_microsoft_copilot_series, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_microsoft_copilot_series IS NOT NULL
  AND p.sku IN (
    'C027',
    'C34',
    'C734',
    'C590',
    'C803',
    'C1768',
    'C811',
    'C903'
  )
GROUP BY p.entity_id, s.store_id;

SET @t_claude_ai_series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'claude-ai-series' LIMIT 1
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @t_claude_ai_series, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @t_claude_ai_series IS NOT NULL
  AND p.sku IN (
    'C197',
    'C201'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @t_claude_ai_series, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @t_claude_ai_series IS NOT NULL
  AND p.sku IN (
    'C197',
    'C201'
  )
GROUP BY p.entity_id, s.store_id;

-- ===== C: pin the curated non-WSQ order (101..117) =====

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C329' THEN 101
  WHEN 'C924' THEN 102
  WHEN 'C013' THEN 103
  WHEN 'C324' THEN 104
  WHEN 'C1234' THEN 105
  WHEN 'C688' THEN 106
  WHEN 'C1276' THEN 107
  WHEN 'C11' THEN 108
  WHEN 'C1468' THEN 109
  WHEN 'C1176' THEN 110
  WHEN 'C802' THEN 111
  WHEN 'C16' THEN 112
  WHEN 'C152' THEN 113
  WHEN 'C1373' THEN 114
  WHEN 'C037' THEN 115
  WHEN 'C162' THEN 116
  WHEN 'C1311' THEN 117
END
WHERE cp.category_id = @gen
  AND p.sku IN (
    'C329',
    'C924',
    'C013',
    'C324',
    'C1234',
    'C688',
    'C1276',
    'C11',
    'C1468',
    'C1176',
    'C802',
    'C16',
    'C152',
    'C1373',
    'C037',
    'C162',
    'C1311'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C329' THEN 101
  WHEN 'C924' THEN 102
  WHEN 'C013' THEN 103
  WHEN 'C324' THEN 104
  WHEN 'C1234' THEN 105
  WHEN 'C688' THEN 106
  WHEN 'C1276' THEN 107
  WHEN 'C11' THEN 108
  WHEN 'C1468' THEN 109
  WHEN 'C1176' THEN 110
  WHEN 'C802' THEN 111
  WHEN 'C16' THEN 112
  WHEN 'C152' THEN 113
  WHEN 'C1373' THEN 114
  WHEN 'C037' THEN 115
  WHEN 'C162' THEN 116
  WHEN 'C1311' THEN 117
END
WHERE i.category_id = @gen
  AND p.sku IN (
    'C329',
    'C924',
    'C013',
    'C324',
    'C1234',
    'C688',
    'C1276',
    'C11',
    'C1468',
    'C1176',
    'C802',
    'C16',
    'C152',
    'C1373',
    'C037',
    'C162',
    'C1311'
  );

