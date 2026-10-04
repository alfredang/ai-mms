-- 1766: Second catalog-placement audit of the enabled non-WSQ (C-prefix)
-- courses. Only category memberships change; status, visibility and every
-- other attribute are untouched. A course may sit on several pages.
--
-- Wrong placements removed (with the right page added where missing):
--   C193  Python Data Analysis Masterclass  - AI Applications, AI for ML  + Data Analytics, Data Visualisation
--   C523  Project Management Masterclass (PMP prep) - Infocomm Technology, Agile & Scrum Certification Exam
--   C698  Agile Project Management Masterclass - Infocomm Technology, Certification Exam Prep,
--         Others Certification Exam Prep, Agile & Scrum Certification Exam  + Business & Soft Skills, Project Management
--   C162  Generative AI for 3D Modeling       - SketchUp (not taught)
--   C711  AB-731 AI Transformation Leader     - Cloud Computing, Azure Certification  + Microsoft Copilot Series
--   C1285 Docker Fundamentals for Beginners   - AI Infrastructure Series, AI Courses  + DevOps
--   C188  AI Vibe Coding for Python Financial Analysis - AI Infrastructure Series
--   C765  Multi-Agent Systems with OpenAI Agent SDK    - Microsoft
--   C803  Copilot for Power Apps              - RPA
--   C1750 CompTIA SecAI+                      - Cloud Computing  + IT Security, Cyber Security
--   C831  AI for Early Childhood              - AI for STEM  + AI for Educators
--   C165  AI for Logistics                    - AI for Manufacturing  + Logistics & Supply Chain, Supply Chain
--
-- Missing placements added:
--   C1223 AI for Lean Manufacturing           + AI Courses, AI Applications Series, AI for Manufacturing
--   C1148 Generative AI for Strategic Planning + AI Courses, Generative AI Series
--   C431  AI for Career Coaching              + AI Courses, AI Applications Series, AI for HR
--   C1373 Generative AI for Video Creation    + GenAI Video Creation
--   C364  GenAI for Script Development and Storytelling + GenAI Content Creation
--   C439  Generative AI for Content Creation  + GenAI Content Creation, Digital Marketing, Content Marketing
--   C1319 Agentic AI for Affiliate Marketing  + Agentic AI Series
--   C818  ChatGPT WORK for Digital Marketing  + Digital Marketing
--   C349  Multi AI Agents System for Digital Marketing + Digital Marketing
--   C500  Voice and Video Agents with n8n     + n8n AI Automations
--   C690  AI Agents for SMEs                  + AI Applications Series, AI for Business
--   C356  AI for Network Security             + IT Security, Network Securities
--   C28   AI Agent Security                   + AI Agents Series
--
-- Series rules checked (title -> series): Agentic -> Agentic AI Series,
-- Generative AI -> Generative AI Series, AI Agent -> AI Agents Series
-- (multi-agent courses stay in Multi AI Agents Series), Copilot -> Microsoft
-- Copilot Series, ChatGPT/Codex -> Codex AI Series, Claude -> Claude AI Series.
-- The only gaps were C1319, C1148 and C28 above.
--
-- Categories by url_key, products by TRIM(sku); no-op where either is missing.
-- Mirrored into catalog_category_product_index (as 1754). Idempotent.

DROP TEMPORARY TABLE IF EXISTS tmp_1766_move;
CREATE TEMPORARY TABLE tmp_1766_move (
  sku VARCHAR(64) NOT NULL,
  url_key VARCHAR(255) NOT NULL,
  op CHAR(3) NOT NULL
);

INSERT INTO tmp_1766_move (sku, url_key, op) VALUES
  ('C193',  'ai-applications-series',                          'del'),
  ('C193',  'ai-for-machine-learning',                         'del'),
  ('C193',  'data-analytics-courses',                          'add'),
  ('C193',  'data-visualisation-courses',                      'add'),
  ('C523',  'computer-programming-and-infocomm-courses',       'del'),
  ('C523',  'agile-scrum-certification-exam',                  'del'),
  ('C698',  'computer-programming-and-infocomm-courses',       'del'),
  ('C698',  'certification-exam-prep-courses',                 'del'),
  ('C698',  'others-certification-exam-prep',                  'del'),
  ('C698',  'agile-scrum-certification-exam',                  'del'),
  ('C698',  'business-soft-skills-courses',                    'add'),
  ('C698',  'project-management-training-courses-in',          'add'),
  ('C162',  'sketchup-software-training',                      'del'),
  ('C711',  'cloud-computing-courses',                         'del'),
  ('C711',  'azure-certification-exam-prep',                   'del'),
  ('C711',  'azure-certification-exam-prep-retired',           'del'),
  ('C711',  'microsoft-copilot-series',                        'add'),
  ('C1285', 'ai-infrastructure-series',                        'del'),
  ('C1285', 'artificial-intelligence-courses',                 'del'),
  ('C1285', 'devops-courses',                                  'add'),
  ('C188',  'ai-infrastructure-series',                        'del'),
  ('C765',  'microsoft-software-training',                     'del'),
  ('C803',  'rpa-api-it-automation-courses',                   'del'),
  ('C1750', 'cloud-computing-courses',                         'del'),
  ('C1750', 'cyber-security-digital-forensic-training-courses','add'),
  ('C1750', 'cybersecurity-threat-analysis-courses',           'add'),
  ('C831',  'ai-for-stem',                                     'del'),
  ('C831',  'ai-for-educators',                                'add'),
  ('C165',  'ai-for-manufacturing',                            'del'),
  ('C165',  'logistics-and-manufacturing-courses',             'add'),
  ('C165',  'supply-chain-and-resource-management-courses',    'add'),
  ('C1223', 'artificial-intelligence-courses',                 'add'),
  ('C1223', 'ai-applications-series',                          'add'),
  ('C1223', 'ai-for-manufacturing',                            'add'),
  ('C1148', 'artificial-intelligence-courses',                 'add'),
  ('C1148', 'generative-ai-series',                            'add'),
  ('C431',  'artificial-intelligence-courses',                 'add'),
  ('C431',  'ai-applications-series',                          'add'),
  ('C431',  'ai-for-hr-courses',                               'add'),
  ('C1373', 'genai-video-creation',                            'add'),
  ('C364',  'chatgpt-and-generative-ai-courses',               'add'),
  ('C439',  'chatgpt-and-generative-ai-courses',               'add'),
  ('C439',  'digital-marketing-courses-in',                    'add'),
  ('C439',  'content-marketing-courses',                       'add'),
  ('C1319', 'agentic-ai-series',                               'add'),
  ('C818',  'digital-marketing-courses-in',                    'add'),
  ('C349',  'digital-marketing-courses-in',                    'add'),
  ('C500',  'n8n-ai-automations-courses',                      'add'),
  ('C690',  'ai-applications-series',                          'add'),
  ('C690',  'ai-for-business',                                 'add'),
  ('C356',  'cyber-security-digital-forensic-training-courses','add'),
  ('C356',  'network-securities-courses',                      'add'),
  ('C28',   'ai-agents-series',                                'add');

DROP TEMPORARY TABLE IF EXISTS tmp_1766_res;
CREATE TEMPORARY TABLE tmp_1766_res AS
SELECT p.entity_id AS product_id, v.entity_id AS category_id, m.op
FROM tmp_1766_move m
JOIN catalog_product_entity p ON TRIM(p.sku) = m.sku
JOIN catalog_category_entity_varchar v ON v.store_id = 0 AND v.value = m.url_key
JOIN eav_attribute a ON a.attribute_id = v.attribute_id
  AND a.entity_type_id = 3 AND a.attribute_code = 'url_key';

-- 1. Remove the wrong direct assignments.
DELETE cp FROM catalog_category_product cp
JOIN tmp_1766_res r ON r.product_id = cp.product_id
  AND r.category_id = cp.category_id AND r.op = 'del';

-- 2. Add the right ones after the category's current last position
--    (C- courses list after TGS-; the ordering sweep re-sorts alphabetically).
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT r.category_id, r.product_id,
  COALESCE((SELECT MAX(x.position) FROM catalog_category_product x
            WHERE x.category_id = r.category_id), 0) + 1
FROM tmp_1766_res r WHERE r.op = 'add';

-- 3. Listing index: drop rows for these products where the product no longer
--    sits in that category or any descendant. Root category 2 is kept.
DELETE i FROM catalog_category_product_index i
JOIN (SELECT DISTINCT product_id FROM tmp_1766_res) r ON r.product_id = i.product_id
JOIN catalog_category_entity c ON c.entity_id = i.category_id
WHERE c.level > 1 AND c.entity_id <> 2
  AND NOT EXISTS (
    SELECT 1 FROM catalog_category_product cp
    JOIN catalog_category_entity cc ON cc.entity_id = cp.category_id
    WHERE cp.product_id = i.product_id
      AND (cc.entity_id = c.entity_id OR cc.path LIKE CONCAT(c.path, '/%')));

-- 4. Index rows for the new assignments, per store, visibility copied from the
--    product's existing index rows (unlisted products get none).
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, s.store_id,
  (SELECT MAX(i2.visibility) FROM catalog_category_product_index i2
   WHERE i2.product_id = cp.product_id AND i2.store_id = s.store_id)
FROM tmp_1766_res r
JOIN catalog_category_product cp ON cp.product_id = r.product_id AND cp.category_id = r.category_id
JOIN core_store s ON s.store_id > 0
WHERE r.op = 'add'
  AND EXISTS (SELECT 1 FROM catalog_category_product_index i3
              WHERE i3.product_id = cp.product_id AND i3.store_id = s.store_id);

DROP TEMPORARY TABLE IF EXISTS tmp_1766_res;
DROP TEMPORARY TABLE IF EXISTS tmp_1766_move;
