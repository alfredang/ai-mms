-- 1277: WSQ Soft Skills Courses (url_key 'wsq-soft-skills-courses') — pin the
-- requested listing order.
--
--   1  TGS-2023037467  WSQ - Mastering the Art of Communication to Enhance Team Collaboration...
--   2  TGS-2025054613  WSQ - Communicate with Confidence: Optimize Your Strengths for Influence & Impact
--   3  TGS-2026061325  WSQ - Generative AI for Business Presentations
--   4  TGS-2025056191  WSQ - Improve Your Business with Excellent Customer Service
--   5  TGS-2025052342  WSQ - Closing Sales with Empathy-Driven People-Focused Selling
--   6  TGS-2025053924  WSQ - Service Branding Strategies to Elevate Your Business
--   7  TGS-2023021752  WSQ - Mastering The Art of Conflict Resolution to Foster Team Collaboration...
--   8  TGS-2024051250  WSQ - Mastering the Art & Science of Working with People & Teams using DISC AsiaPlus
--   9  TGS-2025054484  WSQ - Impactful Leadership Framework
--  10  TGS-2026064719  CASL - Generative AI for Design Thinking
--  11  TGS-2024049781  WSQ - Fast-Track Innovations with Agile Design Thinking and Generative AI (GenAI)
--  12  TGS-2024045222  WSQ - Empowering Employee Health and Wellness at the Workplace
--  13  TGS-2024051421  WSQ - Generative AI for Interviewing
--  14  TGS-2024051519  WSQ - STEAM Sustainability Professional Lesson Plan Development
--  15  TGS-2023020567  WSQ - Unlocking Business Potential with Strategic Negotiation Tactics
--
-- The category holds 15 courses; the requested list named 14. Negotiation
-- Tactics was NOT named and removal was NOT requested, so it is kept and pinned
-- LAST rather than dropped or left to float.
--
-- All fifteen are TGS-, so this category holds no C-prefix course: the nightly
-- sweep has nothing to re-alphabetise and it preserves TGS relative order, so
-- no curated-allowlist entry is needed. Negative positions keep the pinned
-- block ahead of anything unpinned. Business-key lookups only. Idempotent.

SET @ss := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-soft-skills-courses' LIMIT 1);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2023037467' THEN -15
  WHEN 'TGS-2025054613' THEN -14
  WHEN 'TGS-2026061325' THEN -13
  WHEN 'TGS-2025056191' THEN -12
  WHEN 'TGS-2025052342' THEN -11
  WHEN 'TGS-2025053924' THEN -10
  WHEN 'TGS-2023021752' THEN  -9
  WHEN 'TGS-2024051250' THEN  -8
  WHEN 'TGS-2025054484' THEN  -7
  WHEN 'TGS-2026064719' THEN  -6
  WHEN 'TGS-2024049781' THEN  -5
  WHEN 'TGS-2024045222' THEN  -4
  WHEN 'TGS-2024051421' THEN  -3
  WHEN 'TGS-2024051519' THEN  -2
  WHEN 'TGS-2023020567' THEN  -1
END
WHERE cp.category_id = @ss AND @ss IS NOT NULL
  AND p.sku IN ('TGS-2023037467','TGS-2025054613','TGS-2026061325','TGS-2025056191',
                'TGS-2025052342','TGS-2025053924','TGS-2023021752','TGS-2024051250',
                'TGS-2025054484','TGS-2026064719','TGS-2024049781','TGS-2024045222',
                'TGS-2024051421','TGS-2024051519','TGS-2023020567');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2023037467' THEN -15
  WHEN 'TGS-2025054613' THEN -14
  WHEN 'TGS-2026061325' THEN -13
  WHEN 'TGS-2025056191' THEN -12
  WHEN 'TGS-2025052342' THEN -11
  WHEN 'TGS-2025053924' THEN -10
  WHEN 'TGS-2023021752' THEN  -9
  WHEN 'TGS-2024051250' THEN  -8
  WHEN 'TGS-2025054484' THEN  -7
  WHEN 'TGS-2026064719' THEN  -6
  WHEN 'TGS-2024049781' THEN  -5
  WHEN 'TGS-2024045222' THEN  -4
  WHEN 'TGS-2024051421' THEN  -3
  WHEN 'TGS-2024051519' THEN  -2
  WHEN 'TGS-2023020567' THEN  -1
END
WHERE i.category_id = @ss AND @ss IS NOT NULL
  AND p.sku IN ('TGS-2023037467','TGS-2025054613','TGS-2026061325','TGS-2025056191',
                'TGS-2025052342','TGS-2025053924','TGS-2023021752','TGS-2024051250',
                'TGS-2025054484','TGS-2026064719','TGS-2024049781','TGS-2024045222',
                'TGS-2024051421','TGS-2024051519','TGS-2023020567');
