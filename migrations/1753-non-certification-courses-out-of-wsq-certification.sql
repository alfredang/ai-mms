-- 1753: Remove 15 courses that are not certification courses from WSQ
-- Certification Courses ('wsq-certification-courses') — leftovers from
-- earlier lives of these products. The category has no children, and every
-- other membership of these courses is untouched.
--
--   TGS-2023037544  WSQ - Generative AI for 3D Modeling
--   TGS-2023039342  WSQ - Generative AI for 3D Design
--   TGS-2023039180  WSQ - Generative AI Design for Civil 3D
--   TGS-2023039177  WSQ - AI for Cyber Security
--   TGS-2024048311  WSQ - AI for IT Security
--   TGS-2024051414  WSQ - AI for Network Security
--   TGS-2024052076  WSQ - AI for IT Networking
--   TGS-2025056362  WSQ - AI for Cloud Computing
--   TGS-2024042604  WSQ - Security Operations for Autonomous AI Agents
--   TGS-2025053228  WSQ - AI Agent Cybersecurity
--   TGS-2025054471  WSQ - Autonomous AI Agents
--   TGS-2024042588  WSQ - Microsoft Copilot for Content Creation and Task Automation
--   TGS-2024044051  WSQ - AI Transformation with Microsoft Copilot
--   TGS-2023040473  WSQ - AI for Unity 2D and 3D Game Development
--   TGS-2025060471  WSQ - Personal Data Protection Management for SMEs
--
-- Business-key lookups only (url_key + TRIM(sku)); no-op on partner sites.
-- Idempotent.

SET @cert := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-certification-courses' LIMIT 1);

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @cert AND @cert IS NOT NULL
  AND TRIM(p.sku) IN ('TGS-2023037544','TGS-2023039342','TGS-2023039180',
    'TGS-2023039177','TGS-2024048311','TGS-2024051414','TGS-2024052076',
    'TGS-2025056362','TGS-2024042604','TGS-2025053228','TGS-2025054471',
    'TGS-2024042588','TGS-2024044051','TGS-2023040473','TGS-2025060471');

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @cert AND @cert IS NOT NULL
  AND TRIM(p.sku) IN ('TGS-2023037544','TGS-2023039342','TGS-2023039180',
    'TGS-2023039177','TGS-2024048311','TGS-2024051414','TGS-2024052076',
    'TGS-2025056362','TGS-2024042604','TGS-2025053228','TGS-2025054471',
    'TGS-2024042588','TGS-2024044051','TGS-2023040473','TGS-2025060471');
