-- 1015: TGS-2024045802 -- new R2 cover URL after the 1014 repurpose
--   "WSQ - Neo4j Graph Data Science and Large Language Model (LLM)"
--     -> "WSQ - AI Vibe Coding for Data Mining and Modeling"
--
-- Separate file from 1014 because the PNG is rendered + uploaded to R2 out of
-- band (CLI replication of CoursecoverController: getProductBadges -> cover
-- render -> R2 putObject), so the URL is only known after 1014 has been applied.
-- Rendered 2026-08-14; badges baked into the cover are unchanged (WSQ,
-- SkillsFuture Credit, PSEA, UTAP, SFEC, Absentee Payroll, MCES).
--
-- Idempotent: sets a full target value; re-running converges.
-- Partner-safe: TGS- SKUs do not exist on MY/GH, so this matches zero rows there.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024045802');

UPDATE catalog_product_entity_varchar
SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024045802-20260814-133940.png'
WHERE entity_id = @e
  AND attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
