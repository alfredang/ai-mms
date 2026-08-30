-- 1195: Re-pin every curated Series order with POSITIVE positions (1..N).
--
-- Supersedes the negative-position pins from 1186/1188/1189/1190/1192/1193/1194.
-- Negative pins are NOT durable on this install: the scheduled daily full
-- reindex (mmd_reindex_scheduled, 03:00 SGT) clamps negative positions to 0
-- in catalog_category_product_index, and the nightly CategoryOrdering sweep
-- (01:00 UTC) then materialises the zeroed tie-order into BOTH tables --
-- observed scrambling generative-ai-series / agentic-ai-series /
-- multi-agents-series on 2026-08-30. Positive positions survive both jobs
-- (the indexer copies them verbatim; the sweep preserves TGS relative order).
--
-- Per category: unpinned TGS- rows sitting inside 1..N are shifted up by N
-- (relative order preserved; the sweep re-normalises the tail nightly), then
-- the pinned SKUs are set to 1..N. Idempotent: after a sweep the pinned rows
-- already hold 1..N and no unpinned row sits inside the range, so every
-- statement is a no-op. Business-key lookups; TGS- SKUs do not exist on
-- partner instances (clean no-op).

-- ===== generative-ai-series (14 pinned) =====

SET @cat := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'generative-ai-series' LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 14
WHERE cp.category_id = @cat
  AND p.sku LIKE 'TGS-%'
  AND cp.position <= 14
  AND p.sku NOT IN (
    'TGS-2023037589',
    'TGS-2025056983',
    'TGS-2026061325',
    'TGS-2020503501',
    'TGS-2023036653',
    'TGS-2024049183',
    'TGS-2024049781',
    'TGS-2026065050',
    'TGS-2025059025',
    'TGS-2024051421',
    'TGS-2024045220',
    'TGS-2024043855',
    'TGS-2020505925',
    'TGS-2026064709'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 14
WHERE i.category_id = @cat
  AND p.sku LIKE 'TGS-%'
  AND i.position <= 14
  AND p.sku NOT IN (
    'TGS-2023037589',
    'TGS-2025056983',
    'TGS-2026061325',
    'TGS-2020503501',
    'TGS-2023036653',
    'TGS-2024049183',
    'TGS-2024049781',
    'TGS-2026065050',
    'TGS-2025059025',
    'TGS-2024051421',
    'TGS-2024045220',
    'TGS-2024043855',
    'TGS-2020505925',
    'TGS-2026064709'
  );

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2023037589' THEN 1
  WHEN 'TGS-2025056983' THEN 2
  WHEN 'TGS-2026061325' THEN 3
  WHEN 'TGS-2020503501' THEN 4
  WHEN 'TGS-2023036653' THEN 5
  WHEN 'TGS-2024049183' THEN 6
  WHEN 'TGS-2024049781' THEN 7
  WHEN 'TGS-2026065050' THEN 8
  WHEN 'TGS-2025059025' THEN 9
  WHEN 'TGS-2024051421' THEN 10
  WHEN 'TGS-2024045220' THEN 11
  WHEN 'TGS-2024043855' THEN 12
  WHEN 'TGS-2020505925' THEN 13
  WHEN 'TGS-2026064709' THEN 14
END
WHERE cp.category_id = @cat
  AND p.sku IN (
    'TGS-2023037589',
    'TGS-2025056983',
    'TGS-2026061325',
    'TGS-2020503501',
    'TGS-2023036653',
    'TGS-2024049183',
    'TGS-2024049781',
    'TGS-2026065050',
    'TGS-2025059025',
    'TGS-2024051421',
    'TGS-2024045220',
    'TGS-2024043855',
    'TGS-2020505925',
    'TGS-2026064709'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2023037589' THEN 1
  WHEN 'TGS-2025056983' THEN 2
  WHEN 'TGS-2026061325' THEN 3
  WHEN 'TGS-2020503501' THEN 4
  WHEN 'TGS-2023036653' THEN 5
  WHEN 'TGS-2024049183' THEN 6
  WHEN 'TGS-2024049781' THEN 7
  WHEN 'TGS-2026065050' THEN 8
  WHEN 'TGS-2025059025' THEN 9
  WHEN 'TGS-2024051421' THEN 10
  WHEN 'TGS-2024045220' THEN 11
  WHEN 'TGS-2024043855' THEN 12
  WHEN 'TGS-2020505925' THEN 13
  WHEN 'TGS-2026064709' THEN 14
END
WHERE i.category_id = @cat
  AND p.sku IN (
    'TGS-2023037589',
    'TGS-2025056983',
    'TGS-2026061325',
    'TGS-2020503501',
    'TGS-2023036653',
    'TGS-2024049183',
    'TGS-2024049781',
    'TGS-2026065050',
    'TGS-2025059025',
    'TGS-2024051421',
    'TGS-2024045220',
    'TGS-2024043855',
    'TGS-2020505925',
    'TGS-2026064709'
  );

-- ===== agentic-ai-series (13 pinned) =====

SET @cat := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'agentic-ai-series' LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 13
WHERE cp.category_id = @cat
  AND p.sku LIKE 'TGS-%'
  AND cp.position <= 13
  AND p.sku NOT IN (
    'TGS-2024045801',
    'TGS-2023035977',
    'TGS-2026062147',
    'TGS-2025052468',
    'TGS-2023041081',
    'TGS-2022017520',
    'TGS-2025056988',
    'TGS-2026064473',
    'TGS-2020505996',
    'TGS-2023036657',
    'TGS-2024052081',
    'TGS-2023036088',
    'TGS-2025059028'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 13
WHERE i.category_id = @cat
  AND p.sku LIKE 'TGS-%'
  AND i.position <= 13
  AND p.sku NOT IN (
    'TGS-2024045801',
    'TGS-2023035977',
    'TGS-2026062147',
    'TGS-2025052468',
    'TGS-2023041081',
    'TGS-2022017520',
    'TGS-2025056988',
    'TGS-2026064473',
    'TGS-2020505996',
    'TGS-2023036657',
    'TGS-2024052081',
    'TGS-2023036088',
    'TGS-2025059028'
  );

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
END
WHERE cp.category_id = @cat
  AND p.sku IN (
    'TGS-2024045801',
    'TGS-2023035977',
    'TGS-2026062147',
    'TGS-2025052468',
    'TGS-2023041081',
    'TGS-2022017520',
    'TGS-2025056988',
    'TGS-2026064473',
    'TGS-2020505996',
    'TGS-2023036657',
    'TGS-2024052081',
    'TGS-2023036088',
    'TGS-2025059028'
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
END
WHERE i.category_id = @cat
  AND p.sku IN (
    'TGS-2024045801',
    'TGS-2023035977',
    'TGS-2026062147',
    'TGS-2025052468',
    'TGS-2023041081',
    'TGS-2022017520',
    'TGS-2025056988',
    'TGS-2026064473',
    'TGS-2020505996',
    'TGS-2023036657',
    'TGS-2024052081',
    'TGS-2023036088',
    'TGS-2025059028'
  );

-- ===== ai-agents-series (10 pinned) =====

SET @cat := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-agents-series' LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 10
WHERE cp.category_id = @cat
  AND p.sku LIKE 'TGS-%'
  AND cp.position <= 10
  AND p.sku NOT IN (
    'TGS-2025054471',
    'TGS-2020503395',
    'TGS-2023018987',
    'TGS-2026064176',
    'TGS-2026064859',
    'TGS-2023036646',
    'TGS-2023036153',
    'TGS-2024043854',
    'TGS-2025053228',
    'TGS-2024042604'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 10
WHERE i.category_id = @cat
  AND p.sku LIKE 'TGS-%'
  AND i.position <= 10
  AND p.sku NOT IN (
    'TGS-2025054471',
    'TGS-2020503395',
    'TGS-2023018987',
    'TGS-2026064176',
    'TGS-2026064859',
    'TGS-2023036646',
    'TGS-2023036153',
    'TGS-2024043854',
    'TGS-2025053228',
    'TGS-2024042604'
  );

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2025054471' THEN 1
  WHEN 'TGS-2020503395' THEN 2
  WHEN 'TGS-2023018987' THEN 3
  WHEN 'TGS-2026064176' THEN 4
  WHEN 'TGS-2026064859' THEN 5
  WHEN 'TGS-2023036646' THEN 6
  WHEN 'TGS-2023036153' THEN 7
  WHEN 'TGS-2024043854' THEN 8
  WHEN 'TGS-2025053228' THEN 9
  WHEN 'TGS-2024042604' THEN 10
END
WHERE cp.category_id = @cat
  AND p.sku IN (
    'TGS-2025054471',
    'TGS-2020503395',
    'TGS-2023018987',
    'TGS-2026064176',
    'TGS-2026064859',
    'TGS-2023036646',
    'TGS-2023036153',
    'TGS-2024043854',
    'TGS-2025053228',
    'TGS-2024042604'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2025054471' THEN 1
  WHEN 'TGS-2020503395' THEN 2
  WHEN 'TGS-2023018987' THEN 3
  WHEN 'TGS-2026064176' THEN 4
  WHEN 'TGS-2026064859' THEN 5
  WHEN 'TGS-2023036646' THEN 6
  WHEN 'TGS-2023036153' THEN 7
  WHEN 'TGS-2024043854' THEN 8
  WHEN 'TGS-2025053228' THEN 9
  WHEN 'TGS-2024042604' THEN 10
END
WHERE i.category_id = @cat
  AND p.sku IN (
    'TGS-2025054471',
    'TGS-2020503395',
    'TGS-2023018987',
    'TGS-2026064176',
    'TGS-2026064859',
    'TGS-2023036646',
    'TGS-2023036153',
    'TGS-2024043854',
    'TGS-2025053228',
    'TGS-2024042604'
  );

-- ===== multi-agents-series (6 pinned) =====

SET @cat := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'multi-agents-series' LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 6
WHERE cp.category_id = @cat
  AND p.sku LIKE 'TGS-%'
  AND cp.position <= 6
  AND p.sku NOT IN (
    'TGS-2023036153',
    'TGS-2023036646',
    'TGS-2020503207',
    'TGS-2024043854',
    'TGS-2024045806',
    'TGS-2025059028'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 6
WHERE i.category_id = @cat
  AND p.sku LIKE 'TGS-%'
  AND i.position <= 6
  AND p.sku NOT IN (
    'TGS-2023036153',
    'TGS-2023036646',
    'TGS-2020503207',
    'TGS-2024043854',
    'TGS-2024045806',
    'TGS-2025059028'
  );

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2023036153' THEN 1
  WHEN 'TGS-2023036646' THEN 2
  WHEN 'TGS-2020503207' THEN 3
  WHEN 'TGS-2024043854' THEN 4
  WHEN 'TGS-2024045806' THEN 5
  WHEN 'TGS-2025059028' THEN 6
END
WHERE cp.category_id = @cat
  AND p.sku IN (
    'TGS-2023036153',
    'TGS-2023036646',
    'TGS-2020503207',
    'TGS-2024043854',
    'TGS-2024045806',
    'TGS-2025059028'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2023036153' THEN 1
  WHEN 'TGS-2023036646' THEN 2
  WHEN 'TGS-2020503207' THEN 3
  WHEN 'TGS-2024043854' THEN 4
  WHEN 'TGS-2024045806' THEN 5
  WHEN 'TGS-2025059028' THEN 6
END
WHERE i.category_id = @cat
  AND p.sku IN (
    'TGS-2023036153',
    'TGS-2023036646',
    'TGS-2020503207',
    'TGS-2024043854',
    'TGS-2024045806',
    'TGS-2025059028'
  );

-- ===== ai-security-series (7 pinned) =====

SET @cat := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-security-series' LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 7
WHERE cp.category_id = @cat
  AND p.sku LIKE 'TGS-%'
  AND cp.position <= 7
  AND p.sku NOT IN (
    'TGS-2023021102',
    'TGS-2026061329',
    'TGS-2023039177',
    'TGS-2024051414',
    'TGS-2025060473',
    'TGS-2025053228',
    'TGS-2024042604'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 7
WHERE i.category_id = @cat
  AND p.sku LIKE 'TGS-%'
  AND i.position <= 7
  AND p.sku NOT IN (
    'TGS-2023021102',
    'TGS-2026061329',
    'TGS-2023039177',
    'TGS-2024051414',
    'TGS-2025060473',
    'TGS-2025053228',
    'TGS-2024042604'
  );

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2023021102' THEN 1
  WHEN 'TGS-2026061329' THEN 2
  WHEN 'TGS-2023039177' THEN 3
  WHEN 'TGS-2024051414' THEN 4
  WHEN 'TGS-2025060473' THEN 5
  WHEN 'TGS-2025053228' THEN 6
  WHEN 'TGS-2024042604' THEN 7
END
WHERE cp.category_id = @cat
  AND p.sku IN (
    'TGS-2023021102',
    'TGS-2026061329',
    'TGS-2023039177',
    'TGS-2024051414',
    'TGS-2025060473',
    'TGS-2025053228',
    'TGS-2024042604'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2023021102' THEN 1
  WHEN 'TGS-2026061329' THEN 2
  WHEN 'TGS-2023039177' THEN 3
  WHEN 'TGS-2024051414' THEN 4
  WHEN 'TGS-2025060473' THEN 5
  WHEN 'TGS-2025053228' THEN 6
  WHEN 'TGS-2024042604' THEN 7
END
WHERE i.category_id = @cat
  AND p.sku IN (
    'TGS-2023021102',
    'TGS-2026061329',
    'TGS-2023039177',
    'TGS-2024051414',
    'TGS-2025060473',
    'TGS-2025053228',
    'TGS-2024042604'
  );

-- ===== claude-ai-series (3 pinned) =====

SET @cat := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'claude-ai-series' LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 3
WHERE cp.category_id = @cat
  AND p.sku LIKE 'TGS-%'
  AND cp.position <= 3
  AND p.sku NOT IN (
    'TGS-2025052468',
    'TGS-2026061312',
    'TGS-2023018659'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 3
WHERE i.category_id = @cat
  AND p.sku LIKE 'TGS-%'
  AND i.position <= 3
  AND p.sku NOT IN (
    'TGS-2025052468',
    'TGS-2026061312',
    'TGS-2023018659'
  );

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2025052468' THEN 1
  WHEN 'TGS-2026061312' THEN 2
  WHEN 'TGS-2023018659' THEN 3
END
WHERE cp.category_id = @cat
  AND p.sku IN (
    'TGS-2025052468',
    'TGS-2026061312',
    'TGS-2023018659'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2025052468' THEN 1
  WHEN 'TGS-2026061312' THEN 2
  WHEN 'TGS-2023018659' THEN 3
END
WHERE i.category_id = @cat
  AND p.sku IN (
    'TGS-2025052468',
    'TGS-2026061312',
    'TGS-2023018659'
  );

-- ===== microsoft-copilot-series (3 pinned) =====

SET @cat := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'microsoft-copilot-series' LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 3
WHERE cp.category_id = @cat
  AND p.sku LIKE 'TGS-%'
  AND cp.position <= 3
  AND p.sku NOT IN (
    'TGS-2024043856',
    'TGS-2022017524',
    'TGS-2023036648'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 3
WHERE i.category_id = @cat
  AND p.sku LIKE 'TGS-%'
  AND i.position <= 3
  AND p.sku NOT IN (
    'TGS-2024043856',
    'TGS-2022017524',
    'TGS-2023036648'
  );

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2024043856' THEN 1
  WHEN 'TGS-2022017524' THEN 2
  WHEN 'TGS-2023036648' THEN 3
END
WHERE cp.category_id = @cat
  AND p.sku IN (
    'TGS-2024043856',
    'TGS-2022017524',
    'TGS-2023036648'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2024043856' THEN 1
  WHEN 'TGS-2022017524' THEN 2
  WHEN 'TGS-2023036648' THEN 3
END
WHERE i.category_id = @cat
  AND p.sku IN (
    'TGS-2024043856',
    'TGS-2022017524',
    'TGS-2023036648'
  );

