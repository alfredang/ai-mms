-- Rename C1018: "Agentic AI for Healthcare" -> "AI for Healthcare"
-- Rebrand only: name, meta_title, image labels, cover. Description,
-- short_description, meta_description, meta_keyword and the gallery labels
-- already say "AI for Healthcare" and are intentionally untouched.
-- url_key stays ai-for-healthcare (already matches the new title;
-- no slug change, so no url_path drop / rewrite reindex churn needed).
-- Cover re-rendered 2026-07-18 with the new title (no funding chips —
-- C1018 carries no funding-badge tags) and uploaded to R2.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C1018.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1018');
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_ciu  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'AI for Healthcare' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'AI for Healthcare' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- New cover rendered from the new title, uploaded to R2 2026-07-18
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1018-20260717-181525.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'AI for Healthcare' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'AI for Healthcare' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'AI for Healthcare' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_il, @a_sil, @a_til, @a_ciu);
