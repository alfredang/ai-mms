-- 1079: Pin the requested WSQ/CASL order in the AWS Cloud Computing category
-- (url_key 'aws-cloud-computing-courses'):
--    1. TGS-2023039183 — WSQ - AWS Certified Cloud Practitioner Training
--    2. TGS-2024049338 — WSQ - AWS Certified AI Practitioner Training
--    3. TGS-2023040474 — WSQ - DevOps Engineering on AWS
--    4. TGS-2026064535 — CASL - AWS Certified Solutions Architect Associate Training
--       (legacy pre-re-registration SKU TGS-2024048315 pinned to the same slot,
--        so the order is correct on any instance carrying either SKU)
--    5. TGS-2024049340 — WSQ - AWS Certified Machine Learning Engineer Associate Training
--    6. TGS-2025053209 — WSQ - AWS Certified Data Engineer Associate Training
--    7. TGS-2024051413 — WSQ - AWS Certified SysOps Administrator Associate Training
--    8. TGS-2025052675 — WSQ - AWS Certified Developer Associate Training
--    9. TGS-2025053926 — WSQ - AWS Certified Solutions Architect Professional Training
--   10. TGS-2025054815 — WSQ - AWS Certified DevOps Engineer Professional Training
--
-- Negative positions keep these rows ahead of every unpinned course. The daily
-- category-ordering sweep preserves TGS relative order and renumbers them to
-- normal positive positions, so this pin survives. The non-WSQ (C-prefix) block
-- below is untouched and stays alphabetical.
--
-- Category and products resolved by business keys (partner-safe: no-ops on any
-- site lacking these SKUs). Idempotent.

SET @aws_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'aws-cloud-computing-courses'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2023039183' THEN -10
  WHEN 'TGS-2024049338' THEN -9
  WHEN 'TGS-2023040474' THEN -8
  WHEN 'TGS-2026064535' THEN -7
  WHEN 'TGS-2024048315' THEN -7
  WHEN 'TGS-2024049340' THEN -6
  WHEN 'TGS-2025053209' THEN -5
  WHEN 'TGS-2024051413' THEN -4
  WHEN 'TGS-2025052675' THEN -3
  WHEN 'TGS-2025053926' THEN -2
  WHEN 'TGS-2025054815' THEN -1
END
WHERE cp.category_id = @aws_category
  AND p.sku IN (
    'TGS-2023039183',
    'TGS-2024049338',
    'TGS-2023040474',
    'TGS-2026064535',
    'TGS-2024048315',
    'TGS-2024049340',
    'TGS-2025053209',
    'TGS-2024051413',
    'TGS-2025052675',
    'TGS-2025053926',
    'TGS-2025054815'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2023039183' THEN -10
  WHEN 'TGS-2024049338' THEN -9
  WHEN 'TGS-2023040474' THEN -8
  WHEN 'TGS-2026064535' THEN -7
  WHEN 'TGS-2024048315' THEN -7
  WHEN 'TGS-2024049340' THEN -6
  WHEN 'TGS-2025053209' THEN -5
  WHEN 'TGS-2024051413' THEN -4
  WHEN 'TGS-2025052675' THEN -3
  WHEN 'TGS-2025053926' THEN -2
  WHEN 'TGS-2025054815' THEN -1
END
WHERE i.category_id = @aws_category
  AND p.sku IN (
    'TGS-2023039183',
    'TGS-2024049338',
    'TGS-2023040474',
    'TGS-2026064535',
    'TGS-2024048315',
    'TGS-2024049340',
    'TGS-2025053209',
    'TGS-2024051413',
    'TGS-2025052675',
    'TGS-2025053926',
    'TGS-2025054815'
  );
