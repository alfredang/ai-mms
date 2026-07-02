-- 296: DB performance quick wins (from mysql-memory-optimizer audit 2026-07-02)
-- 1) SMTPPro email log: enable 15-day auto-cleaning + one-time 30-day prune
--    (table was 183MB / 15% of DB with cleaning disabled).
-- 2) cms_block.identifier index: per-course section blocks (course_<sku>_<section>)
--    are looked up by identifier on every course page render — was a full scan.
-- 3) Drop duplicate/redundant indexes on course_runs / course_run_enrolments
--    (idx_product_date_time duplicates uk_product_date_time; idx_product is a
--    left-prefix of existing composite indexes). Pure write amplification.
-- All statements are idempotent / guarded for re-runs.

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'smtppro/debug/cleanlog', '1')
ON DUPLICATE KEY UPDATE value = '1';

DELETE FROM smtppro_email_log WHERE log_at < DATE_SUB(NOW(), INTERVAL 30 DAY);

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'cms_block' AND index_name = 'IDX_CMS_BLOCK_IDENTIFIER');
SET @sql := IF(@idx = 0, 'ALTER TABLE cms_block ADD INDEX IDX_CMS_BLOCK_IDENTIFIER (identifier)', 'SELECT 1');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'course_runs' AND index_name = 'idx_product_date_time');
SET @sql := IF(@idx > 0, 'ALTER TABLE course_runs DROP INDEX idx_product_date_time', 'SELECT 1');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'course_runs' AND index_name = 'idx_product');
SET @sql := IF(@idx > 0, 'ALTER TABLE course_runs DROP INDEX idx_product', 'SELECT 1');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'course_run_enrolments' AND index_name = 'idx_product');
SET @sql := IF(@idx > 0, 'ALTER TABLE course_run_enrolments DROP INDEX idx_product', 'SELECT 1');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;
