-- Drop course_courseware.skillsfuture_link.
--
-- The column was a per-course external link to the SkillsFuture
-- Singapore (SSG) listing for that course. The product is going
-- worldwide and SSG is no longer in scope, so the column is removed
-- alongside the courseware UI / labels that referenced it.
--
-- Idempotent: only fires if the column still exists.

SET @col_exists := (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'course_courseware'
      AND COLUMN_NAME  = 'skillsfuture_link'
);

SET @ddl := IF(@col_exists > 0,
    'ALTER TABLE `course_courseware` DROP COLUMN `skillsfuture_link`',
    'DO 0'
);

PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
