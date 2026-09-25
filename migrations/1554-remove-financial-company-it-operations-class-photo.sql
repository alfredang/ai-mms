-- Remove the inline class photo from the IT operations trigger-model article.
-- Preserve the editorial hero used by the blog card and social preview.
SET @is_sg := IF(@mms_instance = 'SG', 1, 0);
UPDATE `mmd_blog_post` SET `content` = CONCAT(SUBSTRING(`content`, 1, LOCATE('<figure>', `content`) - 1), SUBSTRING(`content`, LOCATE('</figure>', `content`) + 9)), `updated_at` = NOW() WHERE `url_key` = 'financial-company-agentic-ai-claude-code-trigger-model-it-operations' AND @is_sg = 1 AND `content` LIKE '%financial-company-operations-class-20260916.jpg%' AND LENGTH(`content`) - LENGTH(REPLACE(`content`, '<figure>', '')) = 8 AND LENGTH(`content`) - LENGTH(REPLACE(`content`, '</figure>', '')) = 9;
