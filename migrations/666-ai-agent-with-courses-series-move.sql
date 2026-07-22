-- 666: Courses titled "AI Agent with ..." belong in "AI Agents Series", NOT "Agentic AI Series".
-- (C1434 AI Agent with Openclaw, C1871 AI Agent with Hermes Agent — resolved by name, not id,
-- so the same file is correct on SG/MY/GH whatever their category/product ids are.)

SET @petid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @cetid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category');
SET @a_pname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @petid AND attribute_code = 'name');
SET @a_cname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @cetid AND attribute_code = 'name');

-- Ensure membership in "AI Agents Series"
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.entity_id, p.entity_id, 0
FROM catalog_category_entity_varchar c
JOIN catalog_product_entity_varchar p ON p.attribute_id = @a_pname AND p.store_id = 0 AND p.value LIKE 'AI Agent with %'
WHERE c.attribute_id = @a_cname AND c.store_id = 0 AND c.value = 'AI Agents Series';

-- Remove from "Agentic AI Series"
DELETE cp FROM catalog_category_product cp
JOIN catalog_category_entity_varchar c ON c.entity_id = cp.category_id AND c.attribute_id = @a_cname AND c.store_id = 0 AND c.value = 'Agentic AI Series'
JOIN catalog_product_entity_varchar p ON p.entity_id = cp.product_id AND p.attribute_id = @a_pname AND p.store_id = 0 AND p.value LIKE 'AI Agent with %';
