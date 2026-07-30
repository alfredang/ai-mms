-- 851: Search-term redirect — "Generative AI for Business Presentations"
--      -> WSQ Designing and Delivering Impactful Business Presentations Using AI
--
-- SG-only (WSQ / TGS- course does not exist on partner sites; the store guard
-- makes this a no-op on MY/GH).
--
-- Matched by LIKE '%generative ai for business present%' so typo / plural /
-- casing variants and rows created after this migration are covered, while the
-- distinct term "generative ai for business" (which correctly points at the
-- Digital Transformation GenAI course) is left alone.
--
-- Applied live on prod 2026-07-30 (query_id 77661).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-designing-and-delivering-impactful-business-presentations-using-ai.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%generative ai for business present%';
