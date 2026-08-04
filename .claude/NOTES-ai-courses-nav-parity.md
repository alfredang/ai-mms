# AI Courses nav/filter parity — MY & GH vs SG (handoff notes, resume here)

Goal: make Malaysia (`tertiarycourses.com.my`) and Ghana (`tertiarycourses.com.gh`)
storefronts match Singapore's "AI Courses" top-nav item and its layered-nav
sidebar filters on `artificial-intelligence-courses.html`. All fixes are
DB-only, applied by pasting PHP snippets into each site's own Coolify terminal
(no direct SSH/DB access from this session — GH and MY are separate DBs per
the franchise one-store-per-site model; SG DB is not directly accessible at
all, only via public HTTP).

## ✅ Done and confirmed working (both GH and MY)

1. **Promoted "Artificial Intelligence" category to a top-level "AI Courses" nav item**,
   matching SG. Used `Category::move()` (NOT manual path/parent_id/level mutation —
   an earlier attempt at that corrupted the `path` field by omitting the category's
   own id; caught before it did real damage, verified EAV was untouched, fixed by
   switching to `move()` + forcing `Mage::app()->setCurrentStore(Mage_Core_Model_App::ADMIN_STORE_ID)`
   at the top of every script — raw CLI scripts without admin scope make
   `Mage_Catalog_Model_Category` pick the flat-catalog resource instead of EAV,
   which crashes outside a real admin/store request).
   - Renamed 6 pre-existing children to SG's "... Series" labels.
   - Created 3 new leaf categories (AI Security Series, Claude AI Series, Codex AI Series)
     matching SG's url_keys, and assigned any already-existing partner products into them
     (products that don't exist yet on that partner were skipped/logged — course porting
     is a separate job, not done here).
   - Script: `promote-ai-courses-nav.php` (recreate from this session's transcript if needed;
     not preserved anywhere durable — scratchpad is ephemeral).

2. **Fixed mega-menu → flat "classic" dropdown mismatch.** SG's "AI Courses" nav item
   renders as a flat list (no sub-columns); MY/GH were rendering as a mega panel because
   they inherited `umm_dd_type = 1` (MEGA) from before promotion. Fixed by setting
   `umm_dd_type = 0` on the "AI Courses" category (Infortis `Infortis_UltraMegamenu_Block_Navigation`:
   at nav level 0, `umm_dd_type = 0` falls through to the theme's own CLASSIC default).
   Confirmed via screenshot — now matches SG.

3. **Set `is_anchor = 1`** on "AI Courses" root + its 6 pre-existing children (the 3 new
   ones already got `is_anchor=1` at creation). Confirmed via diagnostic script this landed
   correctly in the DB on both sites. This alone did NOT fix the missing "Category" sidebar
   filter (see below).

4. **Set `is_filterable = 1`** on the `software` (Course Type: Funded/Non-funded) and
   `sessions` (Session (days)) product attributes on both sites. Reindexed
   `catalog_category_product`, `catalog_category_flat`, `catalog_product_attribute` + full
   cache flush. Confirmed via curl: `software`/"Course Type" already showed and still shows
   fine (single value "Non-funded" on both sites — that's expected, real data, not a bug).
   `sessions` still does NOT show (see open item below — this one is NOT a simple flag fix).

## ❌ Still broken — investigate next

### A. ✅ RESOLVED (Ghana confirmed live; Malaysia needs the same one-line fix)

**Real root cause, found 2026-07-14**: a single global admin config flag,
`ultramegamenu/sidemenu/hide_laynav_categories` (in `core_config_data`, `scope=default`,
`scope_id=0`), was set to `1` on Ghana. This flag drives an `ifconfig`-gated layout action in
`app/design/frontend/ultimo/default/layout/infortis_ultramegamenu.xml`, inside the
`catalog_category_layered` handle (the handle Magento's controller picks for any anchor
category that actually has products — which AI Courses does):
```xml
<reference name="catalog.leftnav">
    <action method="unsetChild" ifconfig="ultramegamenu/sidemenu/hide_laynav_categories">
        <alias>category_filter</alias>
    </action>
</reference>
```
When the flag is truthy, this **unconditionally strips the Category filter child block**
from the layered-nav sidebar — regardless of whether the underlying category/product data is
correct. This affects **every anchor category site-wide**, not just AI Courses.

Fix (already applied + confirmed working on Ghana):
```sql
UPDATE core_config_data SET value = '0'
WHERE path = 'ultramegamenu/sidemenu/hide_laynav_categories' AND scope = 'default' AND scope_id = 0;
```
Applied via the `core/resource` connection (not raw mysql client) + a Redis `FLUSHDB` on
**database 0 only** (cache; sessions are on db 1, untouched) since config cache lives there
and a generic `Mage::app()->getCacheInstance()->getFrontend()->clean()` alone did not
propagate the change (confirmed — this must be run explicitly). Verified via curl: the
"Category" facet now renders on `tertiarycourses.com.gh/artificial-intelligence-courses.html`
with all 9 Series + correct counts, matching SG.

**Confirmed applied and verified on BOTH Ghana and Malaysia** (2026-07-14) — same config flag
was set the same way on both (`value=1` at default scope), same fix applied (tables created,
config flipped to `0`, Redis db0 flushed), same result confirmed via curl: "Category" filter
renders correctly on both sites' AI Courses page with accurate per-series counts, matching SG.
MY correctly shows only 8 of 9 series (AI Security Series has 0 MY products — expected, that
course was never ported from SG, already logged as skipped by the original promotion script).

**Dead ends chased before finding this** (kept here so nobody re-walks them): confirmed
`is_anchor=1` was already correctly set in the DB and NOT the blocker; confirmed
`catalog_category_product_index` had fully correct, non-zero counts for all 9 categories
(so reindexing was never the issue); confirmed the actual filter block computes correct
data (`getItemsCount()=9`) when invoked directly in a properly-scoped test — proving the
backend logic was always fine and the block was being suppressed further upstream, in
layout XML, not in PHP data/logic. Also discovered along the way (harmless, real, and now
fixed regardless): Ghana's DB was completely missing the stock `catalogindex_aggregation`
tables (used for Magento's "Layered Navigation Cache"). Not the actual root cause of this
specific bug (that cache path is a no-op when disabled/tables absent — Magento just computes
fresh every time either way), but a genuine schema gap worth having anyway — captured as
repo migration `migrations/336-create-missing-catalogindex-aggregation-tables.sql` (idempotent,
`CREATE TABLE IF NOT EXISTS`, applies automatically on next deploy to any site missing them).

### B. ✅ RESOLVED (both Ghana and Malaysia confirmed live)

**Real answer, found 2026-07-14**: `sessions` was a red herring. Checked SG directly —
SG's `sessions` attribute (attribute_id=151) is configured **identically** to GH/MY: plain
`varchar`/`text`, `is_filterable=0`, no source model. It was never the attribute powering the
"Session (days)" facet anywhere, including on SG.

The real attribute is `progromming_language` (attribute_id=195 on all three sites — a
pre-existing, oddly-named/misspelled attribute, presumably originally meant for something
programming-language-related, repurposed and relabeled "Session (days)"). It's already fully
configured correctly on **both GH and MY** — `backend_type=int`, `frontend_input=select`,
`is_filterable=1`, and the exact same 5 options (1–5, with matching option_ids 151/309/150/148/308)
as SG. Someone had already done that setup work; **zero products just had a value actually set
for it** on either partner site — a pure data gap, not a schema gap. No attribute-type
migration was needed at all (the feared blast-radius risk in the original plan below never
applied — leaving the plan text for reference/pattern-reuse if a real migration is ever
needed elsewhere).

Fix: backfilled `progromming_language`'s per-product value from each product's already-known-
correct `sessions` text value ("1".."5" → matching option_id), via
`INSERT ... ON DUPLICATE KEY UPDATE` into `catalog_product_entity_int`
(entity_type_id=4, attribute_id=195, store_id=0). 494 products updated on GH, 0 skipped;
similar clean run on MY. Reindexed `catalog_product_attribute` + `catalog_category_product` +
`catalog_category_flat`, cleaned Magento cache + Redis db0. Verified via curl: "Session (days)"
now renders with all 5 options and correct counts on both sites, matching SG.

<details>
<summary>Original migration plan (superseded — kept for reference only, not executed)</summary>

Was originally worried this would require a genuine attribute-type conversion (varchar →
select or decimal), which is real, both because it's a fully global attribute (any error
would have site-wide blast radius) and because changing `backend_type` mid-flight requires
moving existing data across physically different EAV value tables, not just flipping a
column. That concern was correct in principle — it just turned out not to apply here, because
the target attribute already existed pre-configured correctly. If a similar situation arises
where the migration is genuinely needed: create matching `eav_attribute_option` rows if
missing, migrate `catalog_product_entity_varchar` values to `catalog_product_entity_int`
(for `select`) or `catalog_product_entity_decimal` (for `decimal`) via the real attribute
model APIs (never a raw `eav_attribute.backend_type` UPDATE alone — that orphans existing data
in the old table without moving it), update `backend_type`/`frontend_input`/`source_model` to
match, then reindex + flush.
</details>

### C. ✅ RESOLVED (both Ghana and Malaysia confirmed live)

Checked SG directly instead of guessing between the 3 originally-proposed options — turned
out SG did none of them. All 8 matching grandchild categories on SG are still fully
`is_active=1` and still hold their products directly (2–40 products each, nothing moved or
deleted) — the **only** difference is `include_in_menu=0`. 3 categories (AI Ethics &
Governance, Low Code AI Agent Platforms, Full Code AI Agent Platforms) don't exist on SG at
all but DO have real courses on GH/MY (1, 4, 5 products respectively) — user chose to hide
these the same way (`include_in_menu=0`) rather than delete, since deleting wasn't really
"matching SG" so much as an unrelated content decision outside scope.

This corrected an earlier wrong conclusion from a pure code-read: initially traced
`Infortis_UltraMegamenu_Block_Navigation`'s render function and saw it only checks
`getIsActive()` on children, not `include_in_menu` — concluded `include_in_menu` couldn't be
the lever. That was incomplete: the children LIST itself is built earlier via
`getChildrenNodes()` (flat-catalog tree walk, used when flat catalog is enabled), which DOES
filter by `include_in_menu` before the render function ever sees the list. SG's real behavior
proved this empirically; the static code trace alone would have led to the wrong (more
destructive) fix.

Applied: `include_in_menu = 0` on all 11 grandchild categories (Prompt Engineering, GenAI
Content Creation, GenAI Video Creation, RAG & Fine Tuning, AI Ethics & Governance, Copilot
Studio Agents, n8n AI Automations, Low Code AI Agent Platforms, Full Code AI Agent Platforms,
Computer Vision, Reinforcement Learning) on both GH and MY, + `catalog_category_flat` reindex
+ cache/Redis db0 flush. Verified via curl: no `nav-item--parent` class on any of the 9
top-level Series items on either site — zero arrows, matching SG exactly.

**Bonus fix found while verifying**: the AI Courses dropdown panel was rendering at
`width:800px` (leftover `umm_dd_width` category attribute from before promotion, when this
was a wide mega panel) vs SG's `width:260px`. Set `umm_dd_width='260px'` on the "AI Courses"
category on both sites — confirmed via curl, panel width now matches SG exactly.

**Gotcha hit mid-fix, worth remembering**: after running the `include_in_menu` fix on Ghana,
moved on to the width question before confirming the SAME `include_in_menu` fix had actually
been run on Malaysia — it hadn't (only the width fix got run there initially). Always verify
each fix landed on BOTH sites independently before moving to the next item; don't assume
parity between GH/MY just because one was confirmed.

## All three items (A, B, C) are now fully resolved and verified live on both Ghana and
## Malaysia as of 2026-07-14. Nothing outstanding on this task unless new drift is found.

## Environment gotchas learned this session (don't re-discover these)

- **Local Docker sandbox is unreliable for this work**: the local `ai-mms-web-1` container's
  PHP CLI hangs indefinitely on an Xdebug remote-debug handshake (`wchan=request_wait_answer`)
  that never resolves (no debugger client listening) — every `docker exec ... php ...` call
  eventually times out or the whole Docker daemon on this Mac goes flaky (saw literal
  `500 Internal Server Error` from the Docker API mid-session). This is 100% local-only and
  irrelevant to GH/MY's actual production containers, which run these same scripts fine. Don't
  waste time trying to validate against local Docker for this task — read source code directly
  and use read-only live diagnostics instead, or just accept the risk on a well-reasoned change.
- **No SSH/DB/API access to GH, MY, or SG from this session.** All fixes are delivered as
  copy-pasteable PHP heredoc blocks that the user runs directly inside each site's own Coolify
  web-container terminal (Coolify's terminal drops you inside the container already — no
  `docker exec`/`docker cp` available or needed there).
- GH and MY share the same category entity_id scheme in some cases coincidentally (both are
  clones of the same SG seed) but NOT reliably — always resolve categories/attributes by
  `url_key`/`attribute_code`, never hardcode entity/attribute ids across sites.
