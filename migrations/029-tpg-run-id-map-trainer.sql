-- Extend tpg_run_id_map with the SSG-issued trainer override fields.
-- The local product's trainers multiselect / trainerprofile may diverge
-- from what SSG actually has on file for a given Course Run; this lets
-- us cache the SSG-truth so View Course Run shows the right trainer.

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='tpg_run_id_map' AND COLUMN_NAME='trainer_name');
SET @sql := IF(@has=0,
    'ALTER TABLE tpg_run_id_map ADD COLUMN `trainer_name` VARCHAR(160) NOT NULL DEFAULT ""',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='tpg_run_id_map' AND COLUMN_NAME='trainer_id_masked');
SET @sql := IF(@has=0,
    'ALTER TABLE tpg_run_id_map ADD COLUMN `trainer_id_masked` VARCHAR(32) NOT NULL DEFAULT ""',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='tpg_run_id_map' AND COLUMN_NAME='trainer_email');
SET @sql := IF(@has=0,
    'ALTER TABLE tpg_run_id_map ADD COLUMN `trainer_email` VARCHAR(160) NOT NULL DEFAULT ""',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Seed: 1089835 is SSG-assigned to Mohan Pothula Rao per the AI-LMS-TMS reference.
UPDATE tpg_run_id_map
SET trainer_name      = 'Mohan Pothula Rao',
    trainer_id_masked = '*****731H',
    trainer_email     = 'mohanpothula@gmail.com'
WHERE ssg_run_id = 1089835;
