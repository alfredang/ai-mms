-- 1018: TGS-2022017520 cover image URL -> the re-rendered "Agentic AI for Market
-- Research" PNG.
--
-- Companion to 1017 (the repurpose). The rename migration does NOT touch
-- course_image_url, so without this the storefront keeps rendering the OLD
-- branded cover (the R2 PNG bakes the course TITLE, and the 20260717 asset says
-- "Unlocking the Power of Google Analytics (GA4) for Advanced Web Analytics")
-- under the new name -- memory feedback_course_repurpose_cross_site_rollout,
-- "covers go stale on repurpose".
--
-- The PNG was rendered from the product's own name + badges via
-- mmd_courseimage/cover and uploaded with
-- Mage::helper('mmd_courseimage/r2')->putObject(...). That helper returns an
-- ARRAY ['url'=>..., 'bytes'=>...], not a string -- writing its result straight
-- into course_image_url silently stores the literal "Array" while the upload
-- still succeeds, so the value below was asserted to start with https:// before
-- being written (memory feedback_course_repurpose_cross_site_rollout).
-- Badges baked into the cover: WSQ, SkillsFuture Credit, PSEA, UTAP, SFEC,
-- Absentee Payroll, MCES (read from the product's tag_relation -- unchanged by
-- the repurpose). Render verified: 166651 bytes.
--
-- Clears store_id <> 0 overrides so no per-store row shadows the new value.
--
-- PARTNER SAFETY: TGS- SKUs exist only on SG; @e is NULL on MY/GH, so the
-- INSERT is guarded and every statement is a clean no-op there.
--
-- IDEMPOTENCY: full-value upsert; re-running converges.

SET @e   := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2022017520');
SET @a_ci := (SELECT attribute_id FROM eav_attribute
               WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND attribute_id = @a_ci AND store_id <> 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ci, 0, @e,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022017520-20260814-134801.png'
FROM dual
WHERE @e IS NOT NULL AND @a_ci IS NOT NULL
ON DUPLICATE KEY UPDATE
  value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2022017520-20260814-134801.png';
