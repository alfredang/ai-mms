-- 302: Newsletter pipeline — schedule column, auto flag, and subscriber snapshots.
-- Additive + country-safe (guarded ALTERs, CREATE IF NOT EXISTS, DO 0 no-ops so a
-- missing table/column on any instance never aborts apply.php — see memory
-- feedback_migration_country_instance_table_differences).
--
-- Adds:
--   1. newsletters.scheduled_send_at — the Mon/Thu 08:00 slot a proposal was booked
--      into (written by Cron_Flyer::scheduleApproved). Migration 300 shipped the
--      review columns but not this one; without it a real both-approve fatals.
--   2. newsletters.is_auto — 1 for cron-proposed flyers, 0 for hand-built drafts.
--      Drives the "max 2 DESIGNS per week" cap (Blastguard::designsThisWeek).
--   3. mmd_marketing_subscriber_snapshot — one row/day/group of the MailerLite active
--      count, so the dashboard can chart subscriber GROWTH (the API returns only the
--      current count, never history).

-- ---- 1. newsletters.scheduled_send_at (guarded) ------------------------------
SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'newsletters' AND column_name = 'scheduled_send_at');
SET @sql := IF(@c = 0, 'ALTER TABLE newsletters ADD COLUMN scheduled_send_at DATETIME NULL', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---- 2. newsletters.is_auto (guarded) ----------------------------------------
SET @c := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'newsletters' AND column_name = 'is_auto');
SET @sql := IF(@c = 0, 'ALTER TABLE newsletters ADD COLUMN is_auto TINYINT(1) NOT NULL DEFAULT 0', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---- 3. subscriber snapshots for the growth chart ----------------------------
CREATE TABLE IF NOT EXISTS mmd_marketing_subscriber_snapshot (
  snap_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  snap_date    DATE NOT NULL,
  group_id     VARCHAR(64) NOT NULL,
  active_count INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (snap_id),
  UNIQUE KEY uniq_day_group (snap_date, group_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
