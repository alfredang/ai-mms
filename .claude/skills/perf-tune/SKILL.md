---
name: perf-tune
description: Performance tuning playbook for the LMS — caching (Redis/Magento cache types/FPC/OPcache), page speed, and MySQL 5.7 memory/query optimization. Use when asked to "speed up the site", "tune mysql", "optimize caching", "reduce memory", "site is slow", or for a periodic performance review. Orchestrates the caching-speed-optimizer and mysql-memory-optimizer agents, then applies ONLY approved quick wins with full verification.
---

# Performance Tuning Playbook

## Phase 1 — Measure (always first)

Launch both audit agents in parallel (Agent tool):
- `caching-speed-optimizer` — cache backends, OPcache, TTFB per route, asset weight, indexer/cron health.
- `mysql-memory-optimizer` — InnoDB memory model, table bloat, slow-query digest, schema checks.

Wait for both; merge into one prioritized list (HIGH risk first, quick wins flagged).

## Phase 2 — Apply (only what's safe)

Rules of engagement:
- **Apply without asking**: local-only, reversible quick wins — e.g. docker-compose MySQL flags, missing index as a `migrations/NNN-*.sql` (idempotent, apply.php-dry-run-verified), enabling a disabled-but-safe Magento cache type locally.
- **Report but do NOT apply**: anything needing Coolify/prod-side action (prod MySQL variables, Cloudflare settings), anything that changes rendered storefront output, re-enabling CSS/JS merge (known 500 — migration 266 disabled it deliberately), OPcache validate_timestamps=0 (breaks the Coolify deploy model), log-table truncation on prod.
- Every applied change gets the CLAUDE.md pre-push verification (lint, instantiation, route curl, apply.php dry-run) BEFORE it is even committed locally.

## Phase 3 — Verify

- Re-run the TTFB measurements from Phase 1 on the touched routes; report before/after numbers.
- Run the `site-health` skill (localhost scope).
- Storefront must render identically — curl the homepage and diff the HTML `<head>`+banner block against a pre-change copy; any diff beyond cache-buster timestamps is a regression.

## Known constraints (do not relearn these)

- CSS/JS merge OFF on purpose (merged admin bundle 500'd; memory `feedback_reindex_api_prod_flat_stale`).
- Flat catalog reads go stale after attribute writes — every catalog-touching optimization ends with reindex + cache flush (memory `feedback_flat_catalog_reindex`).
- Redis object cache is env-var-driven (commit 0e92013b1) — config lives in env/local.xml wiring, not core_config_data.
- `docker/php.ini` sets 512M/OPcache deliberately; php.ini changes redeploy every country instance.
- Buffer-pool sizing: never above ~60% of the DB container's memory limit; local docker-compose and prod Coolify limits differ — state both.
- No push to GitHub as part of tuning — local commit at most; the admin decides pushes.
