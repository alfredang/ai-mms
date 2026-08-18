-- 1053: Pin the requested WSQ order in the Network Security category
-- (url_key network-securities-courses):
--   1. TGS-2020505561 — WSQ Network Securities for Beginners
--   2. TGS-2023039181 — WSQ CompTIA Certified Security+ Training
--   3. TGS-2024051414 — WSQ AI for Network Security
--   4. TGS-2023039177 — WSQ AI for Cyber Security
--   5. TGS-2023039344 — WSQ AI for IT Security Professionals
--   6. TGS-2024042604 — WSQ Microsoft Security Operations Analyst (SC-200)
-- Unpinned WSQ courses (CISSP, [MC] Advanced Certificate) follow after,
-- then non-WSQ alphabetical as usual.
--
-- Negative positions keep these rows ahead of every unpinned course.
-- The daily category-ordering sweep preserves TGS relative order and
-- renumbers them to normal positive positions. Category/products use
-- business-key lookups. Idempotent.

SET @netsec_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'network-securities-courses'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2020505561' THEN -6
  WHEN 'TGS-2023039181' THEN -5
  WHEN 'TGS-2024051414' THEN -4
  WHEN 'TGS-2023039177' THEN -3
  WHEN 'TGS-2023039344' THEN -2
  WHEN 'TGS-2024042604' THEN -1
END
WHERE cp.category_id = @netsec_category
  AND p.sku IN (
    'TGS-2020505561',
    'TGS-2023039181',
    'TGS-2024051414',
    'TGS-2023039177',
    'TGS-2023039344',
    'TGS-2024042604'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2020505561' THEN -6
  WHEN 'TGS-2023039181' THEN -5
  WHEN 'TGS-2024051414' THEN -4
  WHEN 'TGS-2023039177' THEN -3
  WHEN 'TGS-2023039344' THEN -2
  WHEN 'TGS-2024042604' THEN -1
END
WHERE i.category_id = @netsec_category
  AND p.sku IN (
    'TGS-2020505561',
    'TGS-2023039181',
    'TGS-2024051414',
    'TGS-2023039177',
    'TGS-2023039344',
    'TGS-2024042604'
  );
