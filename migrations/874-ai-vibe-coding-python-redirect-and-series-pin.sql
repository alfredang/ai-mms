-- 874: Point "AI Vibe Coding with Python" search terms at the WSQ course, and
-- pin that course first in the AI Vibe Coding Series category.
--
-- SG-only. TGS- (WSQ) courses do not exist on MY/GH, so the store guard makes
-- this a no-op on partner sites.
--
-- Redirect scope note: this deliberately does NOT touch the terms belonging to
-- the sibling course "WSQ - Build and Deploy Python Applications with Vibe
-- Coding" (matched by 'deploy'), nor the Python finance / data-analysis /
-- PyTorch variants -- those are separate live courses with their own targets.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-with-python.html';

-- 1. Search-term redirects. Correction, not a fill: overwrite any existing
--    redirect that is not already the target (empty-only guards silently skip
--    prod rows that are already populated with the wrong course).
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND redirect <> @tgt
  AND LOWER(query_text) LIKE '%vibe coding%'
  AND LOWER(query_text) LIKE '%python%'
  AND LOWER(query_text) NOT LIKE '%deploy%'
  AND LOWER(query_text) NOT LIKE '%financial%'
  AND LOWER(query_text) NOT LIKE '%finance%'
  AND LOWER(query_text) NOT LIKE '%data analysis%'
  AND LOWER(query_text) NOT LIKE '%pytorch%';

-- 2. Pin TGS-2019504591 first in the AI Vibe Coding Series (url_key
--    'ai-vibe-coding-series'). Resolve ids by lookup so this survives a DB
--    where entity ids differ.
SET @cat := (
  SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v
    ON v.entity_id = e.entity_id AND v.store_id = 0
   AND v.attribute_id = (SELECT attribute_id FROM eav_attribute
                          WHERE attribute_code = 'url_key' AND entity_type_id = 3)
  WHERE v.value = 'ai-vibe-coding-series' LIMIT 1
);
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2019504591' LIMIT 1);

-- Current position of the course; only shift when it is not already first.
SET @cur := (SELECT position FROM catalog_category_product
              WHERE category_id = @cat AND product_id = @pid LIMIT 1);

UPDATE catalog_category_product
SET position = position + 1
WHERE @sg = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL AND @cur IS NOT NULL
  AND @cur > 1
  AND category_id = @cat
  AND position BETWEEN 1 AND @cur - 1;

UPDATE catalog_category_product
SET position = 1
WHERE @sg = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL AND @cur IS NOT NULL
  AND @cur > 1
  AND category_id = @cat AND product_id = @pid;

-- Mirror into the index so the storefront reflects it without a full reindex.
UPDATE catalog_category_product_index
SET position = position + 1
WHERE @sg = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL AND @cur IS NOT NULL
  AND @cur > 1
  AND category_id = @cat AND store_id = 1
  AND position BETWEEN 1 AND @cur - 1;

UPDATE catalog_category_product_index
SET position = 1
WHERE @sg = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL AND @cur IS NOT NULL
  AND @cur > 1
  AND category_id = @cat AND store_id = 1 AND product_id = @pid;
