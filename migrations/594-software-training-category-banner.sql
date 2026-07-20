-- 594 — Add the Software Training category banner.
--
-- The category had no `image` value at all (no EAV row), so the storefront
-- rendered no <p class="category-image"> block. INSERTs at store_id=0,
-- matching migration 592; sibling 591/593 UPDATEd existing rows.
--
-- File is already on R2 (1600x497, ~126KB), served directly by
-- MMD_CourseImage_Model_Catalog_Category::getImageUrl():
--   catalog/category/software-training-banner.jpg
-- No file ships in the repo — media/catalog/category/ is .dockerignore-excluded.
--
-- NOTE: the supplied artwork has typos baked into the image — the headline
-- reads "SOFTWING COURSES" (rather than SOFTWARE) and a badge reads "AUTTDESK".
-- Flagged before shipping and approved by the site owner. Replacing it later is
-- a drop-in: re-upload the corrected JPEG to the SAME R2 key, then reindex +
-- flush (no migration needed, since the attribute value is unchanged).
--
-- Resolved by url_key, not entity_id, so a partner DB lacking this category
-- matches zero rows. Idempotent via ON DUPLICATE KEY UPDATE.

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT
    a.entity_type_id,
    a.attribute_id,
    0 AS store_id,
    k.entity_id,
    'software-training-banner.jpg'
FROM eav_attribute a
JOIN catalog_category_entity_varchar k
  ON k.value = 'software-training-courses'
JOIN eav_attribute ka
  ON ka.attribute_id = k.attribute_id
 AND ka.attribute_code = 'url_key'
 AND ka.entity_type_id = a.entity_type_id
WHERE a.attribute_code = 'image'
  AND a.entity_type_id = (
        SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category'
      )
ON DUPLICATE KEY UPDATE value = VALUES(value);
