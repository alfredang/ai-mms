-- 1771: completes 1770 (series placements requested 2026-10-04). 1770 adds the
-- cyber-security courses to AI Security Series and TGS-2024042961 to Multi AI
-- Agents Series; this file adds the remaining gaps found by the same audit:
--
--   AI Security Series ('ai-security-series'):
--     TGS-2024043419  WSQ - Securing the Future with Quantum Computing and Cryptography
--     TGS-2024047021  WSQ - Microsoft Identity and Access Administrator (SC-300)
--     TGS-2025060471  WSQ - Personal Data Protection Management for SMEs
--   WSQ Multi AI Agents Courses ('wsq-multi-ai-agents-courses'):
--     TGS-2024042961  WSQ - Develop Multi AI Agent Applications with Gemini Agent ADK
--     (the WSQ twin page of Multi AI Agents Series, where its siblings already sit)
--
-- Each addition takes MAX(TGS- position)+1 and shifts any non-TGS row at/after
-- that slot down one; is_parent=0 index rows are mirrored onto every anchor
-- ancestor, as the indexer would. Category memberships only: no course status
-- or content changes. Categories by url_key, products by TRIM(sku); no-op where
-- absent (MY/GH have no TGS- courses). Idempotent.
-- AFTER APPLYING ON PROD: flush block_html / full_page / collections.
-- + TGS-2024043419 -> ai-security-series
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024043419' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='ai-security-series' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024047021 -> ai-security-series
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024047021' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='ai-security-series' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2025060471 -> ai-security-series
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2025060471' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='ai-security-series' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

-- + TGS-2024042961 -> wsq-multi-ai-agents-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024042961' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-multi-ai-agents-courses' LIMIT 1);
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');
UPDATE catalog_category_product cp JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
UPDATE catalog_category_product_index i JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT anc.entity_id, @pid, 10000 + @slot, 0, i.store_id, MAX(i.visibility)
FROM catalog_category_entity c
JOIN catalog_category_entity anc
  ON FIND_IN_SET(anc.entity_id, REPLACE(c.path, '/', ',')) AND anc.entity_id <> c.entity_id AND anc.level >= 2
JOIN catalog_category_entity_int an ON an.entity_id = anc.entity_id AND an.store_id = 0 AND an.value = 1
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id AND aa.entity_type_id = 3 AND aa.attribute_code = 'is_anchor'
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id > 0
WHERE c.entity_id = @cat AND @pid IS NOT NULL
GROUP BY anc.entity_id, i.store_id;

