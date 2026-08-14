-- 1022-tgs2023018659-cover-url.sql
--
-- Companion to 1021-repurpose-tgs2023018659-claude-cowork-for-digital-marketing.sql
-- Pins the regenerated R2 cover for "WSQ - Claude Cowork for Digital Marketing".
-- The cover PNG was rendered + uploaded from the admin/CLI (badges: WSQ, SkillsFuture
-- Credit, PSEA, UTAP, SFEC, Absentee Payroll, MCES); this file makes a rebuilt DB
-- converge on the same URL instead of falling back to the stale Google-Tag-Manager cover.
--
-- Idempotent (plain UPDATE to a constant) and partner-safe (@e is NULL on MY/GH -> no-op).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023018659');
SET @a_ciu := (SELECT attribute_id FROM eav_attribute
                WHERE attribute_code = 'course_image_url' AND entity_type_id = 4);
SET @url := 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023018659-20260814-135418.png';

UPDATE catalog_product_entity_varchar
   SET value = @url
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Guarded insert for the case where the store-0 row does not exist yet.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, @url FROM dual
 WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_product_entity_varchar) v
                    WHERE v.entity_id = @e AND v.attribute_id = @a_ciu AND v.store_id = 0);

-- Drop any store-scoped override so the store-0 value wins.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0;
