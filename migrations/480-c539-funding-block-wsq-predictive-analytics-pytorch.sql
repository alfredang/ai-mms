-- C539 "Funding and Grant" block already points at the right WSQ course
-- (WSQ - Predictive Analytics with PyTorch) but via an OLD url_key
-- (wsq-predictive-modeling-pytorch) that now 301s. Rewrite the link to the
-- direct URL:
--   https://www.tertiarycourses.com.sg/wsq-predictive-analytics-with-pytorch-transform-your-data-to-prediction.html
--   (target validated 200 on SG prod, 2026-07-17)
--
-- Content-only UPDATE on the per-course cms/block row. Does NOT touch
-- cms_block_store mapping. No-op on sites without the block (partners hide the
-- funding card via CSS anyway). Idempotent. Invisible on prod until
-- block_html / full_page caches are flushed after deploy.

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-predictive-analytics-with-pytorch-transform-your-data-to-prediction.html" title="WSQ - Predictive Analytics with PyTorch: Transform Your Data to Prediction">WSQ - Predictive Analytics with PyTorch: Transform Your Data to Prediction</a></span><span style="text-decoration: underline;"></span></p>'
WHERE identifier = 'course_C539_funding_and_grant';
