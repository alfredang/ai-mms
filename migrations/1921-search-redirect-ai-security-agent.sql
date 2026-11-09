-- 1921: Requested SG search term and plural alias -> verified enabled AI Security course.
-- Only fill empty redirects; preserve intentional existing destinations and query statistics.
-- SG instance/store guards make this a no-op on partner databases.
SET @is_sg := IF(@mms_instance = 'SG', 1, 0);
SET @sg := (SELECT store_id FROM core_store WHERE code = 'singapore' LIMIT 1);
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-security-for-autonomous-ai-agents.html';
INSERT INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed) SELECT 'ai security agent', 1, 0, @tgt, @sg, 0, 1, 1 WHERE @is_sg = 1 AND @sg IS NOT NULL AND NOT EXISTS (SELECT 1 FROM catalogsearch_query WHERE store_id = @sg AND query_text = 'ai security agent');
INSERT INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed) SELECT 'ai security agents', 1, 0, @tgt, @sg, 0, 1, 1 WHERE @is_sg = 1 AND @sg IS NOT NULL AND NOT EXISTS (SELECT 1 FROM catalogsearch_query WHERE store_id = @sg AND query_text = 'ai security agents');
UPDATE catalogsearch_query SET redirect = @tgt, num_results = 1, is_processed = 1 WHERE @is_sg = 1 AND store_id = @sg AND LOWER(TRIM(query_text)) IN ('ai security agent', 'ai security agents') AND (redirect IS NULL OR redirect = '');
