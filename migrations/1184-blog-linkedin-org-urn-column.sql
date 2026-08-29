-- 1184: Add `linkedin_org_urn` to mmd_blog_post — dedup marker for the blog's
-- LinkedIn COMPANY-PAGE share (the org twin of `linkedin_urn`, which tracks the
-- member-feed share). Written by Autoblog::shareEverywhere() when the post has
-- been published to the Tertiary Courses Singapore LinkedIn page.
--
-- Idempotent + partner-safe: guarded on information_schema for both the table
-- existing and the column not existing, so a re-run or a site without the blog
-- table is a silent no-op ('DO 0') rather than an error that would abort
-- apply.php's whole chain.

SET @ddl := (
    SELECT IF(
        (SELECT COUNT(*) FROM `information_schema`.`TABLES`
          WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'mmd_blog_post') = 1
        AND
        (SELECT COUNT(*) FROM `information_schema`.`COLUMNS`
          WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'mmd_blog_post'
            AND `COLUMN_NAME` = 'linkedin_org_urn') = 0,
        'ALTER TABLE `mmd_blog_post` ADD COLUMN `linkedin_org_urn` VARCHAR(128) NULL DEFAULT NULL AFTER `linkedin_urn`',
        'DO 0'
    )
);
PREPARE s FROM @ddl;
EXECUTE s;
DEALLOCATE PREPARE s;
