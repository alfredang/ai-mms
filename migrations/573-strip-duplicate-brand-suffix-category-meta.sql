-- 573: Strip the brand suffix from the three meta_titles seeded in 572.
--
-- MMD_Seotitle composes the <title> at render time and appends the store brand
-- postfix itself (see memory project_seo_title_render_time_composer). 572 baked
-- "| Tertiary Courses" into the stored meta_title, so the rendered title came
-- out as "... | Tertiary Courses | Tertiary Courses Singapore". Store the bare
-- title and let the composer add the brand.
--
-- Only touches the three titles 572 wrote. Idempotent (no-op once stripped).
-- After deploy: reindex catalog_category_flat + flush cache (storefront reads flat).

SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title');

UPDATE catalog_category_entity_varchar SET value = 'Java Programming Courses in Singapore'
WHERE attribute_id = @a_mt AND value = 'Java Programming Courses in Singapore | Tertiary Courses';

UPDATE catalog_category_entity_varchar SET value = 'Marketing Analytics Courses in Singapore'
WHERE attribute_id = @a_mt AND value = 'Marketing Analytics Courses in Singapore | Tertiary Courses';

UPDATE catalog_category_entity_varchar SET value = 'Google Cloud Certification Exam Prep Courses'
WHERE attribute_id = @a_mt AND value = 'Google Cloud Certification Exam Prep Courses | Tertiary Courses';
