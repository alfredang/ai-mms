-- Point the "Funding and Grant" section of the AI Vibe Coding series courses
-- C384, C1800 and C683 to the matching WSQ course:
--   WSQ - Build Full Stack React Web App with Vibe Coding (TGS-2020505042)
--   https://www.tertiarycourses.com.sg/wsq-build-full-stack-react-web-app-with-vibe-coding.html
-- (C1143's funding block was already repointed in migration 341.)
--
-- Content-only UPDATE on each per-course cms/block row. Does NOT touch
-- cms_block_store mapping (a model->save() would wipe it and 404 the page).
-- Idempotent: sets an absolute value. Invisible on prod until block_html /
-- full_page caches are flushed after deploy.

SET @funding_html := '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-build-full-stack-react-web-app-with-vibe-coding.html" title="WSQ - Build Full Stack React Web App with Vibe Coding">WSQ - Build Full Stack React Web App with Vibe Coding</a></span><span style="text-decoration: underline;"></span></p>';

UPDATE cms_block SET content = @funding_html WHERE identifier = 'course_C384_funding_and_grant';
UPDATE cms_block SET content = @funding_html WHERE identifier = 'course_C1800_funding_and_grant';
UPDATE cms_block SET content = @funding_html WHERE identifier = 'course_C683_funding_and_grant';
