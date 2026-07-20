-- Point the C141 "Funding and Grant" section to the matching WSQ course:
--   WSQ - Native iOS Apps Development with C++ and Vibe Coding (TGS-2023037545)
--   https://www.tertiarycourses.com.sg/wsq-native-ios-apps-development-with-c-and-vibe-coding.html
--   (target validated 200 on SG prod, 2026-07-17)
--
-- Content-only UPDATE on the per-course cms/block row. Does NOT touch
-- cms_block_store mapping. No-op on sites without the block (partners hide the
-- funding card via CSS anyway). Idempotent. Invisible on prod until
-- block_html / full_page caches are flushed after deploy.

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-native-ios-apps-development-with-c-and-vibe-coding.html" title="WSQ - Native iOS Apps Development with C++ and Vibe Coding">WSQ - Native iOS Apps Development with C++ and Vibe Coding</a></span><span style="text-decoration: underline;"></span></p>'
WHERE identifier = 'course_C141_funding_and_grant';
