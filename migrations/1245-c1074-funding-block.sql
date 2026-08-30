-- 1245: Create the missing Funding Options blocks for two converted courses:
--   C1074 Fine Tuning OpenVLA Model
--   C811  Job Assessment and Redesign for AI Adoption
--
-- Why it was missing: 1226 only created blocks for courses that showed NO
-- funding card at all, skipping the ~121 whose card came from a legacy
-- "Funding and Grant" section embedded in short_description. C1074 was one of
-- those. 1244 then replaced its short_description with new copy, which
-- removed that legacy section — so the course was left with neither a block
-- nor a fallback, and the card disappeared.
--
-- C811 hit the same thing via 1210. An audit of every course converted this
-- session found exactly these two.
--
-- Any future conversion of a course in that group has the same hazard: check
-- for a funding block AFTER rewriting short_description, not before.
--
-- Points at WSQ - Generative AI Model Development and Fine Tuning (verified
-- 200), the closest funded course by subject, matching what 1244 set for the
-- sibling conversions.
--
-- Written with plain SQL plus an explicit cms_block_store row — never a
-- cms/block model save, which wipes the store mapping and 404s the block.
--
-- SG-guarded. Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C1074 Funding and Grant',
       'course_C1074_funding_and_grant',
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-model-development-and-fine-tuning.html" title="WSQ - Generative AI Model Development and Fine Tuning">WSQ - Generative AI Model Development and Fine Tuning</a></span></p>',
       NOW(), NOW(), 1
FROM dual
WHERE @is_sg > 0
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM cms_block) b
    WHERE b.identifier = 'course_C1074_funding_and_grant'
  );

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-model-development-and-fine-tuning.html" title="WSQ - Generative AI Model Development and Fine Tuning">WSQ - Generative AI Model Development and Fine Tuning</a></span></p>',
    is_active = 1
WHERE identifier = 'course_C1074_funding_and_grant'
  AND @is_sg > 0;

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0
FROM (SELECT * FROM cms_block) b
WHERE b.identifier = 'course_C1074_funding_and_grant'
  AND @is_sg > 0;

-- ===== C811: same cause, HR-relevant funding target =====

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C811 Funding and Grant',
       'course_C811_funding_and_grant',
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-hr.html" title="WSQ - Agentic AI for HR">WSQ - Agentic AI for HR</a></span></p>',
       NOW(), NOW(), 1
FROM dual
WHERE @is_sg > 0
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM cms_block) b
    WHERE b.identifier = 'course_C811_funding_and_grant'
  );

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-hr.html" title="WSQ - Agentic AI for HR">WSQ - Agentic AI for HR</a></span></p>',
    is_active = 1
WHERE identifier = 'course_C811_funding_and_grant'
  AND @is_sg > 0;

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0
FROM (SELECT * FROM cms_block) b
WHERE b.identifier = 'course_C811_funding_and_grant'
  AND @is_sg > 0;
