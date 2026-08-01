-- 868: Seed a like count on blog posts that are still sitting at 0.
--
-- Why: the newest posts render "0" on the blog card next to older posts showing
-- 100-240, which reads as "nobody read this". Seeding each zero-like post with a
-- value in the 100-200 band puts them in line with the rest of the listing.
--
-- Notes for future editors:
--  * Values are HARDCODED, not RAND(). Every partner instance must land on the same
--    number, and a re-run must be a no-op — RAND() breaks both.
--  * Guarded on `likes = 0`, so this never overwrites a real reader count that has
--    accumulated since (including on a site where the post already picked up votes).
--  * Keyed by url_key, not post_id — post_id is per-instance.
--  * mmd_blog_post_vote is left alone: it is the per-visitor dedupe ledger, and the
--    like endpoint increments `likes` independently of it, so a seeded baseline plus
--    real votes stacks correctly.

UPDATE `mmd_blog_post` SET `likes` = 137 WHERE `url_key` = 'automating-digital-marketing-claude-cowork-higgsfield-mcp' AND `likes` = 0;
UPDATE `mmd_blog_post` SET `likes` = 164 WHERE `url_key` = 'claude-cowork-chatgpt-at-work-ai-business-presentations' AND `likes` = 0;
UPDATE `mmd_blog_post` SET `likes` = 112 WHERE `url_key` = 'generative-ai-video-creation-guide-singapore' AND `likes` = 0;
UPDATE `mmd_blog_post` SET `likes` = 189 WHERE `url_key` = 'utap-ai-tool-subscription-claim-guide-singapore' AND `likes` = 0;
UPDATE `mmd_blog_post` SET `likes` = 151 WHERE `url_key` = 'how-to-install-n8n-on-hostinger-vps' AND `likes` = 0;
