-- 1770: series placements requested 2026-10-04.
--
-- 1. Every multi-agent course on Multi AI Agents Series (multi-agents-series).
--    Audit on SG prod: all seven non-WSQ multi-agent courses (C20, C349, C765,
--    C829, C991, C1034, C1164) and four WSQ ones are already there; the one gap:
--      TGS-2024042961  WSQ - Develop Multi AI Agent Applications with Gemini Agent ADK
--    (C765's removal from Microsoft shipped in 1766.)
--
-- 2. Every AI-security AND cyber-security course on AI Security Series
--    (ai-security-series). All 13 AI-security courses are already there; the
--    cyber-security courses added:
--      C1123 Wireshark Network Analysis Masterclass   C1136 CompTIA PenTest+
--      C483  CISSP Exam Prep                          C506  Cyber Security Awareness Workshop
--      C628  CompTIA Security+ Exam Prep              C718  CompTIA SecurityX
--      C916  CompTIA CySA+
--      TGS-2020505561 Network Securities for Beginners
--      TGS-2023039181 CompTIA Security+               TGS-2024043392 ISC2 CISSP
--      TGS-2024043420 Navigating Digital Threats (Cyber Frauds and Scams)
--      TGS-2024049211 CompTIA CySA+                   TGS-2025053927 CompTIA SecurityX
--      TGS-2025060519 [MC] Advanced Certificate in Cyber Security
--      TGS-2026061583 Information Security Management & Compliance Frameworks
--      TGS-2026064471 CASL - CompTIA PenTest+
--      TGS-2026064533 CASL - Cyber Security Awareness Course
--    AI Security Series is an anchor child of AI Courses, so these also list on
--    AI Courses by inheritance (is_parent = 0 index row).
--
-- Funded TGS- courses go above the C- block (MIN position), C- courses after it
-- (MAX + 1); the nightly ordering sweep settles the final order. Membership
-- only; status and visibility untouched. Categories by url_key, products by
-- TRIM(sku); no-op where absent. Idempotent.

DROP TEMPORARY TABLE IF EXISTS tmp_1770_add;
CREATE TEMPORARY TABLE tmp_1770_add (sku VARCHAR(64) NOT NULL, url_key VARCHAR(255) NOT NULL);
INSERT INTO tmp_1770_add (sku, url_key) VALUES
  ('TGS-2024042961', 'multi-agents-series'),
  ('C1123', 'ai-security-series'), ('C1136', 'ai-security-series'),
  ('C483',  'ai-security-series'), ('C506',  'ai-security-series'),
  ('C628',  'ai-security-series'), ('C718',  'ai-security-series'),
  ('C916',  'ai-security-series'),
  ('TGS-2020505561', 'ai-security-series'), ('TGS-2023039181', 'ai-security-series'),
  ('TGS-2024043392', 'ai-security-series'), ('TGS-2024043420', 'ai-security-series'),
  ('TGS-2024049211', 'ai-security-series'), ('TGS-2025053927', 'ai-security-series'),
  ('TGS-2025060519', 'ai-security-series'), ('TGS-2026061583', 'ai-security-series'),
  ('TGS-2026064471', 'ai-security-series'), ('TGS-2026064533', 'ai-security-series');

DROP TEMPORARY TABLE IF EXISTS tmp_1770_res;
CREATE TEMPORARY TABLE tmp_1770_res AS
SELECT p.entity_id AS product_id, v.entity_id AS category_id, c.parent_id,
       TRIM(p.sku) LIKE 'TGS-%' AS is_tgs
FROM tmp_1770_add m
JOIN catalog_product_entity p ON TRIM(p.sku) = m.sku
JOIN catalog_category_entity_varchar v ON v.store_id = 0 AND v.value = m.url_key
JOIN eav_attribute a ON a.attribute_id = v.attribute_id
  AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
JOIN catalog_category_entity c ON c.entity_id = v.entity_id;

DROP TEMPORARY TABLE IF EXISTS tmp_1770_pos;
CREATE TEMPORARY TABLE tmp_1770_pos AS
SELECT cp.category_id, MIN(cp.position) AS minp, MAX(cp.position) AS maxp
FROM catalog_category_product cp
WHERE cp.category_id IN (SELECT DISTINCT category_id FROM tmp_1770_res)
GROUP BY cp.category_id;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT r.category_id, r.product_id,
       IF(r.is_tgs, COALESCE(x.minp, 0), COALESCE(x.maxp, 0) + 1)
FROM tmp_1770_res r LEFT JOIN tmp_1770_pos x ON x.category_id = r.category_id;

-- Listing index: the direct row ...
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, s.store_id,
  (SELECT MAX(i2.visibility) FROM catalog_category_product_index i2
   WHERE i2.product_id = cp.product_id AND i2.store_id = s.store_id)
FROM tmp_1770_res r
JOIN catalog_category_product cp ON cp.category_id = r.category_id AND cp.product_id = r.product_id
JOIN core_store s ON s.store_id > 0
WHERE EXISTS (SELECT 1 FROM catalog_category_product_index i3
              WHERE i3.product_id = cp.product_id AND i3.store_id = s.store_id);

-- ... and the anchor parent's inherited row (AI Courses).
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT r.parent_id, r.product_id, 0, 0, s.store_id,
  (SELECT MAX(i2.visibility) FROM catalog_category_product_index i2
   WHERE i2.product_id = r.product_id AND i2.store_id = s.store_id)
FROM tmp_1770_res r
JOIN catalog_category_entity pc ON pc.entity_id = r.parent_id AND pc.level >= 2 AND pc.entity_id <> 2
JOIN core_store s ON s.store_id > 0
WHERE EXISTS (SELECT 1 FROM catalog_category_product_index i3
              WHERE i3.product_id = r.product_id AND i3.store_id = s.store_id);

DROP TEMPORARY TABLE IF EXISTS tmp_1770_pos;
DROP TEMPORARY TABLE IF EXISTS tmp_1770_res;
DROP TEMPORARY TABLE IF EXISTS tmp_1770_add;
