-- Pin the WSQ course order in the Adobe Photoshop category (url_key: adobe-photoshop-courses):
--   1. WSQ - Professional Digital Image Editing with Photoshop   (TGS-2021003585)
--   2. WSQ - Generative AI (GenAI) Visuals in Photoshop and Firefly (TGS-2024045220)
-- Non-WSQ (C-prefix) courses keep their alphabetical block AFTER the WSQ block.
-- Idempotent; partner-safe (no-ops where the category / SKUs are absent).
-- Writes BOTH catalog_category_product (admin source of truth) and
-- catalog_category_product_index (what the storefront listing actually reads),
-- for every store_id present on this instance.

SET @cat := (SELECT uk.entity_id
             FROM catalog_category_entity_varchar uk
             JOIN eav_attribute ea ON ea.attribute_id = uk.attribute_id
                                  AND ea.entity_type_id = 3
                                  AND ea.attribute_code = 'url_key'
             WHERE uk.store_id = 0 AND uk.value = 'adobe-photoshop-courses'
             LIMIT 1);

SET @p1 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2021003585' LIMIT 1);
SET @p2 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024045220' LIMIT 1);

-- Index table (drives the storefront order), all stores on this instance.
UPDATE catalog_category_product_index
   SET position = 1
 WHERE category_id = @cat AND product_id = @p1 AND @cat IS NOT NULL AND @p1 IS NOT NULL;

UPDATE catalog_category_product_index
   SET position = 2
 WHERE category_id = @cat AND product_id = @p2 AND @cat IS NOT NULL AND @p2 IS NOT NULL;

-- Base table (admin view).
UPDATE catalog_category_product
   SET position = 1
 WHERE category_id = @cat AND product_id = @p1 AND @cat IS NOT NULL AND @p1 IS NOT NULL;

UPDATE catalog_category_product
   SET position = 2
 WHERE category_id = @cat AND product_id = @p2 AND @cat IS NOT NULL AND @p2 IS NOT NULL;
