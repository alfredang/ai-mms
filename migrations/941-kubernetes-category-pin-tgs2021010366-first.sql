-- 941: Pin "WSQ - Application Integration with Docker and Kubernetes" (TGS-2021010366)
-- to position 1 in the Kubernetes category (/kubernetes-courses.html).
--
-- The category is already ordered WSQ (TGS-) first, then non-WSQ (C-) alphabetically.
-- This only reorders WITHIN the WSQ block: TGS-2021010366 moves from 4 -> 1 and the
-- three WSQ courses previously at 1..3 shift down to 2..4. Everything from position 5
-- onwards (remaining WSQ + the whole C- alphabetical block) is untouched.
--
-- Partner-safe: keyed off the category url_key + the SKU, both of which resolve to
-- nothing on MY/GH (WSQ TGS- courses are SG-only), so this is a no-op there.
-- Idempotent: re-running recomputes the same positions.

SET @cat := (
    SELECT v.entity_id
    FROM catalog_category_entity_varchar v
    JOIN eav_attribute a
      ON a.attribute_id = v.attribute_id
     AND a.attribute_code = 'url_key'
     AND a.entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category')
    WHERE v.store_id = 0
      AND v.value = 'kubernetes-courses'
    LIMIT 1
);

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021010366' LIMIT 1);

-- Current position of the course being promoted (NULL if not in this category).
SET @old := (
    SELECT position FROM catalog_category_product
    WHERE category_id = @cat AND product_id = @pid
    LIMIT 1
);

-- Shift everything that sits above it (position < @old) down by one, freeing slot 1.
UPDATE catalog_category_product
SET position = position + 1
WHERE @cat IS NOT NULL AND @pid IS NOT NULL AND @old IS NOT NULL AND @old > 1
  AND category_id = @cat
  AND position < @old
  AND position >= 1;

UPDATE catalog_category_product
SET position = 1
WHERE @cat IS NOT NULL AND @pid IS NOT NULL AND @old IS NOT NULL AND @old > 1
  AND category_id = @cat
  AND product_id = @pid;

-- Mirror into the category product index so the storefront listing reflects the new
-- order without waiting for a full reindex (see feedback_category_swap_needs_index_mirror).
UPDATE catalog_category_product_index i
JOIN catalog_category_product ccp
  ON ccp.category_id = i.category_id
 AND ccp.product_id  = i.product_id
SET i.position = ccp.position
WHERE @cat IS NOT NULL
  AND i.category_id = @cat;
