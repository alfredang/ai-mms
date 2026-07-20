-- C1231 "Funding and Grant" block pointed at WSQ Web API Integration with
-- Python Flask — no longer the closest match after the repurpose to
-- "AI Vibe Coding for MCP Tool Development". Point it at the matching WSQ
-- course instead:
--   https://www.tertiarycourses.com.sg/wsq-agentic-ai-applications-with-claude-code.html
--   (target validated 200 on SG prod, 2026-07-17)
--
-- Content-only UPDATE on the per-course cms/block row. Does NOT touch
-- cms_block_store mapping. No-op on sites without the block (partners hide the
-- funding card via CSS anyway). Idempotent. Invisible on prod until
-- block_html / full_page caches are flushed after deploy.

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-applications-with-claude-code.html" title="WSQ - Agentic AI Applications with Claude Code">WSQ - Agentic AI Applications with Claude Code</a></span></p>'
WHERE identifier = 'course_C1231_funding_and_grant';
