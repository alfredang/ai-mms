-- 1134: Bake the R2 hero URL for the SWDA-vs-UTAP AI tools subscription blog post (1119)
-- into the DB, so a rebuilt or restored DB keeps the rendered hero instead of falling
-- back to the CSS gradient card. Rendered 2026-08-26 on SG prod via MMD_Blog_Model_Hero
-- (funding theme, kicker "AI Tool Funding"); 1600x900, safe-band verified (ink spans
-- y=335..595, inside the 225..675 band the 32:9 post banner shows).
-- Numbered 1134 (not 1120) to avoid colliding with a concurrent Microsoft-cert blog
-- series holding 1119-1133; duplicate numbers are ledger-safe (filename-keyed) but
-- confusing. Guarded to only fill an empty or pipeline (blog/auto-*) value -- an
-- admin-uploaded hero is never clobbered.
SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

UPDATE `mmd_blog_post`
SET `hero_image_url` = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/auto-20260826-152525-free-swda-ai-tools-subscription-vs-utap-ai-tools-subscriptio.png'
WHERE @is_sg > 0
  AND `url_key` = 'swda-utap-ai-tools-subscription-maximise-both'
  AND (`hero_image_url` IS NULL OR `hero_image_url` = '' OR `hero_image_url` LIKE '%/blog/auto-%');
