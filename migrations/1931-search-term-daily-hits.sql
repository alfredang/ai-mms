-- 1931: per-day search-term hit log behind the dashboard's Popular Search Terms period
-- filter (3 / 6 / 12 months). catalogsearch_query keeps one row per term with a cumulative
-- popularity, and its updated_at is re-stamped by every bulk UPDATE, so it cannot answer
-- "hits in the last N months". MMD_SearchFallback_ResultController writes one row per
-- term per day from the day this ships. Schema only, same on every site (no guard).
CREATE TABLE IF NOT EXISTS `mmd_search_term_daily` (
  `query_id` INT UNSIGNED NOT NULL,
  `day` DATE NOT NULL,
  `hits` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`query_id`, `day`),
  KEY `idx_search_term_daily_day` (`day`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
