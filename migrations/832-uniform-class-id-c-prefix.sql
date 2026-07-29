-- 832 — Uniform course-run Class IDs: C000001… (no country prefix).
--
-- The old scheme prefixed class_id with the originating store's country code
-- (SG000042 / MY000017 / GH000001), and dashboard cards showed yet another
-- ALL-/SG- prefixed synthetic "Course Run ID" — confusing. New scheme
-- (2026-07): every site numbers its own runs C + 6 digits, starting C000001,
-- in run_id (creation) order. New runs continue the sequence via
-- MMD_RoleManager_Helper_Data::nextClassId() with the uniform 'C' prefix.
--
-- Also re-syncs the class_id snapshot columns in mmd_course_run_attendance
-- and mmd_course_run_certificate via run_id. Issued certificate numbers
-- (cert_no, e.g. "SG000042-001") are deliberately NOT rewritten — those are
-- printed on documents already in learners' hands.
--
-- Partner-safe: each site's DB renumbers only its own rows; every statement
-- is guarded via information_schema so an instance lacking a table skips
-- cleanly. Deterministic (ORDER BY run_id), so a re-run is a no-op.

SET @seq := 0;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='course_runs')>0,
  'UPDATE course_runs cr JOIN (SELECT run_id, @seq := @seq + 1 AS new_seq FROM course_runs ORDER BY run_id) m ON m.run_id = cr.run_id SET cr.class_id = CONCAT(''C'', LPAD(m.new_seq, 6, ''0''))',
  'DO 0');
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_course_run_attendance')>0
         AND (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='course_runs')>0,
  'UPDATE mmd_course_run_attendance a JOIN course_runs cr ON cr.run_id = a.run_id SET a.class_id = cr.class_id WHERE NOT (a.class_id <=> cr.class_id)',
  'DO 0');
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_course_run_certificate')>0
         AND (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='course_runs')>0,
  'UPDATE mmd_course_run_certificate c JOIN course_runs cr ON cr.run_id = c.run_id SET c.class_id = cr.class_id WHERE NOT (c.class_id <=> cr.class_id)',
  'DO 0');
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
