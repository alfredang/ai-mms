-- 1927: search-term redirects for the dashboard "Last 10 search terms" (2026-11-13).
-- Applied LIVE on SG prod 2026-11-14 first; this file keeps a rebuilt DB in the same state.
-- Exact-term match (punctuation variants included), NULL-safe overwrite guard.
-- WSQ course by default; category page when no single course fits.
-- Also removes the two zero-result spam/noise terms ("fashion", "fashiuon").
-- SG-only (every target is a SG URL; TGS- courses do not exist on MY/GH).

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @b  := 'https://www.tertiarycourses.com.sg/';

UPDATE catalogsearch_query SET redirect = CONCAT(@b, 'leadership-training-courses.html'), num_results = 1, is_processed = 1
WHERE @sg = 1 AND store_id = 1 AND LOWER(TRIM(query_text)) = 'smu leaderhip'
  AND NOT (redirect <=> CONCAT(@b, 'leadership-training-courses.html'));

UPDATE catalogsearch_query SET redirect = CONCAT(@b, 'wsq-accounting-for-non-finance-managers.html'), num_results = 1, is_processed = 1
WHERE @sg = 1 AND store_id = 1 AND LOWER(TRIM(query_text)) = 'non finance manager'
  AND NOT (redirect <=> CONCAT(@b, 'wsq-accounting-for-non-finance-managers.html'));

UPDATE catalogsearch_query SET redirect = CONCAT(@b, 'wsq-ai-agents-for-business.html'), num_results = 1, is_processed = 1
WHERE @sg = 1 AND store_id = 1 AND LOWER(TRIM(query_text)) = 'wsq - ai agents for business'
  AND NOT (redirect <=> CONCAT(@b, 'wsq-ai-agents-for-business.html'));

UPDATE catalogsearch_query SET redirect = CONCAT(@b, 'wsq-business-innovation-with-agentic-ai-and-ai-agents.html'), num_results = 1, is_processed = 1
WHERE @sg = 1 AND store_id = 1 AND LOWER(TRIM(query_text)) = 'wsq - business innovation with agentic ai'
  AND NOT (redirect <=> CONCAT(@b, 'wsq-business-innovation-with-agentic-ai-and-ai-agents.html'));

UPDATE catalogsearch_query SET redirect = CONCAT(@b, 'wsq-fundamentals-of-iso-9001-quality-management-system.html'), num_results = 1, is_processed = 1
WHERE @sg = 1 AND store_id = 1
  AND REPLACE(REPLACE(REPLACE(REPLACE(LOWER(TRIM(query_text)), ' ', ''), '(', ''), ')', ''), '''', '') = 'tgs-2023020563'
  AND NOT (redirect <=> CONCAT(@b, 'wsq-fundamentals-of-iso-9001-quality-management-system.html'));

UPDATE catalogsearch_query SET redirect = CONCAT(@b, 'wsq-cisco-certified-network-associate-ccna.html'), num_results = 1, is_processed = 1
WHERE @sg = 1 AND store_id = 1 AND LOWER(TRIM(query_text)) = 'wsq - cisco certified networkassociate (ccna)'
  AND NOT (redirect <=> CONCAT(@b, 'wsq-cisco-certified-network-associate-ccna.html'));

UPDATE catalogsearch_query SET redirect = CONCAT(@b, 'wsq-certified-lean-six-sigma-green-belt-clssgb-training.html'), num_results = 1, is_processed = 1
WHERE @sg = 1 AND store_id = 1 AND LOWER(TRIM(query_text)) = 'lean six green belt'
  AND NOT (redirect <=> CONCAT(@b, 'wsq-certified-lean-six-sigma-green-belt-clssgb-training.html'));

UPDATE catalogsearch_query SET redirect = CONCAT(@b, 'wsq-microsoft-azure-ai-fundamentals-ai-901.html'), num_results = 1, is_processed = 1
WHERE @sg = 1 AND store_id = 1 AND LOWER(TRIM(query_text)) = 'microsoft azure ai fundamentals (ai-901)'
  AND NOT (redirect <=> CONCAT(@b, 'wsq-microsoft-azure-ai-fundamentals-ai-901.html'));

DELETE FROM catalogsearch_query
WHERE @sg = 1 AND store_id = 1 AND LOWER(TRIM(query_text)) IN ('fashion', 'fashiuon')
  AND (redirect IS NULL OR redirect = '');
