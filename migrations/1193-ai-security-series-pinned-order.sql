-- 1193: Pin the requested WSQ course order in the AI Security Series:
--   1. TGS-2023021102  WSQ - Fundamentals of AI Ethics and Responsible AI
--   2. TGS-2026061329  WSQ - AI Security Governance for Businesses
--   3. TGS-2023039177  WSQ - AI for Cyber Security
--   4. TGS-2024051414  WSQ - AI for Network Security
--   5. TGS-2025060473  WSQ - AI Security for Autonomous AI Agents
--   6. TGS-2025053228  WSQ - AI Agent Cybersecurity
--   7. TGS-2024042604  WSQ - Security Operations for Autonomous AI Agents
--
-- WSQ - AI Security Awareness stays in the category, unpinned (sorts after
-- the pinned block). All TGS-, so the nightly CategoryOrdering sweep
-- preserves relative order. Business-key lookups; TGS- SKUs do not exist on
-- partner instances (clean no-op). Idempotent.

SET @security := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-security-series' LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2023021102' THEN -7
  WHEN 'TGS-2026061329' THEN -6
  WHEN 'TGS-2023039177' THEN -5
  WHEN 'TGS-2024051414' THEN -4
  WHEN 'TGS-2025060473' THEN -3
  WHEN 'TGS-2025053228' THEN -2
  WHEN 'TGS-2024042604' THEN -1
END
WHERE cp.category_id = @security
  AND p.sku IN (
    'TGS-2023021102', 'TGS-2026061329', 'TGS-2023039177', 'TGS-2024051414',
    'TGS-2025060473', 'TGS-2025053228', 'TGS-2024042604'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2023021102' THEN -7
  WHEN 'TGS-2026061329' THEN -6
  WHEN 'TGS-2023039177' THEN -5
  WHEN 'TGS-2024051414' THEN -4
  WHEN 'TGS-2025060473' THEN -3
  WHEN 'TGS-2025053228' THEN -2
  WHEN 'TGS-2024042604' THEN -1
END
WHERE i.category_id = @security
  AND p.sku IN (
    'TGS-2023021102', 'TGS-2026061329', 'TGS-2023039177', 'TGS-2024051414',
    'TGS-2025060473', 'TGS-2025053228', 'TGS-2024042604'
  );
