-- 1059: Pin the requested WSQ order in the Docker Courses category
-- (url_key docker-courses):
--   1. TGS-2021010366 — WSQ Application Integration with Docker and Kubernetes
--   2. TGS-2023039343 — WSQ Kubernetes and Cloud Native Associate (KCNA) Training
--   3. TGS-2025053212 — WSQ Certified Kubernetes Application Developer (CKAD) Training
--   4. TGS-2025054612 — WSQ Certified Kubernetes Administrator (CKA) Training
--   5. TGS-2023040474 — WSQ DevOps Engineering on AWS
--   6. TGS-2024042605 — WSQ Designing and Implementing Microsoft DevOps Solutions (AZ-400)
--
-- Two WSQ courses in this category are deliberately NOT pinned and follow the
-- pinned block (still ahead of every non-WSQ course, per the canonical rule):
--   * TGS-2025053174 — the duplicate-titled KCNA record (id 753); the clean
--     canonical slug belongs to TGS-2023039343, which takes the KCNA slot.
--   * TGS-2025054815 — WSQ AWS Certified DevOps Engineer Professional Training.
-- Non-WSQ (C-prefix) courses follow alphabetically as usual.
--
-- Negative positions keep these rows ahead of every unpinned course.
-- The daily category-ordering sweep preserves TGS relative order and
-- renumbers them to normal positive positions. Category/products use
-- business-key lookups. Idempotent.

SET @docker_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'docker-courses'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2021010366' THEN -6
  WHEN 'TGS-2023039343' THEN -5
  WHEN 'TGS-2025053212' THEN -4
  WHEN 'TGS-2025054612' THEN -3
  WHEN 'TGS-2023040474' THEN -2
  WHEN 'TGS-2024042605' THEN -1
END
WHERE cp.category_id = @docker_category
  AND p.sku IN (
    'TGS-2021010366',
    'TGS-2023039343',
    'TGS-2025053212',
    'TGS-2025054612',
    'TGS-2023040474',
    'TGS-2024042605'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2021010366' THEN -6
  WHEN 'TGS-2023039343' THEN -5
  WHEN 'TGS-2025053212' THEN -4
  WHEN 'TGS-2025054612' THEN -3
  WHEN 'TGS-2023040474' THEN -2
  WHEN 'TGS-2024042605' THEN -1
END
WHERE i.category_id = @docker_category
  AND p.sku IN (
    'TGS-2021010366',
    'TGS-2023039343',
    'TGS-2025053212',
    'TGS-2025054612',
    'TGS-2023040474',
    'TGS-2024042605'
  );
