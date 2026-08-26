-- 1118: Bake the R2 hero URL for the AZ-900 blog post (1117) into the DB, so a rebuilt
-- or restored DB keeps the rendered hero instead of falling back to the CSS gradient
-- card. Rendered 2026-08-26 via MMD_Blog_Model_Hero (funding theme -> sky palette +
-- rosette motif, kicker "Microsoft Certification"); 1600x900, safe-band verified
-- (ink spans y=328..602, inside the 225..675 band the 32:9 post banner shows).
-- Guarded to only fill an empty or pipeline (blog/auto-*) value — an admin-uploaded
-- hero is never clobbered.
SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

UPDATE `mmd_blog_post`
SET `hero_image_url` = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/auto-20260826-051555-wsq-microsoft-azure-fundamentals-az-900-in-singapore-exam.png'
WHERE @is_sg > 0
  AND `url_key` = 'wsq-microsoft-azure-fundamentals-az-900-singapore-guide'
  AND (`hero_image_url` IS NULL OR `hero_image_url` = '' OR `hero_image_url` LIKE '%/blog/auto-%');
