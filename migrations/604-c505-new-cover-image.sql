-- Point C505 at its NEW branded cover, rendered from the post-602 title
-- "Generative AI for Curriculum Development" and uploaded to R2.
--
-- The rename template (595/602) does NOT touch course_image_url, so a
-- repurposed course keeps its OLD branded cover — the storefront reads
-- course_image_url, an R2 PNG rendered from the old title. Without this the
-- product tile/page would show "eLearning Instructional Design" artwork under
-- the new name.
-- (memory: feedback_course_repurpose_cross_site_rollout addendum 2026-07-18)
--
-- Shipped as a SEPARATE migration rather than folded into 602 because 602 is
-- already in the schema_migrations ledger — an edited migration never re-runs
-- on a DB that has already applied it.
-- (memory: feedback_edited_shared_migrations_never_rerun_on_prod)
--
-- Old cover: course-covers/C505-20260717-162857.png (rendered from old title)
-- New cover: course-covers/C505-20260718-142106.png (verified 200, 140755 bytes)
--
-- Store scope 0, clearing per-store overrides. Guarded on @e505. Idempotent.

SET @e505 := (SELECT entity_id FROM catalog_product_entity WHERE sku='C505');
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e505, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C505-20260718-142106.png'
FROM DUAL WHERE @e505 IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE v FROM catalog_product_entity_varchar v
WHERE v.entity_id = @e505 AND v.store_id <> 0 AND v.attribute_id = @a_ciu
  AND @e505 IS NOT NULL AND @a_ciu IS NOT NULL;
