-- Point the C138 "Funding and Grant" section to the matching WSQ course:
--   WSQ - Python Fundamental Course for Beginners (TGS-2019503161)
--   https://www.tertiarycourses.com.sg/wsq-python-fundamental-course-for-beginners.html
--
-- Content-only UPDATE on the per-course cms/block row. Does NOT touch
-- cms_block_store mapping. Idempotent. Invisible on prod until block_html /
-- full_page caches are flushed after deploy.

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-python-fundamental-course-for-beginners.html" title="WSQ - Python Fundamental Course for Beginners">WSQ - Python Fundamental Course for Beginners</a></span><span style="text-decoration: underline;"></span></p>'
WHERE identifier = 'course_C138_funding_and_grant';
