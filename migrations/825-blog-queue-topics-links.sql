-- 825: admin brief for the blog queue — per-row research TOPICS + reference
-- LINKS. The admin's direction becomes part of the prompt input for the
-- research agent + writer (Autoblog::_researchTopic / _writerInput), so a
-- queued course can carry "write about X, consult these pages".
-- Idempotent via information_schema column guards (apply.php splits on
-- semicolon-at-EOL — each statement on its own line). mmd_blog_queue exists
-- on every instance via migration 822, so no table guard is needed.
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_blog_queue' AND COLUMN_NAME='topics');
SET @s := IF(@c=0, 'ALTER TABLE mmd_blog_queue ADD COLUMN topics TEXT NULL AFTER position', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_blog_queue' AND COLUMN_NAME='links');
SET @s := IF(@c=0, 'ALTER TABLE mmd_blog_queue ADD COLUMN links TEXT NULL AFTER topics', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;
