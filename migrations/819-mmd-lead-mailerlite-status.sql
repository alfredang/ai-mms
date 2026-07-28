-- Track whether each contact-form lead's email was pushed to the site's
-- MailerLite subscriber group (Dashboard -> Company Setting -> Integrations
-- -> MailerLite). Values: NULL = never attempted (legacy rows), 'sent',
-- 'skipped' (not configured / suppressed opt-out), 'failed'.
--
-- Idempotent (information_schema guard + prepared statement), so it is a
-- no-op on any partner DB that already has the column.

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_lead' AND COLUMN_NAME = 'mailerlite_status');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_lead ADD COLUMN mailerlite_status VARCHAR(20) NULL DEFAULT NULL AFTER auto_reply_status', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;
