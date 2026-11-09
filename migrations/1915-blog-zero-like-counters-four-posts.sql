-- 1915: User-requested display-count adjustment for the four specified SG blogs.
-- Only change zero counters. Preserve positive counts, article fields and votes.
-- Stable values in the inclusive range 100-200; repeat runs have no effect.
UPDATE `mmd_blog_post`
SET `likes` = 100 + MOD(CRC32(`url_key`), 101)
WHERE @mms_instance = 'SG'
  AND `likes` = 0
  AND `url_key` IN (
    'rise-ai-video-creation-higgsfield',
    'singtel-ai-pass-canva-pro-seven-ai-tools-singapore',
    'linux-configuration-shell-scripting-2026-guide',
    'ai-agent-cybersecurity-singapore-guide'
  );
