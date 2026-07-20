-- C1154 "Funding and Grant" block pointed at the WSQ SQL course via an OLD
-- url_key (wsq-sql-beginners) that now 301s. Rewrite the link to the direct
-- URL:
--   https://www.tertiarycourses.com.sg/wsq-sql-fundamental-for-beginners.html
--   (target validated 200 on SG prod, 2026-07-17)
--
-- Content-only UPDATE on the per-course cms/block row. Does NOT touch
-- cms_block_store mapping. No-op on sites without the block (partners hide the
-- funding card via CSS anyway). Idempotent. Invisible on prod until
-- block_html / full_page caches are flushed after deploy.

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-sql-fundamental-for-beginners.html" title="WSQ - SQL Fundamental for Beginners">WSQ - SQL Fundamental for Beginners</a></span></p>'
WHERE identifier = 'course_C1154_funding_and_grant';
