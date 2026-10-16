-- 1826: Take the machine-learning / AI-cert courses off the AI Infrastructure
-- Series ('ai-infrastructure-series'); they belong on AI for Machine Learning
-- ('ai-for-machine-learning'), and DP-100 on Data Analytics + Microsoft Certs.
--
-- Prod audit 2026-10-16 (SG): every course below is ALREADY a direct member of
-- its destination(s), except DP-100 on Data Analytics. So the change is:
--   1) remove all 12 from AI Infrastructure Series (base + index rows);
--   2) add TGS-2023036642 DP-100 to 'data-analytics-courses'.
-- Already in place, no write needed:
--   - the 11 ML courses on 'ai-for-machine-learning' (same relative order);
--   - DP-100, AI-901 (TGS-2023021100) and AI-103 (TGS-2023036651) on
--     'microsoft-certifications-exams'.
--
-- AI Infrastructure Series has no child categories, so nothing re-derives the
-- removed rows on reindex. The courses stay on the AI Series parent through
-- AI for Machine Learning, so its rows are left alone. Remaining 250 rows keep
-- their relative order (curated category; TGS block still above the C block).
--
-- DP-100 takes MAX(TGS- position)+1 on Data Analytics and shifts the non-TGS
-- rows at/after that slot down one (funded first, see 1269 -> 1273); anchor
-- ancestors get an is_parent=0 index row as the indexer would (pattern 1762).
--
-- Category-membership only. Business-key lookups (url_key + TRIM(sku)); TGS-
-- SKUs exist only on SG, so this no-ops on partner sites. Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @infra := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-infrastructure-series' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Leave AI Infrastructure Series.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @infra
  AND TRIM(p.sku) IN (
    'TGS-2026064713',  -- CASL - Computer Vision for Beginners
    'TGS-2020503264',  -- WSQ - Data Mining and Machine Learning Fundamentals for Beginners
    'TGS-2026064715',  -- CASL - Python Text Mining and Analytics
    'TGS-2026064608',  -- CASL - Pattern Recognition and ML with R (casl-ai-vibe-coding-for-machine-learning)
    'TGS-2026064714',  -- CASL - Practical Reinforcement Learning for Beginners
    'TGS-2020505815',  -- WSQ - Building Advanced ML and AI Solutions with Pytorch
    'TGS-2023021100',  -- WSQ - Microsoft Azure AI Fundamentals (AI-901)
    'TGS-2023036651',  -- WSQ - Developing AI Apps and Agents on Azure (AI-103)
    'TGS-2024049338',  -- WSQ - AWS Certified AI Practitioner Training
    'TGS-2024049340',  -- WSQ - AWS Certified ML Engineer Associate Training
    'TGS-2023040476',  -- WSQ - Google Professional ML Engineer Training
    'TGS-2023036642'   -- WSQ - Microsoft Azure Data Scientist Associate (DP-100)
  );

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @infra
  AND TRIM(p.sku) IN (
    'TGS-2026064713','TGS-2020503264','TGS-2026064715','TGS-2026064608',
    'TGS-2026064714','TGS-2020505815','TGS-2023021100','TGS-2023036651',
    'TGS-2024049338','TGS-2024049340','TGS-2023040476','TGS-2023036642'
  );

-- ---------------------------------------------------------------------------
-- 2) + TGS-2023036642 (DP-100) -> data-analytics-courses
-- ---------------------------------------------------------------------------

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2023036642' LIMIT 1);
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='data-analytics-courses' LIMIT 1);
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
