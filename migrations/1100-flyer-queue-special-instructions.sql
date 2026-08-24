-- Per-row SPECIAL INSTRUCTIONS for the next-flyer queue.
--
-- Until now the admin could only line up WHICH WSQ course goes out next; the
-- only way to steer HOW the flyer reads was to reject the finished design and
-- type feedback into the change-request loop. These two columns let the
-- instruction be given UP FRONT, at queue time:
--
--   instructions - free text ("lead with HRDC", "use a teal colour scheme").
--                  Consumed by Cron_Flyer::propose -> createProposal -> the AI
--                  copy prompt, exactly like manager change-request feedback,
--                  and additionally parsed for a colour request that overrides
--                  the per-course accent palette.
--   run_date     - OPTIONAL 'Y-m-d'. Pins WHICH published intake the flyer
--                  leads with, chosen from the course's own Course Date
--                  options. It can only re-order real, bookable dates - it can
--                  never invent one - so a blast cannot advertise an intake the
--                  course does not sell.
--
-- Both are per-QUEUE-ROW, not per-SKU: the row is deleted when the cron pops
-- it, so an instruction applies to exactly one flyer and never silently
-- persists into a later blast for the same course.
--
-- Idempotent via the PREPARE guard (plain ADD COLUMN would abort apply.php on
-- a re-run and 502 the whole site). Safe on every instance: the table itself
-- is created by 305-flyer-queue-table.sql, and this is a no-op where the
-- columns already exist.

SET @tbl := 'mmd_marketing_flyer_queue';

SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tbl
                   AND COLUMN_NAME = 'instructions');
SET @sql := IF(@exists = 0,
  'ALTER TABLE mmd_marketing_flyer_queue ADD COLUMN instructions TEXT NULL AFTER position',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tbl
                   AND COLUMN_NAME = 'run_date');
SET @sql := IF(@exists = 0,
  'ALTER TABLE mmd_marketing_flyer_queue ADD COLUMN run_date DATE NULL AFTER instructions',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
