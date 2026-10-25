-- Prerequisite cards for the Claude certification exam prep ladder (user, 2026-10-25), via the
-- per-course cms/block course_<SKU>_prerequisite (Edit Course -> Prerequisite; rendered as the
-- "Prerequisite" card on C-prefix courses -- same shape as 1858):
--   C437  Claude Certified Architect - Foundations (CCAR-F)    -> complete C991 CCAO-F first
--   C1098 Claude Certified Developer - Foundations (CCDV-F)    -> complete C991 CCAO-F first
--   C740  Claude Certified Architect - Professional (CCAR-P)   -> complete C437 CCAR-F first
-- This is a course prerequisite, not an Anthropic exam requirement (the exams list none), so the
-- copy says "before taking this course".
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @ok := (@sg = 1);

SET @ccaof := '<p>You should complete <a href="https://www.tertiarycourses.com.sg/claude-certified-associate-foundations-ccao-f-exam-prep.html" title="Claude Certified Associate - Foundations (CCAO-F) Exam Prep">Claude Certified Associate - Foundations (CCAO-F) Exam Prep (C991)</a> before taking this course.</p>';

SET @c437 := CONCAT(@ccaof, '\n<p>C991 covers the Claude foundations &ndash; prompting, output evaluation, product and model selection, Claude Projects and responsible use &ndash; that this course builds on to design production-grade solutions with Claude.</p>');
SET @c1098 := CONCAT(@ccaof, '\n<p>C991 covers the Claude foundations &ndash; prompting, output evaluation, product and model selection, Claude Projects and responsible use &ndash; that this course builds on to develop with the Claude API, Claude Code and MCP.</p>');
SET @c740 := '<p>You should complete <a href="https://www.tertiarycourses.com.sg/claude-certified-architect-foundations-ccar-f-exam-prep.html" title="Claude Certified Architect - Foundations (CCAR-F) Exam Prep">Claude Certified Architect - Foundations (CCAR-F) Exam Prep (C437)</a> before taking this course.</p>\n<p>C437 covers the architecture foundations &ndash; agentic architecture, tool design and MCP integration, Claude Code configuration, structured output and reliability &ndash; that this course extends to governing production Claude systems at enterprise scale.</p>';

DROP TEMPORARY TABLE IF EXISTS tmp_claude_prereq;
CREATE TEMPORARY TABLE tmp_claude_prereq (sku VARCHAR(16) NOT NULL PRIMARY KEY, content TEXT NOT NULL);
INSERT INTO tmp_claude_prereq (sku, content)
SELECT t.sku, t.content
  FROM (SELECT 'C437' AS sku, @c437 AS content
        UNION ALL SELECT 'C1098', @c1098
        UNION ALL SELECT 'C740', @c740) t
 WHERE @ok AND EXISTS (SELECT 1 FROM catalog_product_entity p WHERE TRIM(p.sku) = t.sku);

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT CONCAT('Course ', t.sku, ' - Prerequisite'), CONCAT('course_', t.sku, '_prerequisite'), t.content, NOW(), NOW(), 1
  FROM tmp_claude_prereq t
 WHERE NOT EXISTS (SELECT 1 FROM cms_block b WHERE b.identifier = CONCAT('course_', t.sku, '_prerequisite'));

UPDATE cms_block b
  JOIN tmp_claude_prereq t ON b.identifier = CONCAT('course_', t.sku, '_prerequisite')
   SET b.content = t.content, b.is_active = 1, b.update_time = NOW();

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0
  FROM cms_block b
  JOIN tmp_claude_prereq t ON b.identifier = CONCAT('course_', t.sku, '_prerequisite');

DROP TEMPORARY TABLE IF EXISTS tmp_claude_prereq;
