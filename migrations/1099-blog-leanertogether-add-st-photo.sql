-- 1099: Blog post 'learner-built-leanertogether-app-with-claude-code' — add the
--       Straits Times photo of Tan Chin Hock as an in-article credited figure.
--
-- Applied LIVE on SG prod 2026-08-24 (blog content is data, not code, so the
-- shipped migration alone does NOT change an already-populated row). This file
-- exists so a rebuilt DB reproduces the same state.
--
-- Image: cropped from the ST front page scan the learner sent us; the PHOTO ONLY,
-- not the full page. Hosted on our R2 bucket at
--   blog/leanertogether-tan-chin-hock-st.jpg
-- Credit line in the figcaption preserves "ST PHOTO: BRIAN TEO", links the
-- source article, and records that the learner supplied the image.
--
-- Idempotent: the UPDATE no-ops once the figure is present (LOCATE guard), so
-- re-running is safe and never inserts a second copy.
-- SG-only: partner sites have no such post; the url_key match makes it a no-op there.

UPDATE `mmd_blog_post`
   SET `content` = REPLACE(`content`, ' <h2>Who he is, and what he built</h2>', ' <figure class="mmd-blog-figure"><img src="https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/leanertogether-tan-chin-hock-st.jpg" alt="LeanerTogether founder Tan Chin Hock holding a tray of nasi lemak at a hawker centre" width="848" height="608" loading="lazy" /><figcaption>LeanerTogether founder Tan Chin Hock with his favourite nasi lemak at AR-Rina Nasi Padang in Bukit Batok. ST PHOTO: BRIAN TEO &mdash; from <a href="https://www.straitstimes.com/life/food/how-a-47-year-old-lost-weight-with-a-calorie-tracking-app-without-giving-up-hawker-food" target="_blank" rel="noopener">The Straits Times</a>, 23 August 2026, image courtesy of Tan Chin Hock.</figcaption></figure> <h2>Who he is, and what he built</h2>'),
       `updated_at` = NOW()
 WHERE `url_key` = 'learner-built-leanertogether-app-with-claude-code'
   AND LOCATE('mmd-blog-figure', `content`) = 0
   AND LOCATE(' <h2>Who he is, and what he built</h2>', `content`) > 0;
