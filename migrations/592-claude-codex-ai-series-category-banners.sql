-- 592 — Add category banners for Claude AI Series and Codex AI Series.
--
-- Neither category had an `image` value at all (no EAV row), so the storefront
-- rendered no <p class="category-image"> block. This INSERTs the attribute at
-- store_id=0; sibling migration 591 UPDATEd an existing row for IBF.
--
-- Files are already on R2 (1600x497, ~124KB each), served directly by
-- MMD_CourseImage_Model_Catalog_Category::getImageUrl():
--   catalog/category/claude-ai-series-banner.jpg
--   catalog/category/codex-ai-series-banner.jpg
-- No file ships in the repo — media/catalog/category/ is .dockerignore-excluded.
--
-- Resolved by url_key, not entity_id, so a partner DB lacking these SG-only
-- categories matches zero rows rather than banner-ing an unrelated category.
-- Idempotent via ON DUPLICATE KEY UPDATE (unique key on entity/attribute/store),
-- so a re-run — or a later run where the row now exists — converges to the same value.

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT
    a.entity_type_id,
    a.attribute_id,
    0 AS store_id,
    k.entity_id,
    m.filename
FROM (
        SELECT 'claude-ai-series' AS url_key, 'claude-ai-series-banner.jpg' AS filename
  UNION ALL
        SELECT 'codex-ai-series',             'codex-ai-series-banner.jpg'
) m
JOIN eav_attribute a
  ON a.attribute_code = 'image'
 AND a.entity_type_id = (
       SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category'
     )
JOIN catalog_category_entity_varchar k
  ON k.value = m.url_key
JOIN eav_attribute ka
  ON ka.attribute_id = k.attribute_id
 AND ka.attribute_code = 'url_key'
 AND ka.entity_type_id = a.entity_type_id
ON DUPLICATE KEY UPDATE value = VALUES(value);
