-- 875 — mark reconstructed subscriber snapshots.
--
-- The growth chart on the Marketing Dashboard shows a rolling 12-month view,
-- but mmd_marketing_subscriber_snapshot only starts at 2026-07-13 (migration
-- 302), so 10 of the 12 months have no data and the chart rendered 2 bars.
--
-- MailerLite's API exposes no historical count, but every subscriber carries
-- subscribed_at — so the earlier months are reconstructed by counting ACTIVE
-- subscribers per signup month and accumulating. That walk is ~36 API pages
-- (~40s), far too slow for a page render, so it is persisted here once and
-- refreshed only when a month is missing.
--
-- is_estimated separates those reconstructed rows from genuine daily
-- snapshots: reconstructed months exclude anyone who has since unsubscribed,
-- so they read slightly LOW versus the list's true standing at the time. The
-- dashboard renders them dimmed with a caveat note. Real snapshots always win
-- for any month that has one.
--
-- Country-safe: same table exists on every partner server (302 is shared), and
-- the guard makes a re-run a no-op.

SET @c := (SELECT COUNT(*) FROM information_schema.columns
            WHERE table_schema = DATABASE()
              AND table_name = 'mmd_marketing_subscriber_snapshot'
              AND column_name = 'is_estimated');
SET @sql := IF(@c = 0,
    'ALTER TABLE mmd_marketing_subscriber_snapshot ADD COLUMN is_estimated TINYINT(1) NOT NULL DEFAULT 0',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
