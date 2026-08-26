-- Bake the R2 hero URL for the AI-102 blog post (1116) into the DB, so a rebuilt
-- or restored DB keeps the rendered hero instead of falling back to the CSS
-- gradient card. Rendered on SG prod 2026-08-26 via MMD_Blog_Model_Hero
-- (funding theme / badge motif, kicker "Microsoft Certification"); safe-band
-- verified by pixel scan (white text spans y=328..602, inside the 225..675 band,
-- so the 32:9 post-page banner does not clip it).
-- Guarded to only fill an empty or pipeline (blog/auto-*) value -- an
-- admin-uploaded hero is never clobbered.
SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

UPDATE `mmd_blog_post`
SET `hero_image_url` = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/auto-20260826-082732-microsoft-certified-azure-ai-engineer-associate-ai-102-in.png'
WHERE @is_sg > 0
  AND `url_key` = 'azure-ai-engineer-associate-ai-102-certification-singapore'
  AND (`hero_image_url` IS NULL OR `hero_image_url` = '' OR `hero_image_url` LIKE '%/blog/auto-%');
