-- Rename tpg_run_id_map.ssg_run_id → tpg_run_id_map.run_id.
--
-- The column is the primary key of the TPG run-id mapping table and
-- holds the issued run ID for each course run. It was originally named
-- ssg_run_id when the project assumed a tight SkillsFuture Singapore
-- (SSG) integration; that integration is no longer planned, so we drop
-- the SSG-specific naming and keep the column under a generic name.
--
-- Idempotent: only fires the ALTER if the old column still exists, so
-- re-running this migration on a DB that already has run_id is a no-op.
--
-- All call sites (controllers, dashboard templates, future migrations)
-- are updated in the same commit to reference run_id.

SET @col_exists := (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'tpg_run_id_map'
      AND COLUMN_NAME  = 'ssg_run_id'
);

SET @ddl := IF(@col_exists > 0,
    'ALTER TABLE `tpg_run_id_map` CHANGE COLUMN `ssg_run_id` `run_id` INT UNSIGNED NOT NULL',
    'DO 0'
);

PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
