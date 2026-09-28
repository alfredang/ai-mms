-- Search redirect: "ai-103" / "ai 103" / "ai103"
-- -> WSQ Developing AI Apps and Agents on Azure (AI-103) (TGS-2023036651). Applied live on SG prod 2026-09-28.
-- Corrects the 3 prod rows that pointed at the non-WSQ AI-103 certification course. NULL-safe guard fills + corrects.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-developing-ai-apps-and-agents-on-azure-ai-103.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(TRIM(query_text)) IN ('ai-103', 'ai 103', 'ai103');
