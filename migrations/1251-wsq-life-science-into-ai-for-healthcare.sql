-- 1251: Place two WSQ courses in the AI for Healthcare subcategory:
--   TGS-2024049780  WSQ - AI for Life Science and Bioinformatics
--   TGS-2023041022  WSQ - Data Analytics and AI for Healthcare
--
-- TGS-2023041022 is already a member (pinned at 1), so the INSERT for it is a
-- defensive no-op; only the Life Science course is genuinely new.
--
-- Both are pinned at 1..2 ahead of the non-WSQ course C1018 "AI for
-- Healthcare", which moves to the 101+ band. Every member of the category is
-- covered so none drifts (see
-- feedback_curated_leftovers_must_be_pinned_not_parked).
--
-- This is an add, not a move: both WSQ courses keep every existing category
-- membership.
--
-- Business-key lookups; TGS- SKUs do not exist on partner instances and the
-- url_key is SG-only (clean partner no-op). Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @healthcare := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'ai-for-healthcare-courses' LIMIT 1
);

-- ---------------------------------------------------------------------------
-- 1) Assign both WSQ courses (base + index mirror).
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @healthcare, p.entity_id,
       CASE p.sku WHEN 'TGS-2024049780' THEN 1 WHEN 'TGS-2023041022' THEN 2 END
FROM catalog_product_entity p
WHERE @healthcare IS NOT NULL
  AND p.sku IN ('TGS-2024049780', 'TGS-2023041022');

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @healthcare, p.entity_id,
       CASE p.sku WHEN 'TGS-2024049780' THEN 1 WHEN 'TGS-2023041022' THEN 2 END,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @healthcare IS NOT NULL
  AND p.sku IN ('TGS-2024049780', 'TGS-2023041022')
GROUP BY p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 2) Pin the WSQ pair at the top, then the non-WSQ course below.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2024049780' THEN 1
  WHEN 'TGS-2023041022' THEN 2
  WHEN 'C1018'          THEN 101
END
WHERE cp.category_id = @healthcare
  AND p.sku IN ('TGS-2024049780', 'TGS-2023041022', 'C1018');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2024049780' THEN 1
  WHEN 'TGS-2023041022' THEN 2
  WHEN 'C1018'          THEN 101
END
WHERE i.category_id = @healthcare
  AND p.sku IN ('TGS-2024049780', 'TGS-2023041022', 'C1018');
