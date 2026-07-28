---
name: search-term-redirect
description: Point on-site search terms at a specific course page via catalogsearch_query.redirect. Use when asked to "redirect <search term> to <URL>", "when people search X send them to Y", "the search for X goes to the wrong course", "fix the search redirect", or "add a search term redirect". ALWAYS applies the change LIVE on the production server first (search redirects are data, not code, and a shipped migration alone does NOT fix an already-populated prod row), then ships a matching idempotent migrations/NNN-*.sql so a rebuilt DB keeps the state. SG production by default; partner-safe via store guard.
---

# Search-term redirects (catalogsearch_query.redirect)

On-site search redirects are **data, not code**. A user searching a term whose
`catalogsearch_query.redirect` is set gets a 302 straight to that URL instead of
a results page.

## The two rules that matter most

**1. ALWAYS apply live on prod.** Shipping a migration is necessary but NOT
sufficient. Prod's `catalogsearch_query` is populated by real searchers and
diverges hard from localhost. Verify on the live domain before reporting done.

**2. A correction must OVERWRITE; only a fill uses the empty-only guard.**
This is where this task goes wrong most often — see the incident below.

## The empty-only-guard trap (real incident, 2026-07-28)

CLSSYB redirect request. Localhost showed all 13 "yellow belt"/CLSSYB terms with
an **empty** redirect, so migration 823 used the repo's standard
`AND (redirect IS NULL OR redirect = '')` guard. Local verification passed
perfectly — all 13 terms 302'd correctly.

On **prod**, 11 of those same terms were **already populated**, pointing at the
WRONG course (the non-WSQ `certified-lean-six-sigma-yellow-belt.html`) —
including terms literally containing the word "WSQ". The empty-only guard
skipped every one. Prod behaviour did not change at all.

Worse, the user's exact query — `Certified Lean Six Sigma Yellow Belt (CLSSYB`
(unbalanced paren) — was a row **created after** the migration was written, so
no fixed exact-term `IN()` list could ever have matched it.

**Lessons encoded below: dump prod state first; overwrite for corrections;
match by LIKE pattern, not a frozen exact-term list.**

## Procedure

### 1. Identify the target and confirm it is reachable

```bash
curl -sS -o /dev/null -w "HTTP=%{http_code} -> %{redirect_url}\n" '<TARGET_URL>'
```

Must be **200**. A 301/302/404 target re-introduces the dead end. Prefer a
product page; a flat category page is second-best; never a homepage bounce.

Watch for **two similarly-named courses** (a WSQ `TGS-` and a non-WSQ `C-`
variant of the same subject is common). Confirm which one is intended before
writing anything — and check whether the other stays enabled.

### 2. Dump the REAL prod state (never trust localhost)

Find the SG container (Coolify names are hashed):

```bash
ssh root@76.13.180.29 "for c in \$(docker ps --format '{{.Names}}'); do \
  docker exec \$c test -f /var/www/html/app/Mage.php 2>/dev/null && echo \$c; done"
```

Then dump every related row — match broadly by keyword, not exact text:

```bash
ssh root@76.13.180.29 "docker exec <CONTAINER> php -r \"
require_once '/var/www/html/app/Mage.php'; Mage::app();
\\\$r = Mage::getSingleton('core/resource')->getConnection('core_read');
foreach(\\\$r->fetchAll(\\\"SELECT query_id, store_id, query_text, popularity, redirect
  FROM catalogsearch_query
  WHERE LOWER(query_text) LIKE '%<KEYWORD>%' ORDER BY popularity DESC\\\") as \\\$x)
  echo \\\$x['query_id'],' | pop=',\\\$x['popularity'],' | ',\\\$x['query_text'],' => [',\\\$x['redirect'],']',PHP_EOL;
\""
```

Read the output carefully: rows with a **non-empty but wrong** redirect are the
ones an empty-only guard will silently skip.

### 3. Apply live on prod

Use a **LIKE pattern**, not an exact-term list, so typo/paren variants and
rows created later are all covered:

```bash
ssh root@76.13.180.29 "docker exec <CONTAINER> php -r \"
require_once '/var/www/html/app/Mage.php'; Mage::app();
\\\$w = Mage::getSingleton('core/resource')->getConnection('core_write');
\\\$tgt='<TARGET_URL>';
\\\$n = \\\$w->query(\\\"UPDATE catalogsearch_query SET redirect=?, num_results=1, is_processed=1
  WHERE store_id=1 AND (LOWER(query_text) LIKE '%<KEYWORD>%')\\\", array(\\\$tgt))->rowCount();
echo 'rows updated: ',\\\$n,PHP_EOL;
\""
```

No cache flush is needed — the redirect is read per-search from the DB.

### 4. Verify live, including the user's exact wording

```bash
for q in "<term1>" "<term2>"; do
  printf '%-55s ' "$q"
  curl -sS -o /dev/null -w "%{http_code} -> %{redirect_url}\n" \
    "https://www.tertiarycourses.com.sg/catalogsearch/result/?q=$(echo "$q" | sed 's/ /+/g')"
done
```

Every one must be **302 → target**. Test the user's literal query verbatim,
including odd punctuation — that is the case most likely to be missing.

### 5. Ship the matching migration

So a rebuilt/restored DB keeps the state. Same LIKE pattern, plus the SG guard.
Use `redirect <> @tgt` (not the empty-only guard) for a correction:

```sql
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := '<TARGET_URL>';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND redirect <> @tgt
  AND (LOWER(query_text) LIKE '%<KEYWORD>%');
```

Dry-run with the real runner (never the `mysql` client):

```bash
docker exec ai-mms-web-1 php /var/www/html/migrations/apply.php   # must print "applying: NNN ... OK"
```

An **edited** migration never re-runs on prod — if a shipped one was wrong,
ship a NEW numbered file rather than editing it.

## Choosing which terms to redirect

- **Exact / branded terms** (course code, full title) — always safe.
- **Generic terms** (e.g. `yellow belt`) — these also match sibling courses. If
  both courses stay live, redirecting the generic term hides one of them from
  search. Flag this to the user rather than deciding silently.
- Match quality matters: drop a low-confidence term rather than ship a wrong
  redirect. Never bulk-autopopulate by fuzzy matching — that wrote ~10k wrong
  redirects once and had to be disabled (memory
  `feedback_autopopulate_fuzzy_search_redirects_wrong`).

## Partner sites

WSQ/`TGS-` courses are **SG-only**, so a WSQ target does not exist on MY/GH —
the store guard makes those a no-op. For a course that DOES exist cross-site,
redirect on each site to **its own domain** (memory
`feedback_partner_search_redirects_own_domain`); never point a partner search at
another partner's domain.

## Rot

Redirects go stale when a course is later disabled or its url_key changes —
the target then 404s. Re-validate targets when retiring or renaming a course
(memory `feedback_search_redirects_rot_when_course_disabled`).

## Related memories

- `feedback_search_redirects_always_apply_live` — migration alone is not enough
- `feedback_search_redirect_guard_skips_wrong_targets` — the empty-only trap
- `feedback_prod_redirects_already_populated_guard_skips` — prod ≠ localhost
- `feedback_search_redirect_row_created_after_migration` — new rows appear later
- `feedback_edited_shared_migrations_never_rerun_on_prod`
