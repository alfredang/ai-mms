-- Pin the WSQ (TGS-) course order on the Cybersecurity & Threat Analysis
-- category page (url_key = cybersecurity-threat-analysis-courses).
--
-- Owner-requested sequence (2026-08-20). CompTIA Certified SecurityX was not in
-- the requested list; per owner decision it keeps position 13, immediately after
-- the 12 curated courses, so it stays within the WSQ block.
--
-- WSQ pins SURVIVE the nightly CategoryOrdering cron sweep: that sweep preserves
-- existing TGS- relative order (it only re-alphabetises the non-WSQ block), so
-- these positions are stable. Non-WSQ courses are left to the canonical
-- alphabetical rule and are not pinned here.
--
-- Writes BOTH catalog_category_product (admin source of truth) and
-- catalog_category_product_index (what the storefront listing actually reads).
-- Partner-safe: resolved by url_key + SKU, so it is a clean no-op on MY/GH,
-- which carry no TGS- courses.

SET @cat := (SELECT uk.entity_id FROM catalog_category_entity_varchar uk
  JOIN eav_attribute ea ON ea.attribute_id = uk.attribute_id
   AND ea.entity_type_id = 3 AND ea.attribute_code = 'url_key'
  WHERE uk.store_id = 0 AND uk.value = 'cybersecurity-threat-analysis-courses' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS tmp_cyber_wsq_order;
CREATE TEMPORARY TABLE tmp_cyber_wsq_order (sku VARCHAR(64) PRIMARY KEY, pos INT NOT NULL);
INSERT INTO tmp_cyber_wsq_order (sku, pos) VALUES
  ('TGS-2026064533', 1),   -- CASL - Cyber Security Awareness Course for Personal and Businesses
  ('TGS-2024043420', 2),   -- WSQ - Navigating Digital Threats: Proactive Measures Against Cyber Frauds and Scams
  ('TGS-2025060471', 3),   -- WSQ - Personal Data Protection Management for SMEs
  ('TGS-2023039177', 4),   -- WSQ - AI for Cyber Security
  ('TGS-2025053228', 5),   -- WSQ - AI Agent Cybersecurity
  ('TGS-2023039344', 6),   -- WSQ - AI for IT Security Professionals
  ('TGS-2023039181', 7),   -- WSQ - CompTIA Certified Security+ Training
  ('TGS-2024049211', 8),   -- WSQ - CompTIA Cybersecurity Analyst (CySA+) Training
  ('TGS-2024043392', 9),   -- WSQ - ISC2 Information Systems Security Professional (CISSP) Training
  ('TGS-2024042604', 10),  -- WSQ - Microsoft Security Operations Analyst (SC-200)
  ('TGS-2024047021', 11),  -- WSQ - Microsoft Identity and Access Administrator (SC-300)
  ('TGS-2025060519', 12),  -- [MC] Advanced Certificate in Cyber Security (E-Learning)
  ('TGS-2025053927', 13);  -- WSQ - CompTIA Certified SecurityX Training

-- admin-facing source of truth
UPDATE catalog_category_product cp
JOIN catalog_product_entity e ON e.entity_id = cp.product_id
JOIN tmp_cyber_wsq_order t ON t.sku = e.sku
SET cp.position = t.pos
WHERE @cat IS NOT NULL AND cp.category_id = @cat;

-- what the storefront listing actually reads (all stores on this instance)
UPDATE catalog_category_product_index idx
JOIN catalog_product_entity e ON e.entity_id = idx.product_id
JOIN tmp_cyber_wsq_order t ON t.sku = e.sku
SET idx.position = t.pos
WHERE @cat IS NOT NULL AND idx.category_id = @cat;

DROP TEMPORARY TABLE IF EXISTS tmp_cyber_wsq_order;
