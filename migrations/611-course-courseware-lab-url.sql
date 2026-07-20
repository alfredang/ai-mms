-- 611: course_courseware gains lab_url — the Google Drive "Activities" folder
-- holding a course's hands-on lab worksheets.
--
-- Non-WSQ (C-prefix) courses publish five courseware links: trainer slides
-- (PPT), learner slides (PPT PDF), lesson plan, learner guide and now the labs
-- folder. The first four already have columns here; lab_url is the only one
-- missing, so /lms-push-nonwsq had nowhere to write the Activities link.
--
-- Unlike the other columns this one holds a FOLDER link, not a file link — a
-- lab set is many worksheets plus the trainer's datasets/templates, so a single
-- file URL would not do.
--
-- Guarded so re-runs and partner instances with a diverged schema no-op rather
-- than aborting apply.php. Safe on every instance: the column is additive and
-- defaults to '' , so existing rows and the admin save path are unaffected.

SET @has_tbl := (SELECT COUNT(*) FROM information_schema.TABLES
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'course_courseware');

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'course_courseware'
             AND COLUMN_NAME = 'lab_url');

SET @sql := IF(@has_tbl = 1 AND @c = 0,
    'ALTER TABLE course_courseware ADD COLUMN lab_url VARCHAR(1000) NOT NULL DEFAULT '''' AFTER trainer_slides_url',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
