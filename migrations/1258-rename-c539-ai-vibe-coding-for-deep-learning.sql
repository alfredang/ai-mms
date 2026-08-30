-- 1258: Retitle C539 "AI Vibe Coding with PyTorch Deep Learning"
--                -> "AI Vibe Coding for Deep Learning"
--       and re-slug deep-learning-with-pytorch -> ai-vibe-coding-for-deep-learning.
--
-- This is a RETITLE, not a repurpose. The course still teaches PyTorch; only
-- the title framing changes, bringing C539 in line with the rest of the
-- "AI Vibe Coding for <topic>" family (C430 machine-learning, C592
-- computer-vision, ...). short_description / description stay as-is: they
-- accurately describe the PyTorch content and PyTorch remains the tool taught.
--
-- Surfaces updated: name, url_key, url_path, meta_title, meta_description,
-- the three image_label/small_image_label/thumbnail_label alt texts, and the
-- media-gallery label. The image/small_image/thumbnail FILE PATHS are left
-- alone (they are filesystem paths -- renaming them 404s the image), and
-- course_image_url is re-rendered out of band by the cover script (the PNG
-- bakes the title, so a migration cannot do it).
--
-- 301s: the old slug must keep resolving. Every is_system=1 row owning the old
-- path is repointed to the new slug in place (INSERT IGNORE would silently
-- no-op on the UNIQUE (request_path, store_id) key -- see
-- feedback_insert_ignore_swallows_rewrite_301s), and a 301 is created from the
-- old path to the new one using an id_path derived from the OLD SLUG, not the
-- SKU (feedback_second_rename_reuses_301_id_path).
--
-- Search redirects: 75 catalogsearch_query rows point at the old slug URL and
-- would rot into a 301-chain; they are repointed to the new URL directly.
--
-- SG-guarded (C-prefix SKU is SG/partner shared, but this slug + name are SG
-- editorial). Idempotent throughout.

-- NOTE: COUNT(*) here is 2 on prod (default scope + store scope both carry
-- the SG base_url), so this must be tested as > 0, never = 1.
SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url' AND value LIKE '%tertiarycourses.com.sg%'
);

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C539');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlk  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlp  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtit  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

SET @old_name := 'AI Vibe Coding with PyTorch Deep Learning';
SET @new_name := 'AI Vibe Coding for Deep Learning';
SET @old_slug := 'deep-learning-with-pytorch';
SET @new_slug := 'ai-vibe-coding-for-deep-learning';

-- ===== name / metas / alt labels =====

UPDATE catalog_product_entity_varchar
SET value = @new_name
WHERE @is_sg > 0 AND @e IS NOT NULL
  AND entity_id = @e
  AND attribute_id IN (@a_name, @a_mtit, @a_il, @a_sil, @a_til)
  AND value = @old_name;

UPDATE catalog_product_entity_varchar
SET value = 'Vibe code deep learning with Cursor, GitHub Copilot and Claude in this hands-on 2-day course. Build neural networks, CNNs with transfer learning, and LSTMs for time series from plain-English prompts.'
WHERE @is_sg > 0 AND @e IS NOT NULL
  AND entity_id = @e AND attribute_id = @a_mdesc;

-- media gallery alt label
UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = @new_name
WHERE @is_sg > 0 AND @e IS NOT NULL
  AND g.entity_id = @e AND v.label = @old_name;

-- ===== url_key / url_path =====

UPDATE catalog_product_entity_varchar
SET value = @new_slug
WHERE @is_sg > 0 AND @e IS NOT NULL
  AND entity_id = @e AND attribute_id = @a_urlk AND value = @old_slug;

UPDATE catalog_product_entity_varchar
SET value = CONCAT(@new_slug, '.html')
WHERE @is_sg > 0 AND @e IS NOT NULL
  AND entity_id = @e AND attribute_id = @a_urlp
  AND value = CONCAT(@old_slug, '.html');

-- ===== 301 from the bare old slug to the new one =====
-- Create BEFORE repointing the is_system row, so the old path is free.
-- id_path derived from the OLD SLUG (unique per rename by construction).

DELETE FROM core_url_rewrite
WHERE @is_sg > 0
  AND request_path = CONCAT(@old_slug, '.html')
  AND is_system = 1;

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, CONCAT('custom/', @old_slug, '-301'),
       CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'), 0, 'RP'
FROM dual
WHERE @is_sg > 0 AND @e IS NOT NULL;

-- ===== repoint the category-scoped is_system rows onto the new slug =====

UPDATE core_url_rewrite
SET request_path = REPLACE(request_path, CONCAT('/', @old_slug, '.html'),
                                          CONCAT('/', @new_slug, '.html'))
WHERE @is_sg > 0 AND @e IS NOT NULL
  AND product_id = @e AND is_system = 1
  AND request_path LIKE CONCAT('%/', @old_slug, '.html');

-- the bare product rewrite (idp = product/<id>) needs recreating post-delete
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, product_id)
SELECT 1, CONCAT('product/', @e), CONCAT(@new_slug, '.html'),
       CONCAT('catalog/product/view/id/', @e), 1, '', @e
FROM dual
WHERE @is_sg > 0 AND @e IS NOT NULL;

-- ===== flatten existing 301s that targeted the old slug (one hop) =====

UPDATE core_url_rewrite
SET target_path = REPLACE(target_path, CONCAT(@old_slug, '.html'),
                                        CONCAT(@new_slug, '.html'))
WHERE @is_sg > 0
  AND is_system = 0 AND options = 'RP'
  AND target_path LIKE CONCAT('%', @old_slug, '.html');

-- ===== search redirects: repoint at the new URL =====

UPDATE catalogsearch_query
SET redirect = REPLACE(redirect, CONCAT('/', @old_slug, '.html'),
                                  CONCAT('/', @new_slug, '.html'))
WHERE @is_sg > 0
  AND redirect LIKE CONCAT('%/', @old_slug, '.html');
