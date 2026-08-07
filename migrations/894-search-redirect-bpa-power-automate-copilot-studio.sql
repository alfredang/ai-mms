-- Search-term redirect: "Business Process Automation with Power Automate and
-- Copilot Studio Agents" -> the WSQ course product page.
-- Matches by the full-title LIKE pattern so pasted/quoted variants are covered,
-- without touching the shorter "Power Automate and Copilot Studio" term, which
-- intentionally points at the Power Apps workflows-with-Copilot course.
-- Applied live on SG prod 2026-08-07; this keeps a rebuilt DB in the same state.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-business-process-automation-with-power-automate-and-copilot-studio-agents.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect <> @tgt)
  AND LOWER(query_text) LIKE '%business process automation with power automate and copilot studio%';
