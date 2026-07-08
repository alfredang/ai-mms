-- 334: agentic-flyer blast capture.
-- (a) status gains 'scheduling' — an atomic claim state that closes the race where
--     two near-simultaneous manager approvals each passed the idempotency read and
--     double-booked MailerLite (real incident 2026-07-05: campaign 192159528492467427
--     duplicated 192159533836010589 for the same Thursday slot).
-- (b) sent_at + blast_stats columns — the MailerLite blast-capture sync (webhook +
--     cron poll) stamps when a campaign actually blasted and caches its stats JSON
--     (opens/clicks/bounces) for the admin dashboard.
-- Guarded: newsletters is SG-only; every statement no-ops on partner instances.
SET @has := (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'newsletters');
SET @sql := IF(@has = 1, 'ALTER TABLE newsletters MODIFY status ENUM(''draft'',''pushed'',''sent'',''scheduled'',''scheduling'') NOT NULL DEFAULT ''draft''', 'DO 0');
PREPARE _s FROM @sql; EXECUTE _s; DEALLOCATE PREPARE _s;
SET @hascol := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'newsletters' AND COLUMN_NAME = 'sent_at');
SET @sql := IF(@has = 1 AND @hascol = 0, 'ALTER TABLE newsletters ADD COLUMN sent_at DATETIME NULL DEFAULT NULL', 'DO 0');
PREPARE _s FROM @sql; EXECUTE _s; DEALLOCATE PREPARE _s;
SET @hascol := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'newsletters' AND COLUMN_NAME = 'blast_stats');
SET @sql := IF(@has = 1 AND @hascol = 0, 'ALTER TABLE newsletters ADD COLUMN blast_stats TEXT NULL', 'DO 0');
PREPARE _s FROM @sql; EXECUTE _s; DEALLOCATE PREPARE _s;
