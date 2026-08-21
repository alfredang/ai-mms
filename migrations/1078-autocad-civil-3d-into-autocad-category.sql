-- 1078: Add WSQ - AutoCAD Civil 3D for Infrastructure Design (TGS-2021005539) to the
--       Autodesk AutoCAD category (url_key 'autodesk-autocad-trainings'), positioned
--       directly after WSQ - Technical Drawing with AutoCAD Electrical (TGS-2023037466).
--       Also points the "civil3d" / "autocad civil3d" search-term family at the course.
--
-- Idempotent. Partner-safe: every lookup is by SKU / url_key, so on an instance where
-- the course or the category is absent, each statement is a clean no-op.

-- ---------------------------------------------------------------------------
-- Resolve ids (NULL on instances that lack the course or category)
-- ---------------------------------------------------------------------------
SET @cat := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'autodesk-autocad-trainings'
  LIMIT 1
);
SET @pid  := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021005539' LIMIT 1);
SET @after := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023037466' LIMIT 1);

-- Position of the "anchor" course we must slot in behind. Fall back to the last
-- WSQ position so the course still lands in the WSQ block if the anchor is missing.
SET @anchor_pos := (
  SELECT cp.position FROM catalog_category_product cp
  WHERE cp.category_id = @cat AND cp.product_id = @after LIMIT 1
);
SET @anchor_pos := IFNULL(@anchor_pos, (
  SELECT IFNULL(MAX(cp.position), 0)
  FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND p.sku LIKE 'TGS-%'
));
SET @newpos := @anchor_pos + 1;

-- ---------------------------------------------------------------------------
-- 1. Make room: shift everything at/after the new slot down by one.
--    Skipped when the product is already assigned, so re-runs never re-shift.
-- ---------------------------------------------------------------------------
SET @already := (
  SELECT COUNT(*) FROM catalog_category_product
  WHERE category_id = @cat AND product_id = @pid
);

UPDATE catalog_category_product
   SET position = position + 1
 WHERE @cat IS NOT NULL AND @pid IS NOT NULL AND @already = 0
   AND category_id = @cat
   AND position >= @newpos;

UPDATE catalog_category_product_index
   SET position = position + 1
 WHERE @cat IS NOT NULL AND @pid IS NOT NULL AND @already = 0
   AND category_id = @cat
   AND position >= @newpos;

-- ---------------------------------------------------------------------------
-- 2. Direct assignment (admin-facing source of truth)
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @newpos
FROM dual
WHERE @cat IS NOT NULL AND @pid IS NOT NULL;

UPDATE catalog_category_product
   SET position = @newpos
 WHERE @cat IS NOT NULL AND @pid IS NOT NULL
   AND category_id = @cat AND product_id = @pid;

-- ---------------------------------------------------------------------------
-- 3. Index rows (what the storefront actually renders) -- one per store that
--    already carries this category, and only where the product is enabled and
--    assigned to that store's website.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT DISTINCT @cat, @pid, @newpos, 1, s.store_id,
       IFNULL((SELECT vi.value FROM catalog_product_entity_int vi
                JOIN eav_attribute va ON va.attribute_id = vi.attribute_id
                 AND va.entity_type_id = 4 AND va.attribute_code = 'visibility'
               WHERE vi.entity_id = @pid AND vi.store_id = 0 LIMIT 1), 4)
FROM core_store s
JOIN catalog_product_website pw
  ON pw.website_id = s.website_id AND pw.product_id = @pid
WHERE @cat IS NOT NULL AND @pid IS NOT NULL
  AND s.store_id > 0
  AND EXISTS (SELECT 1 FROM catalog_category_product_index i
               WHERE i.category_id = @cat AND i.store_id = s.store_id)
  AND IFNULL((SELECT si.value FROM catalog_product_entity_int si
               JOIN eav_attribute sa ON sa.attribute_id = si.attribute_id
                AND sa.entity_type_id = 4 AND sa.attribute_code = 'status'
              WHERE si.entity_id = @pid AND si.store_id = 0 LIMIT 1), 1) = 1;

-- Re-seat position + parent flag on re-runs (and for any pre-existing
-- anchor-inherited row, which would otherwise keep a stale sort-to-bottom value).
UPDATE catalog_category_product_index
   SET position = @newpos, is_parent = 1
 WHERE @cat IS NOT NULL AND @pid IS NOT NULL
   AND category_id = @cat AND product_id = @pid;

-- ---------------------------------------------------------------------------
-- 4. Search-term redirects -> the course page.
--    Whitespace-insensitive match so "civil 3d", "civil3d", "auto CAD civil 3D"
--    are all caught. Deliberately EXCLUDES the ACP Civil 3D course's own terms,
--    which point at a different (correct) course.
-- ---------------------------------------------------------------------------
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-autocad-civil-3d-for-infrastructure-design.html';

UPDATE catalogsearch_query
   SET redirect = @tgt
 WHERE REPLACE(LOWER(query_text), ' ', '') IN
       ('civil3d', 'autocadcivil3d', 'autocivil3d', 'wsqcivil3d', 'utocadcivil3d')
   AND (redirect IS NULL OR redirect <> @tgt);
