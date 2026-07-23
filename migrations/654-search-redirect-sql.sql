-- 654: Search-term redirect (SG only) — generic "sql" queries ->
--      WSQ SQL Fundamental for Beginners.
--
-- HARD CONSTRAINTS (per CLAUDE.md + memory feedback_search_redirect_guard_skips_wrong_targets
-- and feedback_search_term_redirect_restore):
--   * EMPTY-ONLY: only fill redirect IS NULL/'' — never overwrite an existing
--     intentional product-page redirect. The SG DB already routes NoSQL->nosql
--     courses, PostgreSQL->postgresql, PHP&MySQL->php, Azure SQL->DP-300, etc.
--     Those must stay put.
--   * "sql" is a substring of MANY unrelated DB topics. A blunt LIKE '%sql%'
--     would hijack mysql / nosql / postgresql / mssql / pl-sql / oracle-sql /
--     php-sql searches to the SQL-fundamentals course. So we match rows that
--     contain "sql" but EXCLUDE those tokens, and require the sql to be a
--     standalone-ish token (word boundary), not embedded in a longer word.
--   * SG-gated: absolute .com.sg URL must never be written on a partner DB.
-- Idempotent: empty-only + INSERT IGNORE for the bare "sql" seed.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @url := 'https://www.tertiarycourses.com.sg/wsq-sql-fundamental-for-beginners.html';

-- Seed the bare "sql" term if it was never searched (existing 'sql' keeps its
-- current /database.html redirect — empty-only rule below won't touch it).
INSERT IGNORE INTO catalogsearch_query
  (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed)
SELECT 'sql', 0, 0, @url, 1, 0, 1, 1 FROM DUAL WHERE @sg = 1;

-- Empty-only backfill: any SQL query with NO redirect yet -> SQL Fundamentals,
-- EXCLUDING the other-database families that must route elsewhere.
UPDATE catalogsearch_query
SET redirect = @url
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect = '')
  -- "sql" as a token: start of string / preceded by non-letter, and not the
  -- tail of nosql / mysql / mssql / postgresql / plsql / oraclesql.
  AND LOWER(query_text) REGEXP '(^|[^a-z])sql'
  -- Exclude other DB families (their empty rows should NOT go to SQL Fundamentals).
  AND LOWER(query_text) NOT REGEXP 'no[[:space:]-]*sql'
  AND LOWER(query_text) NOT REGEXP 'my[[:space:]]*sql'
  AND LOWER(query_text) NOT REGEXP 'ms[[:space:]]*sql'
  AND LOWER(query_text) NOT REGEXP 'm[[:space:]]*sql'
  AND LOWER(query_text) NOT REGEXP 'postgre'
  AND LOWER(query_text) NOT REGEXP 'postre'
  AND LOWER(query_text) NOT REGEXP 'postress'
  AND LOWER(query_text) NOT REGEXP 'oracle'
  AND LOWER(query_text) NOT REGEXP 'pl[[:space:]-]*sql'
  AND LOWER(query_text) NOT REGEXP 't[[:space:]-]*sql'
  AND LOWER(query_text) NOT LIKE '%php%'
  AND LOWER(query_text) NOT LIKE '%mongo%';
