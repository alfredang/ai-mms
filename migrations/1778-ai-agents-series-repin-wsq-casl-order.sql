-- 1778: Re-pin the WSQ/CASL (TGS-) order in the AI Agents Series category
-- (url_key ai-agents-series) to the owner's requested sequence:
--    1. TGS-2024049182 — WSQ - Business Transformation with Agentic AI and AI Agents
--    2. TGS-2020503395 — WSQ - Business Innovation with AI Agents
--    3. TGS-2023037472 — WSQ - Business Innovation with Agentic AI and AI Agents
--    4. TGS-2024043854 — WSQ - Build a Human-AI Workforce with Autonomous AI Agents
--    5. TGS-2022017524 — WSQ - Business Process Automation with Power Automate and Copilot Studio Agents
--    6. TGS-2023036657 — WSQ - Agentic AI and AI Agents for Video Inbound Marketing
--    7. TGS-2024052081 — WSQ - Automate Video and Voice AI Agents with n8n
--    8. TGS-2023018987 — WSQ - AI Agents for Business
--    9. TGS-2025054471 — WSQ - Autonomous AI Agents
--   10. TGS-2026064176 — CASL - AI Agent with Hermes Agent
--   11. TGS-2026064859 — CASL - Autonomous AI Agents with OpenClaw
--   12. TGS-2026064173 — CASL - AI Agents with Gemini Spark
--   13. TGS-2023036646 — WSQ - Manage AI Agents with Paperclip
--   14. TGS-2023036153 — WSQ - Multi AI Agents Workflow for Content Creation
--   15. TGS-2025053228 — WSQ - AI Agent Cybersecurity
--   16. TGS-2024042604 — WSQ - Security Operations for Autonomous AI Agents
--   17. TGS-2025060473 — WSQ - AI Security for Autonomous AI Agents
--   18. TGS-2024042309 — WSQ - Develop AI Agents with OpenAI Agent Development Kit
--   19. TGS-2024042961 — WSQ - Develop Multi AI Agent Applications with Gemini Agent ADK
--   20. TGS-2021010367 — WSQ - Harness and Loop Engineering for AI Agents
--   21. TGS-2023036651 — WSQ - Developing AI Apps and Agents on Azure (AI-103)
--
-- All 21 courses already have DIRECT base rows on this category (verified on SG
-- prod 2026-10-05), so the pin survives the daily reindex; the ordering sweep
-- preserves TGS- relative order. Positive positions 1..21 in both tables; the
-- curated non-WSQ block (positions 22+) is untouched. Business-key lookups,
-- no-op where the category or a SKU is absent (partner sites). Idempotent.

SET @ai_agents_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'ai-agents-series'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2024049182' THEN 1
  WHEN 'TGS-2020503395' THEN 2
  WHEN 'TGS-2023037472' THEN 3
  WHEN 'TGS-2024043854' THEN 4
  WHEN 'TGS-2022017524' THEN 5
  WHEN 'TGS-2023036657' THEN 6
  WHEN 'TGS-2024052081' THEN 7
  WHEN 'TGS-2023018987' THEN 8
  WHEN 'TGS-2025054471' THEN 9
  WHEN 'TGS-2026064176' THEN 10
  WHEN 'TGS-2026064859' THEN 11
  WHEN 'TGS-2026064173' THEN 12
  WHEN 'TGS-2023036646' THEN 13
  WHEN 'TGS-2023036153' THEN 14
  WHEN 'TGS-2025053228' THEN 15
  WHEN 'TGS-2024042604' THEN 16
  WHEN 'TGS-2025060473' THEN 17
  WHEN 'TGS-2024042309' THEN 18
  WHEN 'TGS-2024042961' THEN 19
  WHEN 'TGS-2021010367' THEN 20
  WHEN 'TGS-2023036651' THEN 21
END
WHERE cp.category_id = @ai_agents_category
  AND p.sku IN (
    'TGS-2024049182',
    'TGS-2020503395',
    'TGS-2023037472',
    'TGS-2024043854',
    'TGS-2022017524',
    'TGS-2023036657',
    'TGS-2024052081',
    'TGS-2023018987',
    'TGS-2025054471',
    'TGS-2026064176',
    'TGS-2026064859',
    'TGS-2026064173',
    'TGS-2023036646',
    'TGS-2023036153',
    'TGS-2025053228',
    'TGS-2024042604',
    'TGS-2025060473',
    'TGS-2024042309',
    'TGS-2024042961',
    'TGS-2021010367',
    'TGS-2023036651'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2024049182' THEN 1
  WHEN 'TGS-2020503395' THEN 2
  WHEN 'TGS-2023037472' THEN 3
  WHEN 'TGS-2024043854' THEN 4
  WHEN 'TGS-2022017524' THEN 5
  WHEN 'TGS-2023036657' THEN 6
  WHEN 'TGS-2024052081' THEN 7
  WHEN 'TGS-2023018987' THEN 8
  WHEN 'TGS-2025054471' THEN 9
  WHEN 'TGS-2026064176' THEN 10
  WHEN 'TGS-2026064859' THEN 11
  WHEN 'TGS-2026064173' THEN 12
  WHEN 'TGS-2023036646' THEN 13
  WHEN 'TGS-2023036153' THEN 14
  WHEN 'TGS-2025053228' THEN 15
  WHEN 'TGS-2024042604' THEN 16
  WHEN 'TGS-2025060473' THEN 17
  WHEN 'TGS-2024042309' THEN 18
  WHEN 'TGS-2024042961' THEN 19
  WHEN 'TGS-2021010367' THEN 20
  WHEN 'TGS-2023036651' THEN 21
END
WHERE i.category_id = @ai_agents_category
  AND p.sku IN (
    'TGS-2024049182',
    'TGS-2020503395',
    'TGS-2023037472',
    'TGS-2024043854',
    'TGS-2022017524',
    'TGS-2023036657',
    'TGS-2024052081',
    'TGS-2023018987',
    'TGS-2025054471',
    'TGS-2026064176',
    'TGS-2026064859',
    'TGS-2026064173',
    'TGS-2023036646',
    'TGS-2023036153',
    'TGS-2025053228',
    'TGS-2024042604',
    'TGS-2025060473',
    'TGS-2024042309',
    'TGS-2024042961',
    'TGS-2021010367',
    'TGS-2023036651'
  );
