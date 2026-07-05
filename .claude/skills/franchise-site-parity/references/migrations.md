# Schema migrations — the production tripwire

Partner content work is DB-only (no migration). But a genuinely SHARED change (SG + all
partners) goes through the repo migration runner, which is the single most dangerous thing
in this repo. Every rule below is a real outage that happened.

## Mechanics
- Drop `migrations/NNN-foo.sql` (numbered). On deploy `docker/entrypoint.sh` runs
  `migrations/apply.php`, tracked in the `schema_migrations` ledger (runs each file at most once).
- First run against a pre-existing prod DB enters **tolerant mode** (swallows 1050/1051/1060/
  1061/1068/1091 idempotency errors) for that run only; later runs are strict.
- Local dry-run (MANDATORY): `docker exec ai-mms-web-1 php /var/www/html/migrations/apply.php`
  — must print `applying: NNN … OK`. Bootstrap an existing DB: `apply.php --bootstrap`.

## Why you dry-run apply.php and NOT the mysql client
apply.php's PDO DSN is `charset=utf8` and it **aborts the entire chain on the first failed
statement** → container exits non-zero → Coolify keeps the old container OR every host 502s
until a fixed build deploys. The `mysql` client connects latin1 and silently tolerates the
same bad bytes → false confidence. (Real outage 2026-06-05.)

## UTF-8 sanitation
Any INSERT pulling from legacy tables (`catalogsearch_query`, old EAV, anything historically
written latin1) MUST be UTF-8-clean or apply.php dies `1366 Incorrect string value '\x96…'`.
Cheapest filter for ASCII data: `WHERE LENGTH(col) = CHAR_LENGTH(col)`. `QUOTE()` does NOT fix
it — the bytes are invalid UTF-8, not an escaping problem.

## Country-instance table drift
Partner DBs LACK some SG-only tables (e.g. `smtppro_email_log`). A bare `DELETE FROM
smtppro_email_log` 502'd GH/MY/NG. Guard EVERY table-touching statement:
```sql
SET @ok := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='smtppro_email_log');
SET @s := IF(@ok>0, 'DELETE FROM smtppro_email_log WHERE ...', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
```
Use `SET FOREIGN_KEY_CHECKS=0` around FK-touching work. After a migration push, curl
`.com.my`/`.com.gh` too — not just SG. A store-delete does NOT cascade; orphaned store_id
rows crash admin grids ("Invalid store code requested").

## Splitter + idempotency
- apply.php splits on `;` at END OF LINE → a multi-line string VALUE must never have a content
  line ending in `;`. Guard REPLACE rewrites with `MD5(value)` / emit unconditional strip stmts.
- Always `INSERT IGNORE` / `ON DUPLICATE KEY UPDATE`.
- CMS-block `REPLACE()`: generate hex/base64 PROGRAMMATICALLY (read live block → bin2hex/base64
  → write the .sql). Never hand-copy multi-KB hex (corrupts silently). Use `UNHEX()`/`FROM_BASE64`
  to bypass MySQL backslash-escape ambiguity. Reverse a bad REPLACE by swapping the file's own args.
- Encrypted config columns need `Mage::helper('core')->encrypt()` before saving, else
  getStoreConfig returns garbage.
- Search-term redirect migrations (`catalogsearch_query.redirect`): data-only; validate every
  target returns 200/302 on ITS OWN store domain; only fill `redirect IS NULL/''`.

## Post-push watch
`/version.txt` for the new build timestamp; poll the homepage until 200. `/media/migrations-status.json`
(public, counts only). A failed migration shows as a sustained 502 on every host.

Source memories: feedback_migration_applyphp_utf8_outage, feedback_migration_country_instance_table_differences,
feedback_apply_php_sql_splitter, feedback_migration_generator_skipped_strip,
feedback_cms_block_hex_replace_generate_programmatically, feedback_encrypted_config_column_save,
feedback_store_delete_orphans_and_infoschema_migration_502, feedback_db_sync_via_migration,
feedback_search_term_redirect_restore, feedback_reindex_api_prod_flat_stale.
