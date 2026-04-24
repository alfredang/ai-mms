-- NEUTRALIZED — original content would reset every admin_user password to
-- "admin123", which is destructive on any environment that already has real
-- admin passwords. The file is kept so the migration numbering stays
-- contiguous and so schema_migrations ledgers on environments that already
-- ran it don't get out of sync.
--
-- If you need to reset a specific admin's password, do it through Admin →
-- Users in the admin UI or via a targeted one-off SQL, never a blanket
-- migration against all rows.

SELECT 1;
