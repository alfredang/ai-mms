-- 1186: Reorganise the Generative AI Series category (SG content curation).
--
-- 1) Move OUT of Generative AI Series (and out of its child categories
--    GenAI Video Creation / Prompt Engineering / GenAI Content Creation, which
--    anchor-feed the series listing) into their proper series:
--    -> AI Vibe Coding Series : TGS-2024045802 (AI Vibe Coding for Data Mining and Modeling)
--                               TGS-2021006714 (AI Vibe Code of Image Generation)
--    -> Agentic AI Series     : TGS-2023037472 (Business Innovation with Agentic AI and AI Agents)
--                               TGS-2024049182 (Business Transformation with Agentic AI and AI Agents)
--                               TGS-2024045799 (Agentic AI for Product Development)
--                               TGS-2023041081 (Agentic AI Applications with Codex)
--                               TGS-2025056988 (Agentic AI for Digital Marketing)
--                               TGS-2023036088 (Agentic AI for Video Creation)
--                               TGS-2024045795 (Agentic AI for HR)
--    -> AI Agents Series      : TGS-2023037472, TGS-2024049182 (both, as requested),
--                               TGS-2026064173 (CASL - AI Agents with Gemini Spark)
--                               TGS-2023036153 (Multi AI Agents Workflow for Content Creation)
--    -> AI Security Series    : TGS-2025060472 (AI Security Awareness)
--    -> AWS Certification Exams: TGS-2024049338 (AWS Certified AI Practitioner Training)
--    (The three Microsoft Copilot courses are removed here too; migration 1187
--    attaches them to the new Microsoft Copilot Series category.)
--
-- 2) Pin the requested WSQ/CASL order at the top of Generative AI Series.
--    All pinned SKUs are TGS-, so the nightly CategoryOrdering sweep preserves
--    their relative order; non-WSQ C-prefix courses stay alphabetical below.
--
-- Business-key lookups only (url_key / SKU). TGS- SKUs and these url_keys do
-- not exist on partner instances, so this is a clean no-op there. Idempotent.

SET @gen := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'generative-ai-series' LIMIT 1
);
SET @genvid := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'genai-video-creation' LIMIT 1
);
SET @prompt := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'prompt-engineering-courses' LIMIT 1
);
SET @gencontent := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'chatgpt-and-generative-ai-courses' LIMIT 1
);
SET @vibe := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-vibe-coding-series' LIMIT 1
);
SET @agentic := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'agentic-ai-series' LIMIT 1
);
SET @agents := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-agents-series' LIMIT 1
);
SET @security := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-security-series' LIMIT 1
);
SET @aws := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'aws-certification-exams' LIMIT 1
);

-- ---------------------------------------------------------------------------
-- 1) Remove the moved courses from Generative AI Series AND its child
--    categories (anchor inheritance would otherwise keep them on the page).
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id IN (@gen, @genvid, @prompt, @gencontent)
  AND p.sku IN (
    'TGS-2024045802', 'TGS-2021006714',
    'TGS-2023037472', 'TGS-2024049182', 'TGS-2024045799', 'TGS-2023041081',
    'TGS-2025056988', 'TGS-2023036088', 'TGS-2024045795',
    'TGS-2026064173', 'TGS-2023036153',
    'TGS-2025060472',
    'TGS-2024043856', 'TGS-2022017524', 'TGS-2023036648',
    'TGS-2024049338'
  );

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id IN (@gen, @genvid, @prompt, @gencontent)
  AND p.sku IN (
    'TGS-2024045802', 'TGS-2021006714',
    'TGS-2023037472', 'TGS-2024049182', 'TGS-2024045799', 'TGS-2023041081',
    'TGS-2025056988', 'TGS-2023036088', 'TGS-2024045795',
    'TGS-2026064173', 'TGS-2023036153',
    'TGS-2025060472',
    'TGS-2024043856', 'TGS-2022017524', 'TGS-2023036648',
    'TGS-2024049338'
  );

-- ---------------------------------------------------------------------------
-- 2) Attach the moved courses to their target series (base + index mirror).
--    Position 9999 = end of list; the nightly ordering sweep renumbers.
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @vibe, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @vibe IS NOT NULL
  AND p.sku IN ('TGS-2024045802', 'TGS-2021006714');

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @vibe, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @vibe IS NOT NULL
  AND p.sku IN ('TGS-2024045802', 'TGS-2021006714')
GROUP BY p.entity_id, s.store_id;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @agentic, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @agentic IS NOT NULL
  AND p.sku IN (
    'TGS-2023037472', 'TGS-2024049182', 'TGS-2024045799', 'TGS-2023041081',
    'TGS-2025056988', 'TGS-2023036088', 'TGS-2024045795'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @agentic, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @agentic IS NOT NULL
  AND p.sku IN (
    'TGS-2023037472', 'TGS-2024049182', 'TGS-2024045799', 'TGS-2023041081',
    'TGS-2025056988', 'TGS-2023036088', 'TGS-2024045795'
  )
GROUP BY p.entity_id, s.store_id;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @agents, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @agents IS NOT NULL
  AND p.sku IN ('TGS-2023037472', 'TGS-2024049182', 'TGS-2026064173', 'TGS-2023036153');

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @agents, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @agents IS NOT NULL
  AND p.sku IN ('TGS-2023037472', 'TGS-2024049182', 'TGS-2026064173', 'TGS-2023036153')
GROUP BY p.entity_id, s.store_id;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @security, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @security IS NOT NULL
  AND p.sku = 'TGS-2025060472';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @security, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @security IS NOT NULL
  AND p.sku = 'TGS-2025060472'
GROUP BY p.entity_id, s.store_id;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @aws, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @aws IS NOT NULL
  AND p.sku = 'TGS-2024049338';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @aws, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @aws IS NOT NULL
  AND p.sku = 'TGS-2024049338'
GROUP BY p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 3) Pin the requested WSQ/CASL order at the top of Generative AI Series.
--     1. TGS-2023037589  WSQ - Generative AI for Content Creation
--     2. TGS-2025056983  WSQ - Generative AI for Script Development and Storytelling
--     3. TGS-2026061325  WSQ - Generative AI for Business Presentations
--     4. TGS-2020503501  WSQ - Generative AI for Search Engine Optimization (SEO)
--     5. TGS-2023036653  WSQ - Generative AI for Problem Solving
--     6. TGS-2024049183  WSQ - Project Management with Generative AI (GenAI)
--     7. TGS-2024049781  WSQ - Fast-Track Innovations with Agile Design Thinking and Generative AI (GenAI)
--     8. TGS-2026065050  CASL - Generative AI for Finance and Fintech
--     9. TGS-2025059025  WSQ - Generative AI Model Development and Fine Tuning
--    10. TGS-2024051421  WSQ - Generative AI for Interviewing
--    11. TGS-2024045220  WSQ - Generative AI (GenAI) Visuals in Photoshop and Firefly
--    12. TGS-2024043855  WSQ - Creating Engaging Videos with Generative AI (GenAI)
--    13. TGS-2020505925  WSQ - Generative AI for Image and Video Creation
--    14. TGS-2026064709  CASL - UI Design with AI
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2023037589' THEN -14
  WHEN 'TGS-2025056983' THEN -13
  WHEN 'TGS-2026061325' THEN -12
  WHEN 'TGS-2020503501' THEN -11
  WHEN 'TGS-2023036653' THEN -10
  WHEN 'TGS-2024049183' THEN -9
  WHEN 'TGS-2024049781' THEN -8
  WHEN 'TGS-2026065050' THEN -7
  WHEN 'TGS-2025059025' THEN -6
  WHEN 'TGS-2024051421' THEN -5
  WHEN 'TGS-2024045220' THEN -4
  WHEN 'TGS-2024043855' THEN -3
  WHEN 'TGS-2020505925' THEN -2
  WHEN 'TGS-2026064709' THEN -1
END
WHERE cp.category_id = @gen
  AND p.sku IN (
    'TGS-2023037589', 'TGS-2025056983', 'TGS-2026061325', 'TGS-2020503501',
    'TGS-2023036653', 'TGS-2024049183', 'TGS-2024049781', 'TGS-2026065050',
    'TGS-2025059025', 'TGS-2024051421', 'TGS-2024045220', 'TGS-2024043855',
    'TGS-2020505925', 'TGS-2026064709'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2023037589' THEN -14
  WHEN 'TGS-2025056983' THEN -13
  WHEN 'TGS-2026061325' THEN -12
  WHEN 'TGS-2020503501' THEN -11
  WHEN 'TGS-2023036653' THEN -10
  WHEN 'TGS-2024049183' THEN -9
  WHEN 'TGS-2024049781' THEN -8
  WHEN 'TGS-2026065050' THEN -7
  WHEN 'TGS-2025059025' THEN -6
  WHEN 'TGS-2024051421' THEN -5
  WHEN 'TGS-2024045220' THEN -4
  WHEN 'TGS-2024043855' THEN -3
  WHEN 'TGS-2020505925' THEN -2
  WHEN 'TGS-2026064709' THEN -1
END
WHERE i.category_id = @gen
  AND p.sku IN (
    'TGS-2023037589', 'TGS-2025056983', 'TGS-2026061325', 'TGS-2020503501',
    'TGS-2023036653', 'TGS-2024049183', 'TGS-2024049781', 'TGS-2026065050',
    'TGS-2025059025', 'TGS-2024051421', 'TGS-2024045220', 'TGS-2024043855',
    'TGS-2020505925', 'TGS-2026064709'
  );
