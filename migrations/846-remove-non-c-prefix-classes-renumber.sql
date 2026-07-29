-- 846 — Classes exist only for non-WSQ / unfunded C-prefix courses.
--
-- This portal only creates classes for C-prefix course codes (C010, C6…).
-- WSQ (TGS-) classes live in the external SSG system; M- codes are partner
-- legacy; CRS-N-/CRS-Q- are retired SSG reference codes on deleted products
-- (live products were resynced by migration 845); TEST/CK*/etc. are junk.
-- Remove every course_runs row (and its roster + attendance rows) whose
-- course_sku is not C-followed-by-digit, then renumber the surviving
-- class_ids into a contiguous C000001… sequence in run_id (creation) order.
--
-- Safety:
-- - Runs with issued certificates (mmd_course_run_certificate) are KEPT even
--   if non-C, so printed cert links never dangle. (0 such rows on SG.)
-- - cert_no values are never rewritten (printed documents); only the
--   class_id snapshot columns are resynced, as in migration 832.
-- - Renumber is two-phase via a temporary 'X' prefix because old and new ids
--   share the 'C' prefix and a one-pass UPDATE can transiently collide on
--   uk_class_id.
-- - Partner-safe: information_schema guards, each site touches only its own
--   rows, deterministic (ORDER BY run_id), re-run is a no-op.

SET @has_runs := (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='course_runs');
SET @has_enr  := (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='course_run_enrolments');
SET @has_att  := (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_course_run_attendance');
SET @has_cert := (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_course_run_certificate');
SET @keepcert := IF(@has_cert>0, ' AND NOT EXISTS (SELECT 1 FROM mmd_course_run_certificate xc WHERE xc.run_id = cr.run_id)', '');

-- 1. Roster rows of the runs being removed.
SET @s := IF(@has_runs>0 AND @has_enr>0,
  CONCAT('DELETE e FROM course_run_enrolments e JOIN course_runs cr ON cr.run_id = e.run_id WHERE cr.course_sku NOT REGEXP ''^C[0-9]''', @keepcert),
  'DO 0');
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Attendance rows of the runs being removed.
SET @s := IF(@has_runs>0 AND @has_att>0,
  CONCAT('DELETE a FROM mmd_course_run_attendance a JOIN course_runs cr ON cr.run_id = a.run_id WHERE cr.course_sku NOT REGEXP ''^C[0-9]''', @keepcert),
  'DO 0');
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. The runs themselves.
SET @s := IF(@has_runs>0,
  CONCAT('DELETE cr FROM course_runs cr WHERE cr.course_sku NOT REGEXP ''^C[0-9]''', @keepcert),
  'DO 0');
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4a. Renumber phase 1: park every surviving run on a unique X###### id.
SET @seq := 0;
SET @s := IF(@has_runs>0,
  'UPDATE course_runs cr JOIN (SELECT run_id, @seq := @seq + 1 AS new_seq FROM course_runs ORDER BY run_id) m ON m.run_id = cr.run_id SET cr.class_id = CONCAT(''X'', LPAD(m.new_seq, 6, ''0''))',
  'DO 0');
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4b. Renumber phase 2: flip X###### to the final C###### ids.
SET @s := IF(@has_runs>0,
  'UPDATE course_runs SET class_id = CONCAT(''C'', SUBSTRING(class_id, 2)) WHERE class_id LIKE ''X%''',
  'DO 0');
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 5. Resync the class_id snapshot columns (cert_no deliberately untouched).
SET @s := IF(@has_att>0 AND @has_runs>0,
  'UPDATE mmd_course_run_attendance a JOIN course_runs cr ON cr.run_id = a.run_id SET a.class_id = cr.class_id WHERE NOT (a.class_id <=> cr.class_id)',
  'DO 0');
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @s := IF(@has_cert>0 AND @has_runs>0,
  'UPDATE mmd_course_run_certificate c JOIN course_runs cr ON cr.run_id = c.run_id SET c.class_id = cr.class_id WHERE NOT (c.class_id <=> cr.class_id)',
  'DO 0');
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
