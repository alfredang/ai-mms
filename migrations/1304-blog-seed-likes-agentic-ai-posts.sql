-- 1304: Seed a like count on the two newest blog posts, which are still at 0.
--
-- Why: both posts published 2026-09-01 render "0" on the "From our blog" cards
-- next to older posts showing 100-200, which reads as "nobody read this". Same
-- treatment as migrations 868 / 869.
--
-- Notes for future editors (carried over from 868):
--  * Values are HARDCODED, not RAND(). Every partner instance must land on the same
--    number, and a re-run must be a no-op — RAND() breaks both.
--  * Guarded on `likes < 100`, so this never lowers a real reader count that has
--    accumulated since, and re-runs are no-ops once seeded.
--  * Keyed by url_key, not post_id — post_id is per-instance.
--  * mmd_blog_post_vote is left alone: it is the per-visitor dedupe ledger, and the
--    like endpoint increments `likes` independently of it, so a seeded baseline plus
--    real votes stacks correctly.

UPDATE `mmd_blog_post` SET `likes` = 143 WHERE `url_key` = 'uob-agentic-ai-claude-code-it-support-ticketing-app' AND `likes` < 100;
UPDATE `mmd_blog_post` SET `likes` = 178 WHERE `url_key` = 'business-innovation-with-agentic-ai-singapore-guide' AND `likes` < 100;
