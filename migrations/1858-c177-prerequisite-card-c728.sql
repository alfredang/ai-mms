-- Prerequisite card (non-WSQ courses): per-course cms/block course_<SKU>_prerequisite, edited in
-- Edit Course -> Prerequisite and rendered by view.phtml directly above the Certification card
-- (C-prefix SKUs only, hidden when empty).
--
-- C177 Build a Multi AI Agents Workflow for Stock Trading: prerequisite = C728 AI Powered Quantitative
-- Trading Fundamentals (user, 2026-10-25). The card replaces the "Prerequisite" paragraph 1855 put at the
-- top of C177's prerequisite attribute, so that paragraph is removed (the entry requirements and software
-- list stay).
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C177' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);
SET @content := '<p>You should complete <a href="https://www.tertiarycourses.com.sg/ai-powered-quantitative-trading-fundamentals.html" title="AI Powered Quantitative Trading Fundamentals">AI Powered Quantitative Trading Fundamentals (C728)</a> before taking this course.</p>\n<p>C728 demonstrates the multi AI agents trading system and the indicators, backtesting and paper trading it relies on; this course teaches you to build it from scratch.</p>';

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C177 — Prerequisite', 'course_C177_prerequisite', @content, NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C177_prerequisite');

UPDATE cms_block SET content = @content, is_active = 1, update_time = NOW()
 WHERE @ok AND identifier = 'course_C177_prerequisite';

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE @ok AND identifier = 'course_C177_prerequisite';

SET @a_prereq := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
UPDATE catalog_product_entity_text
   SET value = SUBSTRING(value, LOCATE('<h2>Minimum Entry Requirement</h2>', value))
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_prereq AND store_id = 0
   AND value LIKE '<h2>Prerequisite</h2>%C728%' AND LOCATE('<h2>Minimum Entry Requirement</h2>', value) > 0;
