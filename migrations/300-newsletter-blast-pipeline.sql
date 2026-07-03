-- 300: Newsletter blast pipeline foundation (SG-only, human-in-the-loop, rate-limited).
-- Additive + country-safe (guarded ALTERs, CREATE IF NOT EXISTS, DO 0 no-ops so a
-- missing table/column on any instance never aborts apply.php — see memory
-- feedback_migration_country_instance_table_differences).
--
-- Adds:
--   1. Config flag mmd_marketing/newsletter/blast_enabled — default 0 (disabled
--      everywhere); set 1 only on the SG instance (base_url contains
--      tertiarycourses.com.sg). Admin toggle overrides this later.
--   2. Review-workflow columns on `newsletters` (approval state machine).
--   3. mmd_marketing_blast_log — one row per successful MailerLite blast, drives
--      the "max 2 per calendar week" cap.

-- ---- 1. enable flag: default OFF, then ON for SG only -------------------------
INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'mmd_marketing/newsletter/blast_enabled', '0')
ON DUPLICATE KEY UPDATE value = value;   -- keep an existing admin choice untouched

SET @is_sg := (SELECT COUNT(*) FROM core_config_data
  WHERE path IN ('web/unsecure/base_url','web/secure/base_url')
    AND value LIKE '%tertiarycourses.com.sg%');
SET @sql := IF(@is_sg > 0,
  'UPDATE core_config_data SET value = ''1'' WHERE path = ''mmd_marketing/newsletter/blast_enabled'' AND scope = ''default''',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---- 2. review-workflow columns on `newsletters` (guarded) --------------------
SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'newsletters' AND column_name = 'review_status');
SET @sql := IF(@c = 0, 'ALTER TABLE newsletters ADD COLUMN review_status VARCHAR(24) NOT NULL DEFAULT ''none''', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'newsletters' AND column_name = 'review_token');
SET @sql := IF(@c = 0, 'ALTER TABLE newsletters ADD COLUMN review_token VARCHAR(64) NULL', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'newsletters' AND column_name = 'review_decisions');
SET @sql := IF(@c = 0, 'ALTER TABLE newsletters ADD COLUMN review_decisions TEXT NULL', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'newsletters' AND column_name = 'review_feedback');
SET @sql := IF(@c = 0, 'ALTER TABLE newsletters ADD COLUMN review_feedback TEXT NULL', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'newsletters' AND column_name = 'ai_iterations');
SET @sql := IF(@c = 0, 'ALTER TABLE newsletters ADD COLUMN ai_iterations INT UNSIGNED NOT NULL DEFAULT 0', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---- 3. blast log for the weekly cap ----------------------------------------
CREATE TABLE IF NOT EXISTS mmd_marketing_blast_log (
  log_id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  newsletter_id INT UNSIGNED NULL,
  country_code  CHAR(2) NULL,
  mailerlite_id VARCHAR(64) NULL,
  blasted_at    DATETIME NOT NULL,
  blasted_by    INT UNSIGNED NULL,
  PRIMARY KEY (log_id),
  KEY idx_blasted_at (blasted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
