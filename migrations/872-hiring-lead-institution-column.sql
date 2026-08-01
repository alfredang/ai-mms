-- 872: Add `institution` to mmd_hiring_lead so the job/internship application
-- form can capture which school the applicant is from (ITE colleges, the five
-- polytechnics, the local universities, or Other Institution).
--
-- Idempotent: the ADD COLUMN is guarded on information_schema so a re-run (or a
-- partner site that already has the column) is a silent no-op rather than a
-- 1060 duplicate-column error that would abort apply.php's whole chain.

SET @ddl := (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE `mmd_hiring_lead` ADD COLUMN `institution` VARCHAR(128) NULL DEFAULT NULL AFTER `nationality`',
        'DO 0'
    )
    FROM `information_schema`.`COLUMNS`
    WHERE `TABLE_SCHEMA` = DATABASE()
      AND `TABLE_NAME`   = 'mmd_hiring_lead'
      AND `COLUMN_NAME`  = 'institution'
);
PREPARE s FROM @ddl;
EXECUTE s;
DEALLOCATE PREPARE s;
