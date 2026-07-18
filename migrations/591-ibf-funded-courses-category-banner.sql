-- 591 — Swap the IBF Funded Courses category banner.
--
-- Replaces the reused UTAP banner (utap-funding-courses_3.jpg) with a
-- purpose-made IBF banner. The file is already on R2 at
-- catalog/category/ibf-funded-courses-banner.jpg (1600x497, 108KB), which
-- MMD_CourseImage_Model_Catalog_Category::getImageUrl() serves directly from
-- <R2_PUBLIC_URL>/catalog/category/<image>. No file ships in the repo —
-- media/catalog/category/ is .dockerignore-excluded by design.
--
-- Resolved by url_key, not entity_id, so a partner DB lacking this SG-only
-- category matches zero rows instead of writing over an unrelated category.
-- Idempotent: re-running is a no-op once the value is already set.

UPDATE catalog_category_entity_varchar v
JOIN eav_attribute a
  ON a.attribute_id = v.attribute_id
 AND a.attribute_code = 'image'
 AND a.entity_type_id = (
       SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category'
     )
JOIN (
  SELECT k.entity_id
  FROM catalog_category_entity_varchar k
  JOIN eav_attribute ka
    ON ka.attribute_id = k.attribute_id
   AND ka.attribute_code = 'url_key'
   AND ka.entity_type_id = (
         SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category'
       )
  WHERE k.value = 'ibf-sts-funded-courses'
) t ON t.entity_id = v.entity_id
SET v.value = 'ibf-funded-courses-banner.jpg';
