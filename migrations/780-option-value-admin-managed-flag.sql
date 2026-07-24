-- Add an `admin_managed` flag to Course Date (and any) custom-option values.
--
-- Purpose: let a schedule-template Apply reconcile ONLY its own generated
-- dates. A value with admin_managed = 1 is a case-by-case, admin-confirmed
-- class date (added/edited via Edit Course -> Course Schedule, or the agent
-- add_class API) and must NEVER be removed by an automated template Apply.
-- Template-generated values stay admin_managed = 0, so a re-apply keeps
-- reconciling them as before.
--
-- DEFAULT 0 means every pre-existing value is treated as template-managed,
-- which matches the intent: existing template-generated dates keep their
-- current behaviour; only newly admin-added/edited dates get protected.
--
-- Idempotent (information_schema guard + prepared statement), so it is a
-- no-op on any partner DB that already has the column. apply.php runs each
-- ";"-terminated statement on the same PDO connection, so @vars / the
-- prepared statement persist across the split.

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_product_option_type_value' AND COLUMN_NAME = 'admin_managed');
SET @s := IF(@c = 0, 'ALTER TABLE catalog_product_option_type_value ADD COLUMN admin_managed TINYINT(1) NOT NULL DEFAULT 0', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;
