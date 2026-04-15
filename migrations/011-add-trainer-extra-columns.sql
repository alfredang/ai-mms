-- Add extra columns to courses_trainers so the "Add New Trainer" form
-- can persist Telephone, Trainer Type, Gender, and LinkedIn Profile URL.
-- Idempotent — uses INFORMATION_SCHEMA + dynamic SQL so re-running is safe.

DROP PROCEDURE IF EXISTS _add_trainer_col;

DELIMITER //
CREATE PROCEDURE _add_trainer_col(IN col_name VARCHAR(64), IN col_def VARCHAR(255))
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'courses_trainers'
          AND COLUMN_NAME = col_name
    ) THEN
        SET @sql = CONCAT('ALTER TABLE courses_trainers ADD COLUMN `', col_name, '` ', col_def);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END //
DELIMITER ;

CALL _add_trainer_col('telephone',    'VARCHAR(64) NULL');
CALL _add_trainer_col('trainer_type', "VARCHAR(32) NOT NULL DEFAULT 'non-ACLP'");
CALL _add_trainer_col('gender',       'VARCHAR(16) NULL');
CALL _add_trainer_col('linkedin_url', 'VARCHAR(255) NULL');

DROP PROCEDURE _add_trainer_col;
