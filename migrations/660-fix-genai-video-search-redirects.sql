-- 659: fix WRONG search-term redirects for "generative AI video" intent (SG).
--
-- WHY: the autopopulate-search-redirects.php fuzzy matcher scored search terms by
-- containment (matched query tokens / query length) with Jaccard only as a tiebreak.
-- That tiebreak REWARDS shorter, more-generic course names and PENALISES the correct,
-- more-specific (longer) course. It also does no stemming, so "video" never matched
-- "videos". Net effect: terms that clearly mean "create videos WITH generative AI"
-- landed on unrelated non-video courses:
--   'generative ai video'                -> wsq-responsible-generative-ai-basics      (no video)
--   'Video with generative ai'           -> wsq-responsible-generative-ai-basics      (no video)
--   'Video generative Ai'                -> wsq-responsible-generative-ai-basics      (no video)
--   'gen ai videography'                 -> design-thinking-with-gen-ai               (not video)
--   'video creation using generative ai' -> wsq-mastering-prompt-engineering-...      (not video)
--   'Generative AI Video Creation'       -> wsq-mastering-prompt-engineering-...      (not video)
--
-- WHAT: repoint these six EXACT terms to the canonical funded course that teaches
-- exactly this -- TGS-2024043855 "WSQ - Creating Engaging Videos with Generative AI
-- (GenAI)" at wsq-creating-engaging-videos-with-generative-ai-genai.html (HTTP 200).
--
-- SCOPE: an EXPLICIT six-term list, not a LIKE sweep -- other video/genai terms that
-- already point at the right course, the kids GenAI course, or CapCut/agentic-editing
-- courses are intentionally NOT touched. This only corrects the six demonstrably-wrong
-- rows; it does not overwrite any other search term's redirect.
--
-- Partner-safe: SG store-code guard, so MY/GH are a no-op. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-creating-engaging-videos-with-generative-ai-genai.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND LOWER(TRIM(query_text)) IN (
    'generative ai video',
    'video with generative ai',
    'video generative ai',
    'gen ai videography',
    'video creation using generative ai',
    'generative ai video creation'
  );
