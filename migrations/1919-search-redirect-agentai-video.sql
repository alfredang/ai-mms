-- 1919: SG on-site search aliases -> the owner's specified Agentic AI video course.
-- Explicit correction of these aliases only, including existing old-title targets.
-- No other queries or partner stores are changed. Literal seeds survive a rebuild.

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

SET @sg := (SELECT store_id FROM core_store WHERE code = 'singapore' LIMIT 1);

SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-video-creation.html';

INSERT INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed) SELECT 'agentai video', 1, 0, @tgt, @sg, 0, 1, 1 WHERE @is_sg = 1 AND @sg IS NOT NULL AND NOT EXISTS (SELECT 1 FROM catalogsearch_query WHERE store_id = @sg AND query_text = 'agentai video');

INSERT INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed) SELECT 'agenticai video', 1, 0, @tgt, @sg, 0, 1, 1 WHERE @is_sg = 1 AND @sg IS NOT NULL AND NOT EXISTS (SELECT 1 FROM catalogsearch_query WHERE store_id = @sg AND query_text = 'agenticai video');

INSERT INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed) SELECT 'agentic ai video', 1, 0, @tgt, @sg, 0, 1, 1 WHERE @is_sg = 1 AND @sg IS NOT NULL AND NOT EXISTS (SELECT 1 FROM catalogsearch_query WHERE store_id = @sg AND query_text = 'agentic ai video');

INSERT INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed) SELECT 'agentic video', 1, 0, @tgt, @sg, 0, 1, 1 WHERE @is_sg = 1 AND @sg IS NOT NULL AND NOT EXISTS (SELECT 1 FROM catalogsearch_query WHERE store_id = @sg AND query_text = 'agentic video');

INSERT INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed) SELECT 'agentic ai videos', 1, 0, @tgt, @sg, 0, 1, 1 WHERE @is_sg = 1 AND @sg IS NOT NULL AND NOT EXISTS (SELECT 1 FROM catalogsearch_query WHERE store_id = @sg AND query_text = 'agentic ai videos');

INSERT INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed) SELECT 'agentic ai for video', 1, 0, @tgt, @sg, 0, 1, 1 WHERE @is_sg = 1 AND @sg IS NOT NULL AND NOT EXISTS (SELECT 1 FROM catalogsearch_query WHERE store_id = @sg AND query_text = 'agentic ai for video');

INSERT INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed) SELECT 'agentic ai for video creation', 1, 0, @tgt, @sg, 0, 1, 1 WHERE @is_sg = 1 AND @sg IS NOT NULL AND NOT EXISTS (SELECT 1 FROM catalogsearch_query WHERE store_id = @sg AND query_text = 'agentic ai for video creation');

UPDATE catalogsearch_query SET redirect = @tgt, num_results = 1, is_processed = 1 WHERE @is_sg = 1 AND store_id = @sg AND NOT (redirect <=> @tgt) AND REPLACE(REPLACE(LOWER(TRIM(query_text)), '-', ''), ' ', '') IN ('agentaivideo', 'agenticaiforvideo', 'agenticaiforvideocreation', 'agenticaivideo', 'agenticaivideos', 'agenticvideo');
