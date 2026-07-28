-- Lead AI-draft review pipeline (mirrors the blog review flow):
-- the cron drafts a personalised reply with Claude, emails the admin
-- approve / request-changes HMAC links, and an approval auto-sends the
-- reply to the lead.
--
--   draft_subject         subject_course of the pending AI draft
--   draft_html            body_html of the pending AI draft
--   draft_status          NULL = no draft yet, 'pending_review',
--                         'changes_requested', 'approved_sent'
--   draft_review_sent_at  when the approval email went to the admin
--   draft_feedback        reviewer's request-changes notes (latest)
--   draft_events          JSON timeline log [{t, ev, detail}] rendered by
--                         the Lead view pipeline visual
--
-- Idempotent (information_schema guard + prepared statement per column),
-- partner-safe: no-op wherever the column already exists.

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_lead' AND COLUMN_NAME = 'draft_subject');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_lead ADD COLUMN draft_subject TEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_lead' AND COLUMN_NAME = 'draft_html');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_lead ADD COLUMN draft_html MEDIUMTEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_lead' AND COLUMN_NAME = 'draft_status');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_lead ADD COLUMN draft_status VARCHAR(20) NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_lead' AND COLUMN_NAME = 'draft_review_sent_at');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_lead ADD COLUMN draft_review_sent_at DATETIME NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_lead' AND COLUMN_NAME = 'draft_feedback');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_lead ADD COLUMN draft_feedback TEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_lead' AND COLUMN_NAME = 'draft_events');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_lead ADD COLUMN draft_events TEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;
