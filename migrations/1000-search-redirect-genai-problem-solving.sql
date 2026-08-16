-- Point GenAI problem-solving search terms at the WSQ course
--   https://www.tertiarycourses.com.sg/wsq-generative-ai-for-problem-solving.html  (TGS-2023036653)
--
-- Context: the old slug `wsq-innovative-problem-solving-with-generative-ai-genai.html`
-- is a 301 (options='RP') onto this target -- same course, renamed. Search rows still
-- pointing at the old slug are repointed here so users take ONE hop instead of two.
--
-- Deliberately EXCLUDED (do not "fix" these):
--   * '%critical thinking%'  -> the non-WSQ twin C1234 (generative-ai-for-problem-solving.html),
--     a distinct course that is still enabled. Redirecting these would hide it from search.
--   * 8D / machine-learning problem-solving terms -> unrelated subjects, left to live search.
--
-- Correction semantics: uses `redirect <> @tgt`, NOT the empty-only guard, because prod rows
-- were already populated with the pre-rename slug (empty-only would silently skip them).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-problem-solving.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect <> @tgt)
  AND LOWER(query_text) LIKE '%problem solving%'
  AND (
        LOWER(query_text) LIKE '%genai%'
     OR LOWER(query_text) LIKE '%generative%'
     OR LOWER(query_text) LIKE '%innovative problem solving%'
     OR LOWER(query_text) LIKE '%innovation problem solving%'
     OR LOWER(query_text) = 'problem solving'
     OR LOWER(query_text) = 'wsq problem solving'
  )
  AND LOWER(query_text) NOT LIKE '%critical thinking%';
