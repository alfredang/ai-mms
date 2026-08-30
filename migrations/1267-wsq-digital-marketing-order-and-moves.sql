-- 1267: WSQ Digital Marketing Courses (url_key 'wsq-digital-marketing-courses')
-- — pin the requested order, add one course to the Claude AI Series, and move
-- one course out to WSQ Business Courses.
--
-- Requested order (the request listed "WSQ - Claude Cowork for Email Marketing"
-- twice, at 2nd and last; a product holds one slot, so it is pinned once at 2):
--   1  TGS-2023018659  WSQ - Claude Cowork for Digital Marketing
--   2  TGS-2020503109  WSQ - Claude Cowork for Email Marketing
--   3  TGS-2020503501  WSQ - Generative AI for Search Engine Optimization (SEO)
--   4  TGS-2019503343  WSQ - Enhancing Online Presence with AI Powered SEO
--   5  TGS-2022017520  WSQ - Agentic AI for Market Research
--   6  TGS-2023036153  WSQ - Multi AI Agents Workflow for Content Creation
--   7  TGS-2021003023  WSQ - Generative AI for Social Media Marketing
--   8  TGS-2026064473  CASL - Agentic AI for Email Marketing Campaign
--   9  TGS-2025060552  WSQ - Agentic AI for Affiliate Marketing
--  10  TGS-2021009337  WSQ - Pay Per Click (PPC) Campaign Optimization
--
-- Also ADDS TGS-2020503109 (Claude Cowork for Email Marketing) to the Claude AI
-- Series, and REMOVES TGS-2025053924 (Service Branding Strategies) from Digital
-- Marketing. Service Branding is ALREADY a member of WSQ Business Courses, so
-- that move is only the removal here.
--
-- Negative positions keep the pinned block ahead of anything unpinned; the daily
-- ordering sweep preserves TGS relative order. Business-key lookups only.
-- Idempotent.

SET @dm := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-digital-marketing-courses' LIMIT 1);
SET @cl := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='claude-ai-series' LIMIT 1);
SET @bz := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-business-courses' LIMIT 1);

-- 1. Add Claude Cowork for Email Marketing to the Claude AI Series -----------

SET @cl_pos := (SELECT COALESCE(MAX(position),0) FROM catalog_category_product WHERE category_id=@cl);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cl, p.entity_id, @cl_pos + 1
FROM catalog_product_entity p
WHERE p.sku = 'TGS-2020503109' AND @cl IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cl, p.entity_id, @cl_pos + 1, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id=p.entity_id AND i.store_id=s.store_id
WHERE p.sku = 'TGS-2020503109' AND @cl IS NOT NULL
GROUP BY p.entity_id, s.store_id;

-- 2. Ensure Service Branding is in WSQ Business, then drop it from Digital ----
--    Marketing (it is already a member there; this is a safety net).

SET @bz_pos := (SELECT COALESCE(MAX(position),0) FROM catalog_category_product WHERE category_id=@bz);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @bz, p.entity_id, @bz_pos + 1
FROM catalog_product_entity p
WHERE p.sku = 'TGS-2025053924' AND @bz IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @bz, p.entity_id, @bz_pos + 1, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id=p.entity_id AND i.store_id=s.store_id
WHERE p.sku = 'TGS-2025053924' AND @bz IS NOT NULL
GROUP BY p.entity_id, s.store_id;

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @dm AND @dm IS NOT NULL AND p.sku = 'TGS-2025053924';

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @dm AND @dm IS NOT NULL AND p.sku = 'TGS-2025053924';

-- Digital Marketing is a child of WSQ Media & Marketing, which lists ONLY the
-- courses reachable through its sub-categories (migration 1265). Service
-- Branding just left the last such sub-category, so drop its leftover rows on
-- the parent too — otherwise it would still show there.
SET @mm := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-media-marketing-courses' LIMIT 1);

-- Materialise "still reachable via a sub-category" first: MySQL cannot read the
-- same table it is deleting from inside a subquery (error 1093).
DROP TEMPORARY TABLE IF EXISTS tmp_mm_still_child;
CREATE TEMPORARY TABLE tmp_mm_still_child (product_id INT PRIMARY KEY);
INSERT IGNORE INTO tmp_mm_still_child (product_id)
SELECT c2.product_id
FROM catalog_category_product c2
JOIN catalog_category_entity ce ON ce.entity_id = c2.category_id AND ce.parent_id = @mm
JOIN catalog_product_entity p ON p.entity_id = c2.product_id
WHERE @mm IS NOT NULL AND p.sku = 'TGS-2025053924';

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @mm AND @mm IS NOT NULL AND p.sku = 'TGS-2025053924'
  AND cp.product_id NOT IN (SELECT product_id FROM tmp_mm_still_child);

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @mm AND @mm IS NOT NULL AND p.sku = 'TGS-2025053924'
  AND i.product_id NOT IN (SELECT product_id FROM tmp_mm_still_child);

DROP TEMPORARY TABLE IF EXISTS tmp_mm_still_child;

-- 3. Pin the requested Digital Marketing order -------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2023018659' THEN -10
  WHEN 'TGS-2020503109' THEN  -9
  WHEN 'TGS-2020503501' THEN  -8
  WHEN 'TGS-2019503343' THEN  -7
  WHEN 'TGS-2022017520' THEN  -6
  WHEN 'TGS-2023036153' THEN  -5
  WHEN 'TGS-2021003023' THEN  -4
  WHEN 'TGS-2026064473' THEN  -3
  WHEN 'TGS-2025060552' THEN  -2
  WHEN 'TGS-2021009337' THEN  -1
END
WHERE cp.category_id = @dm AND @dm IS NOT NULL
  AND p.sku IN ('TGS-2023018659','TGS-2020503109','TGS-2020503501','TGS-2019503343',
                'TGS-2022017520','TGS-2023036153','TGS-2021003023','TGS-2026064473',
                'TGS-2025060552','TGS-2021009337');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2023018659' THEN -10
  WHEN 'TGS-2020503109' THEN  -9
  WHEN 'TGS-2020503501' THEN  -8
  WHEN 'TGS-2019503343' THEN  -7
  WHEN 'TGS-2022017520' THEN  -6
  WHEN 'TGS-2023036153' THEN  -5
  WHEN 'TGS-2021003023' THEN  -4
  WHEN 'TGS-2026064473' THEN  -3
  WHEN 'TGS-2025060552' THEN  -2
  WHEN 'TGS-2021009337' THEN  -1
END
WHERE i.category_id = @dm AND @dm IS NOT NULL
  AND p.sku IN ('TGS-2023018659','TGS-2020503109','TGS-2020503501','TGS-2019503343',
                'TGS-2022017520','TGS-2023036153','TGS-2021003023','TGS-2026064473',
                'TGS-2025060552','TGS-2021009337');
