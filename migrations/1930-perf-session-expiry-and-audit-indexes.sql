-- 1930: admin speed-up indexes (already applied live on SG 2026-11-14; this keeps a
-- rebuilt DB and the partner sites in step). Idempotent; no-op branch is 'DO 0'.
--
-- 1. core_session(session_expires): the session gc runs
--    DELETE FROM core_session WHERE session_expires < ? on every session close.
--    Without an index it scanned (and row-locked) the whole table: SG avg 2.7 s,
--    max 66 s on 342 MB, queueing every other session write behind it.
-- 2. mmd_audit_issues(status, severity, title) + (status, severity, found_at): the
--    admin header audit bell (page/header.phtml) counts distinct open titles per
--    severity; on SG's 1.4M rows that was ~19 s whenever its cache was cold.
--    Only added where the table's row format allows the long key (Dynamic/Compressed).

SET @has := (SELECT COUNT(*) FROM information_schema.statistics
              WHERE table_schema = DATABASE() AND table_name = 'core_session'
                AND index_name = 'IDX_CORE_SESSION_EXPIRES');
SET @sql := IF(@has = 0,
    'ALTER TABLE core_session ADD INDEX IDX_CORE_SESSION_EXPIRES (session_expires)',
    'DO 0');
PREPARE mms_stmt FROM @sql;
EXECUTE mms_stmt;
DEALLOCATE PREPARE mms_stmt;

SET @ok := (SELECT COUNT(*) FROM information_schema.tables
             WHERE table_schema = DATABASE() AND table_name = 'mmd_audit_issues'
               AND row_format IN ('Dynamic', 'Compressed'));

SET @has := (SELECT COUNT(*) FROM information_schema.statistics
              WHERE table_schema = DATABASE() AND table_name = 'mmd_audit_issues'
                AND index_name = 'idx_status_sev_title');
SET @sql := IF(@ok = 1 AND @has = 0,
    'ALTER TABLE mmd_audit_issues ADD INDEX idx_status_sev_title (status, severity, title)',
    'DO 0');
PREPARE mms_stmt FROM @sql;
EXECUTE mms_stmt;
DEALLOCATE PREPARE mms_stmt;

SET @has := (SELECT COUNT(*) FROM information_schema.statistics
              WHERE table_schema = DATABASE() AND table_name = 'mmd_audit_issues'
                AND index_name = 'idx_status_sev_found');
SET @sql := IF(@ok = 1 AND @has = 0,
    'ALTER TABLE mmd_audit_issues ADD INDEX idx_status_sev_found (status, severity, found_at)',
    'DO 0');
PREPARE mms_stmt FROM @sql;
EXECUTE mms_stmt;
DEALLOCATE PREPARE mms_stmt;
