-- Remove the inline class photo from the IT support case study.
-- Keep the editorial hero_image_url for blog cards and social previews.
-- The article has one figure, containing the class photo, so guard on the
-- neutral image key and exactly one figure before removing that HTML block.
SET @is_sg := IF(@mms_instance = 'SG', 1, 0);
UPDATE `mmd_blog_post` SET `content` = CONCAT(SUBSTRING(`content`, 1, LOCATE('<figure>', `content`) - 1), SUBSTRING(`content`, LOCATE('</figure>', `content`) + 9)), `updated_at` = NOW() WHERE `url_key` = 'financial-company-agentic-ai-claude-code-it-support-ticketing-app' AND @is_sg = 1 AND `content` LIKE '%financial-company-support-class-20260901.jpg%' AND LENGTH(`content`) - LENGTH(REPLACE(`content`, '<figure>', '')) = 8 AND LENGTH(`content`) - LENGTH(REPLACE(`content`, '</figure>', '')) = 9;
