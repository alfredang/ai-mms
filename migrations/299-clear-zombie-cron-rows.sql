-- 297: Clear zombie cron_schedule rows (caching/speed + mysql audits 2026-07-02).
-- Local DB carried 463 rows stuck in status='running' (oldest 2015) — jobs
-- that died mid-run and were never rescheduled; sales_clean_quotes alone had
-- 437, which is why stale-quote cleanup never completes. Removing dead
-- 'running' rows lets Magento's cron dispatcher schedule those jobs again.
-- Idempotent: only touches rows that have been "running" for over a day.

DELETE FROM cron_schedule WHERE status = 'running' AND scheduled_at < NOW() - INTERVAL 1 DAY;
