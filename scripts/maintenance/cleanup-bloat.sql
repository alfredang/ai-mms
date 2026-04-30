-- ============================================================================
-- One-shot DB hygiene — frees ~430 MB of dead weight identified by the
-- 2026-04-30 speed analysis (docs/speed-analysis.md §3).
--
-- THIS IS NOT IN migrations/ ON PURPOSE. It is destructive. Read each
-- section, then run manually against a database that has a fresh backup.
-- The Coolify nightly backup is the obvious safety net, but verify the
-- most recent dump succeeded before you press Enter.
--
-- How to run on production (one section at a time, not all at once):
--   docker exec -it project-web-1 sh -c \
--     'mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"'
--   then paste a single section, watch row counts, eyeball before continuing.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- §1  smtppro_email_log  (~180 MB)
--     Aschroder_SMTPPro keeps the FULL HTML body of every email it sends.
--     Useful for debugging delivery, useless after a few days. Trim to the
--     last 30 days; if you don't even need that, just TRUNCATE.
-- ----------------------------------------------------------------------------

-- Show what we're about to delete (preview, no change):
SELECT COUNT(*)              AS rows_before,
       MIN(created_at)       AS oldest,
       MAX(created_at)       AS newest,
       ROUND(SUM(LENGTH(body))/1024/1024, 1) AS body_mb
FROM smtppro_email_log;

-- Option A — keep last 30 days (safer, recommended):
DELETE FROM smtppro_email_log WHERE created_at < NOW() - INTERVAL 30 DAY;

-- Option B — wipe everything (uncomment if logs aren't needed at all):
-- TRUNCATE TABLE smtppro_email_log;

-- Reclaim disk after the DELETE (locks the table for the duration; runs in
-- seconds at this scale):
OPTIMIZE TABLE smtppro_email_log;


-- ----------------------------------------------------------------------------
-- §2  Abandoned shopping quotes  (~280 MB across 4 tables)
--     Magento 1 has a sales/clean_quotes cron that prunes quotes older than
--     `checkout/cart/delete_quote_after` days (default 30). It's evidently
--     not running here — 924K quote_item_options is the smoking gun. We
--     delete by quote_id cascade because foreign keys aren't always
--     consistent on these legacy installs.
-- ----------------------------------------------------------------------------

-- Preview:
SELECT COUNT(*) AS quotes_to_delete
FROM sales_flat_quote
WHERE updated_at < NOW() - INTERVAL 60 DAY
  AND is_active = 0;

-- Delete in dependency order. Each statement is a single transaction; the
-- whole sequence takes a few minutes on production-sized data.
DELETE qio FROM sales_flat_quote_item_option qio
  JOIN sales_flat_quote_item qi ON qi.item_id = qio.item_id
  JOIN sales_flat_quote      q  ON q.entity_id = qi.quote_id
  WHERE q.updated_at < NOW() - INTERVAL 60 DAY AND q.is_active = 0;

DELETE qi FROM sales_flat_quote_item qi
  JOIN sales_flat_quote q ON q.entity_id = qi.quote_id
  WHERE q.updated_at < NOW() - INTERVAL 60 DAY AND q.is_active = 0;

DELETE qa FROM sales_flat_quote_address qa
  JOIN sales_flat_quote q ON q.entity_id = qa.quote_id
  WHERE q.updated_at < NOW() - INTERVAL 60 DAY AND q.is_active = 0;

DELETE qsm FROM sales_flat_quote_shipping_rate qsm
  JOIN sales_flat_quote_address qa ON qa.address_id = qsm.address_id
  WHERE NOT EXISTS (SELECT 1 FROM sales_flat_quote_address WHERE address_id = qsm.address_id);

DELETE FROM sales_flat_quote
  WHERE updated_at < NOW() - INTERVAL 60 DAY AND is_active = 0;

-- Reclaim:
OPTIMIZE TABLE sales_flat_quote;
OPTIMIZE TABLE sales_flat_quote_item;
OPTIMIZE TABLE sales_flat_quote_item_option;
OPTIMIZE TABLE sales_flat_quote_address;


-- ----------------------------------------------------------------------------
-- §3  core_url_rewrite index bloat  (~50 MB of pure index)
--     This table accumulates duplicate rows every time the catalog URL
--     reindex runs without cleanup. Best handled by Magento's own indexer
--     rather than raw DELETEs (which can break frontend product URLs):
-- ----------------------------------------------------------------------------

-- Run from shell, NOT from this SQL file:
--   docker exec project-web-1 php /var/www/html/shell/indexer.php --reindex catalog_url
--
-- After reindex, optimize to actually shrink the file:
OPTIMIZE TABLE core_url_rewrite;


-- ----------------------------------------------------------------------------
-- §4  Verify
-- ----------------------------------------------------------------------------
SELECT TABLE_NAME,
       table_rows,
       ROUND(data_length/1024/1024, 1)  AS data_mb,
       ROUND(index_length/1024/1024, 1) AS idx_mb
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND TABLE_NAME IN (
    'smtppro_email_log',
    'sales_flat_quote', 'sales_flat_quote_item', 'sales_flat_quote_item_option',
    'sales_flat_quote_address', 'core_url_rewrite'
  )
ORDER BY (data_length + index_length) DESC;
