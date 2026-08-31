-- 1290: Typo fix — category "WSQ Programming & VIbe Coding" -> "Vibe".
--
-- The category (url_key
-- 'wsq-programming-vibe-coding-courses-tertiary-courses-singapore') carries the
-- capital-I misspelling in its `name` attribute at store 0, which is what the
-- Ultimo mega-menu, the breadcrumb and the H1 render. `meta_title` and
-- `url_key` were already correct, so the URL is untouched and no 301 is needed.
--
-- The category `image` value (WSQ_Programming_and_VIbe_Courses.png) is a real
-- filename on the media volume and is deliberately NOT renamed — renaming it
-- would 404 the category banner.
--
-- Mirrors into catalog_category_flat_store_1 (SG's only live store; tables
-- _2.._7 are orphaned leftovers from the retired multi-store install) so the
-- fix shows without waiting for a Category Flat Data reindex.
-- Business-key lookup only. Idempotent. Safe on partner sites (the category
-- does not exist there, so every statement matches zero rows).

SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'wsq-programming-vibe-coding-courses-tertiary-courses-singapore'
  LIMIT 1);

UPDATE catalog_category_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id
 AND a.entity_type_id = 3 AND a.attribute_code = 'name'
SET v.value = REPLACE(v.value, 'VIbe', 'Vibe')
WHERE v.entity_id = @cat AND @cat IS NOT NULL AND v.value LIKE '%VIbe%';

UPDATE catalog_category_flat_store_1 SET name = REPLACE(name, 'VIbe', 'Vibe')
  WHERE entity_id = @cat AND @cat IS NOT NULL AND name LIKE '%VIbe%';
