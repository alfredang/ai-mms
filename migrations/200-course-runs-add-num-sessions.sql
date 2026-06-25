-- Add an optional explicit session-count to course_runs.
-- For most classes the trainer-reminder "Course Duration" is derived from the
-- (course_end_date - course_start_date) span, which is correct for consecutive
-- multi-day courses. But some WSQ courses skip days (e.g. Mon/Tue/Fri, or two
-- non-adjacent Sundays) — there the span over-counts. When num_sessions is set,
-- the reminder uses it verbatim for the duration line; when NULL it falls back
-- to the span calc. Idempotent: tolerant mode swallows 1060 on re-run.
ALTER TABLE `course_runs`
    ADD COLUMN `num_sessions` SMALLINT UNSIGNED NULL DEFAULT NULL
    COMMENT 'Explicit training-session count; overrides span-derived duration in trainer reminders when set'
    AFTER `course_end_date`;
