-- Pin the WSQ/CASL course order in the RPA API IT Automation category
-- (url_key: rpa-api-it-automation-courses):
--   1. CASL - Robotics Process Automation (RPA) for Beginners             (TGS-2026064721)
--   2. WSQ - Agentic AI for Business Process Automation                   (TGS-2024045801)
--   3. WSQ - Business Process Automation with Power Automate and Copilot
--      Studio Agents                                                      (TGS-2022017524)
--   4. WSQ - IT Automation with Google Apps Script                        (TGS-2024042306)
--   5. WSQ - Build Modern RESTFUL API Applications with AI Assisted
--      Programming                                                        (TGS-2025052277)
--   6. WSQ - Microsoft Certified Endpoint Administrator Associate (MD-102) (TGS-2024042603)
--
-- The remaining funded courses follow at 7-11 keeping their prior relative
-- order (CASL Langflow TGS-2026064176, AI Vibe Coding for Excel VBA
-- TGS-2021008700, Power Automate Desktop RPA TGS-2023040472, Docker and
-- Kubernetes TGS-2021010366, Human-AI Workforce TGS-2024043854); the non-WSQ
-- (C-prefix) alphabetical block stays after the funded block.
--
-- Idempotent; partner-safe (MY/GH carry no TGS- SKUs so every UPDATE matches
-- zero rows there). Writes BOTH catalog_category_product (admin source of
-- truth) and catalog_category_product_index (what the storefront listing
-- actually reads), for every store_id present on this instance.
-- Already applied live on SG 2026-08-23.

SET @cat := (SELECT uk.entity_id
             FROM catalog_category_entity_varchar uk
             JOIN eav_attribute ea ON ea.attribute_id = uk.attribute_id
                                  AND ea.entity_type_id = 3
                                  AND ea.attribute_code = 'url_key'
             WHERE uk.store_id = 0 AND uk.value = 'rpa-api-it-automation-courses'
             LIMIT 1);

SET @p1  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064721' LIMIT 1);
SET @p2  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024045801' LIMIT 1);
SET @p3  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2022017524' LIMIT 1);
SET @p4  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024042306' LIMIT 1);
SET @p5  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025052277' LIMIT 1);
SET @p6  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024042603' LIMIT 1);
SET @p7  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064176' LIMIT 1);
SET @p8  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2021008700' LIMIT 1);
SET @p9  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023040472' LIMIT 1);
SET @p10 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2021010366' LIMIT 1);
SET @p11 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024043854' LIMIT 1);

-- Index table (drives the storefront order), all stores on this instance.
UPDATE catalog_category_product_index SET position = 1
 WHERE category_id = @cat AND product_id = @p1  AND @cat IS NOT NULL AND @p1  IS NOT NULL;
UPDATE catalog_category_product_index SET position = 2
 WHERE category_id = @cat AND product_id = @p2  AND @cat IS NOT NULL AND @p2  IS NOT NULL;
UPDATE catalog_category_product_index SET position = 3
 WHERE category_id = @cat AND product_id = @p3  AND @cat IS NOT NULL AND @p3  IS NOT NULL;
UPDATE catalog_category_product_index SET position = 4
 WHERE category_id = @cat AND product_id = @p4  AND @cat IS NOT NULL AND @p4  IS NOT NULL;
UPDATE catalog_category_product_index SET position = 5
 WHERE category_id = @cat AND product_id = @p5  AND @cat IS NOT NULL AND @p5  IS NOT NULL;
UPDATE catalog_category_product_index SET position = 6
 WHERE category_id = @cat AND product_id = @p6  AND @cat IS NOT NULL AND @p6  IS NOT NULL;
UPDATE catalog_category_product_index SET position = 7
 WHERE category_id = @cat AND product_id = @p7  AND @cat IS NOT NULL AND @p7  IS NOT NULL;
UPDATE catalog_category_product_index SET position = 8
 WHERE category_id = @cat AND product_id = @p8  AND @cat IS NOT NULL AND @p8  IS NOT NULL;
UPDATE catalog_category_product_index SET position = 9
 WHERE category_id = @cat AND product_id = @p9  AND @cat IS NOT NULL AND @p9  IS NOT NULL;
UPDATE catalog_category_product_index SET position = 10
 WHERE category_id = @cat AND product_id = @p10 AND @cat IS NOT NULL AND @p10 IS NOT NULL;
UPDATE catalog_category_product_index SET position = 11
 WHERE category_id = @cat AND product_id = @p11 AND @cat IS NOT NULL AND @p11 IS NOT NULL;

-- Base table (admin view).
UPDATE catalog_category_product SET position = 1
 WHERE category_id = @cat AND product_id = @p1  AND @cat IS NOT NULL AND @p1  IS NOT NULL;
UPDATE catalog_category_product SET position = 2
 WHERE category_id = @cat AND product_id = @p2  AND @cat IS NOT NULL AND @p2  IS NOT NULL;
UPDATE catalog_category_product SET position = 3
 WHERE category_id = @cat AND product_id = @p3  AND @cat IS NOT NULL AND @p3  IS NOT NULL;
UPDATE catalog_category_product SET position = 4
 WHERE category_id = @cat AND product_id = @p4  AND @cat IS NOT NULL AND @p4  IS NOT NULL;
UPDATE catalog_category_product SET position = 5
 WHERE category_id = @cat AND product_id = @p5  AND @cat IS NOT NULL AND @p5  IS NOT NULL;
UPDATE catalog_category_product SET position = 6
 WHERE category_id = @cat AND product_id = @p6  AND @cat IS NOT NULL AND @p6  IS NOT NULL;
UPDATE catalog_category_product SET position = 7
 WHERE category_id = @cat AND product_id = @p7  AND @cat IS NOT NULL AND @p7  IS NOT NULL;
UPDATE catalog_category_product SET position = 8
 WHERE category_id = @cat AND product_id = @p8  AND @cat IS NOT NULL AND @p8  IS NOT NULL;
UPDATE catalog_category_product SET position = 9
 WHERE category_id = @cat AND product_id = @p9  AND @cat IS NOT NULL AND @p9  IS NOT NULL;
UPDATE catalog_category_product SET position = 10
 WHERE category_id = @cat AND product_id = @p10 AND @cat IS NOT NULL AND @p10 IS NOT NULL;
UPDATE catalog_category_product SET position = 11
 WHERE category_id = @cat AND product_id = @p11 AND @cat IS NOT NULL AND @p11 IS NOT NULL;
