-- Migration 638: WSQ Build and Deploy Python Applications with Vibe Coding (TGS-2019504591)
-- 1. Strip the assessment lines from the description so the "What You'll Learn"
--    card shows topics only (both the LSN_DATA JSON subsecs and the <p><em> HTML).
-- 2. Set the assessment_methods multiselect (source of the Assessment card) to
--    Written Exam + Case Study + Oral Questioning, resolved by option label.
-- Idempotent. Partner-safe: TGS- SKUs exist on SG only, so this no-ops elsewhere.

UPDATE catalog_product_entity_text t
JOIN catalog_product_entity e ON e.entity_id = t.entity_id AND e.sku = 'TGS-2019504591'
JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code = 'description' AND a.entity_type_id = 4
SET t.value = REPLACE(REPLACE(REPLACE(REPLACE(t.value,
    '{"title":"Written Exam","links":[]},{"title":"Case Study (CS)","links":[]},{"title":"Oral Questioning (OQ)","links":[]}', ''),
    '<p><em>Written Exam</em></p>', ''),
    '<p><em>Case Study (CS)</em></p>', ''),
    '<p><em>Oral Questioning (OQ)</em></p>', '');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, e.entity_id,
    CONCAT_WS(',',
        (SELECT o.option_id FROM eav_attribute_option o
          JOIN eav_attribute_option_value v ON v.option_id = o.option_id AND v.store_id = 0
         WHERE o.attribute_id = a.attribute_id AND v.value = 'Written Exam' LIMIT 1),
        (SELECT o.option_id FROM eav_attribute_option o
          JOIN eav_attribute_option_value v ON v.option_id = o.option_id AND v.store_id = 0
         WHERE o.attribute_id = a.attribute_id AND v.value = 'Case Study' LIMIT 1),
        (SELECT o.option_id FROM eav_attribute_option o
          JOIN eav_attribute_option_value v ON v.option_id = o.option_id AND v.store_id = 0
         WHERE o.attribute_id = a.attribute_id AND v.value = 'Oral Questioning' LIMIT 1))
FROM catalog_product_entity e
JOIN eav_attribute a ON a.attribute_code = 'assessment_methods' AND a.entity_type_id = 4
WHERE e.sku = 'TGS-2019504591'
ON DUPLICATE KEY UPDATE value = VALUES(value);
