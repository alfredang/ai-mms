-- Migration 637: WSQ Build and Deploy Python Applications with Vibe Coding (TGS-2019504591)
-- "What You'll Learn" assessment lines: drop "Final Assessment",
-- rename "Written Assessment - Short Answer Questions (WA-SAQ)" -> "Written Exam".
-- Edits the product description attribute (LSN_DATA JSON comment + rendered HTML).
-- Idempotent (REPLACE no-ops once applied). Partner-safe: TGS- SKUs exist on SG only.

UPDATE catalog_product_entity_text t
JOIN catalog_product_entity e ON e.entity_id = t.entity_id AND e.sku = 'TGS-2019504591'
JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code = 'description' AND a.entity_type_id = 4
SET t.value = REPLACE(REPLACE(REPLACE(REPLACE(t.value,
    '{"title":"Final Assessment","links":[]},', ''),
    '"Written Assessment - Short Answer Questions (WA-SAQ)"', '"Written Exam"'),
    '<p><em>Final Assessment</em></p>', ''),
    '<em>Written Assessment - Short Answer Questions (WA-SAQ)</em>', '<em>Written Exam</em>');
