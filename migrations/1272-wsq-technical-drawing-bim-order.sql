-- 1272: WSQ Technical Drawing & BIM Courses (url_key
-- 'wsq-technical-drawing-and-bim-courses') — rename one course, move one course
-- in from Graphics Design & Media, and pin the requested order for all
-- seventeen.
--
-- 1) RENAME TGS-2026064717 "Application of BIM using Revit"
--       -> "WSQ - Application of BIM using Revit"
--    Only the display name changes. The url_key is ALREADY
--    'wsq-application-of-bim-using-revit' and the meta_title already carries
--    "WSQ", so this makes the name consistent with them; url_key is untouched,
--    so no URL changes and no 301 is required. The name is mirrored into the
--    per-store flat table because the storefront reads flat and no reindex runs
--    at deploy. Guarded via information_schema — a bare/absent flat table name
--    would abort apply.php and 502 every route.
--
-- 2) MOVE TGS-2026065705 "WSQ - 3D Modelling with Blender for Beginners"
--    out of WSQ Graphics Design & Media (349) and into this category (398).
--    349 was its ONLY home among the children of WSQ Media & Marketing (72), so
--    its leftover direct row on 72 is dropped as well (guarded by "not
--    reachable via any other child") — 398 is also a child of 72, so it still
--    surfaces there through the new assignment. Compare 1271, where the removed
--    courses DID remain in another child and their parent rows were kept.
--
-- 3) PIN the requested order (all seventeen are TGS-; the category holds no
--    C-prefix course, so the nightly sweep has nothing to re-alphabetise and it
--    preserves TGS relative order — no curated-allowlist entry needed).
--
-- Business-key lookups only. Idempotent.

SET @bim := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-technical-drawing-and-bim-courses' LIMIT 1);
SET @gfx := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-graphics-design-media-courses' LIMIT 1);
SET @mm := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-media-marketing-courses' LIMIT 1);
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=4);

-- 1. Rename: EAV (source of truth), every store row the product has ----------

UPDATE catalog_product_entity_varchar nv
JOIN catalog_product_entity p ON p.entity_id = nv.entity_id
SET nv.value = 'WSQ - Application of BIM using Revit'
WHERE p.sku = 'TGS-2026064717'
  AND nv.attribute_id = @a_name
  AND nv.value = 'Application of BIM using Revit';

-- Mirror into the per-store flat table. Guarded: which flat tables exist
-- differs per instance, and naming a missing one aborts the whole chain.
SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.TABLES
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_product_flat_1') > 0
  AND (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_product_flat_1' AND COLUMN_NAME='name') > 0,
  "UPDATE catalog_product_flat_1 f JOIN catalog_product_entity p ON p.entity_id=f.entity_id
     SET f.name='WSQ - Application of BIM using Revit'
   WHERE p.sku='TGS-2026064717' AND f.name='Application of BIM using Revit'",
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 2. Move the Blender course into this category ------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @bim, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @bim)
FROM catalog_product_entity p
WHERE p.sku = 'TGS-2026065705' AND @bim IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @bim, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @bim),
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE p.sku = 'TGS-2026065705' AND @bim IS NOT NULL
GROUP BY p.entity_id, s.store_id;

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @gfx AND @gfx IS NOT NULL AND p.sku = 'TGS-2026065705';

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @gfx AND @gfx IS NOT NULL AND p.sku = 'TGS-2026065705';

-- Drop the leftover parent row only if no child of 72 still holds it.
-- Materialised first: MySQL cannot read the table it deletes from (error 1093).
DROP TEMPORARY TABLE IF EXISTS tmp_bim_still_child;
CREATE TEMPORARY TABLE tmp_bim_still_child (product_id INT PRIMARY KEY);
INSERT IGNORE INTO tmp_bim_still_child (product_id)
SELECT c2.product_id
FROM catalog_category_product c2
JOIN catalog_category_entity ce ON ce.entity_id = c2.category_id AND ce.parent_id = @mm
JOIN catalog_product_entity p ON p.entity_id = c2.product_id
WHERE @mm IS NOT NULL AND p.sku = 'TGS-2026065705';

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @mm AND @mm IS NOT NULL AND p.sku = 'TGS-2026065705'
  AND cp.product_id NOT IN (SELECT product_id FROM tmp_bim_still_child);

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @mm AND @mm IS NOT NULL AND p.sku = 'TGS-2026065705'
  AND i.product_id NOT IN (SELECT product_id FROM tmp_bim_still_child);

DROP TEMPORARY TABLE IF EXISTS tmp_bim_still_child;

-- 3. Pin the requested order -------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2021005538' THEN -17
  WHEN 'TGS-2023037469' THEN -16
  WHEN 'TGS-2023037466' THEN -15
  WHEN 'TGS-2023036004' THEN -14
  WHEN 'TGS-2021004287' THEN -13
  WHEN 'TGS-2023037587' THEN -12
  WHEN 'TGS-2023036661' THEN -11
  WHEN 'TGS-2026064717' THEN -10
  WHEN 'TGS-2021005540' THEN  -9
  WHEN 'TGS-2021009334' THEN  -8
  WHEN 'TGS-2021006715' THEN  -7
  WHEN 'TGS-2021010185' THEN  -6
  WHEN 'TGS-2026065705' THEN  -5
  WHEN 'TGS-2021005539' THEN  -4
  WHEN 'TGS-2023039180' THEN  -3
  WHEN 'TGS-2023037544' THEN  -2
  WHEN 'TGS-2023039342' THEN  -1
END
WHERE cp.category_id = @bim AND @bim IS NOT NULL
  AND p.sku IN ('TGS-2021005538','TGS-2023037469','TGS-2023037466','TGS-2023036004',
                'TGS-2021004287','TGS-2023037587','TGS-2023036661','TGS-2026064717',
                'TGS-2021005540','TGS-2021009334','TGS-2021006715','TGS-2021010185',
                'TGS-2026065705','TGS-2021005539','TGS-2023039180','TGS-2023037544',
                'TGS-2023039342');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2021005538' THEN -17
  WHEN 'TGS-2023037469' THEN -16
  WHEN 'TGS-2023037466' THEN -15
  WHEN 'TGS-2023036004' THEN -14
  WHEN 'TGS-2021004287' THEN -13
  WHEN 'TGS-2023037587' THEN -12
  WHEN 'TGS-2023036661' THEN -11
  WHEN 'TGS-2026064717' THEN -10
  WHEN 'TGS-2021005540' THEN  -9
  WHEN 'TGS-2021009334' THEN  -8
  WHEN 'TGS-2021006715' THEN  -7
  WHEN 'TGS-2021010185' THEN  -6
  WHEN 'TGS-2026065705' THEN  -5
  WHEN 'TGS-2021005539' THEN  -4
  WHEN 'TGS-2023039180' THEN  -3
  WHEN 'TGS-2023037544' THEN  -2
  WHEN 'TGS-2023039342' THEN  -1
END
WHERE i.category_id = @bim AND @bim IS NOT NULL
  AND p.sku IN ('TGS-2021005538','TGS-2023037469','TGS-2023037466','TGS-2023036004',
                'TGS-2021004287','TGS-2023037587','TGS-2023036661','TGS-2026064717',
                'TGS-2021005540','TGS-2021009334','TGS-2021006715','TGS-2021010185',
                'TGS-2026065705','TGS-2021005539','TGS-2023039180','TGS-2023037544',
                'TGS-2023039342');
