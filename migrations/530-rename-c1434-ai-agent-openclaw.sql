-- Rename C1434: "Build Autonomous AI Agent with Openclaw" -> "AI Agent with Openclaw"
-- Name-only rebrand (drop the "Build Autonomous" prefix). SKU C1434 unchanged.
-- Touches: name + the three image labels. meta_title/description/keyword are
-- NULL (title composed at render by MMD_Seotitle) so nothing meta to touch.
-- url_key stays build-autonomous-ai-agent-with-openclaw (precedent C1063/C1013:
-- keep the slug — no url_path drop / rewrite reindex churn, no 301 needed).
-- Curriculum (description), overview (short_description), price and duration
-- are intentionally kept.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C1434.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1434');
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'AI Agent with Openclaw' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'AI Agent with Openclaw' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'AI Agent with Openclaw' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'AI Agent with Openclaw' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear per-store overrides so partner store scopes can't shadow store 0.
DELETE v FROM catalog_product_entity_varchar v
WHERE v.entity_id = @e AND v.store_id <> 0
  AND v.attribute_id IN (@a_name, @a_il, @a_sil, @a_til);
