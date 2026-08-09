-- Search-term redirect: "Copilot Studio and Power Automate" -> the WSQ
-- Business Process Automation with Power Automate and Copilot Studio Agents
-- course product page.
--
-- Scoped deliberately to the "copilot studio and power automate" word order.
-- The MIRRORED term "Power Automate and Copilot Studio" (query_id 74339) is
-- NOT touched: migration 894 established that it intentionally points at the
-- WSQ Create Intelligent Power Apps and Power Automate Workflows with Copilot
-- course. A broader LIKE on '%copilot studio%' + '%power automate%' matches
-- both orders and silently clobbers that row -- do not widen this pattern.
--
-- Applied live on SG prod 2026-08-09; this keeps a rebuilt DB in the same state.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-business-process-automation-with-power-automate-and-copilot-studio-agents.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect <> @tgt)
  AND LOWER(query_text) LIKE '%copilot studio and power automate%';
