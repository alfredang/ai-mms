-- Point the C430 "Funding and Grant" section to the matching IBF course:
--   IBF - Machine Learning 101 for Financial Trading (TGS-2023018794)
--   https://www.tertiarycourses.com.sg/ibf-machine-learning-101-for-financial-trading.html
-- This course is IBF-funded (not WSQ), so the pointer text reads "IBF funding".
--
-- Content-only UPDATE on the per-course cms/block row. Does NOT touch
-- cms_block_store mapping. Idempotent. Invisible on prod until block_html /
-- full_page caches are flushed after deploy.

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For IBF funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/ibf-machine-learning-101-for-financial-trading.html" title="IBF - Machine Learning 101 for Financial Trading">IBF - Machine Learning 101 for Financial Trading</a></span><span style="text-decoration: underline;"></span></p>'
WHERE identifier = 'course_C430_funding_and_grant';
