-- Runs after 9999-nonfunded-tms-handover.sql. Separate immutable first-handover
-- metadata prevents later sessions of an ongoing TMS run being adopted midway.
SET @mmd_access_col = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='mmd_tms_run_link' AND column_name='handover_at');
SET @mmd_access_sql = IF(@mmd_access_col=0,'ALTER TABLE mmd_tms_run_link ADD COLUMN handover_at DATETIME NULL, ADD COLUMN approved_at DATETIME NULL, ADD COLUMN approved_first_session_at DATETIME NULL','DO 0');
PREPARE mmd_access_stmt FROM @mmd_access_sql;
EXECUTE mmd_access_stmt;
DEALLOCATE PREPARE mmd_access_stmt;
INSERT IGNORE INTO core_config_data (scope,scope_id,path,value) VALUES ('default',0,'mmd/tms_handover/public_origin',''),('default',0,'mmd/tms_handover/pilot_start_date','2026-10-23');
