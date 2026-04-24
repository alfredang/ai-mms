-- Add extra columns to courses_trainers so the "Add New Trainer" form
-- can persist Telephone, Trainer Type, Gender, and LinkedIn Profile URL.
--
-- Rewritten to NOT use DELIMITER / CREATE PROCEDURE — the PHP migration
-- runner splits SQL on ';' at end-of-line, which breaks stored-procedure
-- bodies (they contain internal semicolons). Each column add is now a
-- self-contained statement that uses INFORMATION_SCHEMA + PREPARE to stay
-- idempotent. Safe to re-run against a DB that already has the columns.

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'courses_trainers'
               AND COLUMN_NAME = 'telephone');
SET @sql := IF(@has = 0,
    'ALTER TABLE courses_trainers ADD COLUMN `telephone` VARCHAR(64) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'courses_trainers'
               AND COLUMN_NAME = 'trainer_type');
SET @sql := IF(@has = 0,
    "ALTER TABLE courses_trainers ADD COLUMN `trainer_type` VARCHAR(32) NOT NULL DEFAULT 'non-ACLP'",
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'courses_trainers'
               AND COLUMN_NAME = 'gender');
SET @sql := IF(@has = 0,
    'ALTER TABLE courses_trainers ADD COLUMN `gender` VARCHAR(16) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'courses_trainers'
               AND COLUMN_NAME = 'linkedin_url');
SET @sql := IF(@has = 0,
    'ALTER TABLE courses_trainers ADD COLUMN `linkedin_url` VARCHAR(255) NULL',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
