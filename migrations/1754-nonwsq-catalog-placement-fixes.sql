-- 1754: Catalog placement fixes for non-WSQ (C-prefix) courses.
-- Only category memberships change; status, visibility and every other
-- attribute are untouched.
--
-- A. Non-WSQ courses out of WSQ-only categories
--   C711   AB-731 Microsoft Certified AI Transformation Leader
--            - WSQ and IBF courses, WSQ Certification Courses
--   C1543  Cisco CCNP for ENARSI Training (disabled)
--            - WSQ and IBF courses, WSQ Funded, WSQ Mfg & Green,
--              WSQ IT & Security, WSQ Certification Courses
--
-- B. Wrong topic categories (leftovers from earlier lives of the products)
--   C141   Claude Cowork for Digital Marketing  - Mobile Apps, iOS  + Digital Marketing
--   C181   Tableau Data Prep Masterclass        - Certification Exam Prep and both
--                                                 Tableau Certification Exam Prep
--   C1759  AI-200 Azure AI Cloud Developer      - Microsoft Dynamics Cert  + Azure Certification
--   C1762  AI-300 ML Operations Engineer        - Microsoft Dynamics Cert  + Azure Certification
--   C1760  AB-620 AI Agent Builder              - Microsoft Dynamics Cert  + Power Platform Certification
--   C1415  DP-900 Azure Data Fundamentals       - Power Platform Certification
--   C1285  Docker Fundamentals for Beginners    - RPA
--   C476   CompTIA DataAI Training              - RPA
--   C329   Generative AI for Business Presentation - Video & Micro Drama
--   C197   Claude Microsoft 365 Masterclass     - Infographics
--   C978   Build a RAG Chatbot with n8n         - Business & Soft Skills  + n8n AI Automations
--
-- Categories resolved by url_key, products by TRIM(sku); no-op where either
-- is missing (partner sites). The listing reads catalog_category_product_index,
-- so the same delta is mirrored there. Idempotent.

DROP TEMPORARY TABLE IF EXISTS tmp_1754_move;
CREATE TEMPORARY TABLE tmp_1754_move (
  sku VARCHAR(64) NOT NULL,
  url_key VARCHAR(255) NOT NULL,
  op CHAR(3) NOT NULL
);

INSERT INTO tmp_1754_move (sku, url_key, op) VALUES
  ('C711',  'latest-courses',                                  'del'),
  ('C711',  'wsq-certification-courses',                       'del'),
  ('C1543', 'latest-courses',                                  'del'),
  ('C1543', 'wsq-funded-courses',                              'del'),
  ('C1543', 'wsq-finance-mfg-green-courses',                   'del'),
  ('C1543', 'wsq-it-security-courses',                         'del'),
  ('C1543', 'wsq-certification-courses',                       'del'),
  ('C141',  'mobile-programming-courses',                      'del'),
  ('C141',  'ios-xcode-swift-programming-courses',             'del'),
  ('C141',  'digital-marketing-courses-in',                    'add'),
  ('C181',  'certification-exam-prep-courses',                 'del'),
  ('C181',  'tableau-certificaitons-exam-prep-courses',        'del'),
  ('C181',  'tableau-certification-exam-prep',                 'del'),
  ('C1759', 'microsoft-dynamics-certification-courses',        'del'),
  ('C1759', 'azure-certification-exam-prep',                   'add'),
  ('C1762', 'microsoft-dynamics-certification-courses',        'del'),
  ('C1762', 'azure-certification-exam-prep',                   'add'),
  ('C1760', 'microsoft-dynamics-certification-courses',        'del'),
  ('C1760', 'microsoft-power-platform-certification-courses',  'add'),
  ('C1415', 'microsoft-power-platform-certification-courses',  'del'),
  ('C1285', 'rpa-api-it-automation-courses',                   'del'),
  ('C476',  'rpa-api-it-automation-courses',                   'del'),
  ('C329',  'video-micro-drama-courses',                       'del'),
  ('C197',  'infographics-courses',                            'del'),
  ('C978',  'business-soft-skills-courses',                    'del'),
  ('C978',  'n8n-ai-automations-courses',                      'add');

DROP TEMPORARY TABLE IF EXISTS tmp_1754_res;
CREATE TEMPORARY TABLE tmp_1754_res AS
SELECT p.entity_id AS product_id, v.entity_id AS category_id, m.op
FROM tmp_1754_move m
JOIN catalog_product_entity p ON TRIM(p.sku) = m.sku
JOIN catalog_category_entity_varchar v ON v.store_id = 0 AND v.value = m.url_key
JOIN eav_attribute a ON a.attribute_id = v.attribute_id
  AND a.entity_type_id = 3 AND a.attribute_code = 'url_key';

-- 1. Remove the wrong direct assignments.
DELETE cp FROM catalog_category_product cp
JOIN tmp_1754_res r ON r.product_id = cp.product_id
  AND r.category_id = cp.category_id AND r.op = 'del';

-- 2. Add the correct ones, appended after the category's current last
--    position (C- courses list after TGS-; the ordering sweep re-sorts).
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT r.category_id, r.product_id,
  COALESCE((SELECT MAX(x.position) FROM catalog_category_product x
            WHERE x.category_id = r.category_id), 0) + 1
FROM tmp_1754_res r WHERE r.op = 'add';

-- 3. Mirror into the listing index: drop rows for these products where the
--    product no longer sits in that category or any of its descendants
--    (covers anchor-inherited parent rows too). Root category 2 is kept.
DELETE i FROM catalog_category_product_index i
JOIN (SELECT DISTINCT product_id FROM tmp_1754_res) r ON r.product_id = i.product_id
JOIN catalog_category_entity c ON c.entity_id = i.category_id
WHERE c.level > 1 AND c.entity_id <> 2
  AND NOT EXISTS (
    SELECT 1 FROM catalog_category_product cp
    JOIN catalog_category_entity cc ON cc.entity_id = cp.category_id
    WHERE cp.product_id = i.product_id
      AND (cc.entity_id = c.entity_id OR cc.path LIKE CONCAT(c.path, '/%')));

-- 4. Index rows for the new assignments, per store, visibility copied from the
--    product's existing index rows (products without any index row — i.e. not
--    listed — get none).
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, s.store_id,
  (SELECT MAX(i2.visibility) FROM catalog_category_product_index i2
   WHERE i2.product_id = cp.product_id AND i2.store_id = s.store_id)
FROM tmp_1754_res r
JOIN catalog_category_product cp ON cp.product_id = r.product_id AND cp.category_id = r.category_id
JOIN core_store s ON s.store_id > 0
WHERE r.op = 'add'
  AND EXISTS (SELECT 1 FROM catalog_category_product_index i3
              WHERE i3.product_id = cp.product_id AND i3.store_id = s.store_id);

DROP TEMPORARY TABLE IF EXISTS tmp_1754_res;
DROP TEMPORARY TABLE IF EXISTS tmp_1754_move;
