-- Pin the WSQ course order in the DevOps category (url_key: devops-courses):
--   1. WSQ - DevOps Foundation Training                                   (TGS-2024049184)
--   2. WSQ - DevOps Engineering on AWS                                    (TGS-2023040474)
--   3. WSQ - AWS Certified DevOps Engineer Professional Training          (TGS-2025054815)
--   4. WSQ - Designing and Implementing Microsoft DevOps Solutions AZ-400 (TGS-2024042605)
--   5. WSQ - Kubernetes and Cloud Native Associate (KCNA) Training        (TGS-2023039343)
--   6. WSQ - Certified Kubernetes Application Developer (CKAD) Training   (TGS-2025053212)
--   7. WSQ - Certified Kubernetes Administrator (CKA) Training            (TGS-2025054612)
--
-- The remaining WSQ courses in this category (Github Foundations TGS-2025053207,
-- the duplicate KCNA TGS-2025053174, Application Integration with Docker and
-- Kubernetes TGS-2021010366) keep their positions AFTER the pinned block, and the
-- non-WSQ (C-prefix) courses keep their alphabetical block after the WSQ block.
--
-- Idempotent; partner-safe (no-ops where the category / SKUs are absent — MY/GH
-- carry no TGS- SKUs so every UPDATE matches zero rows there).
-- Writes BOTH catalog_category_product (admin source of truth) and
-- catalog_category_product_index (what the storefront listing actually reads),
-- for every store_id present on this instance.

SET @cat := (SELECT uk.entity_id
             FROM catalog_category_entity_varchar uk
             JOIN eav_attribute ea ON ea.attribute_id = uk.attribute_id
                                  AND ea.entity_type_id = 3
                                  AND ea.attribute_code = 'url_key'
             WHERE uk.store_id = 0 AND uk.value = 'devops-courses'
             LIMIT 1);

SET @p1 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024049184' LIMIT 1);
SET @p2 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023040474' LIMIT 1);
SET @p3 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025054815' LIMIT 1);
SET @p4 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024042605' LIMIT 1);
SET @p5 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023039343' LIMIT 1);
SET @p6 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025053212' LIMIT 1);
SET @p7 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025054612' LIMIT 1);

-- Index table (drives the storefront order), all stores on this instance.
UPDATE catalog_category_product_index SET position = 1
 WHERE category_id = @cat AND product_id = @p1 AND @cat IS NOT NULL AND @p1 IS NOT NULL;
UPDATE catalog_category_product_index SET position = 2
 WHERE category_id = @cat AND product_id = @p2 AND @cat IS NOT NULL AND @p2 IS NOT NULL;
UPDATE catalog_category_product_index SET position = 3
 WHERE category_id = @cat AND product_id = @p3 AND @cat IS NOT NULL AND @p3 IS NOT NULL;
UPDATE catalog_category_product_index SET position = 4
 WHERE category_id = @cat AND product_id = @p4 AND @cat IS NOT NULL AND @p4 IS NOT NULL;
UPDATE catalog_category_product_index SET position = 5
 WHERE category_id = @cat AND product_id = @p5 AND @cat IS NOT NULL AND @p5 IS NOT NULL;
UPDATE catalog_category_product_index SET position = 6
 WHERE category_id = @cat AND product_id = @p6 AND @cat IS NOT NULL AND @p6 IS NOT NULL;
UPDATE catalog_category_product_index SET position = 7
 WHERE category_id = @cat AND product_id = @p7 AND @cat IS NOT NULL AND @p7 IS NOT NULL;

-- Push the non-pinned WSQ courses below the pinned block (they previously sat at 6-8).
UPDATE catalog_category_product_index SET position = 8
 WHERE category_id = @cat AND @cat IS NOT NULL
   AND product_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025053207' LIMIT 1);
UPDATE catalog_category_product_index SET position = 9
 WHERE category_id = @cat AND @cat IS NOT NULL
   AND product_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025053174' LIMIT 1);

-- Base table (admin view).
UPDATE catalog_category_product SET position = 1
 WHERE category_id = @cat AND product_id = @p1 AND @cat IS NOT NULL AND @p1 IS NOT NULL;
UPDATE catalog_category_product SET position = 2
 WHERE category_id = @cat AND product_id = @p2 AND @cat IS NOT NULL AND @p2 IS NOT NULL;
UPDATE catalog_category_product SET position = 3
 WHERE category_id = @cat AND product_id = @p3 AND @cat IS NOT NULL AND @p3 IS NOT NULL;
UPDATE catalog_category_product SET position = 4
 WHERE category_id = @cat AND product_id = @p4 AND @cat IS NOT NULL AND @p4 IS NOT NULL;
UPDATE catalog_category_product SET position = 5
 WHERE category_id = @cat AND product_id = @p5 AND @cat IS NOT NULL AND @p5 IS NOT NULL;
UPDATE catalog_category_product SET position = 6
 WHERE category_id = @cat AND product_id = @p6 AND @cat IS NOT NULL AND @p6 IS NOT NULL;
UPDATE catalog_category_product SET position = 7
 WHERE category_id = @cat AND product_id = @p7 AND @cat IS NOT NULL AND @p7 IS NOT NULL;
UPDATE catalog_category_product SET position = 8
 WHERE category_id = @cat AND @cat IS NOT NULL
   AND product_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025053207' LIMIT 1);
UPDATE catalog_category_product SET position = 9
 WHERE category_id = @cat AND @cat IS NOT NULL
   AND product_id = (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025053174' LIMIT 1);
