-- 869: Follow-up to 868 — seed like counts on the blog posts that 868 missed.
--
-- Why 868 missed them:
--  * UTAP post: a real visitor liked it on the live site between the migration
--    being written and the deploy landing, so `likes` was 1, not 0, and 868's
--    `likes = 0` guard correctly skipped it. It shipped showing "1 Like".
--  * The two agentic-ai posts exist on production but not in the local DB
--    snapshot 868 was authored against, so they were never in its list.
--
-- Guard is `likes < 100` rather than `likes = 0`, so it also catches a post that
-- has picked up a handful of genuine votes. This only ever RAISES a count into the
-- 100-200 band, and posts with a real count already at/above 100 are untouched.
--
-- Deliberately NOT touched: posts with low-but-organic counts that were never
-- seeded (urban-farming 12, openclaw-blockchain 43, red-beacon 39, kajima 61,
-- charles-and-keith 34, msig 38). Those numbers are real reader activity — this
-- migration is scoped by url_key so it can never sweep them up.
--
-- Values hardcoded (not RAND()) for the same reason as 868: identical across every
-- partner instance, and a re-run is a no-op once the count is >= 100.

UPDATE `mmd_blog_post` SET `likes` = 189 WHERE `url_key` = 'utap-ai-tool-subscription-claim-guide-singapore' AND `likes` < 100;
UPDATE `mmd_blog_post` SET `likes` = 126 WHERE `url_key` = 'agentic-ai-applications-claude-code-singapore' AND `likes` < 100;
UPDATE `mmd_blog_post` SET `likes` = 173 WHERE `url_key` = 'agentic-ai-for-business-process-automation-singapore' AND `likes` < 100;
