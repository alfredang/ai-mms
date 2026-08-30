-- 1232: Place the two educator-facing courses in the Generative AI Series,
-- the AI Applications Series and the AI for Educators subcategory:
--   C505  Generative AI for Curriculum Development
--   C1176 Generative AI for Instructional Design
--
-- C1176 is already in the Generative AI Series (that INSERT is a defensive
-- no-op and its curated position there is left untouched); C505 joins it.
-- Both are new to the AI Applications Series and to AI for Educators, which
-- has been empty since 1206 created it — these are its first two courses.
--
-- Order in AI for Educators: Curriculum Development then Instructional
-- Design (design follows curriculum). On the AI Applications Series parent
-- the two are appended after the existing non-WSQ groups, in the same order.
-- Positions stay in the 101+ band, after every WSQ/CASL/IBF course; the
-- categories carry a curated non-WSQ order so the sweep preserves this.
--
-- SG-guarded; C-prefix SKUs and these url_keys are SG-only (partner no-op).
-- Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @gen := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'generative-ai-series' LIMIT 1);
SET @apps := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1);
SET @educators := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-educators' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Assign both courses to all three categories (base + index mirror).
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.id, p.entity_id, 9999
FROM catalog_product_entity p
JOIN (SELECT @gen AS id UNION ALL SELECT @apps UNION ALL SELECT @educators) c
  ON c.id IS NOT NULL
WHERE @is_sg > 0
  AND p.sku IN ('C505', 'C1176');

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT c.id, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN (SELECT @gen AS id UNION ALL SELECT @apps UNION ALL SELECT @educators) c
  ON c.id IS NOT NULL
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @is_sg > 0
  AND p.sku IN ('C505', 'C1176')
GROUP BY c.id, p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 2) AI for Educators — the category's first two courses.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku WHEN 'C505' THEN 101 WHEN 'C1176' THEN 102 END
WHERE cp.category_id = @educators
  AND p.sku IN ('C505', 'C1176');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku WHEN 'C505' THEN 101 WHEN 'C1176' THEN 102 END
WHERE i.category_id = @educators
  AND p.sku IN ('C505', 'C1176');

-- ---------------------------------------------------------------------------
-- 3) AI Applications Series parent — append after the existing non-WSQ
--    groups (Machine Learning currently ends at 136 after 1220).
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku WHEN 'C505' THEN 137 WHEN 'C1176' THEN 138 END
WHERE cp.category_id = @apps
  AND p.sku IN ('C505', 'C1176');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku WHEN 'C505' THEN 137 WHEN 'C1176' THEN 138 END
WHERE i.category_id = @apps
  AND p.sku IN ('C505', 'C1176');

-- ---------------------------------------------------------------------------
-- 4) Generative AI Series — seat C505 next to C1176, which sits in the
--    curated non-WSQ block created by 1199 (C1176 is at 110 there).
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = 110
WHERE cp.category_id = @gen
  AND p.sku = 'C505';

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = 110
WHERE i.category_id = @gen
  AND p.sku = 'C505';

-- C1176 shifts one place down so the pair reads Curriculum then Instructional
-- Design, and the rest of the curated block follows unchanged.
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C1176' THEN 111
  WHEN 'C802'  THEN 112
  WHEN 'C16'   THEN 113
  WHEN 'C152'  THEN 114
  WHEN 'C1373' THEN 115
  WHEN 'C037'  THEN 116
  WHEN 'C162'  THEN 117
  WHEN 'C1311' THEN 118
END
WHERE cp.category_id = @gen
  AND p.sku IN ('C1176', 'C802', 'C16', 'C152', 'C1373', 'C037', 'C162', 'C1311');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C1176' THEN 111
  WHEN 'C802'  THEN 112
  WHEN 'C16'   THEN 113
  WHEN 'C152'  THEN 114
  WHEN 'C1373' THEN 115
  WHEN 'C037'  THEN 116
  WHEN 'C162'  THEN 117
  WHEN 'C1311' THEN 118
END
WHERE i.category_id = @gen
  AND p.sku IN ('C1176', 'C802', 'C16', 'C152', 'C1373', 'C037', 'C162', 'C1311');
