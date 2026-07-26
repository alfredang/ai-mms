-- 805: "WSQ - Build Modern RESTFUL API Applications with AI Assisted
--      Programming" (TGS-2025052277)
--      -> ADD to "AI Vibe Coding Series" (cat 414)
--      -> REMOVE from "Generative AI Series" (cat 433)
--
-- WSQ (TGS-) membership of the series categories is curated by hand and is
-- never touched by the badge-driven backfill (541) / cleanup (584)
-- migrations, so this explicit statement is the correct mechanism.
--
-- Ordering follows the category-ordering rule: WSQ (TGS-) first, then
-- non-WSQ alphabetically. Cat 414 holds WSQ at positions 1-17 (17 added by
-- migration 804) and non-WSQ from 18, so the new WSQ row lands at 18 and the
-- non-WSQ block shifts down by one.
--
-- NOTE: only the "Generative AI Series" (433, under AI Courses) is touched.
-- The separate "WSQ Generative AI Courses" (379, under WSQ AI Courses) is a
-- different category and is deliberately left alone.
--
-- Idempotent: resolves IDs by SKU / category name, INSERT IGNORE on the
-- unique key, and the position shift is guarded so a re-run cannot
-- double-shift. Partner-safe: SG-only SKU; on MY/GH the SELECTs return no
-- rows and every statement is a NULL-guarded no-op.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025052277' LIMIT 1);

SET @cat_vibe := (
    SELECT cv.entity_id
    FROM catalog_category_entity_varchar cv
    JOIN eav_attribute a
      ON a.attribute_id = cv.attribute_id
     AND a.attribute_code = 'name'
     AND a.entity_type_id = 3
    WHERE cv.store_id = 0
      AND cv.value = 'AI Vibe Coding Series'
    LIMIT 1
);

SET @cat_genai := (
    SELECT cv.entity_id
    FROM catalog_category_entity_varchar cv
    JOIN eav_attribute a
      ON a.attribute_id = cv.attribute_id
     AND a.attribute_code = 'name'
     AND a.entity_type_id = 3
    WHERE cv.store_id = 0
      AND cv.value = 'Generative AI Series'
    LIMIT 1
);

-- Only shift when the product is not already a member (prevents double-shift
-- on re-run). Positions >= 18 are the non-WSQ block.
SET @already := (
    SELECT COUNT(*) FROM catalog_category_product
    WHERE category_id = @cat_vibe AND product_id = @pid
);

UPDATE catalog_category_product
SET position = position + 1
WHERE @pid IS NOT NULL
  AND @cat_vibe IS NOT NULL
  AND @already = 0
  AND category_id = @cat_vibe
  AND position >= 18;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat_vibe, @pid, 18
FROM DUAL
WHERE @pid IS NOT NULL AND @cat_vibe IS NOT NULL;

-- Mirror into the index so the change is visible before the next reindex.
INSERT IGNORE INTO catalog_category_product_index
    (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat_vibe, @pid, 18, 1, i.store_id, i.visibility
FROM catalog_category_product_index i
WHERE @pid IS NOT NULL
  AND @cat_vibe IS NOT NULL
  AND i.product_id = @pid
GROUP BY i.store_id, i.visibility;

-- Remove from the Generative AI Series category (both table and index).
DELETE FROM catalog_category_product
WHERE @pid IS NOT NULL
  AND @cat_genai IS NOT NULL
  AND category_id = @cat_genai
  AND product_id = @pid;

DELETE FROM catalog_category_product_index
WHERE @pid IS NOT NULL
  AND @cat_genai IS NOT NULL
  AND category_id = @cat_genai
  AND product_id = @pid;
