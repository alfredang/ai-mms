-- 1161: Follow-up to 1160 - render the em-dashes in the AI-for-Network-Security post
--       excerpt as real characters instead of the HTML entity `&mdash;`.
--
-- Why: the excerpt is reused verbatim as PLAIN TEXT by
-- MMD_Blog_Model_Cron_Autoblog::_linkedinCommentary() (and the newsletter copy),
-- which does no entity decoding - so `&mdash;` would ship literally into the
-- LinkedIn post body. The storefront renders the entity fine, so this was
-- invisible on the blog page and only showed up in the share preview.
--
-- Scope: the `excerpt` column ONLY. `content` deliberately stays pure ASCII with
-- HTML entities (see 1160 and feedback_migration_applyphp_utf8_outage) because it
-- is only ever rendered as HTML.
--
-- The em-dash is written via CHAR(0xE2,0x80,0x94 USING utf8mb4) rather than as a
-- literal byte, so this file itself stays ASCII and cannot trip apply.php's
-- utf8 connection charset.
--
-- Idempotent: REPLACE() is a no-op once the entity is gone. SG-only guard.

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

UPDATE `mmd_blog_post` SET `excerpt` = REPLACE(`excerpt`, '&mdash;', CHAR(0xE2,0x80,0x94 USING utf8mb4)) WHERE @is_sg > 0 AND `url_key` = 'ai-for-network-security-singapore-guide' AND `excerpt` LIKE '%&mdash;%';
