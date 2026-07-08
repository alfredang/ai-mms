-- Add 'scheduled' to newsletters.status so scheduleApproved's write persists.
-- The legacy enum was ('draft','pushed','sent'); writing 'scheduled' silently
-- stored '' (invalid enum in non-strict mode), which broke the "already
-- scheduled" idempotency guard and the pipeline stage display.
-- Guarded: the newsletters table is SG-only (migration 300); this no-ops on any
-- partner instance that doesn't have it, so apply.php never aborts there.
SET @sql := (
  SELECT IF(
    EXISTS(SELECT 1 FROM information_schema.TABLES
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'newsletters'),
    'ALTER TABLE newsletters MODIFY status ENUM(''draft'',''pushed'',''sent'',''scheduled'') NOT NULL DEFAULT ''draft''',
    'DO 0'
  )
);
PREPARE _s FROM @sql; EXECUTE _s; DEALLOCATE PREPARE _s;

-- Backfill: rows already booked to MailerLite but with a blanked status.
UPDATE newsletters SET status = 'scheduled'
 WHERE mailerlite_id IS NOT NULL AND mailerlite_id <> '' AND status = '' ;
