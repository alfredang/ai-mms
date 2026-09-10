--
-- 1378: Replace the AI Vibe Coding workflow post's plain-gradient fallback
-- with a designed editorial hero.
--
-- The 1600x900 PNG was rendered through MMD_Blog_Model_Hero with the
-- "AI Coding" kicker, visually checked at full 16:9 and within the post-page
-- 32:9 centre crop, uploaded to R2, and verified HTTP 200 image/png.
--
-- This post was created through the production admin and is absent from some
-- partner/local databases, so the guarded UPDATE is intentionally a safe no-op
-- there. An admin-uploaded non-auto hero remains authoritative.

UPDATE `mmd_blog_post`
SET `hero_image_url` = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/auto-20260910-185345-from-prompt-to-production-the-3-phase-ai-vibe-coding-workfl.png',
    `updated_at` = NOW()
WHERE `url_key` = 'three-phase-ai-vibe-coding-full-stack-workflow'
  AND (`hero_image_url` IS NULL OR `hero_image_url` = '' OR `hero_image_url` LIKE '%/blog/auto-%');
