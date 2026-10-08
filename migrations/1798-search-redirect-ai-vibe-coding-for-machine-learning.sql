-- Search redirect: "AI Vibe Coding for Machine Learning" + its course code
-- TGS-2019504643 -> the WSQ course page.
--
-- TGS-2019504643 previously pointed at wsq-machine-learning-python-course.html,
-- which now 301s to the same page; repoint it straight at the final URL.
-- NOTE: the exact title also names the non-WSQ C430 course; user chose the WSQ one.
-- Already applied live on SG prod 2026-10-08. Exact terms only (no LIKE) so a
-- rebuilt DB can't sweep in sibling "vibe coding" terms. SG-only (TGS- course).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-machine-learning-scikit-learn.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(TRIM(query_text)) IN (
    'ai vibe coding for machine learning',
    'wsq - ai vibe coding for machine learning',
    'wsq ai vibe coding for machine learning',
    'tgs-2019504643'
  );
