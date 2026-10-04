-- 1747: Azure / data exam courses belong on the Microsoft Certification Exam
-- Prep pages; DP-300 does not belong in Power Platform Certification.
--
--   TGS-2023036642  WSQ - Microsoft Azure Data Scientist Associate (DP-100)
--   TGS-2024042602  WSQ - Microsoft Certified Fabric Data Engineer Associate (DP-700) Training
--   TGS-2024048319  WSQ - Administering Microsoft Azure SQL Solutions (DP-300)
--
-- 1. Safety net: all three in Microsoft Certification Exam Prep (url_keys
--    'microsoft-certifications-exams' + child 'instructor-led-microsoft-exam-prep').
--    On SG they are ALREADY direct members of both (verified on prod 2026-10-04),
--    so these INSERT IGNOREs no-op there.
-- 2. Remove DP-300 from Power Platform Certification
--    ('microsoft-power-platform-certification-courses'). Parent-anchor check:
--    DP-300 keeps its direct rows on both parents and stays in Azure
--    Certification, so nothing else is touched. DP-100 / DP-700 are left in
--    Power Platform Certification as requested.
--
-- Business-key lookups only (url_key + TRIM(sku)); partner sites carry no TGS-
-- courses, so the file no-ops there. Idempotent.

SET @ms := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='microsoft-certifications-exams' LIMIT 1);
SET @msil := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='instructor-led-microsoft-exam-prep' LIMIT 1);
SET @pp := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='microsoft-power-platform-certification-courses' LIMIT 1);

-- 1. Ensure membership in Microsoft Certification Exam Prep -------------------

DROP TEMPORARY TABLE IF EXISTS tmp_dp_place;
CREATE TEMPORARY TABLE tmp_dp_place (category_id INT, product_id INT, PRIMARY KEY (category_id, product_id));
INSERT IGNORE INTO tmp_dp_place (category_id, product_id)
SELECT c.id, p.entity_id
FROM (SELECT @ms AS id UNION ALL SELECT @msil) c
JOIN catalog_product_entity p ON TRIM(p.sku) IN ('TGS-2023036642','TGS-2024042602','TGS-2024048319')
WHERE c.id IS NOT NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT t.category_id, t.product_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = t.category_id)
FROM tmp_dp_place t;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT t.category_id, t.product_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = t.category_id),
       1, i.store_id, MAX(i.visibility)
FROM tmp_dp_place t
JOIN catalog_category_product_index i ON i.product_id = t.product_id AND i.store_id > 0
GROUP BY t.category_id, t.product_id, i.store_id;

DROP TEMPORARY TABLE IF EXISTS tmp_dp_place;

-- 2. Remove DP-300 from Power Platform Certification --------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @pp AND @pp IS NOT NULL
  AND TRIM(p.sku) = 'TGS-2024048319';

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @pp AND @pp IS NOT NULL
  AND TRIM(p.sku) = 'TGS-2024048319';
