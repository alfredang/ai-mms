-- 968: Point TGS-2025053228 at its regenerated AI Agent Cybersecurity cover.
--
-- Migration 954 renamed this course from "WSQ - Pearson Vue Certified IT
-- Specialist Cybersecurity" to "WSQ - AI Agent Cybersecurity", but the cover
-- image is a PRE-RENDERED PNG on R2 -- renaming the product does not redraw it.
-- The live storefront kept serving the 2026-07-17 render, whose baked-in title
-- still read "Pearson Vue Certified IT Specialist Cybersecurity".
--
-- The new PNG has already been rendered by MMD_CourseImage_Model_Cover (same
-- code path as the admin cover dialog / bulkRunAction) and uploaded to R2:
--   course-covers/TGS-2025053228-20260813-053628.png   (155545 bytes, HTTP 200)
-- R2 is SHARED storage read by every site, so the object is already reachable
-- from production; only the course_image_url pointer needs updating here.
--
-- The 7 funding badges were passed to the renderer unchanged
-- (WSQ, SkillsFuture Credit, PSEA, UTAP, SFEC, Absentee Payroll, MCES) so the
-- chips on the cover still match the `tag` rows that drive the storefront
-- pills -- no tag writes are needed and none are made here.
--
-- The superseded 2026-07-17 object is deliberately NOT deleted from R2: it
-- keeps this change trivially reversible (repoint the URL) and costs nothing.
--
-- Idempotent: plain UPDATE to a literal value; re-running converges.
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025053228' LIMIT 1);
SET @a_ciu := (SELECT attribute_id FROM eav_attribute
                WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

-- course_image_url is Store View scoped (migration 126). This install serves a
-- single store, and the existing value lives at the global scope, so write
-- scope 0 and clear any store-scoped row that would shadow it.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2025053228-20260813-053628.png'
 WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0
   AND @e IS NOT NULL AND @a_ciu IS NOT NULL;

-- NOTE: the storefront reads product data from the FLAT table
-- (catalog/frontend/flat_catalog_product is enabled on this install), and an
-- EAV write alone leaves the flat row stale. The deploy does not reindex, so
-- after this migration applies, run "Catalog Flat Data" (or the reindex API)
-- for the cover to actually change on the live listing + product page.
