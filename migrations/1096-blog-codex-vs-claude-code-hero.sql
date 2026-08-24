-- 1096: Set the hero image for the "Codex vs Claude Code" blog post.
--
-- Why this file exists: migration 1093 created the post but left
-- hero_image_url NULL, so the card rendered the CSS gradient fallback
-- (.mmd-blog-hero-fallback) — a flat blue/purple block with typeset text and
-- no artwork, which next to the rendered heroes reads as a missing image.
--
-- The PNG was rendered by MMD_Blog_Model_Hero and is already uploaded to the
-- shared R2 bucket, so this migration only writes the URL.
--
-- Related code change (same commit): Hero.php gained a `coding_agent` theme
-- ABOVE `automation`, because "…AI Coding Agent…" matched automation's `agent`
-- keyword first and drew the green n8n-style node graph on what is a
-- coding-tools comparison. Named tools (codex / claude code / cursor /
-- copilot) now render the cyan terminal motif.
--
-- Idempotent: only fills a NULL/empty hero or replaces a pipeline-generated
-- `blog/auto-*` one, so an admin-uploaded hero is never clobbered.
-- SG-only guard via @mms_instance.

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

UPDATE `mmd_blog_post`
   SET `hero_image_url` = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/auto-20260824-054829-codex-vs-claude-code-which-ai-coding-agent-should-you-actua.png',
       `updated_at` = NOW()
 WHERE @is_sg > 0
   AND `url_key` = 'codex-vs-claude-code-which-ai-coding-agent'
   AND (`hero_image_url` IS NULL OR `hero_image_url` = '' OR `hero_image_url` LIKE '%/blog/auto-%');
