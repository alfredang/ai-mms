---
name: category-ordering
description: Enforce the storefront category listing order — WSQ (TGS- SKU) courses first, then non-WSQ (C- SKU) courses ALPHABETICALLY by course name, then partner (M-prefix / other) last — in EVERY category. Also covers DISABLING an empty category (no products on the storefront). Use when asked to "sort courses in a category", "WSQ first", "list WSQ courses before non-WSQ", "order the category alphabetically", "fix the course order on a category page", "disable this empty category", "hide the empty category", or after adding/renaming a course that must slot into the right place in its category listing. Delivered as an idempotent migrations/NNN-*.sql that renumbers catalog_category_product.position AND mirrors it into catalog_category_product_index. Partner-safe (no SKU list; prefix convention holds on every site).
---

# Category ordering (WSQ-first, non-WSQ alphabetical)

The **hard rule** for every category listing on every storefront (SG/MY/GH):

1. **WSQ** courses first — SKU `TGS-%`. Existing relative order preserved.
2. **Non-WSQ** courses next — SKU `C%`. Ordered **alphabetically by course name**.
3. **Everything else** last — partner `M`-prefix / other. Existing order preserved.

The alphabetical key is the product `name` at `store_id = 0`. Because AI Vibe
Coding course names share the `AI Vibe Coding ...` stem, and Microsoft cert
courses start with the exam code (`AI-102`, `AZ-104` ...), alphabetical reads
naturally as topic/exam-code order.

## HARD RULE — never name a flat table in a migration (it 502s every site)

**There is NO `catalog_category_flat` table. There is NO `catalog_product_flat`
table.** Flat data lives ONLY in per-store tables — `catalog_category_flat_store_1`,
`_store_2`, … — and **which of those exist differs per site** (SG carries
`_store_1..7`, leftovers from the retired multi-store install; MY/GH have their
own sets). Bare `catalog_category_flat` is the **indexer code**, valid only in a
PHP `Mage::getModel('index/process')->load('catalog_category_flat', …)` call —
never a table name in SQL.

Naming a table that doesn't exist is **not a localized failure**:
`apply.php` aborts the entire chain on the first failed statement → the
container exits non-zero → Coolify serves nothing → **every route on the site
returns 502**, not just the page you were changing.

> Real outage 2026-07-18. Migration 590 mirrored a category rename into
> `catalog_category_flat`. SG and MY went fully dark and stayed down through all
> 12 entrypoint retries. Reported as "/blog is showing bad gateway" — the whole
> site was down. Signature in `docker logs <app>`:
> `SQLSTATE[42S02] ... Table 'default.catalog_category_flat' doesn't exist`
> followed by `migration attempt N failed`.

**Two valid ways to make the change land. Pick one — never hardcode a table.**

*Option A — EAV only, then reindex (simplest; use for renames).* The EAV rows
are the source of truth and the storefront picks the change up on the Category
Flat Data reindex, which is already the documented post-deploy step below. This
is what fixed migration 590.

*Option B — EAV + guarded flat mirror (use when the change must land WITHOUT a
reindex).* The storefront reads flat, so if no reindex will run, EAV alone
leaves the page stale. Mirror into flat, but **guard every statement with
`information_schema`** so a table missing on this instance is a clean no-op
instead of a site-wide 502:

```sql
SET @sql = IF((SELECT COUNT(*) FROM information_schema.TABLES
               WHERE TABLE_SCHEMA=DATABASE()
                 AND TABLE_NAME='catalog_category_flat_store_1')>0,
  "UPDATE catalog_category_flat_store_1 SET name='WSQ Funded Courses' WHERE name='WSQ Courses'", 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
```

Repeat per store (SG=1, MY=2, GH=3). The `megamenu-structure` skill uses
exactly this guarded form — see its "Dual write" section and
`migrations/553-menu-classical-scope-to-adult-courses.sql`. **The guard is the
whole point**: 590 did an unguarded flat write and took two sites down.

What is never acceptable, in either option, is a bare `catalog_category_flat`
or an unguarded `catalog_category_flat_store_N`.

Note this is the *opposite* of the `catalog_category_product_index` rule in the
next section: that index table **does** exist on every instance and **must** be
written directly. The distinction is existence, not preference — index tables
are unconditional, flat tables are per-store and conditional.

**Before pushing any migration**, dry-run the real runner (never the `mysql`
client, which tolerates things `apply.php` won't):

```bash
docker exec ai-mms-web-1 php /var/www/html/migrations/apply.php   # must print OK
```

**If a site is already 502ing on a bad migration**, don't wait for a deploy:
apply the corrected SQL directly to the prod DB, `INSERT IGNORE` the filename
into `schema_migrations`, `docker restart` the app container — then commit the
fix so the next deploy doesn't re-run the broken statement. (Editing the
migration in place is safe here *only* because a failed migration is never
recorded as applied, so it re-runs fresh everywhere.)

## Why two tables — and why you must renumber the INDEX directly

The storefront sorts by **`catalog_category_product_index.position`**, NOT by
`catalog_category_product.position`. There is **no PHP reindex hook at deploy**
(see `feedback_flat_catalog_reindex`), so a migration must write BOTH:
- `catalog_category_product.position` — the source of truth (admin-facing).
- `catalog_category_product_index.position` — what the listing actually reads,
  for **every `store_id` present on this instance** (SG=1; MY adds 2; GH adds 3).

**CRITICAL GOTCHA (the anchor-inheritance bug).** The index contains rows that
have **no matching `catalog_category_product` base row** — products that surface
in a category only by **anchor inheritance** (an anchor/parent category shows its
child categories' products). Early ordering migrations (539/542) renumbered the
base table then mirrored into the index with an INNER JOIN:

```sql
UPDATE index idx JOIN catalog_category_product cp ON (category_id, product_id) ...
```

That join **skips the anchor-inherited rows**, leaving them at stale positions
(seen as `20015`, `20016` …), which sorts them to the BOTTOM. Real incident:
WSQ courses (CompTIA CySA+, "Navigating Digital Threats") fell below non-WSQ
courses on cyber-security page 2 even though WSQ must always be on top.

**Fix: renumber `catalog_category_product_index` DIRECTLY** (self-contained — no
dependency on the base table), grouped per `(category_id, store_id)`. Then
renumber the base table separately for the admin view.

## Canonical implementation

`migrations/545-category-ordering-index-selfcontained.sql` is the live rule and
the file to **copy for any future reorder**. It renumbers the index directly
(covering anchor-inherited rows) AND the base table, to a dense `1..N` per
category. Idempotent. It supersedes:
- `539-wsq-first-category-ordering.sql` (per-category alpha, only 135/358), and
- `542-non-wsq-alpha-ordering-all-categories.sql` (universal alpha but had the
  INNER-JOIN anchor bug).

**Do not re-add per-category special cases** and **do not copy 539/542** — 545 is
canonical. The sort expression (applied to the index, per category+store):

```sql
ORDER BY
  i.category_id ASC,
  i.store_id ASC,
  CASE WHEN e.sku LIKE 'TGS-%' THEN 0 WHEN e.sku LIKE 'C%' THEN 1 ELSE 2 END ASC,
  CASE WHEN e.sku LIKE 'TGS-%' THEN i.position END ASC,          -- WSQ keep relative order
  CASE WHEN e.sku LIKE 'TGS-%' THEN NULL ELSE nv.value END ASC,  -- non-WSQ alphabetical
  i.product_id ASC
```

## When to ship a fresh ordering migration

The order is **data-derived** — adding, renaming, disabling, or re-categorising a
course does NOT auto-reorder its category. After any such change, re-apply the
ordering so the new/renamed course lands in the right alphabetical slot. Two
options:

- **Preferred** — ship a NEW `migrations/NNN-reorder-<reason>.sql` that is a
  verbatim copy of **545's** two UPDATE statements (the ledger tracks by
  filename; an edited already-applied file never re-runs on prod — see
  `feedback_edited_shared_migrations_never_rerun_on_prod`). Copy 545, rename,
  push.
- **Local re-test** — clear 545's ledger row and re-run `apply.php` (all
  statements are idempotent):
  ```bash
  docker exec ai-mms-web-1 php -r "require '/var/www/html/app/Mage.php'; Mage::app();
    Mage::getSingleton('core/resource')->getConnection('core_write')
      ->query(\"DELETE FROM schema_migrations WHERE filename='545-category-ordering-index-selfcontained.sql'\");"
  docker exec ai-mms-web-1 php /var/www/html/migrations/apply.php
  ```

## Verify (localhost)

Check the index order for one category (store_id 1 = SG), enabled products only:

```sql
SELECT idx.position, e.sku,
  CASE WHEN e.sku LIKE 'TGS-%' THEN 'WSQ' WHEN e.sku LIKE 'C%' THEN 'non-WSQ' ELSE 'other' END grp,
  nv.value
FROM catalog_category_product_index idx
JOIN catalog_product_entity e ON e.entity_id=idx.product_id
LEFT JOIN catalog_product_entity_varchar nv ON nv.entity_id=e.entity_id AND nv.store_id=0
  AND nv.attribute_id=(SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=4)
JOIN catalog_product_entity_int s ON s.entity_id=e.entity_id AND s.store_id=0
  AND s.attribute_id=(SELECT attribute_id FROM eav_attribute WHERE attribute_code='status' AND entity_type_id=4)
WHERE idx.category_id=<CAT_ID> AND idx.store_id=1 AND s.value=1
ORDER BY idx.position;
```

Expect: all WSQ rows first, then non-WSQ rows in A→Z `name` order, then M/other.
On prod after deploy, flush Redis / run the reindex API so the flat + block/FPC
caches pick up the new positions.

## Guardrails

- **Partner-safe**: no SKU list — the `TGS-`/`C`/`M` prefix convention holds on
  every site, and `M`-prefix (partner) SKUs always sort last. WSQ product DATA is
  never touched; only listing order changes.
- **Never** reorder by anything other than the three-group + alpha rule (no
  manual position pinning, no featured-first hacks) — the whole point is a single
  predictable rule across the whole catalog.

## Disabling an empty category

When a category renders empty on the storefront (all its C-courses disabled /
retired), disable it so it drops off the listing pages and the mega-menu. Set
BOTH `is_active = 0` and `include_in_menu = 0` at `store_id = 0`. The category
page then returns 404.

**Emptiness test = the storefront INDEX, not a store-0 status count.** Check
`catalog_category_product_index` for the category (all stores on this instance):

```sql
SELECT COUNT(*) FROM catalog_category_product_index WHERE category_id = <CAT>;
```

Why the index and not `catalog_product_entity_int.status`: **M-prefix (partner)
products carry `status = 1` at `store_id = 0` but are excluded from SG's
storefront index** — so a store-0 status count would falsely report the category
as non-empty on SG. The index is what the listing actually reads, so it is the
true emptiness test AND it is naturally partner-correct (on a partner site the
live SDN course IS in that store's index).

**Make the disable CONDITIONAL** so the shared migration is partner-safe — it
must no-op on any site where the category still has an indexed product:

```sql
SET @cat := (SELECT uk.entity_id FROM catalog_category_entity_varchar uk
  JOIN eav_attribute ea ON ea.attribute_id=uk.attribute_id AND ea.entity_type_id=3 AND ea.attribute_code='url_key'
  WHERE uk.store_id=0 AND uk.value='<url-key>' LIMIT 1);
SET @a_active := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='is_active');
SET @a_menu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='include_in_menu');
SET @indexed  := (SELECT COUNT(*) FROM catalog_category_product_index WHERE category_id=@cat);

UPDATE catalog_category_entity_int SET value=0
WHERE entity_id=@cat AND store_id=0 AND attribute_id=@a_active AND @indexed=0 AND @cat IS NOT NULL;
UPDATE catalog_category_entity_int SET value=0
WHERE entity_id=@cat AND store_id=0 AND attribute_id=@a_menu   AND @indexed=0 AND @cat IS NOT NULL;
```

Resolve the category by **url_key** (partner-safe; ids differ per site). After
deploy, reindex `catalog_category_flat` + `catalog_url` and flush block/FPC so
the page 404s and the menu drops the item.

**Catalog-parity model (why one migration fits all sites).** Non-WSQ (C-prefix)
courses and the category tree are the SAME across SG/MY/GH; SG additionally
carries WSQ + IBF (TGS-prefix). Consequences the empty-disable relies on:
- A category empty on SG is empty on MY/GH too (same C-catalog) → disable everywhere.
- MY/GH have NO WSQ courses, so a category populated on SG **only** by WSQ courses
  is empty on MY/GH → the SAME conditional migration disables it there
  automatically (the guard is per-instance index count).
- SG must not carry HRDF/Malaysia-only categories (e.g.
  `recommended-hrdf-courses-malaysia`) — empty on SG, so disabled there.

**Reference implementations:**
- `migrations/550-disable-empty-categories-storefront.sql` — the canonical
  MULTI-category form. A temp-table **url_key allow-list** of course-listing
  categories, each disabled only where its storefront index is empty on that
  instance. Copy this to disable a new batch — extend the `VALUES (...)` list.
- `migrations/548-disable-empty-sdn-category.sql` — the original single-category
  form (SDN, 199).

**NEVER disable a non-product menu category.** Landing-page categories (Enquiry,
Refund Request, Assessment Appeal Form, Pearson Vue Exams, Associate Trainer,
Pages, etc.) are empty by design — functional form/CMS menu links. The migration
uses an **explicit url_key allow-list of course-listing categories only**, so a
landing page can never be caught. Do NOT switch to a "disable every empty active
category" sweep — it would kill the whole utility menu.

## Curated per-category overrides — DEAD since the nightly cron (2026-07-18)

> **STATUS 2026-07-29: curated NON-WSQ overrides no longer stick.** The daily
> `MMD_RoleManager_Model_Cron_CategoryOrdering` sweep (01:00 UTC, shipped
> 2026-07-18) re-applies the canonical rule nightly with NO curated exemption,
> so any non-WSQ pin (positions 101+) is flattened back to alphabetical within
> a day — verified on prod 2026-07-29: `claude-ai-series` is pure alphabetical
> despite re-apply 741. The owner's 2026-07-29 request ("sort non-funded
> courses alphabetically") endorses alphabetical, so DO NOT ship curated
> re-apply migrations any more — they are dead within 24h. WSQ (TGS-) pins DO
> survive (the sweep preserves TGS relative order — the 784/785/786 pattern).
> If a curated non-WSQ order is ever wanted again, the cron itself needs a
> curated-exemption first. Historical context below.

Some categories deliberately override the canonical alphabetical non-WSQ order
with a hand-curated sequence at positions 101+ (safely after the WSQ block):

- `claude-ai-series` — 648/650/656 pattern: Masterclasses first
  (C1417 Code, C1382 Cowork, C201 Design, C197 Microsoft 365), then the
  certifications (C744, C437, C364, C439).
- `python-programming` — 642: C138, C193, C179, C539, C188.
- `react-js-courses` — 645: C1143, C1800.

**HARD RULE:** the canonical global reorder (545/613 pattern) flattens these
back to alphabetical. Whenever you ship or run a global reorder — or any
migration that re-runs it — you MUST ship a re-apply migration in the SAME
push that re-issues the curated position writes (copy
`migrations/656-reapply-curated-orders-2.sql` to a new number). This has been
missed twice on 2026-07-21 alone (613 backlog deploy, then a parallel
session's 651/652 rollout); each miss silently re-alphabetised the storefront.
When curating a NEW category, add it to the list above AND to the re-apply
template.
