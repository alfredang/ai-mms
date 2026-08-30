-- 1226: Add a Funding Options card to every enabled non-WSQ (C-prefix)
-- course that currently shows none.
--
-- Scope, measured on prod: 248 enabled C-prefix courses; 29 already have a
-- course_C<SKU>_funding_and_grant block and 121 more already render the card
-- from a legacy "Funding and Grant" section still embedded in
-- short_description (view.phtml falls back to that). This migration targets
-- only the remaining ~102 that render NO card at all — the others are left
-- untouched so no existing copy is overwritten.
--
-- The card recommends a WSQ course chosen by the series the course sits in
-- (agreed approach). One target per series, each URL verified 200 on prod:
--
--   AI Vibe Coding Series     -> WSQ - AI Vibe Coding for Multi Agents System
--   AI Security Series        -> WSQ - AI Security for Autonomous AI Agents
--   Claude AI Series          -> WSQ - Agentic AI Applications with Claude Code
--   Codex AI Series           -> WSQ - Agentic AI Applications with Codex
--   Microsoft Copilot Series  -> WSQ - Enhance Work Productivity with M365 Copilot
--   Multi AI Agents Series    -> WSQ - Multi AI Agents Workflow for Content Creation
--   AI Agents Series          -> WSQ - Autonomous AI Agents
--   Agentic AI Series         -> WSQ - Agentic AI for Business Process Automation
--   AI for Finance            -> CASL - Generative AI for Finance and Fintech
--   AI for Healthcare         -> WSQ - Data Analytics and AI for Healthcare
--   AI for HR                 -> WSQ - Agentic AI for HR
--   AI Infrastructure / ML    -> WSQ - Data Mining and ML Fundamentals for Beginners
--   Generative AI Series      -> WSQ - Generative AI for Content Creation
--   AI Applications Series    -> WSQ - AI Agents for Business
--
-- Courses in more than one series take the first match in the order above
-- (most specific series first). Courses in NO AI series (~29) get the same
-- card WITHOUT a recommendation link rather than a guessed one.
--
-- cms_block rows are written with plain SQL plus an explicit cms_block_store
-- row at store 0 — never a model save, which wipes the store mapping and
-- 404s the block.
--
-- SG-guarded; C-prefix SKUs are SG-only (partner no-op). Idempotent: only
-- inserts where no block exists, so re-running never overwrites content.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_status := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

-- Working set: enabled C-prefix courses with no funding block AND no legacy
-- "Funding and Grant" section in short_description.
DROP TEMPORARY TABLE IF EXISTS tmp_needs_funding;
CREATE TEMPORARY TABLE tmp_needs_funding (
  entity_id INT UNSIGNED NOT NULL PRIMARY KEY,
  sku VARCHAR(64) NOT NULL,
  cats TEXT NULL
);

INSERT INTO tmp_needs_funding (entity_id, sku, cats)
SELECT p.entity_id, p.sku,
       CONCAT(',', IFNULL((SELECT GROUP_CONCAT(cp.category_id) FROM catalog_category_product cp
                           WHERE cp.product_id = p.entity_id), ''), ',')
FROM catalog_product_entity p
LEFT JOIN catalog_product_entity_text sd
  ON sd.entity_id = p.entity_id AND sd.store_id = 0 AND sd.attribute_id = @a_sdesc
WHERE @is_sg > 0
  AND p.sku LIKE 'C%'
  AND COALESCE((SELECT value FROM catalog_product_entity_int
                WHERE entity_id = p.entity_id AND store_id = 0 AND attribute_id = @a_status), 1) = 1
  AND NOT EXISTS (SELECT 1 FROM cms_block b
                  WHERE b.identifier = CONCAT('course_', p.sku, '_funding_and_grant'))
  AND (sd.value IS NULL OR sd.value NOT REGEXP 'Funding[[:space:]]+(and|&amp;|&)[[:space:]]+Grant');

-- ai-vibe-coding-series
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' Funding and Grant'),
       CONCAT('course_', t.sku, '_funding_and_grant'),
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-multi-agents-system.html" title="WSQ - AI Vibe Coding for Multi Agents System">WSQ - AI Vibe Coding for Multi Agents System</a></span></p>',
       NOW(), NOW(), 1
FROM tmp_needs_funding t
WHERE (t.cats LIKE '%,414,%');

-- ai-security-series
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' Funding and Grant'),
       CONCAT('course_', t.sku, '_funding_and_grant'),
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-ai-security-for-autonomous-ai-agents.html" title="WSQ - AI Security for Autonomous AI Agents">WSQ - AI Security for Autonomous AI Agents</a></span></p>',
       NOW(), NOW(), 1
FROM tmp_needs_funding t
WHERE (t.cats LIKE '%,214,%')
  AND NOT ((t.cats LIKE '%,414,%'));

-- claude-ai-series
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' Funding and Grant'),
       CONCAT('course_', t.sku, '_funding_and_grant'),
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-applications-with-claude-code.html" title="WSQ - Agentic AI Applications with Claude Code">WSQ - Agentic AI Applications with Claude Code</a></span></p>',
       NOW(), NOW(), 1
FROM tmp_needs_funding t
WHERE (t.cats LIKE '%,281,%')
  AND NOT ((t.cats LIKE '%,414,%') OR (t.cats LIKE '%,214,%'));

-- codex-ai-series
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' Funding and Grant'),
       CONCAT('course_', t.sku, '_funding_and_grant'),
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-applications-with-codex.html" title="WSQ - Agentic AI Applications with Codex">WSQ - Agentic AI Applications with Codex</a></span></p>',
       NOW(), NOW(), 1
FROM tmp_needs_funding t
WHERE (t.cats LIKE '%,283,%')
  AND NOT ((t.cats LIKE '%,414,%') OR (t.cats LIKE '%,214,%') OR (t.cats LIKE '%,281,%'));

-- microsoft-copilot-series
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' Funding and Grant'),
       CONCAT('course_', t.sku, '_funding_and_grant'),
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-enhance-work-productivity-with-microsoft-365-copilot.html" title="WSQ - Enhance Work Productivity with Microsoft 365 Copilot">WSQ - Enhance Work Productivity with Microsoft 365 Copilot</a></span></p>',
       NOW(), NOW(), 1
FROM tmp_needs_funding t
WHERE (t.cats LIKE '%,357,%')
  AND NOT ((t.cats LIKE '%,414,%') OR (t.cats LIKE '%,214,%') OR (t.cats LIKE '%,281,%') OR (t.cats LIKE '%,283,%'));

-- multi-agents-series
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' Funding and Grant'),
       CONCAT('course_', t.sku, '_funding_and_grant'),
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/multi-ai-agents-workflow-for-content-creation.html" title="WSQ - Multi AI Agents Workflow for Content Creation">WSQ - Multi AI Agents Workflow for Content Creation</a></span></p>',
       NOW(), NOW(), 1
FROM tmp_needs_funding t
WHERE (t.cats LIKE '%,187,%')
  AND NOT ((t.cats LIKE '%,414,%') OR (t.cats LIKE '%,214,%') OR (t.cats LIKE '%,281,%') OR (t.cats LIKE '%,283,%') OR (t.cats LIKE '%,357,%'));

-- ai-agents-series
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' Funding and Grant'),
       CONCAT('course_', t.sku, '_funding_and_grant'),
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/autonomous-ai-agents.html" title="WSQ - Autonomous AI Agents">WSQ - Autonomous AI Agents</a></span></p>',
       NOW(), NOW(), 1
FROM tmp_needs_funding t
WHERE (t.cats LIKE '%,415,%')
  AND NOT ((t.cats LIKE '%,414,%') OR (t.cats LIKE '%,214,%') OR (t.cats LIKE '%,281,%') OR (t.cats LIKE '%,283,%') OR (t.cats LIKE '%,357,%') OR (t.cats LIKE '%,187,%'));

-- agentic-ai-series
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' Funding and Grant'),
       CONCAT('course_', t.sku, '_funding_and_grant'),
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-business-process-automation.html" title="WSQ - Agentic AI for Business Process Automation">WSQ - Agentic AI for Business Process Automation</a></span></p>',
       NOW(), NOW(), 1
FROM tmp_needs_funding t
WHERE (t.cats LIKE '%,189,%')
  AND NOT ((t.cats LIKE '%,414,%') OR (t.cats LIKE '%,214,%') OR (t.cats LIKE '%,281,%') OR (t.cats LIKE '%,283,%') OR (t.cats LIKE '%,357,%') OR (t.cats LIKE '%,187,%') OR (t.cats LIKE '%,415,%'));

-- ai-for-finance
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' Funding and Grant'),
       CONCAT('course_', t.sku, '_funding_and_grant'),
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/casl-generative-ai-for-finance-and-fintech.html" title="CASL - Generative AI for Finance and Fintech">CASL - Generative AI for Finance and Fintech</a></span></p>',
       NOW(), NOW(), 1
FROM tmp_needs_funding t
WHERE (t.cats LIKE '%,230,%')
  AND NOT ((t.cats LIKE '%,414,%') OR (t.cats LIKE '%,214,%') OR (t.cats LIKE '%,281,%') OR (t.cats LIKE '%,283,%') OR (t.cats LIKE '%,357,%') OR (t.cats LIKE '%,187,%') OR (t.cats LIKE '%,415,%') OR (t.cats LIKE '%,189,%'));

-- ai-for-healthcare
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' Funding and Grant'),
       CONCAT('course_', t.sku, '_funding_and_grant'),
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-data-analytics-and-ai-for-healthcare.html" title="WSQ - Data Analytics and AI for Healthcare">WSQ - Data Analytics and AI for Healthcare</a></span></p>',
       NOW(), NOW(), 1
FROM tmp_needs_funding t
WHERE (t.cats LIKE '%,235,%')
  AND NOT ((t.cats LIKE '%,414,%') OR (t.cats LIKE '%,214,%') OR (t.cats LIKE '%,281,%') OR (t.cats LIKE '%,283,%') OR (t.cats LIKE '%,357,%') OR (t.cats LIKE '%,187,%') OR (t.cats LIKE '%,415,%') OR (t.cats LIKE '%,189,%') OR (t.cats LIKE '%,230,%'));

-- ai-for-hr
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' Funding and Grant'),
       CONCAT('course_', t.sku, '_funding_and_grant'),
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-hr.html" title="WSQ - Agentic AI for HR">WSQ - Agentic AI for HR</a></span></p>',
       NOW(), NOW(), 1
FROM tmp_needs_funding t
WHERE (t.cats LIKE '%,378,%')
  AND NOT ((t.cats LIKE '%,414,%') OR (t.cats LIKE '%,214,%') OR (t.cats LIKE '%,281,%') OR (t.cats LIKE '%,283,%') OR (t.cats LIKE '%,357,%') OR (t.cats LIKE '%,187,%') OR (t.cats LIKE '%,415,%') OR (t.cats LIKE '%,189,%') OR (t.cats LIKE '%,230,%') OR (t.cats LIKE '%,235,%'));

-- ai-infrastructure-ml
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' Funding and Grant'),
       CONCAT('course_', t.sku, '_funding_and_grant'),
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-data-mining-and-machine-learning-fundamentals-for-beginners.html" title="WSQ - Data Mining and Machine Learning Fundamentals for Beginners">WSQ - Data Mining and Machine Learning Fundamentals for Beginners</a></span></p>',
       NOW(), NOW(), 1
FROM tmp_needs_funding t
WHERE (t.cats LIKE '%,250,%' OR t.cats LIKE '%,245,%')
  AND NOT ((t.cats LIKE '%,414,%') OR (t.cats LIKE '%,214,%') OR (t.cats LIKE '%,281,%') OR (t.cats LIKE '%,283,%') OR (t.cats LIKE '%,357,%') OR (t.cats LIKE '%,187,%') OR (t.cats LIKE '%,415,%') OR (t.cats LIKE '%,189,%') OR (t.cats LIKE '%,230,%') OR (t.cats LIKE '%,235,%') OR (t.cats LIKE '%,378,%'));

-- generative-ai-series
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' Funding and Grant'),
       CONCAT('course_', t.sku, '_funding_and_grant'),
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-for-content-creation.html" title="WSQ - Generative AI for Content Creation">WSQ - Generative AI for Content Creation</a></span></p>',
       NOW(), NOW(), 1
FROM tmp_needs_funding t
WHERE (t.cats LIKE '%,433,%')
  AND NOT ((t.cats LIKE '%,414,%') OR (t.cats LIKE '%,214,%') OR (t.cats LIKE '%,281,%') OR (t.cats LIKE '%,283,%') OR (t.cats LIKE '%,357,%') OR (t.cats LIKE '%,187,%') OR (t.cats LIKE '%,415,%') OR (t.cats LIKE '%,189,%') OR (t.cats LIKE '%,230,%') OR (t.cats LIKE '%,235,%') OR (t.cats LIKE '%,378,%') OR (t.cats LIKE '%,250,%' OR t.cats LIKE '%,245,%'));

-- ai-applications-series
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' Funding and Grant'),
       CONCAT('course_', t.sku, '_funding_and_grant'),
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-ai-agents-for-business.html" title="WSQ - AI Agents for Business">WSQ - AI Agents for Business</a></span></p>',
       NOW(), NOW(), 1
FROM tmp_needs_funding t
WHERE (t.cats LIKE '%,139,%' OR t.cats LIKE '%,128,%')
  AND NOT ((t.cats LIKE '%,414,%') OR (t.cats LIKE '%,214,%') OR (t.cats LIKE '%,281,%') OR (t.cats LIKE '%,283,%') OR (t.cats LIKE '%,357,%') OR (t.cats LIKE '%,187,%') OR (t.cats LIKE '%,415,%') OR (t.cats LIKE '%,189,%') OR (t.cats LIKE '%,230,%') OR (t.cats LIKE '%,235,%') OR (t.cats LIKE '%,378,%') OR (t.cats LIKE '%,250,%' OR t.cats LIKE '%,245,%') OR (t.cats LIKE '%,433,%'));

-- No AI series membership: same card, no recommendation link.
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' Funding and Grant'),
       CONCAT('course_', t.sku, '_funding_and_grant'),
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>',
       NOW(), NOW(), 1
FROM tmp_needs_funding t
WHERE 1 = 1
  AND NOT ((t.cats LIKE '%,414,%') OR (t.cats LIKE '%,214,%') OR (t.cats LIKE '%,281,%') OR (t.cats LIKE '%,283,%') OR (t.cats LIKE '%,357,%') OR (t.cats LIKE '%,187,%') OR (t.cats LIKE '%,415,%') OR (t.cats LIKE '%,189,%') OR (t.cats LIKE '%,230,%') OR (t.cats LIKE '%,235,%') OR (t.cats LIKE '%,378,%') OR (t.cats LIKE '%,250,%' OR t.cats LIKE '%,245,%') OR (t.cats LIKE '%,433,%') OR (t.cats LIKE '%,139,%' OR t.cats LIKE '%,128,%'));

-- Store mapping for every block created above (store 0 = all stores).
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0
FROM cms_block b
JOIN tmp_needs_funding t ON b.identifier = CONCAT('course_', t.sku, '_funding_and_grant');

DROP TEMPORARY TABLE IF EXISTS tmp_needs_funding;

