---
name: search-term-redirect
description: Point on-site search terms at a specific course page via catalogsearch_query.redirect. Use when asked to "redirect <search term> to <URL>", "when people search X send them to Y", "the search for X goes to the wrong course", "fix the search redirect", or "add a search term redirect". ALWAYS applies the change LIVE on the production server first (search redirects are data, not code, and a shipped migration alone does NOT fix an already-populated prod row), then ships a matching idempotent migrations/NNN-*.sql so a rebuilt DB keeps the state. SG production by default; partner-safe via store guard.
---

# Search-term redirects (catalogsearch_query.redirect)

On-site search redirects are **data, not code**. A user searching a term whose
`catalogsearch_query.redirect` is set gets a 302 straight to that URL instead of
a results page.

## The three rules that matter most

**1. ALWAYS apply live on prod.** Shipping a migration is necessary but NOT
sufficient. Prod's `catalogsearch_query` is populated by real searchers and
diverges hard from localhost. Verify on the live domain before reporting done.

**2. A correction must OVERWRITE; only a fill uses the empty-only guard.**
This is where this task goes wrong most often — see the incident below.

**3. Follow the target to its FINAL status — `200` on the first hop is not
enough.** A redirect target that returns `301` may chain into a `404`. Always
curl with `-L` and check the final code, then confirm the destination course is
actually enabled (`status = 1`) / the category is `is_active = 1`. A 301 to a
retired course is still a dead end. See "The 404 sweep" below.

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
# first hop AND final destination -- a 301 can chain into a 404
curl -sS -o /dev/null -w "first=%{http_code} -> %{redirect_url}\n" '<TARGET_URL>'
curl -sS -o /dev/null -w "final=%{http_code}\n" -L '<TARGET_URL>'
```

The **final** code must be **200**. A target that 404s — or 301s into a 404 —
re-introduces the dead end. Prefer a product page; a flat category page is
second-best; never a homepage bounce.

If the first hop is a 301, prefer redirecting the search term **straight at the
final URL** so users take one hop instead of two.

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
  WHERE store_id=1 AND NOT (redirect <=> ?)
    AND (LOWER(query_text) LIKE '%<KEYWORD>%')\\\", array(\\\$tgt, \\\$tgt))->rowCount();
echo 'rows updated: ',\\\$n,PHP_EOL;
\""
```

`NOT (redirect <=> ?)` is the **NULL-safe** guard — it fills unset rows AND
overwrites wrong ones, while no-opping on rows already correct. A bare
`redirect <> ?` silently skips every `redirect IS NULL` row, because
`NULL <> 'x'` is NULL, not TRUE. That trap has bitten three times (2026-08-16
agentic-AI-for-HR, 2026-08-17 IoT, 2026-08-17 genai-SEO) — each time the
user's own literal search term was one of the skipped rows.

**Never trust `rowCount()`** — MySQL counts *changed* rows, so `0` never means
"already correct". Always re-SELECT the matched rows afterwards (step 4).

Beware the flip side: because this guard fills NULL rows, a loose `<KEYWORD>`
sweeps in every unrelated term that happens to contain it. Keep the pattern
tight, and run a **collateral check** — rows now pointing at the target that
do *not* match the topic keyword must come back empty.

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
Use the **NULL-safe** `NOT (redirect <=> @tgt)` for a correction:

```sql
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := '<TARGET_URL>';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (LOWER(query_text) LIKE '%<KEYWORD>%');
```

> **Never write a bare `redirect <> @tgt`.** In SQL three-valued logic
> `NULL <> 'x'` is NULL, not TRUE, so it silently skips every row where
> `redirect IS NULL` — precisely the empty rows a fill must populate. This bug
> shipped twice (2026-08-16, 2026-08-17). `NOT (redirect <=> @tgt)` fills unset
> rows AND overwrites wrong ones in one guard.
>
> Also: `rowCount()` counts *changed* rows, not *matched* — `0` never proves
> "already correct". Re-SELECT the rows to confirm actual state.

**The flip side of the NULL-safe guard: keep `<KEYWORD>` tight.** Because it
fills unset rows, a generic pattern captures every empty row containing that
substring. A rebuilt DB has far more empty rows than today's prod, so a
migration that looked surgical live can mis-redirect dozens of unrelated
courses on restore — SG prod carries ~180 empty `%genai%` rows (`genai video`,
`genai hr`, `genai fintech`, …). For a generic keyword (`ai`, `genai`, `seo`),
use an explicit verified term list plus one tight course-title pattern instead
of a bare LIKE. Then run a **collateral check** — rows now pointing at the
target that do *not* match the topic keyword must return `count=0`. Worked
example: `migrations/1042-search-redirect-genai-seo.sql`.

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

## The 404 sweep (audit ALL redirects, not just the one you're editing)

Rot accumulates silently. A 2026-08-10 audit of SG prod found **141 of 1,269**
distinct redirect targets broken — 110 hard 404s plus 31 that 301-chained into
a 404 — affecting 834 search rows / 13,257 popularity. Users searching those
terms hit a dead end with no results and no way back.

Run this sweep whenever asked to "check the search terms for 404s", and after
any bulk course retirement or slug rename.

```bash
# 1. dump every distinct target with its traffic weight
ssh root@76.13.180.29 "docker exec <CONTAINER> php -r \"
require_once '/var/www/html/app/Mage.php'; Mage::app();
\\\$r = Mage::getSingleton('core/resource')->getConnection('core_read');
foreach(\\\$r->fetchAll(\\\"SELECT redirect, COUNT(*) c, SUM(popularity) pop FROM catalogsearch_query
  WHERE store_id=1 AND redirect IS NOT NULL AND redirect<>'' GROUP BY redirect ORDER BY pop DESC\\\") as \\\$x)
  echo \\\$x['c'],\\\"\t\\\",\\\$x['pop'],\\\"\t\\\",\\\$x['redirect'],PHP_EOL;
\"" > targets.tsv

# 2. check first hop AND final code for each (parallelise -- 1200+ URLs)
#    macOS split has no `-n r/N`; use `split -l N` and background the chunks.
```

**Diagnose before repairing.** Resolve each broken slug against prod's own
`core_url_rewrite` + live entity status. The 2026-08 sweep found the cause was
almost never bad redirect data — it was that the destination had been retired
(`status = 2`) or its category deactivated (`is_active = 0`).

Then split the broken set in two:

**A. The course was RENAMED (a live successor exists).** Repoint the search rows
at the new URL *and* add a 301 rewrite so the old course URL keeps working —
see the section below.

**B. The course is RETIRED with no successor.** Do **not** invent a
replacement. Set `redirect = NULL` so Magento serves live search results
instead of a 404. This is a genuine improvement: `rpa` went from a hard 404 to
HTTP 200 with 5 relevant courses. In the sweep all 732 affected terms returned
200 after clearing.

**Never auto-pick a replacement by fuzzy matching.** In the same sweep, token
scoring proposed `basic-tableau-training` → *basic-accounting-course*,
`linux-operating-system` → *robot-operating-system*, `adobe-xd` → *Adobe
Lightroom*, and `basic-electronics-for-kids` → *hydroponics*. Only accept a
match that is exact, a known prefix variant (`wsq-`/`casl-`/`ibf-`), or covers
**≥2 distinctive tokens** — and curl-verify each one returns 200 before writing
it. Everything else goes to bucket B. (memory
`feedback_autopopulate_fuzzy_search_redirects_wrong`)

**Only clear a target you have PROVEN dead.** A curl code of `000` is a timeout
or a network block from the audit host, not a 404 — leave those rows alone.

## Course URL renames must be a 301 (never a 404)

When a course's `url_key` changes, the old URL must **301 permanently** to the
new one. Otherwise every external backlink, bookmark, Google result and stored
search redirect breaks. Magento records renames in `core_url_rewrite`, but rows
go stale when a product is swapped, re-created, or its rewrite points at a
now-retired entity — the old slug then 404s.

`options = 'RP'` is what makes a rewrite a **301 permanent**; an empty
`options` is a 302 temporary. Always use `'RP'` for a rename.

```sql
-- repoint an existing rewrite to the new slug, as a 301
UPDATE core_url_rewrite
SET target_path = '<new-slug>.html', options = 'RP', is_system = 0
WHERE request_path = '<old-slug>.html' AND store_id IN (0, 1);

-- or create one when no row exists (store 0 = default scope, 1 = SG)
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
VALUES
  (0, CONCAT('manual-301-', MD5('<old-slug>.html'), '-0'),
   '<old-slug>.html', '<new-slug>.html', 0, 'RP');
```

Verify the old URL 301s **and** the final page is 200:

```bash
curl -sS -o /dev/null -w "%{http_code}"    'https://www.tertiarycourses.com.sg/<old-slug>.html'  # 301
curl -sS -o /dev/null -w "%{http_code}" -L 'https://www.tertiarycourses.com.sg/<old-slug>.html'  # 200
```

A rename is only finished when: the old URL 301s to a 200 page, the new URL is
200, and no `catalogsearch_query.redirect` still points at the old slug.

## Related memories

- `feedback_search_redirects_always_apply_live` — migration alone is not enough
- `feedback_search_redirect_guard_skips_wrong_targets` — the empty-only trap
- `feedback_prod_redirects_already_populated_guard_skips` — prod ≠ localhost
- `feedback_search_redirect_row_created_after_migration` — new rows appear later
- `feedback_edited_shared_migrations_never_rerun_on_prod`
