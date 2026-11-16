-- 1938 — QR class check-in: optional phone number on the class roster.
--
-- The trainer's Check-in QR now opens a public form (name, email, optional
-- phone). The phone is kept on the learner's enrolment row for that class and
-- shown under the email on E-Attendance.
--
-- Country-safe: course_run_enrolments exists on every site; the guard makes a
-- re-run a no-op ('DO 0', never 'SELECT 1').

SET @c := (SELECT COUNT(*) FROM information_schema.columns
            WHERE table_schema = DATABASE()
              AND table_name = 'course_run_enrolments'
              AND column_name = 'learner_phone');
SET @sql := IF(@c = 0,
    'ALTER TABLE course_run_enrolments ADD COLUMN learner_phone VARCHAR(40) NULL AFTER learner_name',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
