-- 1334: Extend the AI-draft review pipeline (migration 826, mmd_lead) to the
--       Corporate Training, Franchise Enquiry and Customised Training leads.
--       Every one of those enquiries now gets a Claude-drafted reply emailed
--       to the reviewers for approval, exactly like a General Enquiry lead.
--
--   draft_subject / draft_html / draft_status / draft_review_sent_at /
--   draft_feedback / draft_events  — same contract as mmd_lead (826)
--   replied_at / replied_by / replied_message — set by markReplied() when the
--   approved reply goes out, so the sent copy is kept on the row.
--
-- Idempotent (information_schema guard + PREPARE per column, 'DO 0' no-op),
-- partner-safe: no-op wherever a column already exists.

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_corporate_lead' AND COLUMN_NAME = 'draft_subject');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_corporate_lead ADD COLUMN draft_subject TEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_corporate_lead' AND COLUMN_NAME = 'draft_html');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_corporate_lead ADD COLUMN draft_html MEDIUMTEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_corporate_lead' AND COLUMN_NAME = 'draft_status');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_corporate_lead ADD COLUMN draft_status VARCHAR(20) NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_corporate_lead' AND COLUMN_NAME = 'draft_review_sent_at');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_corporate_lead ADD COLUMN draft_review_sent_at DATETIME NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_corporate_lead' AND COLUMN_NAME = 'draft_feedback');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_corporate_lead ADD COLUMN draft_feedback TEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_corporate_lead' AND COLUMN_NAME = 'draft_events');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_corporate_lead ADD COLUMN draft_events TEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_corporate_lead' AND COLUMN_NAME = 'replied_at');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_corporate_lead ADD COLUMN replied_at DATETIME NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_corporate_lead' AND COLUMN_NAME = 'replied_by');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_corporate_lead ADD COLUMN replied_by INT UNSIGNED NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_corporate_lead' AND COLUMN_NAME = 'replied_message');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_corporate_lead ADD COLUMN replied_message TEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_franchise_lead' AND COLUMN_NAME = 'draft_subject');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_franchise_lead ADD COLUMN draft_subject TEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_franchise_lead' AND COLUMN_NAME = 'draft_html');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_franchise_lead ADD COLUMN draft_html MEDIUMTEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_franchise_lead' AND COLUMN_NAME = 'draft_status');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_franchise_lead ADD COLUMN draft_status VARCHAR(20) NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_franchise_lead' AND COLUMN_NAME = 'draft_review_sent_at');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_franchise_lead ADD COLUMN draft_review_sent_at DATETIME NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_franchise_lead' AND COLUMN_NAME = 'draft_feedback');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_franchise_lead ADD COLUMN draft_feedback TEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_franchise_lead' AND COLUMN_NAME = 'draft_events');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_franchise_lead ADD COLUMN draft_events TEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_franchise_lead' AND COLUMN_NAME = 'replied_at');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_franchise_lead ADD COLUMN replied_at DATETIME NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_franchise_lead' AND COLUMN_NAME = 'replied_by');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_franchise_lead ADD COLUMN replied_by INT UNSIGNED NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_franchise_lead' AND COLUMN_NAME = 'replied_message');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_franchise_lead ADD COLUMN replied_message TEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_customised_lead' AND COLUMN_NAME = 'draft_subject');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_customised_lead ADD COLUMN draft_subject TEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_customised_lead' AND COLUMN_NAME = 'draft_html');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_customised_lead ADD COLUMN draft_html MEDIUMTEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_customised_lead' AND COLUMN_NAME = 'draft_status');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_customised_lead ADD COLUMN draft_status VARCHAR(20) NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_customised_lead' AND COLUMN_NAME = 'draft_review_sent_at');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_customised_lead ADD COLUMN draft_review_sent_at DATETIME NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_customised_lead' AND COLUMN_NAME = 'draft_feedback');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_customised_lead ADD COLUMN draft_feedback TEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_customised_lead' AND COLUMN_NAME = 'draft_events');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_customised_lead ADD COLUMN draft_events TEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_customised_lead' AND COLUMN_NAME = 'replied_at');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_customised_lead ADD COLUMN replied_at DATETIME NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_customised_lead' AND COLUMN_NAME = 'replied_by');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_customised_lead ADD COLUMN replied_by INT UNSIGNED NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_customised_lead' AND COLUMN_NAME = 'replied_message');
SET @s := IF(@c = 0, 'ALTER TABLE mmd_customised_lead ADD COLUMN replied_message TEXT NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
