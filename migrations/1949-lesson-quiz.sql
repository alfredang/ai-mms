-- Lesson quizzes: a developer adds a Quiz to a sub topic of a course's Lesson.
-- The Lesson itself (topics, sub topics, links, videos) stays in the course
-- description's LSN_DATA marker, which holds only the quiz id: the questions
-- and the correct answers live here, never in the public course page.
-- One row per attempt in mmd_lesson_quiz_attempt (web quiz page or mobile app).
-- Runs on every site (SG/MY/GH), schema only, no data. Safe to re-run.

CREATE TABLE IF NOT EXISTS `mmd_lesson_quiz` (
    `quiz_id`     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id`  INT UNSIGNED NOT NULL COMMENT 'course the quiz was written for',
    `title`       VARCHAR(255) NOT NULL DEFAULT '',
    `questions`   MEDIUMTEXT NOT NULL COMMENT 'JSON [{id, question, options[], correct}]',
    `created_at`  DATETIME NOT NULL COMMENT 'UTC',
    `updated_at`  DATETIME NOT NULL COMMENT 'UTC',
    PRIMARY KEY (`quiz_id`),
    KEY `idx_mmd_lesson_quiz_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mmd_lesson_quiz_attempt` (
    `attempt_id`    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `quiz_id`       INT UNSIGNED NOT NULL,
    `run_id`        INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'course_runs.run_id of the class, 0 = no class',
    `learner_email` VARCHAR(255) NOT NULL,
    `learner_name`  VARCHAR(255) NOT NULL DEFAULT '',
    `score`         SMALLINT UNSIGNED NOT NULL,
    `total`         SMALLINT UNSIGNED NOT NULL,
    `answers`       TEXT NOT NULL COMMENT 'JSON {question id: chosen option index}',
    `source`        VARCHAR(10) NOT NULL DEFAULT 'web' COMMENT 'web | app',
    `completed_at`  DATETIME NOT NULL COMMENT 'UTC',
    PRIMARY KEY (`attempt_id`),
    KEY `idx_mmd_lesson_quiz_attempt_quiz` (`quiz_id`, `run_id`),
    KEY `idx_mmd_lesson_quiz_attempt_learner` (`learner_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
