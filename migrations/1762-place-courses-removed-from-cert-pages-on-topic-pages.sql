-- 1762: Follow-up to 1753. The courses taken off the certification pages are
-- placed on every topic page they belong on, and the eight that are also on
-- the Certification Exam Prep hub ('certification-exam-prep-courses') come off
-- it too — none of them is a certification course.
--
-- Additions (each course was missing this page; all others already correct):
--   TGS-2023039342  Generative AI for 3D Design            -> Generative AI Series
--   TGS-2024048311  AI for IT Security                     -> WSQ Cyber Security & PDPA, Cyber Security
--   TGS-2024052076  AI for IT Networking                   -> WSQ Cloud Computing & Networking, AI Infrastructure Series
--   TGS-2025056362  AI for Cloud Computing                 -> AI Infrastructure Series
--   TGS-2024042588  Microsoft Copilot for Content Creation -> WSQ Generative AI Courses
--   TGS-2024044051  AI Transformation with Microsoft Copilot -> WSQ AI Applications Courses, Microsoft Copilot
--
-- Each addition takes MAX(TGS- position)+1 on its page and shifts any non-TGS
-- row at/after that slot down one (funded first, see 1269 -> 1273). Every
-- ancestor of the page is an anchor and no reindex runs at deploy, so an
-- is_parent=0 index row is mirrored onto each anchor ancestor (INSERT IGNORE:
-- no-op where the course is already listed), exactly as the indexer would.
--
-- Category-membership only: no course status, visibility or content changes.
-- Business-key lookups only (url_key + TRIM(sku)); no-op on partner sites.
-- Idempotent: each shift runs only while the course is not yet on that page.

-- + TGS-2023039342 -> generative-ai-series
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2023039342' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='generative-ai-series' LIMIT 1);
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

-- + TGS-2024048311 -> wsq-cyber-security-pdpa-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024048311' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cyber-security-pdpa-courses' LIMIT 1);
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

-- + TGS-2024048311 -> cybersecurity-threat-analysis-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024048311' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='cybersecurity-threat-analysis-courses' LIMIT 1);
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

-- + TGS-2024052076 -> wsq-cloud-computing-and-networking-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024052076' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cloud-computing-and-networking-courses' LIMIT 1);
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

-- + TGS-2024052076 -> ai-infrastructure-series
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024052076' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='ai-infrastructure-series' LIMIT 1);
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

-- + TGS-2025056362 -> ai-infrastructure-series
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2025056362' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='ai-infrastructure-series' LIMIT 1);
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

-- + TGS-2024042588 -> wsq-generative-ai-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024042588' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-generative-ai-courses' LIMIT 1);
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

-- + TGS-2024044051 -> wsq-ai-applications-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024044051' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-ai-applications-courses' LIMIT 1);
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

-- + TGS-2024044051 -> microsoft-copilot-courses
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2024044051' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='microsoft-copilot-courses' LIMIT 1);
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

-- Remove the eight non-certification courses from Certification Exam Prep.
-- None sits in a child of that page, so the direct row is the only listing.

SET @cep := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='certification-exam-prep-courses' LIMIT 1);

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @cep AND @cep IS NOT NULL
  AND TRIM(p.sku) IN ('TGS-2023037544','TGS-2023039180','TGS-2024048311','TGS-2024051414',
    'TGS-2024052076','TGS-2025056362','TGS-2024042604','TGS-2025054471');

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @cep AND @cep IS NOT NULL
  AND TRIM(p.sku) IN ('TGS-2023037544','TGS-2023039180','TGS-2024048311','TGS-2024051414',
    'TGS-2024052076','TGS-2025056362','TGS-2024042604','TGS-2025054471');
