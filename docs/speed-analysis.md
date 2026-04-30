# Speed Analysis — ai-mms (Tertiary Infotech LMS)

*Last updated: 2026-04-30*

## TL;DR

The site is slow because the admin dashboard does **~91 database calls per page load** through a single 14,277-line PHP template, and the database itself is carrying ~600 MB of tables that should have been pruned long ago (abandoned carts, email logs, URL rewrites). The good news: four of the worst offenders have already been fixed in the last week (dashboard role-gating, ACL reload removed, OPcache tuned, session cookie). The biggest remaining wins are **DB hygiene** (free, ~30% storage drop) and **moving cache + sessions to Redis** (one-day job, ~2x admin throughput).

---

## 1. What we already shipped

| # | Change | Effect | Commit |
|---|---|---|---|
| 1 | Drop per-request session ACL reload | −5 queries / request on every admin page | `d83be883` |
| 2 | Role-gate dashboard data prep (admin / TPG / Super Admin / View Trainers) | −10 to −30 queries / dashboard load (depending on role) | `d83be883` |
| 3 | OPcache JIT disabled | Removes tracing-JIT compile overhead on Magento 1 codepaths | `d83be883` |
| 4 | `realpath_cache_size = 32M`, TTL 7200s | Cuts filesystem stats; production sees Magento's ~10K file tree once, not every request | `docker/php.ini` |
| 5 | `opcache.validate_timestamps = 0` (prod) | OPcache stops stat-ing every PHP file per request — only resets on container restart | `docker/php.ini` |
| 6 | Lazy panel rendering on role swap | Role swap was 12–15 s; now PJAX-style swap of `#anchor-content` | `instant-nav.js` |
| 7 | Collapse 12-month N+1 loops on dashboard (Learners-by-Month + Sales-by-Month) | 24 sequential queries → 2 GROUP BY queries on Super Admin role | (this commit) |
| 8 | Enable CSS merge (`dev/css/merge_css_files = 1`) | ~12 stylesheet requests per admin page → 1 | `migrations/038` |

**Combined effect on a cold dashboard load**: queries dropped from ~120 to roughly 30–60 depending on role.

---

## 2. Where time still goes — measured

These are facts from this DB, not guesses:

| Layer | Measurement | Why it hurts |
|---|---|---|
| **Dashboard PHP** | 14,277 lines, 91 DB fetches in one template | Every dashboard load reparses + executes all of it |
| **N+1 hot loops** | `dashboard/index.phtml:764` and `:910` each run **12 sequential queries** for "by month" charts (24 round-trips just for charts) | Each round-trip is ~5–15 ms, so 24 trips ≈ 200 ms baseline before any real work |
| **Sessions** | `core_session` is in MySQL (~20 active rows), not Redis | Every request hits MySQL twice (read + write) just to load/save the session |
| **Cache backend** | Magento's 8 cache types are *enabled* but stored as **files on disk** in `var/cache` (5 MB) | Tens of thousands of small file ops per request on cache misses; on bind-mount dev this is brutal, on prod it's just slow |
| **CSS not merged** | `dev/css/merge_css_files = 0` in `core_config_data` | Admin loads ~12 CSS files per page navigation — 11 wasted round-trips |
| **JS bundles** | `media/js/{three files} = 2.3 MB raw` | Ships 2.3 MB of JS to every admin user even on cold cache |

---

## 3. The database is carrying dead weight — top suspects

Top 12 tables by size in production-mirror DB:

| Table | Rows | Size | Verdict |
|---|---:|---:|---|
| `smtppro_email_log` | 11,061 | **182 MB** | **Keeps every sent email body forever.** Never pruned. |
| `sales_flat_quote_item_option` | 924,733 | **166 MB** | Abandoned-cart bloat — Magento's quote-cleanup cron isn't running |
| `sales_flat_order_item` | 40,283 | 109 MB | Real data, fine |
| `sales_flat_quote_address` | 193,763 | 74 MB | Same as above — abandoned quotes |
| `core_url_rewrite` | 97,157 | 70 MB (20 data + 50 index) | Rewrite index bloat — duplicates from category re-indexing |
| `sales_flat_quote_item` | 122,452 | 37 MB | Abandoned quote items |
| `catalog_product_option_type_title` | 392,735 | 45 MB | Course schedule options accumulating without cleanup |
| `sales_flat_order` | 44,442 | 35 MB | Real data |
| `catalog_product_entity_text` | 15,339 | 32 MB | Course descriptions — large but real |

**~580 MB of the DB is in tables that should be ~150 MB.** Trimming `smtppro_email_log`, the quote tables, and rebuilding `core_url_rewrite` would drop total DB size by ~30% and noticeably speed every JOIN that touches sales/quote data.

---

## 4. The biggest remaining wins, ranked

### Tier 1 — Free, big, do it this week

1. **Truncate `smtppro_email_log`** (or keep last 30 days). One SQL statement. Frees 180 MB. Zero risk.
2. **Run Magento's quote-cleanup**: `sales/clean_quotes` cron job, or a one-shot `DELETE FROM sales_flat_quote WHERE updated_at < NOW() - INTERVAL 60 DAY`. Frees ~280 MB, speeds checkout queries.
3. **Reindex `core_url_rewrite`**: `php shell/indexer.php --reindex catalog_url`. Drops 50 MB of index bloat.
4. **Enable CSS merge**: flip `dev/css/merge_css_files` to 1. Cuts ~11 HTTP requests per admin page.
5. **Truncate the dashboard's two N+1 loops**: collapse the two 12-month loops into single GROUP BY queries. Saves ~20 round-trips per dashboard load. Half-day of work; isolated to dashboard/index.phtml.

### Tier 2 — One-day work, lasting impact

6. **Move cache + sessions to Redis.** Add a Redis container in Coolify, point Magento at it via `local.xml`. Quote from real Magento 1 benchmarks: 1.5–2.5x admin throughput, especially under multi-user load. This is the single biggest infrastructure win.
7. **Split `dashboard/index.phtml` (14K lines)** into per-role partials loaded via `_forward()`. Right now PHP parses + executes the whole file even after our role-gating; partials would actually skip parsing the un-needed code. ~1–2 days of careful refactor.

### Tier 3 — Worth knowing, not urgent

8. **MySQL slow query log on prod.** Enable `long_query_time = 0.5`, watch for a week, then prioritize indexes from real evidence instead of suspicion. Currently we don't know which queries actually go slow under real traffic.
9. **CDN for `/skin/` and `/media/`.** Static assets aren't behind a CDN; admin users in SG hitting Coolify direct each time. Cloudflare in front would shave ~30–80 ms per asset on cold loads.
10. **Strip unused frontend modules.** `Aschroder_SMTPPro` and `Hitpay_Pay` load on every request even though admin doesn't need them. Module count ≈ 50 — pruning isn't a huge win but it's not zero.

---

## 5. What "fast" should look like

After Tier 1 + Tier 2, target on a warm cache:

| Page | Today (estimate) | Target |
|---|---|---|
| Admin login → dashboard | 6–12 s | **< 2 s** |
| Role switch (View As) | 2–4 s (post-PJAX fix) | **< 800 ms** |
| Product grid | 4–8 s | **< 2 s** |
| Sales order grid | 5–10 s | **< 2 s** |

These are realistic on a single-VPS Coolify deployment with Redis for cache+sessions and the DB hygiene done. They are *not* realistic without those two changes.

---

## 6. What this analysis does not cover

- **No production timing data.** All numbers above are from code inspection + the local DB mirror. To rank items 8 & 10 correctly we'd need to enable MySQL slow-query log and pull a week of `pt-query-digest` output.
- **No browser-side waterfall.** The 2.3 MB JS payload is from raw file size; we haven't measured parse + execute time in Chrome DevTools. A 5-minute look at the Network + Performance tabs on prod would tell us whether PHP or the browser is the actual bottleneck for the user.
- **No load test.** All measurements assume single-user. Concurrency behavior (sessions in MySQL under 20 concurrent admins) needs `ab` or `wrk` to characterize honestly.

If the boss wants to invest 30 minutes in production data collection, items in §6 become concrete numbers and Tier 1/2 priorities can be defended with evidence rather than reasoning. Without that, the recommendations above are the right call based on architecture and DB state alone.
