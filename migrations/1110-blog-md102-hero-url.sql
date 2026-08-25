-- Bake the R2 hero URL for the MD-102 blog post (1109) into the DB, so a rebuilt
-- or restored DB keeps the rendered hero instead of falling back to the CSS
-- gradient card. Rendered on SG prod 2026-08-25 via MMD_Blog_Model_Hero
-- (funding/badge theme, kicker "Microsoft Certification"); safe-band verified.
-- Guarded to only fill an empty or pipeline (blog/auto-*) value — an
-- admin-uploaded hero is never clobbered.
SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

UPDATE `mmd_blog_post`
SET `hero_image_url` = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/auto-20260825-034629-microsoft-endpoint-administrator-md-102-certification-in-s.png'
WHERE @is_sg > 0
  AND `url_key` = 'microsoft-endpoint-administrator-md-102-certification-singapore'
  AND (`hero_image_url` IS NULL OR `hero_image_url` = '' OR `hero_image_url` LIKE '%/blog/auto-%');
