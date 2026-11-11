-- 1925: Owner-requested thumbs-up display baselines for the three zero-like SG posts.
-- Snapshot verified 12 Nov 2026. Preserve positive counters, article fields and votes.
-- Stable values in 100-200 inclusive; SG-only and idempotent.
UPDATE `mmd_blog_post`
SET `likes` = 100 + MOD(CRC32(`url_key`), 101)
WHERE @mms_instance = 'SG'
  AND EXISTS (SELECT 1 FROM `core_store` WHERE `store_id` = 1 AND `code` = 'singapore')
  AND `status` = 1
  AND `likes` = 0
  AND `url_key` IN (
    'claude-ai-architecture-course-singapore',
    'ai-security-autonomous-ai-agents-five-principles',
    'agentic-ai-video-creation-claude-code-higgsfield'
  );
