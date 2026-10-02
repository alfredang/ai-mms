-- C1158 "Improve Employee Wellness and Work Resilience" (1-day non-WSQ twin of TGS-2024045222
-- WSQ - Empowering Employee Health and Wellness at the Workplace).
--
-- 1. About (short_description) + topics (description, with LSN_DATA) copied verbatim from the
--    WSQ parent. The parent copy states no day count and does not name its own title.
-- 2. Cover: re-rendered with the new title (Agent API regenerate_image, 2026-10-02) — recorded
--    here so a rebuilt DB keeps it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1158' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024045222' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_cover := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, attribute_id, 0, @pid, value
  FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @src AND attribute_id IN (@a_short, @a_desc) AND store_id = 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1158-20261002-212902.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_cover AND store_id <> 0;
