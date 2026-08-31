-- 1284: WSQ Cloud Computing & Networking (url_key
-- 'wsq-cloud-computing-and-networking-courses', cat 426) — pin the requested
-- listing order for all 23 courses.
--
-- The request listed "WSQ - Kubernetes and Cloud Native Associate (KCNA)
-- Training" TWICE (2nd and 3rd). That is NOT a typo: the catalog really holds
-- two distinct enabled products with that identical name —
--   TGS-2025053174 (entity 753)  and  TGS-2023039343 (entity 1463)
-- both already in this category. They are pinned 2nd and 3rd respectively,
-- preserving their previous relative order (753 sat above 1463).
--   NOTE: both also share the SAME url_key
--   'wsq-kubernetes-and-cloud-native-associate-kcna-training', so only one can
--   own that URL. That is a pre-existing data problem, out of scope here and
--   deliberately NOT touched by this migration — flagged to the owner.
--
-- Order (all 23 are TGS-, so the category holds no C-prefix course: the nightly
-- sweep has nothing to re-alphabetise and preserves TGS relative order — no
-- curated-allowlist entry needed):
--    1 TGS-2025056362  AI for Cloud Computing
--    2 TGS-2025053174  KCNA (first)
--    3 TGS-2023039343  KCNA (second)
--    4 TGS-2025054612  Certified Kubernetes Administrator (CKA)
--    5 TGS-2024049214  CompTIA Certified Cloud+
--    6 TGS-2023039183  AWS Certified Cloud Practitioner
--    7 TGS-2024049338  AWS Certified AI Practitioner
--    8 TGS-2026064535  CASL - AWS Certified Solutions Architect Associate
--    9 TGS-2024051413  AWS Certified SysOps Administrator Associate
--   10 TGS-2025052675  AWS Certified Developer Associate
--   11 TGS-2025054815  AWS Certified DevOps Engineer Professional
--   12 TGS-2024049340  AWS Certified Machine Learning Engineer Associate
--   13 TGS-2023040474  DevOps Engineering on AWS
--   14 TGS-2025053926  AWS Certified Solutions Architect Professional
--   15 TGS-2025053209  AWS Certified Data Engineer Associate
--   16 TGS-2023036449  Microsoft Azure Fundamentals (AZ-900)
--   17 TGS-2023021100  Microsoft Azure AI Fundamentals (AI-900)
--   18 TGS-2023036651  Microsoft Certified Azure AI Engineer Associate (AI-102)
--   19 TGS-2023036641  Microsoft Azure Data Fundamentals (DP-900)
--   20 TGS-2023036642  Microsoft Azure Data Scientist Associate (DP-100)
--   21 TGS-2023039182  Microsoft Certified Azure Administrator Associate (AZ-104)
--   22 TGS-2024048319  Administering Microsoft Azure SQL Solutions (DP-300)
--   23 TGS-2023041024  Google Associate Cloud Engineer
--
-- Matched on SKU, not title — several of these names carry trailing or double
-- spaces in the DB (e.g. "Solutions Architect  Professional"), which makes title
-- matching unreliable. Negative positions keep the pinned block ahead of
-- anything unpinned. Business-key lookups only. Idempotent.

SET @cl := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cloud-computing-and-networking-courses' LIMIT 1);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2025056362' THEN -23
  WHEN 'TGS-2025053174' THEN -22
  WHEN 'TGS-2023039343' THEN -21
  WHEN 'TGS-2025054612' THEN -20
  WHEN 'TGS-2024049214' THEN -19
  WHEN 'TGS-2023039183' THEN -18
  WHEN 'TGS-2024049338' THEN -17
  WHEN 'TGS-2026064535' THEN -16
  WHEN 'TGS-2024051413' THEN -15
  WHEN 'TGS-2025052675' THEN -14
  WHEN 'TGS-2025054815' THEN -13
  WHEN 'TGS-2024049340' THEN -12
  WHEN 'TGS-2023040474' THEN -11
  WHEN 'TGS-2025053926' THEN -10
  WHEN 'TGS-2025053209' THEN  -9
  WHEN 'TGS-2023036449' THEN  -8
  WHEN 'TGS-2023021100' THEN  -7
  WHEN 'TGS-2023036651' THEN  -6
  WHEN 'TGS-2023036641' THEN  -5
  WHEN 'TGS-2023036642' THEN  -4
  WHEN 'TGS-2023039182' THEN  -3
  WHEN 'TGS-2024048319' THEN  -2
  WHEN 'TGS-2023041024' THEN  -1
END
WHERE cp.category_id = @cl AND @cl IS NOT NULL
  AND p.sku IN ('TGS-2025056362','TGS-2025053174','TGS-2023039343','TGS-2025054612',
                'TGS-2024049214','TGS-2023039183','TGS-2024049338','TGS-2026064535',
                'TGS-2024051413','TGS-2025052675','TGS-2025054815','TGS-2024049340',
                'TGS-2023040474','TGS-2025053926','TGS-2025053209','TGS-2023036449',
                'TGS-2023021100','TGS-2023036651','TGS-2023036641','TGS-2023036642',
                'TGS-2023039182','TGS-2024048319','TGS-2023041024');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2025056362' THEN -23
  WHEN 'TGS-2025053174' THEN -22
  WHEN 'TGS-2023039343' THEN -21
  WHEN 'TGS-2025054612' THEN -20
  WHEN 'TGS-2024049214' THEN -19
  WHEN 'TGS-2023039183' THEN -18
  WHEN 'TGS-2024049338' THEN -17
  WHEN 'TGS-2026064535' THEN -16
  WHEN 'TGS-2024051413' THEN -15
  WHEN 'TGS-2025052675' THEN -14
  WHEN 'TGS-2025054815' THEN -13
  WHEN 'TGS-2024049340' THEN -12
  WHEN 'TGS-2023040474' THEN -11
  WHEN 'TGS-2025053926' THEN -10
  WHEN 'TGS-2025053209' THEN  -9
  WHEN 'TGS-2023036449' THEN  -8
  WHEN 'TGS-2023021100' THEN  -7
  WHEN 'TGS-2023036651' THEN  -6
  WHEN 'TGS-2023036641' THEN  -5
  WHEN 'TGS-2023036642' THEN  -4
  WHEN 'TGS-2023039182' THEN  -3
  WHEN 'TGS-2024048319' THEN  -2
  WHEN 'TGS-2023041024' THEN  -1
END
WHERE i.category_id = @cl AND @cl IS NOT NULL
  AND p.sku IN ('TGS-2025056362','TGS-2025053174','TGS-2023039343','TGS-2025054612',
                'TGS-2024049214','TGS-2023039183','TGS-2024049338','TGS-2026064535',
                'TGS-2024051413','TGS-2025052675','TGS-2025054815','TGS-2024049340',
                'TGS-2023040474','TGS-2025053926','TGS-2025053209','TGS-2023036449',
                'TGS-2023021100','TGS-2023036651','TGS-2023036641','TGS-2023036642',
                'TGS-2023039182','TGS-2024048319','TGS-2023041024');
