-- 1288: WSQ Generative AI Courses (379) — move nine courses out, pin the
-- requested order for the twelve that remain, and complete two series->WSQ
-- category mappings.
--
-- MOVES OUT of WSQ Generative AI:
--   -> WSQ Agentic AI Courses (196): Agentic AI for HR, Business Innovation
--      with Agentic AI and AI Agents, Agentic AI for Product Development,
--      Generative AI for Content Creation, Multi AI Agents Workflow for Content
--      Creation, Agentic AI Applications with Codex, Business Process
--      Automation with Power Automate and Copilot Studio Agents.
--      (The request said to move these "to WSQ Generative AI Courses" — the page
--      they were already on. They are agentic/content courses and the companion
--      request asks that every Agentic AI Series course be listed in WSQ Agentic
--      AI, so WSQ Agentic AI is the destination; three of the seven also appear
--      in that series-gap list, so both requests agree.)
--      Codex and Power Automate are already members there -> removal only.
--   -> WSQ Business (302): Business Transformation with Agentic AI and AI
--      Agents, AI Security Governance for Businesses. Neither is in WSQ Business
--      yet, so both are genuinely added.
--
-- ALSO, so every series course appears in its WSQ counterpart:
--   * Generative AI Series (433) -> WSQ Generative AI (379): adds the five TGS-
--     courses that were missing (Business Presentations, GenAI for SEO,
--     Generative AI for Interviewing, CASL UI Design with AI, Enhancing Online
--     Presence with AI Powered SEO). Only TGS- courses are copied — the series'
--     C-prefix courses stay put, since the WSQ category is WSQ/CASL-only.
--     ONE DELIBERATE EXCEPTION: TGS-2023037589 "Generative AI for Content
--     Creation" is in the Generative AI Series but was explicitly named for
--     removal from WSQ Generative AI, so it is NOT re-added by the sync — the
--     specific move instruction wins over the blanket "list every series course"
--     rule. It lands in WSQ Agentic AI instead.
--   * Agentic AI Series (189) -> WSQ Agentic AI (196): adds the seven missing
--     TGS- courses (which include four of the movers above).
--
-- Requested order for the twelve remaining in WSQ Generative AI:
--   1 TGS-2024043856  Enhance Work Productivity with Microsoft 365 Copilot
--   2 TGS-2023036653  Generative AI for Problem Solving
--   3 TGS-2023039342  Generative AI for 3D Design
--   4 TGS-2023037544  Generative AI for 3D Modeling
--   5 TGS-2024049183  Project Management with Generative AI (GenAI)
--   6 TGS-2024049781  Fast-Track Innovations with Agile Design Thinking and GenAI
--   7 TGS-2026065050  CASL - Generative AI for Finance and Fintech
--   8 TGS-2025056983  Generative AI for Script Development and Storytelling
--   9 TGS-2024045220  Generative AI (GenAI) Visuals in Photoshop and Firefly
--  10 TGS-2024043855  Creating Engaging Videos with Generative AI (GenAI)
--  11 TGS-2020505925  Generative AI for Image and Video Creation
--  12 TGS-2025059025  Generative AI Model Development and Fine Tuning
-- The five courses added from the series are NOT in the requested order, so they
-- keep their places after the pinned block rather than being dropped.
--
-- Newly added rows go ABOVE the C-block where one exists (196 and 379 are
-- all-TGS, so appending is safe here). Business-key lookups only. Idempotent.

SET @gen := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-generative-ai-courses' LIMIT 1);
SET @ag := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-agentic-ai-courses' LIMIT 1);
SET @bz := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-business-courses' LIMIT 1);

-- Ensure the movers + Agentic-series gap are in WSQ Agentic AI (196)
DROP TEMPORARY TABLE IF EXISTS tmp_add;
CREATE TEMPORARY TABLE tmp_add (sku VARCHAR(64) PRIMARY KEY);
INSERT IGNORE INTO tmp_add (sku) VALUES ('TGS-2020505996'),('TGS-2022017524'),('TGS-2023036153'),('TGS-2023036657'),('TGS-2023037472'),('TGS-2023037589'),('TGS-2023041081'),('TGS-2024045795'),('TGS-2024045799'),('TGS-2024049182'),('TGS-2026064473');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @ag, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @ag)
FROM tmp_add m JOIN catalog_product_entity p ON p.sku = m.sku
WHERE @ag IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @ag, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @ag),
       1, s.store_id, MAX(i.visibility)
FROM tmp_add m
JOIN catalog_product_entity p ON p.sku = m.sku
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id=p.entity_id AND i.store_id=s.store_id
WHERE @ag IS NOT NULL
GROUP BY p.entity_id, s.store_id;

DROP TEMPORARY TABLE IF EXISTS tmp_add;

-- Add the two business courses to WSQ Business (302)
DROP TEMPORARY TABLE IF EXISTS tmp_add;
CREATE TEMPORARY TABLE tmp_add (sku VARCHAR(64) PRIMARY KEY);
INSERT IGNORE INTO tmp_add (sku) VALUES ('TGS-2024049182'),('TGS-2026061329');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @bz, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @bz)
FROM tmp_add m JOIN catalog_product_entity p ON p.sku = m.sku
WHERE @bz IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @bz, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @bz),
       1, s.store_id, MAX(i.visibility)
FROM tmp_add m
JOIN catalog_product_entity p ON p.sku = m.sku
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id=p.entity_id AND i.store_id=s.store_id
WHERE @bz IS NOT NULL
GROUP BY p.entity_id, s.store_id;

DROP TEMPORARY TABLE IF EXISTS tmp_add;

-- Add the Generative-AI-series gap to WSQ Generative AI (379)
DROP TEMPORARY TABLE IF EXISTS tmp_add;
CREATE TEMPORARY TABLE tmp_add (sku VARCHAR(64) PRIMARY KEY);
INSERT IGNORE INTO tmp_add (sku) VALUES ('TGS-2026061325'),('TGS-2020503501'),('TGS-2024051421'),('TGS-2026064709'),('TGS-2019503343');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @gen, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @gen)
FROM tmp_add m JOIN catalog_product_entity p ON p.sku = m.sku
WHERE @gen IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @gen, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @gen),
       1, s.store_id, MAX(i.visibility)
FROM tmp_add m
JOIN catalog_product_entity p ON p.sku = m.sku
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id=p.entity_id AND i.store_id=s.store_id
WHERE @gen IS NOT NULL
GROUP BY p.entity_id, s.store_id;

DROP TEMPORARY TABLE IF EXISTS tmp_add;

-- Remove the nine moved courses from WSQ Generative AI
DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @gen AND @gen IS NOT NULL
  AND p.sku IN ('TGS-2024045795','TGS-2023037472','TGS-2024045799','TGS-2023037589',
                'TGS-2023036153','TGS-2023041081','TGS-2022017524','TGS-2024049182',
                'TGS-2026061329');

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @gen AND @gen IS NOT NULL
  AND p.sku IN ('TGS-2024045795','TGS-2023037472','TGS-2024045799','TGS-2023037589',
                'TGS-2023036153','TGS-2023041081','TGS-2022017524','TGS-2024049182',
                'TGS-2026061329');

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2024043856' THEN -12
  WHEN 'TGS-2023036653' THEN -11
  WHEN 'TGS-2023039342' THEN -10
  WHEN 'TGS-2023037544' THEN -9
  WHEN 'TGS-2024049183' THEN -8
  WHEN 'TGS-2024049781' THEN -7
  WHEN 'TGS-2026065050' THEN -6
  WHEN 'TGS-2025056983' THEN -5
  WHEN 'TGS-2024045220' THEN -4
  WHEN 'TGS-2024043855' THEN -3
  WHEN 'TGS-2020505925' THEN -2
  WHEN 'TGS-2025059025' THEN -1
END
WHERE cp.category_id = @gen AND @gen IS NOT NULL
  AND p.sku IN ('TGS-2024043856','TGS-2023036653','TGS-2023039342','TGS-2023037544',
                'TGS-2024049183','TGS-2024049781','TGS-2026065050','TGS-2025056983',
                'TGS-2024045220','TGS-2024043855','TGS-2020505925','TGS-2025059025');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2024043856' THEN -12
  WHEN 'TGS-2023036653' THEN -11
  WHEN 'TGS-2023039342' THEN -10
  WHEN 'TGS-2023037544' THEN -9
  WHEN 'TGS-2024049183' THEN -8
  WHEN 'TGS-2024049781' THEN -7
  WHEN 'TGS-2026065050' THEN -6
  WHEN 'TGS-2025056983' THEN -5
  WHEN 'TGS-2024045220' THEN -4
  WHEN 'TGS-2024043855' THEN -3
  WHEN 'TGS-2020505925' THEN -2
  WHEN 'TGS-2025059025' THEN -1
END
WHERE i.category_id = @gen AND @gen IS NOT NULL
  AND p.sku IN ('TGS-2024043856','TGS-2023036653','TGS-2023039342','TGS-2023037544',
                'TGS-2024049183','TGS-2024049781','TGS-2026065050','TGS-2025056983',
                'TGS-2024045220','TGS-2024043855','TGS-2020505925','TGS-2025059025');
