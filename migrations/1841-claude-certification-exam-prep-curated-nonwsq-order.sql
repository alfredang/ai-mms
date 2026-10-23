-- 1841: Curated non-WSQ (C-prefix) order in the Claude Certification Exam Prep
-- category (url_key claude-certification-exam-prep-courses), per the owner's
-- requested sequence (foundations ladder first, professional last):
--   2. C991  — Claude Certified Associate - Foundations (CCAO-F) Exam Prep
--   3. C1098 — Claude Certified Developer - Foundations (CCDV-F) Exam Prep
--   4. C437  — Claude Certified Architect - Foundations (CCAR-F) Exam Prep
--   5. C740  — Claude Certified Architect - Professional (CCAR-P) Exam Prep
--
-- Two halves, both required:
--   1. Register the category in mmd/category_ordering/curated_url_keys, or the
--      nightly MMD_RoleManager_Model_Cron_CategoryOrdering sweep re-alphabetises
--      the C-block within a day. WSQ-first is still enforced either way.
--   2. Write the positions, continuing after the TGS- row at position 1.
--
-- Both the storefront-facing index and the admin-facing base table are written.
-- Resolved by url_key + SKU: a clean no-op on sites lacking this category/SKUs.
-- Idempotent.

-- 1. curated allow-list — append idempotently, preserving whatever is already there.
UPDATE core_config_data
   SET value = CONCAT(value, ',claude-certification-exam-prep-courses')
 WHERE path = 'mmd/category_ordering/curated_url_keys'
   AND FIND_IN_SET('claude-certification-exam-prep-courses', value) = 0;

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'default', 0, 'mmd/category_ordering/curated_url_keys', 'claude-certification-exam-prep-courses'
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM (SELECT 1 FROM core_config_data
        WHERE path = 'mmd/category_ordering/curated_url_keys' LIMIT 1) x);

-- 2. the curated positions.
SET @claude_cert_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'claude-certification-exam-prep-courses'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE TRIM(p.sku)
  WHEN 'C991' THEN 2
  WHEN 'C1098' THEN 3
  WHEN 'C437' THEN 4
  WHEN 'C740' THEN 5
END
WHERE cp.category_id = @claude_cert_category
  AND TRIM(p.sku) IN ('C991', 'C1098', 'C437', 'C740');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE TRIM(p.sku)
  WHEN 'C991' THEN 2
  WHEN 'C1098' THEN 3
  WHEN 'C437' THEN 4
  WHEN 'C740' THEN 5
END
WHERE i.category_id = @claude_cert_category
  AND TRIM(p.sku) IN ('C991', 'C1098', 'C437', 'C740');
