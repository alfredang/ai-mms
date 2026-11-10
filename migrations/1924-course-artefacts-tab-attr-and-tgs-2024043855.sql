-- Course "Artefacts" tab: sample work produced in a course (videos, images,
-- links) shown in a product-page tab after Course Info
-- (catalog/product/view/artefacts.phtml). The tab only appears when the
-- attribute has content.
--
-- 1) Creates the `artefacts` attribute (global scope, text/textarea, HTML).
-- 2) Assigns it to the "General" group of every product attribute set. Without
--    that, Product::load() skips the attribute and getArtefacts() is null.
-- 3) Embeds the YouTube Short k-FEeYSxmZc on TGS-2024043855 (Creating Engaging
--    Videos with Generative AI). The SKU exists only on SG, so on MY/GH this
--    step matches no rows. Steps 1-2 are harmless schema on every site.
-- 4) Same video on C1373 (Generative AI for Video Creation), SG only: C-prefix
--    SKUs also exist on MY/GH, so the write is guarded by @mms_instance='SG'.
--
-- Re-runnable: create is guarded; assignment is INSERT IGNORE; the value write
-- is INSERT ... ON DUPLICATE KEY UPDATE.

-- 1) Create the attribute if missing.
SET @existing := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'artefacts' LIMIT 1);
INSERT INTO eav_attribute (entity_type_id, attribute_code, backend_type, frontend_input, frontend_label, is_required, is_user_defined, is_unique, note)
SELECT 4, 'artefacts', 'text', 'textarea', 'Artefacts', 0, 1, 0,
       'HTML shown in the Artefacts tab of the course page (e.g. embedded YouTube videos of work made in the course). Leave empty to hide the tab.'
FROM DUAL WHERE @existing IS NULL;
SET @attr_artefacts := IFNULL(@existing, LAST_INSERT_ID());
INSERT IGNORE INTO catalog_eav_attribute (attribute_id, is_global, is_visible, is_html_allowed_on_front, is_wysiwyg_enabled, used_in_product_listing)
VALUES (@attr_artefacts, 1, 1, 1, 1, 0);

-- 2) Assign to the "General" group of every product attribute set.
INSERT IGNORE INTO eav_entity_attribute (entity_type_id, attribute_set_id, attribute_group_id, attribute_id, sort_order)
SELECT 4, eag.attribute_set_id, eag.attribute_group_id, @attr_artefacts, 61
FROM eav_attribute_group eag
JOIN eav_attribute_set eas ON eas.attribute_set_id = eag.attribute_set_id
WHERE eag.attribute_group_name = 'General' AND eas.entity_type_id = 4;

-- 3) TGS-2024043855: embed the course's sample AI-generated video (a YouTube Short).
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_artefacts, 0, e.entity_id,
       '<p>A short video created with generative AI tools, the kind of work you will produce in this course.</p>\n<div class="artefact-video artefact-video--short"><iframe src="https://www.youtube.com/embed/k-FEeYSxmZc" title="Video created with generative AI" loading="lazy" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe></div>'
FROM catalog_product_entity e
WHERE e.sku = 'TGS-2024043855'
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- 4) C1373 Generative AI for Video Creation (SG only; the SKU also exists on MY/GH).
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_artefacts, 0, e.entity_id,
       '<p>A short video created with generative AI tools, the kind of work you will produce in this course.</p>\n<div class="artefact-video artefact-video--short"><iframe src="https://www.youtube.com/embed/k-FEeYSxmZc" title="Video created with generative AI" loading="lazy" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe></div>'
FROM catalog_product_entity e
WHERE e.sku = 'C1373' AND @mms_instance = 'SG'
ON DUPLICATE KEY UPDATE value = VALUES(value);
