--
-- 1377: Replace two plain-gradient blog fallbacks with designed editorial heroes.
--
-- Both 1600x900 PNGs were rendered through MMD_Blog_Model_Hero, visually
-- checked at full 16:9 and within the post-page 32:9 centre crop, uploaded to
-- the existing R2 blog/auto-* namespace, and verified HTTP 200 image/png.
--
-- Only empty or auto-generated heroes are replaceable. An admin-uploaded hero
-- (a blog URL without the auto-* marker) remains authoritative.

UPDATE `mmd_blog_post`
SET `hero_image_url` = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/auto-20260910-175820-uob-engineers-apply-microsoft-365-copilot-to-fmea-dmaic-and.png',
    `updated_at` = NOW()
WHERE `url_key` = 'uob-engineers-microsoft-365-copilot-fmea-dmaic-spc'
  AND (`hero_image_url` IS NULL OR `hero_image_url` = '' OR `hero_image_url` LIKE '%/blog/auto-%');

UPDATE `mmd_blog_post`
SET `hero_image_url` = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/blog/auto-20260910-175820-the-six-skills-behind-production-ready-ai-applications.png',
    `updated_at` = NOW()
WHERE `url_key` = 'six-skills-production-ready-ai-applications'
  AND (`hero_image_url` IS NULL OR `hero_image_url` = '' OR `hero_image_url` LIKE '%/blog/auto-%');
