-- 1141: Search-term redirects for SQL intent, admin-requested 2026-08-27:
--   "sql", "mysql", "relational sql" (+ the "my sql" spacing variant)
--     -> https://www.tertiarycourses.com.sg/relational-sql-databases.html
--
-- Live SG rows at write time (probe 2026-08-27):
--   175   mysql           NULL
--   194   sql             -> database.html            (broader parent category)
--   2216  my sql          '' (empty)
--   44732 relational sql  -> relational-sql-databases.html (already correct)
--   77502 sql (dup row)   -> wsq-sql-fundamental-for-beginners.html
-- The admin explicitly asked for these terms to land on the Relational SQL
-- category, so the two existing non-empty targets are intentionally
-- overwritten (this supersedes the usual only-fill-empty rule, which guards
-- BULK restores, not explicit per-term requests). Target verified HTTP 200 on
-- its own store domain.
--
-- Search redirects are DATA: this was applied LIVE on SG prod the same day;
-- the migration keeps a rebuilt DB consistent and re-runs as a no-op.
--
-- PARTNER SAFETY: partner DBs have their own store 1 and their own
-- catalogsearch_query rows; pointing them at an SG URL would be a cross-site
-- redirect (forbidden). Guarded on the instance base_url so MY/GH no-op.
--
-- Idempotent: fixed target value, exact-term match.

SET @is_sg := (SELECT COUNT(*) FROM core_config_data
               WHERE path = 'web/unsecure/base_url'
                 AND value LIKE '%tertiarycourses.com.sg%');

UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/relational-sql-databases.html'
WHERE store_id = 1
  AND LOWER(query_text) IN ('sql', 'mysql', 'my sql', 'relational sql')
  AND @is_sg > 0;
