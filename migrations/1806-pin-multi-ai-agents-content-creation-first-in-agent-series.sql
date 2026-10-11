-- 1806: Pin "WSQ - Multi AI Agents Workflow for Content Creation"
-- (TGS-2023036153) first in the AI Agents Series and Multi Agents Series
-- categories.
--
-- SG-only: guarded on @mms_instance (set by apply.php). TGS- courses do not
-- exist on MY/GH either, so @pid is NULL there and every statement is a no-op.
--
-- Ids are resolved by url_key / SKU so this survives a DB where entity ids
-- differ. Rows above the course shift down by one, so every other course keeps
-- its relative order. Re-running is a no-op once the course is already first.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023036153' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1. AI Agents Series (url_key 'ai-agents-series')
-- ---------------------------------------------------------------------------
SET @cat := (
  SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v
    ON v.entity_id = e.entity_id AND v.store_id = 0
   AND v.attribute_id = (SELECT attribute_id FROM eav_attribute
                          WHERE attribute_code = 'url_key' AND entity_type_id = 3)
  WHERE v.value = 'ai-agents-series' LIMIT 1
);
SET @cur := (SELECT position FROM catalog_category_product
              WHERE category_id = @cat AND product_id = @pid LIMIT 1);

UPDATE catalog_category_product
SET position = position + 1
WHERE @mms_instance = 'SG' AND @cat IS NOT NULL AND @pid IS NOT NULL AND @cur IS NOT NULL
  AND @cur > 1
  AND category_id = @cat
  AND position BETWEEN 1 AND @cur - 1;

UPDATE catalog_category_product
SET position = 1
WHERE @mms_instance = 'SG' AND @cat IS NOT NULL AND @pid IS NOT NULL AND @cur IS NOT NULL
  AND @cur > 1
  AND category_id = @cat AND product_id = @pid;

-- Mirror into the index so the storefront reflects it without a full reindex.
UPDATE catalog_category_product_index
SET position = position + 1
WHERE @mms_instance = 'SG' AND @cat IS NOT NULL AND @pid IS NOT NULL AND @cur IS NOT NULL
  AND @cur > 1
  AND category_id = @cat AND store_id = 1
  AND position BETWEEN 1 AND @cur - 1;

UPDATE catalog_category_product_index
SET position = 1
WHERE @mms_instance = 'SG' AND @cat IS NOT NULL AND @pid IS NOT NULL AND @cur IS NOT NULL
  AND @cur > 1
  AND category_id = @cat AND store_id = 1 AND product_id = @pid;

-- ---------------------------------------------------------------------------
-- 2. Multi Agents Series (url_key 'multi-agents-series')
-- ---------------------------------------------------------------------------
SET @cat := (
  SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v
    ON v.entity_id = e.entity_id AND v.store_id = 0
   AND v.attribute_id = (SELECT attribute_id FROM eav_attribute
                          WHERE attribute_code = 'url_key' AND entity_type_id = 3)
  WHERE v.value = 'multi-agents-series' LIMIT 1
);
SET @cur := (SELECT position FROM catalog_category_product
              WHERE category_id = @cat AND product_id = @pid LIMIT 1);

UPDATE catalog_category_product
SET position = position + 1
WHERE @mms_instance = 'SG' AND @cat IS NOT NULL AND @pid IS NOT NULL AND @cur IS NOT NULL
  AND @cur > 1
  AND category_id = @cat
  AND position BETWEEN 1 AND @cur - 1;

UPDATE catalog_category_product
SET position = 1
WHERE @mms_instance = 'SG' AND @cat IS NOT NULL AND @pid IS NOT NULL AND @cur IS NOT NULL
  AND @cur > 1
  AND category_id = @cat AND product_id = @pid;

UPDATE catalog_category_product_index
SET position = position + 1
WHERE @mms_instance = 'SG' AND @cat IS NOT NULL AND @pid IS NOT NULL AND @cur IS NOT NULL
  AND @cur > 1
  AND category_id = @cat AND store_id = 1
  AND position BETWEEN 1 AND @cur - 1;

UPDATE catalog_category_product_index
SET position = 1
WHERE @mms_instance = 'SG' AND @cat IS NOT NULL AND @pid IS NOT NULL AND @cur IS NOT NULL
  AND @cur > 1
  AND category_id = @cat AND store_id = 1 AND product_id = @pid;
