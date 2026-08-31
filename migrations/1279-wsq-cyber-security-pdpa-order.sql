-- 1279: WSQ Cyber Security & PDPA (url_key 'wsq-cyber-security-pdpa-courses') —
-- add one missing course and pin the requested order for all fifteen.
--
-- TGS-2026064471 "CASL - CompTIA PenTest+ Training" was NOT a member of this
-- category (it is live, enabled, visibility 4, and sits in 13 other categories),
-- which is why it never appeared on the page. It is assigned here first, then
-- pinned at position 13. Without the assignment the ORDER BY below would match
-- zero rows for it and the course would silently stay missing.
--
-- Requested order:
--   1  TGS-2026064533  CASL - Cyber Security Awareness Course for Personal and Businesses
--   2  TGS-2025060471  WSQ - Personal Data Protection Management for SMEs
--   3  TGS-2023039177  WSQ - AI for Cyber Security
--   4  TGS-2024051414  WSQ - AI for Network Security
--   5  TGS-2023039344  WSQ - AI for IT Security Professionals
--   6  TGS-2025053228  WSQ - AI Agent Cybersecurity
--   7  TGS-2024042604  WSQ - Security Operations for Autonomous AI Agents
--   8  TGS-2024043420  WSQ - Navigating Digital Threats
--   9  TGS-2024043392  WSQ - ISC2 CISSP Training
--  10  TGS-2026061583  WSQ - Information Security Management & Compliance Frameworks
--  11  TGS-2023039181  WSQ - CompTIA Certified Security+ Training
--  12  TGS-2024049211  WSQ - CompTIA Cybersecurity Analyst (CySA+) Training
--  13  TGS-2026064471  CASL - CompTIA PenTest+ Training      <- newly assigned
--  14  TGS-2025053927  WSQ - CompTIA Certified SecurityX Training
--  15  TGS-2025060519  [MC] Advanced Certificate in Cyber Security (E-Learning)
--
-- All fifteen carry TGS- SKUs — including the "[MC] ..." title, which is
-- TGS-2025060519 — so the category holds no C-prefix course: the nightly sweep
-- has nothing to re-alphabetise and preserves TGS relative order, and no
-- curated-allowlist entry is needed. No parent cleanup applies (cat 364's parent
-- 301 already holds PenTest+ directly). Business-key lookups only. Idempotent.

SET @cy := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-cyber-security-pdpa-courses' LIMIT 1);

-- 1. Assign the missing course to this category ------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cy, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @cy)
FROM catalog_product_entity p
WHERE p.sku = 'TGS-2026064471' AND @cy IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cy, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @cy),
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE p.sku = 'TGS-2026064471' AND @cy IS NOT NULL
GROUP BY p.entity_id, s.store_id;

-- 2. Pin the requested order --------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2026064533' THEN -15
  WHEN 'TGS-2025060471' THEN -14
  WHEN 'TGS-2023039177' THEN -13
  WHEN 'TGS-2024051414' THEN -12
  WHEN 'TGS-2023039344' THEN -11
  WHEN 'TGS-2025053228' THEN -10
  WHEN 'TGS-2024042604' THEN  -9
  WHEN 'TGS-2024043420' THEN  -8
  WHEN 'TGS-2024043392' THEN  -7
  WHEN 'TGS-2026061583' THEN  -6
  WHEN 'TGS-2023039181' THEN  -5
  WHEN 'TGS-2024049211' THEN  -4
  WHEN 'TGS-2026064471' THEN  -3
  WHEN 'TGS-2025053927' THEN  -2
  WHEN 'TGS-2025060519' THEN  -1
END
WHERE cp.category_id = @cy AND @cy IS NOT NULL
  AND p.sku IN ('TGS-2026064533','TGS-2025060471','TGS-2023039177','TGS-2024051414',
                'TGS-2023039344','TGS-2025053228','TGS-2024042604','TGS-2024043420',
                'TGS-2024043392','TGS-2026061583','TGS-2023039181','TGS-2024049211',
                'TGS-2026064471','TGS-2025053927','TGS-2025060519');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2026064533' THEN -15
  WHEN 'TGS-2025060471' THEN -14
  WHEN 'TGS-2023039177' THEN -13
  WHEN 'TGS-2024051414' THEN -12
  WHEN 'TGS-2023039344' THEN -11
  WHEN 'TGS-2025053228' THEN -10
  WHEN 'TGS-2024042604' THEN  -9
  WHEN 'TGS-2024043420' THEN  -8
  WHEN 'TGS-2024043392' THEN  -7
  WHEN 'TGS-2026061583' THEN  -6
  WHEN 'TGS-2023039181' THEN  -5
  WHEN 'TGS-2024049211' THEN  -4
  WHEN 'TGS-2026064471' THEN  -3
  WHEN 'TGS-2025053927' THEN  -2
  WHEN 'TGS-2025060519' THEN  -1
END
WHERE i.category_id = @cy AND @cy IS NOT NULL
  AND p.sku IN ('TGS-2026064533','TGS-2025060471','TGS-2023039177','TGS-2024051414',
                'TGS-2023039344','TGS-2025053228','TGS-2024042604','TGS-2024043420',
                'TGS-2024043392','TGS-2026061583','TGS-2023039181','TGS-2024049211',
                'TGS-2026064471','TGS-2025053927','TGS-2025060519');
