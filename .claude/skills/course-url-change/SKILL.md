---
name: course-url-change
description: Change a course's URL slug (url_key) safely, so the OLD url 301-permanently redirects to the new one and nothing 404s. Use when asked to "rename the course url", "change the url key/slug", "the old course link is broken/404", "add a 301 redirect for this course", "we renamed a course - fix the links", or after a WSQ->CASL / course-repurpose rename. Also covers auditing the whole site for course URLs that 404. SG production by default; partner-safe via store guard.
---

# Course URL (url_key) changes — always a 301, never a 404

Changing a course's `url_key` breaks every external backlink, Google result,
bookmark, email link and stored search redirect pointing at the old URL —
unless the old URL **301 permanently** redirects to the new one.

**The rule: a course URL change is not finished until the old URL returns 301
and following it lands on a 200 page.**

## Why this goes wrong

Magento writes a rewrite row on rename, but it goes stale when:

- the product is disabled and replaced by a new product (the old rewrite still
  points at the retired `catalog/product/view/id/<old>`),
- a WSQ→CASL / repurpose flow creates a *new* product instead of renaming,
- the rewrite's `options` column is empty — that is a **302 temporary**, not a
  301, so search engines never transfer ranking,
- `catalog_url_rewrite` reindex regenerates rows and drops a manual one.

A 2026-08-10 SG audit found **141 of 1,269** search-redirect targets broken:
110 hard 404s plus 31 that 301-chained *into* a 404. Root cause in nearly every
case was a destination course that had been retired or renamed without a
working 301.

## The `options` column IS the 301

| `options` | Behaviour |
|-----------|-----------|
| `'RP'`    | **301 Moved Permanently** — use this for every rename |
| `''`/NULL | 302 Temporary — ranking is NOT transferred |

`is_system = 0` marks the row as manual so a reindex is less likely to clobber
it. Write both `store_id = 0` (default scope) and `store_id = 1` (SG).

## Procedure

### 1. Establish the old and new slug, and confirm the new one is live

```bash
curl -sS -o /dev/null -w "new: %{http_code}\n" 'https://www.tertiarycourses.com.sg/<new-slug>.html'
curl -sS -o /dev/null -w "old: %{http_code} -> %{redirect_url}\n" 'https://www.tertiarycourses.com.sg/<old-slug>.html'
```

The **new** URL must be 200 before you point anything at it. Confirm the target
product is enabled (`status = 1`) — a 301 to a disabled course still 404s.

### 2. Inspect the existing rewrite rows

```bash
ssh root@76.13.180.29 "docker exec <CONTAINER> php -r \"
require_once '/var/www/html/app/Mage.php'; Mage::app();
\\\$r = Mage::getSingleton('core/resource')->getConnection('core_read');
foreach(\\\$r->fetchAll(\\\"SELECT url_rewrite_id, store_id, request_path, target_path, options, is_system
  FROM core_url_rewrite WHERE request_path LIKE '<old-slug>%'\\\") as \\\$x)
  echo \\\$x['url_rewrite_id'],' | store=',\\\$x['store_id'],' | ',\\\$x['request_path'],
       ' -> ',\\\$x['target_path'],' opt=[',\\\$x['options'],']',PHP_EOL;
\""
```

Watch for a `target_path` of `catalog/product/view/id/<N>` pointing at a
**retired** product — that is the classic silent 404.

### 3. Apply live on prod, then ship the migration

Same shape as the migration below; apply on prod first, verify, then commit the
numbered `.sql` so a rebuilt DB keeps the state.

```sql
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- repoint an existing rewrite and force it to 301
UPDATE core_url_rewrite
SET target_path = '<new-slug>.html', options = 'RP', is_system = 0
WHERE @sg = 1 AND request_path = '<old-slug>.html' AND store_id IN (0, 1);

-- create the row when none exists (both scopes)
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5('<old-slug>.html'), '-', s.store_id),
       '<old-slug>.html', '<new-slug>.html', 0, 'RP'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @sg = 1
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.request_path = '<old-slug>.html' AND x.store_id = s.store_id);
```

`id_path` must be unique — deriving it from `MD5(old_slug)` keeps the migration
idempotent and collision-free.

Dry-run with the real runner, never the `mysql` client:

```bash
docker exec ai-mms-web-1 php /var/www/html/migrations/apply.php   # "applying: NNN ... OK"
```

### 4. Update anything else that stored the OLD url

A 301 fixes inbound links, but stored references should point straight at the
new URL so users take one hop instead of two:

```sql
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/<new-slug>.html'
WHERE store_id = 1 AND redirect = 'https://www.tertiarycourses.com.sg/<old-slug>.html';
```

Also grep CMS blocks/pages and the mega-menu (`umm_cat_target`) for the old slug.

### 5. Verify — old 301s, final 200, new 200

```bash
for s in '<old-slug>' '<new-slug>'; do
  printf '%-60s ' "$s"
  printf 'first=%s ' "$(curl -sS -o /dev/null -w '%{http_code}'    "https://www.tertiarycourses.com.sg/$s.html")"
  printf 'final=%s\n' "$(curl -sS -o /dev/null -w '%{http_code}' -L "https://www.tertiarycourses.com.sg/$s.html")"
done
```

Old must be `first=301 final=200`. New must be `first=200`.

## Auditing the whole site for 404ing course URLs

When asked to "check all the course links / search terms for 404s":

1. Dump every distinct `catalogsearch_query.redirect` with its traffic weight.
2. curl each for **first hop and final code** (`-L`) — a 301 chaining into a
   404 is just as broken as a hard 404, and is invisible if you only check the
   first hop. Parallelise; macOS `split` has no `-n r/N`, use `split -l N`.
3. For each broken target, resolve it against `core_url_rewrite` + live entity
   status to learn *why*: retired product (`status = 2`), deactivated category
   (`is_active = 0`), or a genuine rename.
4. Repair per the two buckets in the `search-term-redirect` skill —
   **renamed** → 301 + repoint; **retired with no successor** → clear the
   redirect so search results show instead of a 404.

**Never guess a replacement course by fuzzy name matching.** Scoring once
proposed `basic-tableau-training` → *basic-accounting-course* and
`linux-operating-system` → *robot-operating-system*. Accept only exact matches,
known prefix variants (`wsq-`/`casl-`/`ibf-`), or ≥2 distinctive-token overlap
— and curl-verify each returns 200 before writing it.

**A curl code of `000` is a timeout, not a 404.** Never clear or repoint a row
on an unconfirmed target.

## Partner sites

WSQ/`TGS-` courses are SG-only, so the store guard makes those a no-op on
MY/GH. For a course that exists cross-site, add the 301 on each site pointing
at **its own domain** — never another partner's
(memory `feedback_partner_search_redirects_own_domain`).

## Related

- `search-term-redirect` skill — the `catalogsearch_query.redirect` side, incl.
  the full 404-sweep procedure
- `feedback_search_redirects_rot_when_course_disabled`
- `feedback_insert_ignore_swallows_rewrite_301s` — `INSERT IGNORE` silently
  no-ops when a rewrite row already exists; UPDATE the existing row instead
- `feedback_catalog_url_reindex_regenerates_disabled_category_301`
- `feedback_flat_url_collision_suffix_explosion`
