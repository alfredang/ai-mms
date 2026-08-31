-- 1278: WSQ Project Management Courses (url_key 'wsq-project-management-courses')
-- — move one course out and pin the requested order for the remaining eleven.
--
-- MOVED OUT: TGS-2024051900 "WSQ - Certified Lean Six Sigma Black Belt (CLSSBB)
-- Training" -> WSQ Quality Assurance. It is ALREADY a member of Quality
-- Assurance (position 14 there), so this is a removal from Project Management
-- only; the INSERT IGNORE below is a per-instance safety net.
-- No parent cleanup is needed here: cat 9's parent (160) holds no direct row for
-- this product, unlike the WSQ Media & Marketing cases in 1267/1269/1272.
--
-- Requested order:
--   1  TGS-2020505545  WSQ - Effective Project Management for Small Projects
--   2  TGS-2024045797  WSQ - Project Management Professional
--   3  TGS-2023018967  WSQ - Agile Project Management for Business
--   4  TGS-2023018990  WSQ - Mastering Agile Project Management for IT Projects
--   5  TGS-2024045803  WSQ - Scrum Master Fundamentals for High-Performing Teams
--   6  TGS-2024049183  WSQ - Project Management with Generative AI (GenAI)
--   7  TGS-2024049781  WSQ - Fast-Track Innovations with Agile Design Thinking and GenAI
--   8  TGS-2024042307  WSQ - Fundamentals of Microsoft Project Management
--   9  TGS-2024049350  WSQ - ITIL 4 Foundation Training
--  10  TGS-2024045800  WSQ - Implementing Digital Facilities Management System
--  11  TGS-2023041080  WSQ - Mastering Notion for Content, Project, and Database Management
--
-- All eleven are TGS- and the category holds no C-prefix course, so the nightly
-- sweep has nothing to re-alphabetise and it preserves TGS relative order — no
-- curated-allowlist entry needed. Negative positions keep the pinned block ahead
-- of anything unpinned. Business-key lookups only. Idempotent.

SET @pm := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-project-management-courses' LIMIT 1);
SET @qa := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-quality-assurance-courses' LIMIT 1);

-- 1. Safety net: ensure the course is in Quality Assurance ---------------------

SET @qa_pos := (SELECT COALESCE(MAX(position),0) FROM catalog_category_product WHERE category_id=@qa);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @qa, p.entity_id, @qa_pos + 1
FROM catalog_product_entity p
WHERE p.sku = 'TGS-2024051900' AND @qa IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @qa, p.entity_id, @qa_pos + 1, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE p.sku = 'TGS-2024051900' AND @qa IS NOT NULL
GROUP BY p.entity_id, s.store_id;

-- 2. Remove it from Project Management ---------------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @pm AND @pm IS NOT NULL AND p.sku = 'TGS-2024051900';

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @pm AND @pm IS NOT NULL AND p.sku = 'TGS-2024051900';

-- 3. Pin the requested order --------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2020505545' THEN -11
  WHEN 'TGS-2024045797' THEN -10
  WHEN 'TGS-2023018967' THEN  -9
  WHEN 'TGS-2023018990' THEN  -8
  WHEN 'TGS-2024045803' THEN  -7
  WHEN 'TGS-2024049183' THEN  -6
  WHEN 'TGS-2024049781' THEN  -5
  WHEN 'TGS-2024042307' THEN  -4
  WHEN 'TGS-2024049350' THEN  -3
  WHEN 'TGS-2024045800' THEN  -2
  WHEN 'TGS-2023041080' THEN  -1
END
WHERE cp.category_id = @pm AND @pm IS NOT NULL
  AND p.sku IN ('TGS-2020505545','TGS-2024045797','TGS-2023018967','TGS-2023018990',
                'TGS-2024045803','TGS-2024049183','TGS-2024049781','TGS-2024042307',
                'TGS-2024049350','TGS-2024045800','TGS-2023041080');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2020505545' THEN -11
  WHEN 'TGS-2024045797' THEN -10
  WHEN 'TGS-2023018967' THEN  -9
  WHEN 'TGS-2023018990' THEN  -8
  WHEN 'TGS-2024045803' THEN  -7
  WHEN 'TGS-2024049183' THEN  -6
  WHEN 'TGS-2024049781' THEN  -5
  WHEN 'TGS-2024042307' THEN  -4
  WHEN 'TGS-2024049350' THEN  -3
  WHEN 'TGS-2024045800' THEN  -2
  WHEN 'TGS-2023041080' THEN  -1
END
WHERE i.category_id = @pm AND @pm IS NOT NULL
  AND p.sku IN ('TGS-2020505545','TGS-2024045797','TGS-2023018967','TGS-2023018990',
                'TGS-2024045803','TGS-2024049183','TGS-2024049781','TGS-2024042307',
                'TGS-2024049350','TGS-2024045800','TGS-2023041080');
