-- 309-home-agentic-ai-slider.sql
-- SG homepage: replace the "Certification Exam Prep WSQ Courses" featured slider
-- (category 345) with "SkillsFuture Funded AI Courses" listing the WSQ Agentic AI
-- Courses category (196, url_key wsq-agentic-ai-courses, 18 courses).
--
-- Targeted REPLACE keyed off the unique old block markup, so it only touches the
-- single SG homepage row that contains it. Idempotent: after the swap the old
-- string no longer matches, so a re-run is a no-op. MY/GH homepages never carried
-- this block, so this is a no-op on those partner DBs.
UPDATE cms_page
SET content = REPLACE(
  content,
  'category_id="345" product_count="10" breakpoints="[0, 1], [320, 2], [480, 3], [768, 4]" pagination="1" centered="1" hide_button="0"   block_name="Certification Exam Prep WSQ Courses"',
  'category_id="196" product_count="18" breakpoints="[0, 1], [320, 2], [480, 3], [768, 4]" pagination="1" centered="1" hide_button="0"   block_name="SkillsFuture Funded AI Courses"'
)
WHERE content LIKE '%block_name="Certification Exam Prep WSQ Courses"%';
