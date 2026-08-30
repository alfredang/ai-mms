-- 1221: Move "Business Transformation with AI Agents" (C997) out of the
-- AI Infrastructure Series and into the AI Agents Series.
--
-- It is ALREADY a member of the AI Applications Series and its AI for
-- Business subcategory (added by 1204, which converted this course from
-- "Google Cloud Certified Professional Machine Learning Engineer Training"),
-- so those two INSERTs are defensive no-ops and its curated position in
-- AI for Business (right after "Business Transformation with AI Agents"'s
-- sibling entries) is left untouched.
--
-- In the AI Agents Series it is placed directly after C691 "Business
-- Transformation with OpenClaw Digital Employees" — the same
-- business-transformation theme — and the non-WSQ rows below it shift down
-- one. That category carries a curated non-WSQ order
-- (mmd/category_ordering/curated_url_keys), so the full block is re-pinned
-- here rather than left to drift; positions stay in the 101+ band, after
-- every WSQ/CASL/IBF course.
--
-- Business-key lookups; SG-only SKU/url_keys (partner no-op). Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @infra := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-infrastructure-series' LIMIT 1);
SET @agents := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-agents-series' LIMIT 1);
SET @apps := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1);
SET @business := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-business' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Leave the AI Infrastructure Series.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @infra
  AND p.sku = 'C997';

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @infra
  AND p.sku = 'C997';

-- ---------------------------------------------------------------------------
-- 2) Ensure membership of the AI Agents Series, the AI Applications Series
--    and AI for Business (the latter two already hold it).
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.id, p.entity_id, 9999
FROM catalog_product_entity p
JOIN (SELECT @agents AS id UNION ALL SELECT @apps UNION ALL SELECT @business) c
  ON c.id IS NOT NULL
WHERE p.sku = 'C997';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT c.id, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN (SELECT @agents AS id UNION ALL SELECT @apps UNION ALL SELECT @business) c
  ON c.id IS NOT NULL
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE p.sku = 'C997'
GROUP BY c.id, p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 3) AI Agents Series — re-pin the curated non-WSQ block with C997 inserted
--    after C691.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C690'  THEN 101
  WHEN 'C1871' THEN 102
  WHEN 'C1434' THEN 103
  WHEN 'C691'  THEN 104
  WHEN 'C997'  THEN 105
  WHEN 'C1259' THEN 106
  WHEN 'C177'  THEN 107
  WHEN 'C1440' THEN 108
  WHEN 'C1760' THEN 109
  WHEN 'C926'  THEN 110
  WHEN 'C814'  THEN 111
END
WHERE cp.category_id = @agents
  AND p.sku IN ('C690','C1871','C1434','C691','C997','C1259','C177','C1440','C1760','C926','C814');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C690'  THEN 101
  WHEN 'C1871' THEN 102
  WHEN 'C1434' THEN 103
  WHEN 'C691'  THEN 104
  WHEN 'C997'  THEN 105
  WHEN 'C1259' THEN 106
  WHEN 'C177'  THEN 107
  WHEN 'C1440' THEN 108
  WHEN 'C1760' THEN 109
  WHEN 'C926'  THEN 110
  WHEN 'C814'  THEN 111
END
WHERE i.category_id = @agents
  AND p.sku IN ('C690','C1871','C1434','C691','C997','C1259','C177','C1440','C1760','C926','C814');
