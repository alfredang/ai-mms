-- Repoint the C1143 "Funding and Grant" section to the correct WSQ alternative.
-- After repurposing C1143 to "React AI Vibe Coding for React Development"
-- (migration 340), the funding pointer should send learners seeking WSQ
-- funding to the matching WSQ course rather than the old React UI course.
--
-- Old link: NICF - UI Development with React for Beginners
--           (/wsq-react-ui-course.html)
-- New link: WSQ - Build Full Stack React Web App with Vibe Coding
--           (TGS-2020505042, /wsq-build-full-stack-react-web-app-with-vibe-coding.html)
--
-- Content-only UPDATE on the per-course cms/block row (identifier
-- course_C1143_funding_and_grant). Does NOT touch cms_block_store mapping, so
-- the block stays scoped as-is (a model->save() would wipe the mapping and
-- 404 the page — deliberately avoided). Idempotent: sets an absolute value.
-- On production this is invisible until the block_html/full_page caches are
-- flushed (entrypoint clears file caches, not Redis) — reindex/flush after deploy.

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-build-full-stack-react-web-app-with-vibe-coding.html" title="WSQ - Build Full Stack React Web App with Vibe Coding">WSQ - Build Full Stack React Web App with Vibe Coding</a></span><span style="text-decoration: underline;"></span></p>'
WHERE identifier = 'course_C1143_funding_and_grant';
