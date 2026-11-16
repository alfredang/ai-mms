-- 1939: course_courseware gains lab_simulator_url — a hosted lab simulator
-- (e.g. a GitHub Pages exam/lab simulator) for a course.
--
-- Developers set it in Edit Course -> Courseware ("Lab Simulator URL"). When
-- set, a "Lab Simulator" tile shows in the Courseware section for Developer,
-- Trainer and Learner; when empty the tile is hidden.
--
-- 1. Column: every instance (additive, defaults to ''). Guarded so re-runs and
--    partner schemas that diverged no-op instead of aborting apply.php.
-- 2. Data: SG only (store guard) — the two Claude Certified Architect courses.
--    Only fills an empty value, so a later edit in the admin is never reverted.

SET @has_tbl := (SELECT COUNT(*) FROM information_schema.TABLES
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'course_courseware');

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'course_courseware'
             AND COLUMN_NAME = 'lab_simulator_url');

SET @sql := IF(@has_tbl = 1 AND @c = 0,
    'ALTER TABLE course_courseware ADD COLUMN lab_simulator_url VARCHAR(1000) NOT NULL DEFAULT '''' AFTER lab_url',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @is_sg := ((SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);

-- Courses with no course_courseware row yet get one.
INSERT INTO course_courseware (product_id)
SELECT e.entity_id
  FROM catalog_product_entity e
  LEFT JOIN course_courseware c ON c.product_id = e.entity_id
 WHERE @is_sg AND @has_tbl = 1
   AND e.sku IN ('C437', 'TGS-2026061312')
   AND c.id IS NULL;

UPDATE course_courseware c
  JOIN catalog_product_entity e ON e.entity_id = c.product_id
   SET c.lab_simulator_url = CASE e.sku
         WHEN 'C437'           THEN 'https://tertiarycourses.github.io/C437-Claude-Certified-Architect-Foundations-Certification/'
         WHEN 'TGS-2026061312' THEN 'https://tertiarycourses.github.io/TGS-2026061312-Claude-Certified-Architect-Foundation/'
       END
 WHERE @is_sg
   AND e.sku IN ('C437', 'TGS-2026061312')
   AND c.lab_simulator_url = '';
