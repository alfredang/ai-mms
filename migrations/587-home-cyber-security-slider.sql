-- 587: SG homepage — add a 4th featured slider row, "SkillsFuture Funded Cyber
-- Security Courses", listing the WSQ Cyber Security & PDPA Courses category
-- (364, url_key wsq-cyber-security-pdpa-courses).
--
-- Appended immediately after the existing "SkillsFuture Funded AI Courses" row,
-- reusing that row's exact widget markup (same breakpoints/pagination/centered)
-- plus is_random="1" so the courses shown are a random pick from the whole
-- category, re-rolled on each block-cache regen (migration 330's rationale).
--
-- Scoped by the SG-only "SkillsFuture Funded AI Courses" block name, so this is a
-- no-op on the MY/GH partner DBs. Idempotent: the NOT LIKE guard means a re-run
-- after the row exists matches nothing.
UPDATE cms_page
SET content = REPLACE(
  content,
  'category_id="196" product_count="18" breakpoints="[0, 1], [320, 2], [480, 3], [768, 4]" pagination="1" centered="1" hide_button="0"   block_name="SkillsFuture Funded AI Courses"}}',
  'category_id="196" product_count="18" breakpoints="[0, 1], [320, 2], [480, 3], [768, 4]" pagination="1" centered="1" hide_button="0"   block_name="SkillsFuture Funded AI Courses"}}\n{{block type="ultimo/product_list_featured" template="catalog/product/list_featured_slider.phtml" is_random="1" category_id="364" product_count="13" breakpoints="[0, 1], [320, 2], [480, 3], [768, 4]" pagination="1" centered="1" hide_button="0"   block_name="SkillsFuture Funded Cyber Security Courses"}}'
)
WHERE identifier = 'home'
  AND content LIKE '%block_name="SkillsFuture Funded AI Courses"%'
  AND content NOT LIKE '%block_name="SkillsFuture Funded Cyber Security Courses"%';

-- Verified against SG prod (2026-07-18): only cms_page.page_id=2 carries the
-- "SkillsFuture Funded AI Courses" anchor, so exactly one row is updated. The
-- other 10 `home` rows on prod belong to retired stores (NG/BT/IN/Infotech) and
-- carry unrelated rail names -- page_id 34 has a rail literally named "Cyber
-- Security Courses", which is why both guards key on the FULL block_name string
-- rather than a "Cyber Security" substring.
