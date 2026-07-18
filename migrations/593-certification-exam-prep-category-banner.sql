-- 593 — Swap the Certification Exam Prep category banner.
--
-- Replaces the generic certification-courses.jpg with a purpose-made banner.
-- The file is already on R2 (1600x497, ~131KB), served directly by
-- MMD_CourseImage_Model_Catalog_Category::getImageUrl():
--   catalog/category/certification-exam-prep-banner.jpg
-- No file ships in the repo — media/catalog/category/ is .dockerignore-excluded.
--
-- UPDATE (the category already has an `image` row), matching migration 591;
-- sibling 592 INSERTed for categories that had none.
--
-- Resolved by url_key, not entity_id, so a partner DB lacking this category
-- matches zero rows rather than re-bannering an unrelated category.
-- Idempotent: re-running converges to the same value.

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
  WHERE k.value = 'certification-exam-prep-courses'
) t ON t.entity_id = v.entity_id
SET v.value = 'certification-exam-prep-banner.jpg';
