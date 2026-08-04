# Category & course taxonomy parity — SG / MY / GH (handoff notes, resume here)

Goal: standardise MY (`tertiarycourses.com.my`) and GH (`tertiarycourses.com.gh`)
to match SG (`tertiarycourses.com.sg`), the agreed source of truth. Franchise
model = one DB per site, no live sync; all changes applied per-site via each
site's own Coolify terminal. SG's DB is also reachable read-only from a
Coolify terminal (confirmed 2026-07-20) — used to export its tree/catalog,
never written to.

## ✅ Phase 1 — category/nav structure sync: COMPLETE (2026-07-21)

All 5 branch-scoped chunks (Adult Courses/Infocomm, rest of Adult Courses, AI
Courses, Certification Exam Prep, Software Training) synced clean on both MY
and GH — names, parent placement, position, `is_anchor`, `display_mode`,
`include_in_menu`, `is_active`, all `umm_dd_*` UltraMegamenu attributes now
match SG. MY/GH-only extras hidden (`is_active=0`, `include_in_menu=0`),
never deleted. Bootcamp nav item removed (SG has none). Visual verification
pass done on both sites, confirmed matching SG.

Also created the 2 structurally-missing categories and ported cleaned-up SG
description content (dropping SG's own content bugs — broken meta fields on
Claude Cert Prep, SG-specific "Autodesk ATC" badge on Revit):
- **Claude Certification Exam Prep** — created on MY and GH, position fixed via
  `move()` (direct `setPosition()` on a fresh category is silently overridden
  by Magento's auto-append — `move($parentId, $afterCategoryId)` is the correct
  API). Image copied from SG on MY (confirmed live); **GH image copy is the
  only remaining loose end from Phase 1** — script written, run pending.
- **Autodesk Revit** — created on MY (GH already had it, just needed the sync
  pass). Position + image both confirmed live on MY.

Both new categories currently have **0 products** — that's why they show no
filter bar and no course grid; this is expected until Phase 2 below runs.

### Reusable mechanics from Phase 1 (keep for Phase 2)

- **Large JSON → remote container**: never paste single-line JSON through the
  browser Coolify terminal (corrupts above ~19KB). Always pretty-print
  (`JSON_PRETTY_PRINT`) and write via `cat > file.json << 'JSONEOF' ... JSONEOF`,
  validate with `json_decode()` before use.
- **Never match cross-site by `url_key` alone** — SG sometimes uses a different
  slug than MY/GH for the conceptually-same category (or product). Caused two
  wrongly-hidden-real-category incidents in Phase 1. Prefer a secondary key
  (SKU for products) and sanity-check any "extra"/"missing" list against known
  content before hiding anything.
- **New DB row position bug**: `setPosition()` before the first `save()` on a
  freshly-created row is silently overridden — use `move($parentId,
  $afterId)` for explicit ordering (categories; likely true for products too
  via `position` in `catalog_category_product` — verify in Phase 2).
- **`/tmp` scratch files don't survive a Coolify redeploy** — recreate heredocs
  if a script "Could not open input file" errors.
- **Cross-site image fetch**: `file_get_contents()` on a remote URL failed
  silently (`allow_url_fopen` likely off); curl without headers got HTTP 403
  (Cloudflare/WAF). Fix: curl with a real `CURLOPT_USERAGENT` + `Referer` +
  `Accept` headers. Working pattern in `copy-category-images-curl2.php`.

## ✅ Phase 2 — course content parity: COMPLETE (2026-07-21)

**Final result: MY and GH both match SG exactly** on visible non-funded
course counts across all 4 managed branches — **257 (Adult Courses) / 132 (AI
Courses) / 85 (Certification Exam Prep) / 68 (Software Training)** — verified
by full SKU-list diff, not just totals (byte-for-byte identical SKU sets on
AI Courses; count-identical after the recursion-bug fix below on the rest).

**Huge scope surprise, confirmed early in Phase 2 and worth remembering for
any future cross-site product work**: MY and GH's catalogs were **already a
near-complete SKU mirror of SG's** (cloned from a shared historical seed).
Actual new product creation ended up being **zero** across all 5 chunks on
both sites — every single SG SKU already existed locally. The real work was
entirely: (1) un-hide the right existing products, (2) fix their category
links to match SG, (3) clean up legacy stray links so counts didn't overshoot.
The original 5-step plan below (kept for the reasoning trail) assumed mass
product creation would be needed — don't assume that next time either;
always test-run the create path against a known-should-be-missing category
first (Claude Cert Prep, in this case) before committing to a "creates are
rare/none" conclusion.

### What actually ran (reusable pipeline)

1. **`sg-export-courses.php`** (on SG) — per branch chunk, exports SKU, name,
   price, description, image path, categories (by url_key), and full custom
   options (Course Date/Time/Mode/Sponsorship/Message — needed for checkout
   to keep working on any genuinely-new product). Writes to a randomly-named
   file under SG's public `media/tmp-export/`, printed as a fetchable
   `PUBLIC_URL`. **Always delete the temp file from SG's media dir once
   fetched** — don't leave course data sitting in a guessable public path.
2. **Hide MY/GH's entire existing catalog** (`hide-all-current-courses.php`)
   — bulk `visibility` → Not Visible Individually via
   `Mage_Catalog_Model_Product_Action::updateAttributes()` (never
   `->load()`/`->save()` per-product — see CLI crash gotcha below). MY:
   352/352, GH: 354/354.
3. **`product-sync-runner.php`** (on MY, then GH) — per chunk: curl-fetch the
   SG chunk JSON, for each row: if the SKU already exists locally, set
   `visibility` back to Catalog+Search and add any missing SG category links
   (union, never removes); if genuinely missing, create fresh (same SKU,
   virtual type, "Courses" attribute set, price × FX rate, image fetched from
   SG's public media URL, custom options copied verbatim from SG's export).
   **FX rates used: SGD→MYR ×3.4, SGD→GHS ×12, rounded to nearest whole
   number** (user-supplied, 2026-07-21).
4. **`cleanup-stray-category-links.php`** — removes any category link inside
   the 4 managed branches that isn't in SG's target set for that SKU (legacy
   MY/GH-only categorization that predates this sync). Only touches links
   inside the 4 managed branch subtrees — WSQ/IBF/Enquiries etc. never
   touched. **Must be re-run after any category-url_key mapping fix** (its
   target-set calculation depends on the mapping being complete).
5. **Reindex + cache flush**, then **`diff-branch-skus.php`** to verify exact
   SKU-list parity per branch.

### Gotchas found + fixed (all reusable for any future cross-site product work)

- **`Mage::getModel('catalog/product')->load($id)` fatals in this codebase's
  CLI context.** Triggers `_afterLoad()` → `MMD_CustomOptions_Model_Catalog_Product_Option::getProductOptionCollection()`
  → `Mage::getSingleton('customer/session')->start()` → "Unable to start
  session." — surfaces via Magento's exception-report redirect script
  (`window.location.href = '.../errors/report.php?id=...'`), not printed to
  CLI; check `var/report/<id>` on that site for the real stack trace. Same
  root cause hits any explicit `$product->getProductOptionsCollection()`
  call too — it's a custom error handler that `exit()`s immediately, which
  bypasses `try/catch(Exception)` entirely (need `set_error_handler` override
  or, simpler, just never trigger the code path). **Fix: never `->load()` a
  product by id in a CLI script here.** Use a collection instead
  (`addFieldToFilter('entity_id', ...)` or `addFieldToFilter('sku', ...)`) —
  collection items don't go through `_afterLoad()`. For bulk attribute
  changes (visibility, custom attributes) use
  `Mage::getSingleton('catalog/product_action')->updateAttributes($ids, $data, $storeId)`
  instead of `->load()->set...()->save()`. For custom options, read/write via
  raw SQL on `catalog_product_option*` tables directly (see below).
- **~~The `software`/`level` EAV attributes are unpopulated site-wide~~ —
  WRONG, corrected 2026-07-22.** This was a real conclusion drawn from a bad
  signal: **SG's flat product catalog (`catalog_product_flat_1`) is stale**,
  and every collection-based read (`addAttributeToSelect(...)`,
  `getAttributeText(...)`) goes through flat, not raw EAV, on this install.
  Confirmed directly — `C012` reads `level: NULL` via the collection but the
  raw `catalog_product_entity_int` table has real data (`value = 11` =
  "Beginner"); `C167`'s `name` reads blank via collection but is populated in
  `catalog_product_entity_varchar`. **Both `level` and `software` are real,
  meaningfully-populated attributes** that genuinely drive the storefront's
  Level filter facet and the Funded/Non-funded split — confirmed live (SG's
  layered nav shows Beginner 194 / Beginner-to-Intermediate 19 / Intermediate
  38 / Advanced 4, summing close to the branch total). **Any future script
  reading product attribute values on this codebase should query the raw EAV
  backend table directly** (`catalog_product_entity_<backend_type>`, join
  `eav_attribute_option_value` for the label) instead of trusting a
  collection's `addAttributeToSelect()` — the collection silently reflects
  flat catalog, which may lag behind real edits until the next "Product Flat
  Data" reindex runs on that site. Pattern used to fix this (`export-level-and-funded.php`):
  ```php
  $attribute = Mage::getModel('catalog/resource_eav_attribute')->loadByCode('catalog_product', $code);
  $table = $resource->getTableName('catalog/product') . '_' . $attribute->getBackendType();
  $value = $read->fetchOne("SELECT value FROM $table WHERE entity_id = ? AND attribute_id = ?", [$entityId, $attribute->getId()]);
  ```
  **Practical impact was limited**: since Phase 2 created zero new products
  (100% unhide-existing), the stale `level`/`software` reads never corrupted
  any *written* data — `name`/`description`/`price` were never touched on
  existing products either. The two real consequences were (1) `level` was
  never synced to MY/GH during the original Phase 2 pass (turned out to be
  moot on MY — its values already matched SG's real data byte-for-byte,
  263/263, since MY was cloned from the same seed and never diverged) and (2)
  **one course, `C167` ("Build a Conversational AI Agent with Google
  Gemini"), is actually `Funded` per the real `software` value but has a
  non-`TGS-` SKU** — it slipped through the TGS--prefix funding-status
  scope check and got unhidden as if non-funded. Fixed by hiding it
  specifically (`visibility` → Not Visible) on MY 2026-07-22; **GH still
  needs the same fix — was blocked on terminal access, revisit**. Only 1
  leak found across the full 264-product managed scope, so this is very
  unlikely to be a bigger problem, but if any *other* discrepancy surfaces
  later, check for more `software=Funded` SKUs outside the TGS- prefix
  before assuming something else is wrong.
- **Creating custom options via raw SQL needs two extra tables the stock
  Magento schema doesn't have** — this codebase's `MMD_CustomOptions` module
  (`app/code/local/MMD/CustomOptions/`) adds a `custom_options_option_view_mode`
  table and a `customer_groups` column on `catalog_product_option`. The
  storefront's `getProductOptionCollection()` (`Model/Catalog/Product/Option.php:1302`)
  **drops any option whose `view_mode` resolves to NULL/0** (a loose `==`
  comparison — `NULL == 0` is `true` in PHP) and **drops any option whose
  `customer_groups` isn't exactly `''`** (empty string = "all groups"; NULL
  fails the check if the per-option customer-group feature is enabled, which
  it is on this install). A plain option insert with neither of these set
  **silently vanishes from checkout** — no error, the required Course
  Date/Time field just never renders. Any future raw custom-option insert
  needs: `customer_groups = ''` on the option row, plus an explicit
  `custom_options_option_view_mode` row with `view_mode = 1, store_id = 0`.
- **SKU numbering is shared/cloned, not independently assigned per site** —
  confirmed by spot-checking low SKU numbers (C012–C027) match by name across
  SG/MY, contrary to the CLAUDE.md-documented C-prefix(SG)/M-prefix(others)
  convention (that convention doesn't hold in practice — MY/GH's own catalog
  uses C-prefix SKUs too). This is *why* Phase 2 turned out to be almost
  entirely "unhide + relink" rather than "create."
- **`getChildrenCategories()` is unreliable in this CLI context** — confirmed
  directly: category id 86 (Google Certification Exam Prep, on GH) reports
  child id `87` correctly via `getChildren()` (the raw comma-list method) but
  `getChildrenCategories()` (the collection-building method) returns
  **empty** for the same category, silently dropping id 87 and everything
  beneath it from any recursive tree-walk. This broke both
  `cleanup-stray-category-links.php`'s "which categories am I allowed to
  clean" set (missed ~70 deep category ids on each site — 200 found vs the
  real ~270) and `diff-branch-skus.php`'s category enumeration, though the
  latter mostly self-corrected because Magento's anchor-category product
  rollup still surfaced deep products in the *count* even when the *category
  id itself* was never explicitly collected — the miscount only showed up as
  small (+1 to +2) leftover-stray-link deltas, not big gaps. **Fix: don't use
  `getChildrenCategories()` for recursive tree walks in CLI scripts on this
  codebase — query `catalog_category_entity` directly by `path LIKE
  '<parent_path>/%'`.** Reusable pattern:
  ```php
  $rows = $read->fetchCol(
      "SELECT entity_id FROM catalog_category_entity WHERE path = ? OR path LIKE ?",
      [$category->getPath(), $category->getPath() . '/%']
  );
  ```
- **Website terminal mix-ups are easy and dangerous** — every write script
  prints `Website id:` (1=SG, 2=MY, 3=GH on this install) specifically so a
  copy-pasted command run in the wrong site's Coolify terminal is
  immediately visible. This happened once during Phase 2 (a MY-intended run
  landed on SG) — harmless that time only because SG's own data matched
  SG's own export exactly (a pure no-op self-sync), but **always check
  `Website id:` in the output before trusting a write-script's result.**
- **AI Series category url_keys diverge from SG on both MY and GH, and MY/GH
  use the *same* divergent slugs as each other** (both cloned from the same
  seed): `generative-ai-series`→`generative-ai-gai-llm-courses`,
  `agentic-ai-series`→`ai-agent-courses`, `ai-applications-series`→`machine-learning-courses`,
  `ai-agents-series`→`openclaw-ai-agent-courses`, `ai-vibe-coding-series`→`vibe-coding-courses`,
  `ai-devops-series`→`voice-agents-and-video-agents-coures`. (`ai-security-series`,
  `claude-ai-series`, `codex-ai-series` all match SG's own url_key — no
  mapping needed.) This is the same class of bug as Phase 1's Incident 1 —
  any future url_key-keyed cross-site script must account for it, or silently
  fail to link/find these categories.

### Currency & content decisions made (2026-07-21)

- Ported products **keep SG's exact SKU** (not re-prefixed to M-), overriding
  the documented convention — simplifies idempotency and future re-syncs.
- FX rates: **SGD→MYR ×3.4, SGD→GHS ×12**, rounded to nearest whole number.
- `level`/`software` attributes: ~~confirmed non-functional~~ **corrected
  2026-07-22 — both are real and matter for the storefront filter bar.** See
  the corrected gotcha above. `level` synced to MY (already matched, 0
  changes needed); the one `software=Funded` scope leak (`C167`) hidden on
  MY, GH pending.
- Custom option Course Date/Time values are **copied verbatim from SG** —
  this is a one-time snapshot, not an ongoing sync. Future SG schedule
  changes (new dates, closed sessions) won't propagate to MY/GH
  automatically; there's no recurring sync job. If ongoing schedule sync is
  wanted later, that's new infrastructure, not something this pass built.

**Branch url_keys used for all 5 chunks** (SG, confirmed via
`list-sg-branches.php`) — needed if any future re-sync reruns this pipeline:
- Chunk 1 (Infocomm, 175 products): `computer-programming-and-infocomm-courses`
- Chunk 2 (rest of Adult, 104 products): `digital-media-courses,
  iot-robotics-courses-in, digital-marketing-courses-in,
  business-soft-skills-courses, fintech-courses,
  logistics-and-manufacturing-courses,
  electronics-semiconductor-training-courses, life-science-courses-training,
  esg-and-sustainability-courses`
- Chunk 3 (AI, 132 products): `artificial-intelligence-courses`
- Chunk 4 (Cert Prep, 85 products): `certification-exam-prep-courses`
- Chunk 5 (Software Training, 68 products): `software-training-courses`
- Explicitly excluded from every chunk: `wsq-ibf-skillsfuture-utap-funded-courses`,
  `ibf-sts-funded-courses` (SG-only funding schemes).

## ✅ Phase 3 — filter-bar discrepancy investigation: MY DONE, GH PENDING (2026-07-22)

User flagged live filter-bar mismatches (Level / Category / Session counts,
e.g. SG Adult Courses total 256 vs MY 257, Session-1 SG 112 vs MY 110) the
day after Phase 2 wrapped. Two distinct root causes found and fixed.

**Incident A — `level` never synced + one `Funded` scope leak.** The Phase 2
"level is unpopulated" conclusion was wrong (flat-catalog staleness on SG —
see corrected gotcha in the Phase 2 section above), so `level` was never
actually synced, and a narrow SKU-prefix funding-status assumption let one
real `Funded` course (`C167`) leak into the ported "non-funded" set. Both
fixed on **MY** 2026-07-22 (`level`: 263/263 already matched SG, 0 changes
needed; `C167` hidden).

**Incident B — much bigger: a silent curl-fetch failure made `cleanup-stray-category-links.php`
skip most SKUs without saying so, letting real stray links survive.** Caught
because MY's live "Software Training" page suddenly showed 117 items instead
of the correct 68 — user (rightly) asked "what did you do to my server?".
Root cause: `sg-export-courses.php` generates a **new random filename every
run**, and by the time an earlier "fixed" cleanup pass ran, one or more of
the chunk export URLs it was pointed at had already been superseded/deleted.
`fetchWithCurl()` returning `false` only printed a `[WARN]` and `continue`d
— silently excluding every SKU from that chunk from the "what should this
product's categories be" check, so any of *those* SKUs' legacy/stray
category links (pre-dating this whole sync effort) never got evaluated or
removed. This had been quietly wrong since the very first "13 stray links
removed" cleanup run on MY — the real number was 265. **Fix applied to
`cleanup-stray-category-links.php`: a failed or empty chunk fetch now
`die()`s immediately instead of warning-and-continuing** — never trust a
partial run again. Recovered by: regenerating all 5 SG chunk exports fresh,
confirming every fetch succeeded (each chunk logs `OK: <url> (<n> rows)`
before merging), re-running cleanup (265 real stray links removed this
time), then re-running `product-sync-runner` per chunk to catch up on
category links for content SG had added since the original Phase 2 pass
(SG's catalog is live and keeps changing — don't assume a snapshot stays
accurate). **MY confirmed fully matching SG again 2026-07-22: 254/131/77/68
on all 4 branches**, verified with a fresh SG baseline pulled the same day
(SG's own counts had also shifted since Phase 2 — 257→254, 132→131, 85→77 —
this is normal organic catalog growth/editing on SG's side, not a bug).

**GH still needs the identical Incident A + B + C fix — blocked on terminal
access, resume here.** Since GH was only cleaned up once (same "13 removed"
pattern MY had before Incident B/C were found), assume GH has all three
classes of problem until proven otherwise. Procedure:
1. Regenerate fresh SG chunk exports (5x `sg-export-courses.php` calls — note
   branch url_keys may have drifted since Phase 2, e.g. Healthcare's
   `life-science-courses-training` became `healthcare-and-wsh-courses`
   sometime between 2026-07-21 and 2026-07-22 — re-verify with
   `loadByAttribute('name', 'Healthcare')` if a branch url_key 404s).
2. **Verify GH's own AI-series + Cert Prep wrapper url_keys by name lookup
   before trusting the mapping written down for MY** — GH's mapping was
   confirmed identical to MY's on 2026-07-21 (`ai-agent-courses`,
   `ai-applications-series-courses` may or may not match — MY's own mapping
   for 2 of these drifted a day later, so don't assume GH is still in sync
   with what MY had even yesterday). Current 7-entry map (verify each):
   ```php
   $urlKeyMap = [
       'generative-ai-series' => 'generative-ai-gai-llm-courses',
       'agentic-ai-series' => 'ai-agent-courses',
       'ai-applications-series' => 'ai-applications-series-courses',
       'ai-agents-series' => 'openclaw-ai-agent-courses',
       'ai-vibe-coding-series' => 'vibe-coding-courses',
       'ai-devops-series' => 'ai-devops-series-courses',
       'others-certification-exam-prep' => 'miscellaneous-certification-exam-prep',
   ];
   ```
3. Run the **hardened** `cleanup-stray-category-links.php` (the one with
   `die()` on fetch failure) confirming all 5 chunks show `OK:`.
4. Re-run `product-sync-runner` per chunk to catch up on new SG content.
5. Run `export-level-and-funded.php` fresh on SG, run
   `sync-level-and-funded.php` on GH (Incident A: level sync + Funded-leak
   hide — GH's own leaked SKU may or may not be `C167`, re-derive from
   fresh data, don't assume).
6. Reindex + flush, then run the **full** `full-scan.php` audit (not just
   `diff-branch-skus.php` branch totals — Incident C proved branch totals
   can match while individual subcategories are wrong underneath) against a
   **freshly-pulled SG baseline** (not yesterday's numbers — SG's catalog
   moves; also fix the `full-scan.php` Session-facet store_id bug if using
   an older copy of that script).

**Lesson for any future one-off cross-site script**: if a script's success
message doesn't distinguish "processed everything" from "processed what it
could reach," it will eventually silently under-deliver. Prefer failing loud
over warning-and-continuing whenever partial data would produce a
plausible-looking but wrong result — this bit us for a full day before
surfacing as a "why did the number suddenly change" user report.

**Incident C — 2 more url_key mappings drifted independently, on top of
Incident B.** After fixing Incident B, a full audit (every subcategory +
Level/Course Type/Session facets, not just branch totals — user explicitly
asked for this level of rigor after the Incident B scare) found the branch
*totals* matched (131=131 for AI Courses) while two specific subcategories
were wrong underneath: `ai-applications-series` (SG) and `ai-devops-series`
(SG) had **silently renamed their own MY-side target url_keys** sometime
between Phase 2 (2026-07-21) and this audit (2026-07-22) —
`machine-learning-courses` → `ai-applications-series-courses`, and
`voice-agents-and-video-agents-coures` → `ai-devops-series-courses`. Because
the `urlKeyMap` still pointed at the old (now-nonexistent) url_keys,
`resolveCategoryId()` returned `null` for both, which meant `cleanup-stray-category-links.php`
saw an *empty* target set for every product that should be in those
categories — and deleted all ~36 real links as "stray" in the very same
"fixed" cleanup run that fixed Incident B. A 7th, previously-unmapped
mismatch was also found the same way: `others-certification-exam-prep` (SG)
→ `miscellaneous-certification-exam-prep` (MY) was never in the map at all,
so exactly the 2 products that needed a *fresh* link there (`C1186`, `C483`
— pre-existing MY-native members of that category were unaffected, only new
adds silently failed) never got linked in any Phase 2/3 run.

**Fixed**: `urlKeyMap` in both `product-sync-runner.php` and
`cleanup-stray-category-links.php` updated to the corrected/complete set
(**current canonical mapping, verify by name lookup before trusting further —
this list has already drifted twice**):
```php
$urlKeyMap = [
    'generative-ai-series' => 'generative-ai-gai-llm-courses',
    'agentic-ai-series' => 'ai-agent-courses',
    'ai-applications-series' => 'ai-applications-series-courses',
    'ai-agents-series' => 'openclaw-ai-agent-courses',
    'ai-vibe-coding-series' => 'vibe-coding-courses',
    'ai-devops-series' => 'ai-devops-series-courses',
    'others-certification-exam-prep' => 'miscellaneous-certification-exam-prep',
];
```
Re-ran the affected chunks (3 and 4) on MY, recovered all 38 wrongly-dropped
links (36 + 2). Also fixed a `full-scan.php` query bug found during this same
audit: the Session facet (`progromming_language` attribute) summed to 335
instead of 264 on SG because the raw EAV query wasn't scoped to `store_id =
0` — leftover multi-store-era rows in `catalog_product_entity_int` double-
counted. Added `AND store_id = 0` to every raw EAV facet query going
forward.

**Lesson**: category url_keys on this codebase are not stable over time —
something (manual admin edits, a background process, unclear) renames them
independently of any sync work. **Any hardcoded url_key→url_key mapping is a
liability that silently rots.** Prefer verifying by category *name* lookup
(`loadByAttribute('name', ...)`) at the start of any future sync run rather
than trusting a mapping written down previously, or accept that periodic
re-verification is required.

**Final result after Incident C fix — MY confirmed matching SG on every
axis checked, not just branch totals** (`full-scan.php`, 2026-07-22):
total 264=264; all 4 branch totals 254/131/77/68; ~230 individual
subcategories checked line-by-line, all matching except one **pre-existing,
already-documented gap** (MY has no "Video Editing" category at all, SG has
3 there — this predates Phase 2, not a regression, see carried-over open
items below); Level facet sums match (SG has 1 product with a blank/NULL
level that MY has as "Beginner" — a SG-side content gap, not a bug); Course
Type facet correctly shows MY with 0 Funded (by design) vs SG's 1 (SG's own
choice to keep `C167` visible on its own site); Session facet now
byte-for-byte identical (97/110/24/26/7) after the store_id fix.

Still not fully explained: the exact SG-live-page-total-vs-script-count
off-by-one pattern seen earlier in Phase 3 (SG's own live "Adult Courses"
page showed 256 while our script computed 257 for the identical scope) — 
most likely the same flat-catalog staleness affecting SG's *own* storefront
rendering (a pre-existing SG issue, not something MY/GH sync caused), but
never root-caused precisely. If it resurfaces, check whether SG's own
`catalog_product_flat` / `catalog_category_flat` indexers are behind.
- **Orphaned "Soft  Skills" category** (id 75, MY and GH, note double space in
  name) — already hidden, but holds 10 (MY) / 11 (GH) real product
  assignments. Need to confirm those products are also reachable via a
  visible category before it's safe to ignore permanently. Do not delete.
- **Naming-only diffs** (rename to match SG, cosmetic, low priority): "Google
  Cloud Platform"→"Google Cloud", "Data Visualisation and Dashboard"→"Data
  Visualisation" (MY/GH), "Hydroponics Urban Farming"→"Urban Farming",
  "Critical Thinking & Problem Solving"→"Problem Solving", "Java & Scala"→
  "Java" (GH), "CyberSecurity & Threat Analysis"→"Cyber Security" (MY/GH).
- **SG-missing-vs-MY/GH content** (partner-only categories/courses: Swift,
  Marketplaces, Magento, Investment, Coaching & Mentoring, Digital/Analog IC
  Design, Speed Typing, Microsoft Access, Qlik, Google Sheets/Tag
  Manager/Looker Studio, Autodesk Maya, Microsoft Outlook, etc.) — **now
  effectively resolved as a side effect of Phase 2**: since Phase 2 hid
  MY/GH's *entire* pre-existing catalog and only unhid SKUs that also exist
  on SG, any of these SG-lacking MY/GH-only products are now hidden from the
  storefront (visibility = Not Visible Individually). The underlying
  product/category records still exist (nothing deleted), just invisible —
  no further action needed unless the business wants this content back
  someday, in which case it'd need individual `visibility` restoration.
- **Needs re-verification**: MY "AI Security Series" course count (crawl grabbed
  a wrong URL, never actually confirmed); GH "Unreal Engine" (Software
  Training) — crawler flagged the page as possibly showing Claude AI listings
  instead. Re-check both live pages directly.
- **Unrelated bug**: GH's `sitemap.xml` serves stale `tertiarycourses.com.sg`
  URLs, not GH's own. Separate SEO ticket, not a category-parity issue.

## Reference

Full leaf-by-leaf category count comparison (all ~250+ categories, all three
sites): published artifact from the 2026-07-20 session, "SG / MY / GH
Category Parity Audit". Regenerate by re-crawling if stale.
