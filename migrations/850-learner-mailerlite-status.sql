-- 850: mmd_learner_mailerlite.status — records WHY an email is or isn't in
-- the MailerLite group, driving the Manage Learners MailerLite column:
--   submitted    - pushed to the subscriber group (read-only checked box)
--   excluded     - learner's store has no MailerLite group
--   unsubscribed - MailerLite knows the email as unsubscribed (never re-add)
--   blocked      - MailerLite knows the email as bounced / junk
-- 849 created the table without this column and is already ledgered on SG,
-- so the column ships as its own migration. Guarded via information_schema
-- (MySQL 5.7 has no ADD COLUMN IF NOT EXISTS) — idempotent, partner-safe:
-- on installs where the edited 849 already created the column this is a no-op.
SET @has_status := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_learner_mailerlite' AND COLUMN_NAME = 'status');
SET @ddl := IF(@has_status = 0, 'ALTER TABLE `mmd_learner_mailerlite` ADD COLUMN `status` VARCHAR(16) NOT NULL DEFAULT ''submitted'' AFTER `store_code`', 'DO 0');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
