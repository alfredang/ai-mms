-- 1208: Move "Creating AI Agents and Chatbots with Microsoft Copilot Studio"
-- (C814) out of the Agentic AI Series and into the AI Agents Series; it is
-- already in the Microsoft Copilot Series.
--
-- How it reaches the Agentic AI Series: C814 has NO direct row there. It
-- surfaces only by ANCHOR INHERITANCE from the child category
-- 'Copilot Studio Agents' (microsoft-copilot-studio-agents), which sits under
-- the Agentic AI Series — the index row is is_parent = 0. So the removal is
-- the child-category assignment, not a row on 189 itself. (1200 removed the
-- other three members of that child category for the same reason.)
--
-- It is appended to the AI Agents Series after the existing rows, which sit
-- below that category's WSQ/CASL block, so WSQ/CASL/IBF still lead there.
-- Its Microsoft Copilot Series membership and pinned position (set by 1203)
-- are untouched.
--
-- Business-key lookups; SG-only SKU/url_keys (clean partner no-op).
-- Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @agentic := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'agentic-ai-series' LIMIT 1
);
SET @copilot_child := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'microsoft-copilot-studio-agents' LIMIT 1
);
SET @agents := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'ai-agents-series' LIMIT 1
);

-- Drop the child-category assignment that anchor-feeds the Agentic AI Series,
-- plus any index row on the series itself.
DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @copilot_child
  AND p.sku = 'C814';

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id IN (@agentic, @copilot_child)
  AND p.sku = 'C814';

-- Add to the AI Agents Series, after the existing rows.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @agents, p.entity_id,
       COALESCE((SELECT MAX(cp2.position) FROM (SELECT * FROM catalog_category_product) cp2
                 WHERE cp2.category_id = @agents), 0) + 1
FROM catalog_product_entity p
WHERE @agents IS NOT NULL
  AND p.sku = 'C814';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @agents, p.entity_id,
       COALESCE((SELECT MAX(i2.position) FROM (SELECT * FROM catalog_category_product_index) i2
                 WHERE i2.category_id = @agents AND i2.store_id = s.store_id), 0) + 1,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @agents IS NOT NULL
  AND p.sku = 'C814'
GROUP BY p.entity_id, s.store_id;
