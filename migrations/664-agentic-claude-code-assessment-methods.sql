-- 664: TGS-2025052468 (WSQ Agentic AI Applications with Claude Code)
-- Assessment card must show Written Exam + Practical Exam (was Practical Exam only).
-- Also strips the stray "<p><em>Written Assessment (SAQ)</em></p>" line baked into
-- the description — assessment lines live in assessment_methods, never in description.
-- Partner-safe: joins on the TGS- SKU, which exists only on SG; no-op elsewhere.

-- Ensure the assessment_methods row exists at store_id=0
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT a.entity_type_id, a.attribute_id, 0, e.entity_id, ''
FROM catalog_product_entity e
JOIN eav_attribute a
  ON a.attribute_code = 'assessment_methods'
 AND a.entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product')
WHERE e.sku = 'TGS-2025052468'
  AND NOT EXISTS (
    SELECT 1 FROM catalog_product_entity_text t
    WHERE t.entity_id = e.entity_id AND t.attribute_id = a.attribute_id AND t.store_id = 0
  );

-- Set Written Exam + Practical Exam, resolving option ids by label (never hardcoded)
UPDATE catalog_product_entity_text t
JOIN catalog_product_entity e ON e.entity_id = t.entity_id AND e.sku = 'TGS-2025052468'
JOIN eav_attribute a
  ON a.attribute_id = t.attribute_id
 AND a.attribute_code = 'assessment_methods'
 AND a.entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product')
SET t.value = (
  SELECT GROUP_CONCAT(o.option_id ORDER BY FIELD(v.value, 'Written Exam', 'Practical Exam'))
  FROM eav_attribute_option o
  JOIN eav_attribute_option_value v ON v.option_id = o.option_id AND v.store_id = 0
  WHERE o.attribute_id = a.attribute_id AND v.value IN ('Written Exam', 'Practical Exam')
)
WHERE t.store_id = 0;

-- Remove the stray assessment line from the description (ASCII-only replace, byte-safe)
UPDATE catalog_product_entity_text t
JOIN catalog_product_entity e ON e.entity_id = t.entity_id AND e.sku = 'TGS-2025052468'
JOIN eav_attribute a
  ON a.attribute_id = t.attribute_id
 AND a.attribute_code = 'description'
 AND a.entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product')
SET t.value = REPLACE(t.value, '<p><em>Written Assessment (SAQ)</em></p>', '')
WHERE t.value LIKE '%<p><em>Written Assessment (SAQ)</em></p>%';
