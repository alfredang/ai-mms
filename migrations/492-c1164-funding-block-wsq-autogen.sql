-- C1164 "Funding and Grant" block pointed at the old IBF Machine Learning 101
-- for Financial Trading course. The course is now "Multi Agents System for
-- Algorithmic Trading", so relink the block to the matching WSQ course:
--   https://www.tertiarycourses.com.sg/wsq-develop-multi-agent-ai-applications-with-autogen.html
--   (target validated 200 on SG prod, 2026-07-17)
--
-- Content-only UPDATE on the per-course cms/block row. Does NOT touch
-- cms_block_store mapping. No-op on sites without the block (partners hide the
-- funding card via CSS anyway). Idempotent. Invisible on prod until
-- block_html / full_page caches are flushed after deploy.

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-develop-multi-agent-ai-applications-with-autogen.html" title="WSQ - Develop Multi-Agent AI Applications with AutoGen">WSQ - Develop Multi-Agent AI Applications with AutoGen</a></span></p>'
WHERE identifier = 'course_C1164_funding_and_grant';
