-- 1556: User approved immediate website publication of the 26 September Codex class post.
-- Publish the exact SG article and suppress automatic LinkedIn/Facebook sharing.
-- Keep the approval history and all article content untouched.
SET @is_sg := IF(@mms_instance = 'SG', 1, 0);
UPDATE `mmd_blog_post` SET `linkedin_urn` = 'manual-skip', `facebook_post_id` = 'manual-skip', `status` = 1, `published_at` = '2026-09-26', `scheduled_publish_at` = NULL, `updated_at` = NOW() WHERE @is_sg = 1 AND `url_key` = 'agentic-ai-codex-bakery-academy-class-september-2026' AND `status` IN (0, 2, 3, 4);
