-- 682: Multi Agents Series (679 follow-up) — the former RAG & Fine Tuning
-- category carried include_in_menu = 0, so the renamed series was missing from
-- the AI Courses mega-menu dropdown. Enable it (siblings all carry 1).
-- Resolved by url_key; idempotent.

SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_menu := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'include_in_menu');
SET @cat := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id = @a_uk AND store_id = 0 AND value = 'multi-agents-series' LIMIT 1);

UPDATE catalog_category_entity_int SET value = 1
  WHERE entity_id = @cat AND attribute_id = @a_menu AND store_id = 0;
INSERT IGNORE INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
  SELECT 3, @a_menu, 0, @cat, 1 FROM dual
  WHERE @cat IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM catalog_category_entity_int WHERE entity_id = @cat AND attribute_id = @a_menu AND store_id = 0);
