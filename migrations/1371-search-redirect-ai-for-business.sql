-- Search-term redirect: generic "AI for business" queries -> the AI for Business category page.
-- Applied live on SG prod 2026-09-09; this file keeps a rebuilt DB in the same state.
--
-- Scope note: an explicit term list (not a LIKE) because "%ai%business%" also matches
-- ~180 rows that name a SPECIFIC course (Business Innovation with AI, GenAI for Business
-- Presentations, Agentic AI for Business Process Automation, ...). Those redirects are
-- intentional and must not be clobbered.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/ai-for-business.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg > 0
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND TRIM(LOWER(query_text)) IN (
        'ai for business',
        'ai for businesses',
        'ai business',
        'business ai',
        'ai for business owners',
        'artificial intelligence for business',
        'artificial intelligence for businesses',
        'ai in business',
        'ai 4 business',
        'wsq - ai for business',
        'wsq ai for business'
      );
