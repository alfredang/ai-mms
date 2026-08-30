-- 1235: Add two WSQ courses to the AI for HR subcategory, ahead of its
-- non-WSQ courses:
--   1. TGS-2024045795  WSQ - Agentic AI for HR
--   2. TGS-2024051421  WSQ - Generative AI for Interviewing
--
-- Both keep every existing category membership — this is an add, not a move.
--
-- WSQ rows are pinned at 1..2 and the three non-WSQ courses re-pinned at
-- 101..103, so the WSQ block leads the listing. (The sweep sorts TGS- first
-- regardless of position, so this holds either way; the explicit pin keeps
-- the two WSQ courses in the requested order rather than whatever relative
-- order they happen to have.)
--
-- Every non-WSQ member is covered by the CASE so none drifts above the block
-- — see feedback_curated_leftovers_must_be_pinned_not_parked.
--
-- Business-key lookups; TGS- SKUs do not exist on partner instances and the
-- url_key is SG-only (clean partner no-op). Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @hr := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'ai-for-hr-courses' LIMIT 1
);

-- ---------------------------------------------------------------------------
-- 1) Assign both WSQ courses (base + index mirror).
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @hr, p.entity_id,
       CASE p.sku WHEN 'TGS-2024045795' THEN 1 WHEN 'TGS-2024051421' THEN 2 END
FROM catalog_product_entity p
WHERE @hr IS NOT NULL
  AND p.sku IN ('TGS-2024045795', 'TGS-2024051421');

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @hr, p.entity_id,
       CASE p.sku WHEN 'TGS-2024045795' THEN 1 WHEN 'TGS-2024051421' THEN 2 END,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @hr IS NOT NULL
  AND p.sku IN ('TGS-2024045795', 'TGS-2024051421')
GROUP BY p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 2) Pin the WSQ pair at the top, in the requested order.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2024045795' THEN 1
  WHEN 'TGS-2024051421' THEN 2
END
WHERE cp.category_id = @hr
  AND p.sku IN ('TGS-2024045795', 'TGS-2024051421');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2024045795' THEN 1
  WHEN 'TGS-2024051421' THEN 2
END
WHERE i.category_id = @hr
  AND p.sku IN ('TGS-2024045795', 'TGS-2024051421');

-- ---------------------------------------------------------------------------
-- 3) Keep the non-WSQ courses in the 101+ band, below the WSQ block.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C811' THEN 101
  WHEN 'C903' THEN 102
  WHEN 'C820' THEN 103
END
WHERE cp.category_id = @hr
  AND p.sku IN ('C811', 'C903', 'C820');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C811' THEN 101
  WHEN 'C903' THEN 102
  WHEN 'C820' THEN 103
END
WHERE i.category_id = @hr
  AND p.sku IN ('C811', 'C903', 'C820');
