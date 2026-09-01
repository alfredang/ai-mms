-- Search-term redirect: "AI for Finance" (and its gen/generative/GAI/GenAI
-- variants) -> the AI for Finance category page.
--
-- These 9 SG rows previously pointed at individual course pages
-- (wsq-generative-ai-for-finance-and-fintech.html, generative-ai-for-finance.html),
-- both of which now 301-chain to a single CASL course. The category page lists
-- that course plus 14 siblings, so the generic query surfaces the whole range
-- instead of one course.
--
-- NULL-safe guard: NOT (redirect <=> @tgt) fills unset rows AND overwrites
-- wrong ones. A bare <> would skip every redirect IS NULL row.
-- The REGEXP is anchored (^...$) so only bare "AI for finance"-shaped queries
-- match -- full course-title searches and fintech/trading terms are untouched.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/ai-for-finance-courses.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg > 0
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(REPLACE(query_text, '  ', ' ')) REGEXP '^(gen(erative)? )?(ai|gai|genai)( |-)?(for|in) finance$';
