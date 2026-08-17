-- Search-term redirects for Generative AI / SEO terms (SG only).
--
-- Two buckets, deliberately different targets:
--   1. genai + SEO terms      -> WSQ - Generative AI for SEO (TGS-2020503501)
--   2. generic "ai seo" terms -> the SEO category listing, because BOTH
--      "WSQ - Enhancing Online Presence with AI Powered SEO" (TGS-2019503343)
--      and the Generative AI course are live; sending a generic AI-SEO query
--      straight at one course hides the other. The listing shows both.
--
-- Applied live on SG prod 2026-08-17; this file only preserves that state for
-- a rebuilt/restored DB.
--
-- Two traps encoded here:
--
-- (a) NULL-safe guard. `redirect <> @x` alone evaluates to NULL (not TRUE) for
--     rows whose redirect IS NULL, silently skipping exactly the empty rows
--     this is meant to fill. On prod that left `gen ai for seo` untouched on
--     the first pass. Always pair it with an explicit IS NULL test.
--
-- (b) Do NOT widen bucket 1 to a bare `LIKE '%genai%' AND LIKE '%seo%'` with
--     the NULL branch. Prod carries ~180 genai rows with an EMPTY redirect
--     (genai video, genai hr, genai fintech, ...). A loose pattern combined
--     with the IS NULL fill would sweep unrelated genai courses into the SEO
--     course on a rebuilt DB. Bucket 1 is therefore an explicit verified term
--     list plus one tight "generative ai ... seo" title pattern.

SET @sg    := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @genai := 'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-search-engine-optimization-seo.html';
SET @cat   := 'https://www.tertiarycourses.com.sg/search-engine-optimisation-seo-training-courses.html';

-- Seed the genai variants that may not exist yet on a rebuilt DB.
INSERT INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed, display_in_terms)
SELECT t.q, 1, 1, 0, @genai, 1, 0
FROM (
            SELECT 'gen ai for seo' AS q
  UNION ALL SELECT 'genai for seo'
  UNION ALL SELECT 'gen ai seo'
  UNION ALL SELECT 'generative ai for seo'
  UNION ALL SELECT 'generative ai seo'
) t
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text, store_id FROM catalogsearch_query) c
    WHERE c.store_id = 1 AND c.query_text = t.q
  );

-- 1. Verified genai-SEO terms -> the Generative AI for SEO course.
UPDATE catalogsearch_query
SET redirect = @genai, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect <> @genai)
  AND (
        LOWER(TRIM(query_text)) IN (
          'gen ai for seo', 'genai for seo', 'gen ai seo', 'genai seo',
          'generative ai for seo', 'generative ai seo', 'seo genai', 'seo gen ai'
        )
        -- exact course-title queries, e.g.
        -- "WSQ - Generative AI for Search Engine Optimization (SEO)"
        OR LOWER(query_text) LIKE '%generative ai for search engine optimi%'
      );

-- 2. Generic AI-SEO terms -> the SEO category listing (both courses visible).
--    Exact-match only: a LIKE '%ai%seo%' here would swallow the genai terms
--    set above and every "AI Powered SEO" exact-title query.
UPDATE catalogsearch_query
SET redirect = @cat, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect <> @cat)
  AND LOWER(TRIM(query_text)) IN ('ai seo', 'ai for seo', 'seo ai', 'seo for ai');
