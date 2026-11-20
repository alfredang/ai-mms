-- 1941: course_courseware gains practice_exam_url — a link to a practice exam
-- for a course (e.g. its exam on exams.tertiaryinfotech.com).
--
-- Developers set it in Edit Course -> Courseware ("Practice Exam URL", placed
-- after "Lab Simulator URL"). When set, a "Practice Exam" tile shows in the
-- Courseware section for Developer, Trainer and Learner (and in the learner
-- app's class materials); when empty the tile is hidden.
--
-- Column only, on every instance (additive, defaults to ''). Guarded so re-runs
-- and partner schemas that diverged no-op ('DO 0') instead of aborting apply.php.

SET @has_tbl := (SELECT COUNT(*) FROM information_schema.TABLES
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'course_courseware');

SET @has_after := (SELECT COUNT(*) FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'course_courseware'
                     AND COLUMN_NAME = 'lab_simulator_url');

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'course_courseware'
             AND COLUMN_NAME = 'practice_exam_url');

SET @sql := IF(@has_tbl = 1 AND @c = 0,
    IF(@has_after = 1,
       'ALTER TABLE course_courseware ADD COLUMN practice_exam_url VARCHAR(1000) NOT NULL DEFAULT '''' AFTER lab_simulator_url',
       'ALTER TABLE course_courseware ADD COLUMN practice_exam_url VARCHAR(1000) NOT NULL DEFAULT '''''),
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
