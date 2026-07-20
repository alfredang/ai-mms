-- 450: Blog review pipeline — manager approval + Mon/Thu publish scheduling
-- + Facebook share tracking (mirrors the newsletter blast pipeline, migration 300).
--
-- Adds to mmd_blog_post (all guarded so re-runs / diverged partner schemas never
-- abort apply.php):
--   * scheduled_publish_at — the Mon/Thu 09:00 slot an approved post publishes at
--   * review_decisions    — JSON: per-reviewer decision + _sent_at/_reminder_sent_at markers
--   * review_feedback     — the manager's "request changes" text
--   * facebook_post_id    — Facebook page post id (once-only share dedupe)
--
-- Config: turns OFF mmd_blog/autoblog/auto_publish on the SG instance only
-- (base_url contains tertiarycourses.com.sg) so cron posts go through manager
-- review + Mon/Thu scheduling. Partner instances (MY/GH) keep auto_publish=1
-- (their existing immediate-publish behaviour) and are otherwise untouched.

-- ---- 1. review/scheduling columns on mmd_blog_post (guarded) ------------------
SET @has_tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'mmd_blog_post');

SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'mmd_blog_post' AND column_name = 'scheduled_publish_at');
SET @sql := IF(@has_tbl = 1 AND @c = 0, 'ALTER TABLE mmd_blog_post ADD COLUMN scheduled_publish_at DATETIME NULL AFTER published_at', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'mmd_blog_post' AND column_name = 'review_decisions');
SET @sql := IF(@has_tbl = 1 AND @c = 0, 'ALTER TABLE mmd_blog_post ADD COLUMN review_decisions TEXT NULL AFTER linkedin_urn', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'mmd_blog_post' AND column_name = 'review_feedback');
SET @sql := IF(@has_tbl = 1 AND @c = 0, 'ALTER TABLE mmd_blog_post ADD COLUMN review_feedback TEXT NULL AFTER review_decisions', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'mmd_blog_post' AND column_name = 'facebook_post_id');
SET @sql := IF(@has_tbl = 1 AND @c = 0, 'ALTER TABLE mmd_blog_post ADD COLUMN facebook_post_id VARCHAR(128) NULL AFTER linkedin_urn', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---- 2. SG only: cron posts require manager review (auto_publish off) ---------
INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'mmd_blog/autoblog/auto_publish', '1')
ON DUPLICATE KEY UPDATE value = value;   -- keep an existing admin choice untouched

SET @is_sg := (SELECT COUNT(*) FROM core_config_data
  WHERE path IN ('web/unsecure/base_url','web/secure/base_url')
    AND value LIKE '%tertiarycourses.com.sg%');
SET @sql := IF(@is_sg > 0,
  'UPDATE core_config_data SET value = ''0'' WHERE path = ''mmd_blog/autoblog/auto_publish'' AND scope = ''default''',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
