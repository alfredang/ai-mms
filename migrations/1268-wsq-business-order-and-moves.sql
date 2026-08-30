-- 1268: WSQ Business Courses (url_key 'wsq-business-courses') — move four
-- courses out and pin the requested order for the remaining twelve.
--
-- Moves OUT of WSQ Business (each is ALREADY a member of its destination, so
-- these are removals from WSQ Business only; the INSERT IGNOREs below are a
-- safety net in case an instance is missing the destination row):
--   TGS-2026064719  CASL - Generative AI for Design Thinking      -> WSQ Soft Skills
--   TGS-2026064533  CASL - Cyber Security Awareness Course        -> WSQ Cyber Security & PDPA
--   TGS-2026064859  CASL - Autonomous AI Agents with OpenClaw     -> WSQ Agentic AI
--   TGS-2023018967  WSQ - Agile Project Management for Business   -> WSQ Project Management
--
-- Requested order for the twelve that remain:
--   1  TGS-2025053924  WSQ - Service Branding Strategies to Elevate Your Business
--   2  TGS-2025056191  WSQ - Improve Your Business with Excellent Customer Service
--   3  TGS-2023020567  WSQ - Unlocking Business Potential with Strategic Negotiation Tactics
--   4  TGS-2026061325  WSQ - Generative AI for Business Presentations
--   5  TGS-2026061582  WSQ - Managing Business Disruptions and Continuity
--   6  TGS-2025053923  WSQ - Corporate Law Compliance for Business Owners
--   7  TGS-2026064716  CASL - Business Innovation with Artificial Intelligence
--   8  TGS-2023037472  WSQ - Business Innovation with Agentic AI and AI Agents
--   9  TGS-2020503395  WSQ - Business Innovation with AI Agents
--  10  TGS-2024045801  WSQ - Agentic AI for Business Process Automation
--  11  TGS-2026064711  CASL - Business Innovation with Internet-of-Things (IoT)
--  12  TGS-2023039835  WSQ - Business Innovation with Metaverse and Immersive Technologies
--
-- Negative positions keep the pinned block ahead of anything unpinned; the daily
-- ordering sweep preserves TGS relative order. Business-key lookups only.
-- Idempotent.

SET @bz := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-business-courses' LIMIT 1);
SET @ss := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-soft-skills-courses' LIMIT 1);
SET @cy := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cyber-security-pdpa-courses' LIMIT 1);
SET @ag := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-agentic-ai-courses' LIMIT 1);
SET @pm := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-project-management-courses' LIMIT 1);

-- 1. Safety net: ensure each mover exists in its destination category ---------

DROP TEMPORARY TABLE IF EXISTS tmp_bz_moves;
CREATE TEMPORARY TABLE tmp_bz_moves (sku VARCHAR(64) PRIMARY KEY, dest_id INT);
INSERT INTO tmp_bz_moves (sku, dest_id) VALUES
  ('TGS-2026064719', @ss),
  ('TGS-2026064533', @cy),
  ('TGS-2026064859', @ag),
  ('TGS-2023018967', @pm);
DELETE FROM tmp_bz_moves WHERE dest_id IS NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT m.dest_id, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = m.dest_id)
FROM tmp_bz_moves m
JOIN catalog_product_entity p ON p.sku = m.sku;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT m.dest_id, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = m.dest_id),
       1, s.store_id, MAX(i.visibility)
FROM tmp_bz_moves m
JOIN catalog_product_entity p ON p.sku = m.sku
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
GROUP BY m.dest_id, p.entity_id, s.store_id;

-- 2. Remove the four movers from WSQ Business --------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @bz AND @bz IS NOT NULL
  AND p.sku IN ('TGS-2026064719','TGS-2026064533','TGS-2026064859','TGS-2023018967');

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @bz AND @bz IS NOT NULL
  AND p.sku IN ('TGS-2026064719','TGS-2026064533','TGS-2026064859','TGS-2023018967');

DROP TEMPORARY TABLE IF EXISTS tmp_bz_moves;

-- 3. Pin the requested WSQ Business order ------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2025053924' THEN -12
  WHEN 'TGS-2025056191' THEN -11
  WHEN 'TGS-2023020567' THEN -10
  WHEN 'TGS-2026061325' THEN  -9
  WHEN 'TGS-2026061582' THEN  -8
  WHEN 'TGS-2025053923' THEN  -7
  WHEN 'TGS-2026064716' THEN  -6
  WHEN 'TGS-2023037472' THEN  -5
  WHEN 'TGS-2020503395' THEN  -4
  WHEN 'TGS-2024045801' THEN  -3
  WHEN 'TGS-2026064711' THEN  -2
  WHEN 'TGS-2023039835' THEN  -1
END
WHERE cp.category_id = @bz AND @bz IS NOT NULL
  AND p.sku IN ('TGS-2025053924','TGS-2025056191','TGS-2023020567','TGS-2026061325',
                'TGS-2026061582','TGS-2025053923','TGS-2026064716','TGS-2023037472',
                'TGS-2020503395','TGS-2024045801','TGS-2026064711','TGS-2023039835');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2025053924' THEN -12
  WHEN 'TGS-2025056191' THEN -11
  WHEN 'TGS-2023020567' THEN -10
  WHEN 'TGS-2026061325' THEN  -9
  WHEN 'TGS-2026061582' THEN  -8
  WHEN 'TGS-2025053923' THEN  -7
  WHEN 'TGS-2026064716' THEN  -6
  WHEN 'TGS-2023037472' THEN  -5
  WHEN 'TGS-2020503395' THEN  -4
  WHEN 'TGS-2024045801' THEN  -3
  WHEN 'TGS-2026064711' THEN  -2
  WHEN 'TGS-2023039835' THEN  -1
END
WHERE i.category_id = @bz AND @bz IS NOT NULL
  AND p.sku IN ('TGS-2025053924','TGS-2025056191','TGS-2023020567','TGS-2026061325',
                'TGS-2026061582','TGS-2025053923','TGS-2026064716','TGS-2023037472',
                'TGS-2020503395','TGS-2024045801','TGS-2026064711','TGS-2023039835');
