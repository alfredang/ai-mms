-- 1827: Follow-up to 1826 — the non-WSQ twins of the ML / Azure AI cert
-- courses also come off the AI Infrastructure Series ('ai-infrastructure-series')
-- and belong on AI for Machine Learning ('ai-for-machine-learning').
--
-- Prod audit 2026-10-17 (SG): all seven are ALREADY direct members of AI for
-- Machine Learning, so this is a removal only:
--   C430  AI Vibe Coding for Machine Learning
--   C592  AI Vibe Coding for Computer Vision
--   C539  AI Vibe Coding for Deep Learning
--   C1071 AI-901 Microsoft Azure AI Fundamentals
--   C926  AI-103 Microsoft Certified Azure AI Apps and Agents Developer Associate
--   C1759 AI-200 Microsoft Certified Azure AI Cloud Developer Associate
--   C1762 AI-300 Microsoft Certified Machine Learning Operations Engineer Associate
-- C922 Fine Tuning Open Source LLM stays (twin of the WSQ fine-tuning course
-- that remains on the series).
--
-- AI Infrastructure Series has no child categories, so nothing re-derives the
-- removed rows on reindex. Remaining rows keep their relative order.
--
-- C- SKUs also exist on partner sites, so the writes are SG-guarded
-- (@mms_instance). Category-membership only. Idempotent.

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

SET @infra := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-infrastructure-series' LIMIT 1);

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE @is_sg = 1
  AND cp.category_id = @infra
  AND TRIM(p.sku) IN ('C430','C592','C539','C1071','C926','C1759','C1762');

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE @is_sg = 1
  AND i.category_id = @infra
  AND TRIM(p.sku) IN ('C430','C592','C539','C1071','C926','C1759','C1762');
