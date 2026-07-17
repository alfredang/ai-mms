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

Reference implementation: `migrations/548-disable-empty-sdn-category.sql`
(disabled "Software Defined Networks (SDN)", category 199). Resolve the category
by **url_key** (partner-safe; ids differ per site). After deploy, reindex
`catalog_category_flat` + `catalog_url` and flush block/FPC so the page 404s and
the menu drops the item.
