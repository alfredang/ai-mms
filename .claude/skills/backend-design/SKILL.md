---
name: backend-design
description: Design system for the OpenMage admin panel — branding, color tokens, buttons, grids, toolbars, badges. Use when styling or reviewing any adminhtml UI (dark theme, custom modules, RoleManager, dashboards, grids), when a button/toolbar/badge "looks off" or inconsistent, when adding a new admin page, or on requests like "make the admin look more professional", "modern button design", "consistent backend design", "fix the dark theme". Keeps every admin screen visually consistent with the existing token system.
---

# Backend (admin) design system

The admin panel is OpenMage 1.x styled into a custom dark theme. **Do not invent
new colors, paddings, or button styles per-page.** Everything routes through one
token set and a small number of component rules. New admin UI must reuse them so
the panel stays consistent.

## Design philosophy: Neon + Minimalist (entire backend)

The admin's visual language is **neon on near-black with a minimalist content
discipline**. Every new admin surface — grids, modals, banners, dashboards,
sidebars, modules — must read like part of the same product. The defining
qualities:

- **Surface = deep dark, not "Magento gray".** Page background and chrome
  use `#0b0f17` / `#0f172a` / token-driven `--d*` shades. No pastel washes,
  no Magento 1's stock taupe panels. If a surface needs to draw attention,
  it does so with a neon accent line or glow — not by switching to a light
  fill.
- **Color is reserved.** Body text, labels, captions, table cells are all
  in the cool-gray family (`#e5e7eb`, `#cbd5e1`, `#6b7280`). Color appears
  only where the UI is signalling state or category:
  - Brand cyan/blue for primary action, hover, active tab.
  - Red `#ff3b5c` for critical / destructive / high risk.
  - Amber `#f5c451` for warning / medium risk.
  - Green `#3df5a8` for success / quick win.
  - Violet `#b07cff` for "big bet" / experimental / AI-driven.
  - Muted slate `#8aa1bd` for low risk / neutral metadata.
  Saturated fills are banned; the same hues appear as **1px borders + soft
  `box-shadow` glow** (`0 0 6px <color>`, `inset 0 0 6px <color>/0.1`) so
  the chrome reads as outline-on-dark, not as colored blocks.
- **Components are outlined, not filled.** Pills, badges, buttons,
  notifications, status chips — all share the same shape: 1px solid
  `currentColor`, 2px corner radius, transparent fill, neon glow on hover
  or active. The audit-notification pills (`.audit-pill-*` in
  `dark-theme.css`) and the "View issues" link button are the reference
  implementation; reuse the same pattern (border + glow + uppercase
  letter-spaced label) for every new chip-shaped element across the
  backend.
- **Density is calm, not cramped.** Vertical rhythm uses 6 / 10 / 14 / 18px
  steps. Tables and grids keep generous row padding (10–12px). No
  decorative borders inside a card; one outer border (or none) plus
  whitespace is enough. Don't add icons or color "for visual interest" —
  if it doesn't carry information, leave it out.
- **Typography is utilitarian.** `Inter` / `SF Pro Text` / system stack at
  11.5–12px for body, 10.5px uppercase letter-spaced (1.2–1.4px) for
  section / status labels, tabular-nums for any column of numbers or
  timestamps. Headings are weight + size, never decorative.
- **Motion is restrained.** Transitions are 0.15s ease on `box-shadow` /
  `background` / `border-color` only. No bouncing, no scaling, no fade-in
  delays. Hover state lights up an outline; that's the whole interaction
  vocabulary.

When designing or reviewing any admin surface (a new module page, a grid
toolbar, a modal, a status badge), the test is: *strip every shadow,
gradient, and color — does the page still communicate its hierarchy
through layout and typography alone?* If not, the chrome is doing too
much work. Add the neon back only at the points where the user needs to
notice state.

## Hard rule: ONE global design system, no per-page ad-hoc components

Every admin page — core Magento, MMD module, custom dashboard, role-manager,
search-spam cleanup, anything new — must look like part of the same product.
That means:

- **One typography system.** Body text inherits the admin font stack and base
  size from `dark-theme.css`. New templates do NOT set their own `font-family`,
  do NOT override the base `font-size`, and do NOT introduce display fonts.
  Section labels, headings, and body all flow from §"Density preference"
  defaults below — pick the matching role, don't reinvent the scale.
- **One color palette.** Every color is a CSS custom property declared in
  `:root` (`--d*`, `--b*`, `--t*`, `--brand`, `--blue`, etc.). No new raw hex
  in a template, phtml, or inline `style=""`. If the shade you need isn't a
  token, add the token to `:root` first.
- **One component library.** Tabs, buttons, tables, pagers, checkboxes,
  badges, action icons, branch-pill strips, modals — each has exactly one
  canonical implementation referenced below. New code reuses the class names
  (`.dev-country-btn`, `.mm-btn-primary`, `.mm-table`, `.mmd-grid-actions`,
  etc.); new code does NOT clone the markup into a per-feature class
  (`.my-feature-tab`, `.spam-pill`, `.search-btn`).
- **One button registration pattern.** Page-level action buttons (Save / Add
  New / "Clean Spam" / etc.) are registered via `$this->_addButton()` on the
  block (so they flow through `Mage_Adminhtml_Block_Widget_Container::getButtonsHtml()`
  and inherit §18 styling). Templates do NOT emit raw `<a class="button">` or
  `<button>` markup for page-level actions — that path produces a visually
  smaller, inconsistent control. The exception is a button rendered *inside*
  a form row or card body, where `.mm-btn` / `.mm-btn-primary` is used.
- **No "this page is special" exemption.** If a new feature seems to need a
  bespoke component, the answer is almost always to extend an existing one or
  to file the gap as a new entry in this skill — not to drop a one-off into
  the template.

When reviewing or writing admin code, the test is: *would a screenshot of this
page look indistinguishable from a screenshot of the Search Terms / Cache /
Catalog grid in terms of typography, spacing, and control style?* If not,
that's the bug.

## Density preference — compact, not airy

Strongly prefer **compact** layouts. Admin users are power users who want
high information density and short mouse travel — not a marketing landing
page. When in doubt, smaller is better.

Defaults to use unless there's a specific reason otherwise:

- **Buttons in toolbars / action rows**: `height: 28px`, `padding: 2px 14px`, `font-size: 12px`, `border-radius: 6px`. (Page-level Save/Cancel primary buttons stay at the bigger §18 size — those are deliberate emphasis.)
- **Selects / dropdowns in toolbars**: `height: 28px`, `padding: 2px 8px`, `font-size: 12px`, `border-radius: 6px`. Match button height exactly so they sit on the same baseline.
- **Section sub-headers** (bare `<h3>` like "Additional Cache Management"): `font: 700 12px/1.4`, `--t4`, `uppercase`, `letter-spacing: 0.6px`. Not a 26px title.
- **Form-list / stacked-rows panels**: prefer **no card wrapper** — just rows sitting on the page background with a `1px var(--b1)` hairline between them (`tr + tr { border-top }`). Reach for a card (`--d3` bg + border + radius) only when the panel needs to stand apart from neighbouring content.
- **Toolbar / massaction row padding**: `6px 12px` on the wrapper, `gap: 6px` between Actions+select+Submit, `gap: 14px` between selection links.
- **Grid rows**: `6-10px` cell padding, never more.
- **Labels next to inputs**: 12px muted (`--t4`), small `margin-right` (~6px) — they're metadata, not headings.

Anti-pattern: wrapping every section in a `--d3` card with 16-20px padding "for visual separation". On a dense admin page this stacks into nested-panel mush. Stack tightly, separate with thin lines, use a card only when truly needed.

## Page title — ONE framework rule for every page (do not whitelist classes)

Every admin page has exactly one page title, and it renders **identically
everywhere**: flush on the page surface (no gradient container), `18px / 700`,
`var(--t1)`, with a `1px var(--b1)` hairline underline and `0 0 12px` padding /
`0 0 16px` margin. This is the minimalist look — a title, a hairline, then the
content. No `.dcf-mag-bar` gradient behind a page title (that bar is only for
**section-card** headers inside forms like Edit Course's "General"/"Inventory").

**The single source of truth** is one rule in
`skin/adminhtml/default/default/admin-dashboard.css` ("Global page-title type
ramp"). It is a **framework net, not a whitelist** — it matches the whole
page-title family by shape so new pages need zero CSS:

```css
.admin-main h1[class*="-title"],                                   /* every h1 *-title = page title */
.admin-main h2[class*="-title"]:not([class*="card"]):not([class*="modal"]), /* h2 page titles, minus card/modal sub-heads */
.admin-main .content-header h3,                                    /* native Magento page titles */
.admin-main .content-header h3.icon-head { font-size:18px !important; … hairline … }
```

Why this shape:
- An `<h1 class="…-title">` is *always* a page title — the net covers
  `.dash-title`, `.dev-page-title`, `.att-title`, `.trn-title`, … and any future
  one automatically.
- `<h2 class="…-title">` is usually a page title (`.rm-title`, `.lmc-title`,
  `.seo-info-title`) **except** card/modal sub-headings (`.hsp-card-title`,
  `.lp-modal-title`) — hence the two `:not()` guards.
- `<h3 class="…-title">` is *never* a page title (they're card / section /
  sidebar sub-heads: `.el-card-title`, `.dcf-section-title`,
  `.dcf-edit-sidebar-title`, …) — deliberately NOT matched.
- The auto-wrapped grid title (`.dcf-mag.mmd-auto-card > .dcf-mag-bar`) is
  flattened to the same 18px flush treatment in `sidebar-nav.css` §25a.

**Rules for new admin pages:**
1. Emit the page title as `<h1 class="…-title">` (or `<h2>` if the class does
   NOT contain `card`/`modal`). It inherits the canonical look with no new CSS.
2. Never give a page title its own `font-size` — that recreates the drift this
   rule exists to kill. Section/card/sub headings use §"Section headers" or the
   h4/h5/h6 ramp, never a `*-title` page-title class.
3. Do NOT re-add a competing 28px page-title rule anywhere (a duplicate 18px
   block was already a dead-code landmine — keep exactly one source of truth).

Incident: page titles had drifted across ~15 bespoke per-module classes
(`.rm-title` at 24px, `.dash-title` at 28px, native `.content-header h3` at
28px, …); a class *whitelist* kept missing new ones (e.g. `h2.rm-title` on
Upcoming Classes stayed huge). The shape-based net above ended the whack-a-mole.

## Where things live

| File | Role |
|------|------|
| `skin/adminhtml/default/default/dark-theme.css` | `:root` design tokens + base dark reset. **Tokens are the single source of truth.** |
| `skin/adminhtml/default/default/sidebar-nav.css` | Component layer: grids, buttons (§18), form panels, toolbars/massaction (§16), filters, KPI cards. Numbered sections — keep them. |
| `skin/adminhtml/default/default/js/sidebar-nav-v2.js` | Grid enhancements: checkbox-column removal, per-row action dropdowns, KPI cards. Has per-grid opt-outs (e.g. `cache_grid_table`). |
| `app/design/adminhtml/default/default/template/` | Admin phtml (header, menu, login, rolemanager). Prefer ID selectors — legacy `boxes.css` has high-specificity rules. |

## Layout cascade — how the admin shell is positioned

A trap that has eaten multiple sessions: the admin shell already
accommodates the 250px left sidebar in `.admin-main`. **Don't add
extra `padding-left` or `margin-left` to wrappers inside `.admin-main`
to "clear" the sidebar — it stacks on top of the existing 250px gap
and pushes the content off the right edge.**

The actual chain (sidebar-nav.css 7–68):

1. `body > .admin-sidebar-layout` is a `display: flex; flex-direction: column` shell.
2. `.admin-topbar` is `position: fixed; top:0; left:0; right:0; z-index:1400` (56px tall).
3. `.admin-sidebar` is `position: fixed; top:56px; left:0; bottom:0; width:250px; z-index:1200`.
4. **`.admin-main { margin-left: 250px; padding-top: 56px; padding-left: 20px; flex: 1 }`** — this `margin-left:250px` is the gap for the sidebar.
5. Responsive (`@media (max-width:1024px)`) and `body.sidebar-collapsed` shrink BOTH `.admin-sidebar` to 60px AND `.admin-main { margin-left: 60px }`. They move together.

**Edit Course / Leads pattern (admin-dashboard.css 370–377):**

- `body:has(.dcf-edit-sidebar) #admin-sidebar { display: none }` + `body:has(.dcf-edit-sidebar) .sidebar-toggle { display: none }` hide the regular admin sidebar.
- `.dcf-edit-sidebar { position: fixed; top:56px; left:0; bottom:0; width:250px; z-index:1200 }` slots into the same 250px slot.
- **No extra `padding-left` is added to `.main-col-inner` / `.middle` / the page wrap.** The existing `.admin-main { margin-left:250px }` is the gap; the new sidebar just visually replaces the old one.

So when adding a new page that uses `.dcf-edit-sidebar` (Leads adopted this), reuse the class verbatim and let the shell margin handle the offset. Adding `padding-left:270px` "to push the wrap right of the sidebar" was the bug: 250 (admin-main) + 270 (wrap) = 520px from the viewport edge, table shoved off-screen.

## Admin grid page — canonical layout (global, applies to every list page)

**THE shape every admin list / grid page MUST take** — MMD custom
pages, Magento core pages (Catalog, Sales, Customers, CMS, Newsletter,
Promotions, URL Rewrite, Reviews, Funding Tags, Search Terms, System →
Manage Stores, …) — every route with a `.content-header` + `.grid`
in the main container. The Edit Course page is the visual benchmark
for edit-mode pages; **the All Reviews page (and the Leads page) is
the visual benchmark for grids**. No per-page variants — if any list
page looks different from those, that's a bug to file, not a design
choice to honour.

**Grid benchmark anatomy** (top to bottom — match exactly):

1. `.dcf-mag-bar` header — bold title left, page-action buttons
   ("Add New Review", "Add URL Rewrite", "Filters ▾", etc.) flush
   right inside `.mmd-auto-card-actions`. Gradient-bar styling is
   global in `admin-dashboard.css`; do NOT restate or override per
   page.
2. Mass-action toolbar (`[id$="_massaction"]`) — slim row, "0 items
   selected" left, `ACTIONS [select] Submit` right, single hairline
   `border-bottom` separating it from the table body.
3. Grid table — checkbox column visible (canonical rule below: any
   grid with non-empty mass-actions surfaces its checkboxes), then
   the standard column set, then a single icon-only **Actions**
   column on the right when bulk operations are also per-row
   available.
4. Pagination/footer row — `Showing X-Y of Z records | Show [20]
   per page | First ‹ Prev 1 Next › Last` — flat-text pager
   (`.dev-pg-btn` / `-pg-btn`), no chip backgrounds. See "Minimalist
   pagination" below.

If a screenshot of your grid wouldn't look indistinguishable from
the All Reviews screenshot when squinted at, something is off —
usually a missing `_prepareMassaction()` on the block, a custom
inline `<style>` block fighting the global rules, or a
`.content-header` the auto-wrap didn't find.

The four invariants:

1. **Container header** — title sits in a `.dcf-mag-bar` (the dark
   gradient bar at the top of the card), NOT in a floating `<h3>`
   above the table. Form buttons (Add New, Reset, etc.) flush right
   in the same bar via `.mmd-auto-card-actions`. `.dcf-mag-bar`
   styling (gradient bg, `padding:13px 22px`, `font:15px/700`,
   `border-bottom`) is global in `admin-dashboard.css` — do NOT
   restate or override it on a per-page basis.

2. **Row-select checkbox column** — visible on every grid that has
   active mass-actions (Delete, Change status, etc.). Magento's
   massaction column is auto-injected when the grid block defines
   `_prepareMassaction()`. `sidebar-nav-v2.js::removeCheckboxColumn()`
   now applies a **canonical rule**: if `#<grid_id>_massaction select`
   has at least one option with a non-empty value, the checkbox
   column stays visible. No per-grid allow-list to maintain. **No
   per-grid checkbox CSS** — the global `input[type="checkbox"]`
   rule in `dark-theme.css` already styles them (16×16, `#475569`
   border, transparent bg, blue fill on `:checked`). See the
   "Minimalist checkbox" section above.

   The only opt-outs are deliberate UX choices, hard-coded in the JS:
   `cache_grid_table` and `indexer_processes_grid_table` use
   dedicated Reindex/Flush buttons in the toolbar instead of the
   massaction select+submit dance, so we hide their checkboxes even
   though `_prepareMassaction()` runs. Any new grid that wants
   mass-action selection just declares `_prepareMassaction()` in PHP
   — the canonical rule surfaces the column automatically; no JS
   change required.

3. **Action column is icon-only** — already guaranteed by the global
   class rewrite of `Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Action`
   (see the "Grid Action column" section above). Anything declared
   as `'type' => 'action'` renders as 26×26 ghost icon buttons. Do
   NOT add `'renderer' => …` keys to action columns; do NOT render
   text-link action HTML manually in a custom renderer.

4. **Font size matches Leads** — every grid inherits `§14` from
   `sidebar-nav.css` (cell padding, font size, header style, row
   separator). No per-page font overrides — no `font-size:` in
   page-scoped CSS or inline templates. If a column needs density
   tweaks, use the `td.muted` / `td.strong` / `td.center` modifiers
   from the `.mm-table` block (for MMD custom panels) or accept §14
   defaults (for native Magento grids).

**Auto-rollout** — `sidebar-nav-v2.js::wrapMmdGridInCard()` applies
invariant #1 (and #3 indirectly) to **every** admin grid route by
hoisting the `.content-header` into a `.dcf-mag` section card. The
function is **deny-list** scoped, not allow-list: it fires on every
page with a `.content-header h3` + a `.grid` in the main container,
including Magento core pages (URL Rewrite Management, Reviews &
Ratings, Newsletters, Search Terms, Google Sitemap, Catalog Tags,
etc.). The design system is now the universal admin chrome — there
should be no second-class "this page is a core Magento page so it
gets the old layout" carve-out for grids.

**Hard exclude** — any `adminhtml-dashboard-*` body class. Course
Edit is the design benchmark (its `.dcf-section` + `.dcf-mag` cards
already match what we want everywhere else) and the global admin
dashboard has its own chrome. The wrap function returns early on
those body classes. Leads ships its own custom phtml that already
emits `.dcf-mag` — the wrap function detects `.mmd-leads-wrap` and
the `.mmd-auto-card` class it emits, so re-runs are idempotent.

**Pages without a Magento grid** (e.g. Marketing dashboard's KPI
tiles, dashboards rendered from a hand-written phtml) don't get
auto-wrapped because there's no `.grid` to find. For those, wrap
manually in the template:

```html
<div class="dcf-mag mmd-auto-card">
  <div class="dcf-mag-bar">
    <span><?php echo $this->__('Marketing Dashboard') ?></span>
    <span class="mmd-auto-card-actions">[buttons]</span>
  </div>
  <div class="dcf-mag-body" style="padding:0;">
    <!-- table / content -->
  </div>
</div>
```

— same classes the auto-wrap emits, so the CSS already covers them.

## Grid checkbox column — canonical rule (active mass-actions = visible)

**Rule:** if a grid has wired-up mass-actions, its row-select
checkboxes are visible. No allow-list to maintain.

`sidebar-nav-v2.js::removeCheckboxColumn()` (around line 1262)
inspects each `.grid table.data` whose first body cell is an
`<input type="checkbox">` (i.e. Magento auto-injected its mass-action
column) and asks one question: does the grid's
`#<grid_id>_massaction select` have at least one option with a
non-empty value? If yes — the grid has actual actions to apply, so
keep the column visible. If no — the column is decorative noise,
hide it.

That replaces the old hardcoded allow-list. Adding a new MMD admin
grid that needs bulk select now requires zero JS changes — declare
`_prepareMassaction()` in PHP with at least one item, and the
canonical rule picks it up automatically.

**Hard-coded exceptions (deliberate UX choices):**

- `cache_grid_table` (Cache Management) — uses dedicated Flush
  buttons in the toolbar, not the massaction select+submit. The
  per-row checkboxes were intentionally removed (commit `6c437f504`)
  to prevent accidental bulk reindex / flush.
- `indexer_processes_grid_table` (Index Management) — same pattern.

When troubleshooting "the mass-action toolbar shows '0 items
selected' but I can't see any checkboxes to tick", check in this
order: (1) does the grid block actually declare `_prepareMassaction`
with non-empty items? (2) is the grid one of the two opt-outs
above? If not, the canonical rule should be surfacing the column —
look at JS console errors or the merged JS bundle freshness.

If you find yourself writing
`body .admin-main #foo_table input[type=checkbox] { ... }`, stop —
the issue is upstream (the JS strip or a missing
`_prepareMassaction` declaration), not the CSS cascade.

Adjacent helper: `injectHeaderSelectAll()` (right below) adds the
"select all" checkbox into the empty header cell of any grid that
HAS a mass-action checkbox column. It uses the same detection
(first body cell contains `<input type="checkbox">`), so any grid
that keeps its checkboxes under the canonical rule gets the header
"select all" toggle for free.

These are static skin assets — **no build step, no Magento cache clear**. Changes
ship on next deploy; users just hard-refresh.

## Design tokens (never hardcode — use the var)

Defined in `dark-theme.css` `:root`:

- **Surfaces:** `--d0`…`--d6` (darkest→lightest). Page `--d1`, cards `--d3`, raised bars/headers `--d4`, hover `--d5`.
- **Borders:** `--b1` (subtle), `--b2` (default), `--b3` (strong).
- **Text:** `--t1` (headings) → `--t4` (muted/labels) → `--t5` (faint).
- **Accent / brand:** `--brand` (#2563eb, the Tertiary admin primary), `--brand-2`.
- **Semantic:** `--blue/2/3`, `--green/2`, `--red/2`, `--yellow`, `--orange`.
- **Focus ring:** `--ring` — use for every interactive `:focus-visible`.
- **Button gradients:** `--btn-primary[-hover]`, `--btn-success[-hover]`, `--btn-danger[-hover]`.

If a needed shade doesn't exist, add a token to `:root` — don't drop a raw hex
into a component rule.

## Minimalist button system (canonical for new code — `dark-theme.css` end block)

For any new admin UI in MMD custom modules (dashboard, course editor, role-manager,
marketing newsletter, etc.) **use the `mm-btn` family**. Lives at the bottom of
`dark-theme.css` so it loads on every admin page, scoped with `.admin-main` to bump
specificity past `sidebar-nav.css`'s generic `.admin-main button` rule.

| Class | Use | Spec |
|---|---|---|
| `.mm-btn` | Base / neutral. Transparent fill, slate border, lightens on hover. | 34px tall, `padding: 7px 14px`, `font: 13px/1 500`, `border-radius: 6px` |
| `.mm-btn-primary` | The one solid blue action per area (Save Changes, Submit). | Same size; `bg #2563eb`, white text, no gradient, no shadow |
| `.mm-btn-ghost` | Cancel / secondary / Upload. Same as `.mm-btn` but explicit. | Identical to base |
| `.mm-btn-sm` | Inline / row actions in tables. | 28px tall, `padding: 5px 11px`, `font: 12px`, `border-radius: 5px` |
| `.mm-btn-icon` | Square icon-only (close, hamburger). | 34×34px, no horizontal padding |

The override also catches **legacy chunky classes** so existing per-feature buttons
inherit the minimalist look automatically — no template churn needed:

- `button.dcf-btn`, `button.dcf-btn-save`, `button.dcf-btn-cancel`, `button.dcf-btn-edit`, `button.dcf-btn-save-cont`
- `button[class*="-btn-primary"]` → `dash-btn-primary`, `trn-btn-primary`, `cnc-btn-primary`, `alm-btn-primary`, `el-btn-primary`, `cp-btn-primary`, `atm-btn-primary`
- `button[class*="-btn-secondary"]`, `button[class*="-btn-cancel"]`, `button[class*="-btn-ghost"]`
- `button.at-action-btn`, `button.al-action-btn` → auto-shrink to `mm-btn-sm` size

**Out of scope** — these are intentionally not styled by the mm-btn block: Magento's
native `.scalable` / `.form-button` toolbar buttons on catalog/sales grids and System →
Configuration. Those still go through `sidebar-nav.css` §18/§16 (below).

Anti-patterns to avoid:
- Inline `style="background:#2563eb;padding:10px 20px;..."` on a button. Use `mm-btn-primary`.
- A new per-feature button class (`my-feature-btn`). Use the mm-btn family.
- Gradient backgrounds, drop shadows, `text-transform:uppercase`, `letter-spacing`. All banned.

## Minimalist table (`mm-table` — `dark-theme.css` end block)

For tables in **MMD custom panels** (dashboard tabs, role-manager lists, marketing
panels, course-editor sub-lists) use the `.mm-table` class. Lives at the bottom of
`dark-theme.css`, scoped with `.admin-main` to beat generic admin table rules.

**Native Magento grids (`.grid`, sales/customers/catalog) keep their existing
§14/§20 styling — do NOT opt them into `.mm-table`.** This component is for
brand-new MMD tables only.

Specs (all opt-in via class):

| Class | Use |
|---|---|
| `.mm-table` | Base. Transparent cells, hairline `tr+tr` row separators, small uppercase muted header, 6×10 padding, single-line cells with ellipsis truncation. |
| `.mm-table.mm-table-tight` | Denser variant — 4×8 padding, 11.5px font. |
| `td.num` / `th.num` | Right-align (numeric / IDs). |
| `td.center` / `th.center` | Center-align. |
| `td.muted` | Dimmed (`--t4`) — metadata, secondary IDs. |
| `td.faint` | Most dimmed (`--t5`) — store IDs, faint footnotes. |
| `td.strong` | Bumped to `--t1` + weight 500 — primary label / title cell. |
| `td.status` | Pairs with inline `style="color:var(--green/yellow/red)"` for status. |
| `td.wrap` | Opt back into wrapping for a long-content column. |
| `.mm-table-empty` | Empty-state row (`<td colspan="N" class="mm-table-empty">…`). |

Anti-patterns:
- Inline `<style>` block next to a `.mm-table` re-declaring padding/colors — extend the component or use a utility class.
- Adding `background:#…` to `<td>` (re-introduces gray cells).
- Zebra striping. Hairline-only separation is the canonical look.
- Putting `.mm-table` on a Magento native `.grid` (will fight §14).

Reference: the **Course Review** table in `dashboard/index.phtml` (tab `data-tab="reviews"`).

## Minimalist pagination (admin-wide — `admin-dashboard.css`)

For any paged table in MMD admin panels (dashboards, role manager, course
manager, etc.) the pager is **flat text only — no buttons, no borders, no
chips**. The global rule lives in
`skin/adminhtml/default/default/admin-dashboard.css` and matches any class
ending in `-pg-btn` or `-page-btn` (e.g. `dash-pg-btn`, `al-pg-btn`,
`at-pg-btn`, `dev-page-btn`) plus the legacy `pagination-btn`. Works on
both `<button>` and `<a>` elements.

Specs:
- Container: `display:flex; gap:14px; align-items:center` — applied via
  `[class$="-pager-ctrls"]`.
- Item: `background:transparent`, `border:0`, `box-shadow:none`,
  `padding:2px 4px`, `font-size:12px`, `font-weight:400`, `color:#64748b`.
- Hover (not disabled): `color:#e2e8f0`. Nothing else changes.
- Active page: `color:#22d3ee`, `font-weight:600`. No background.
- Disabled (Prev at page 1, Next at last page): `opacity:.35`,
  `cursor:not-allowed`.
- Ellipsis: a `<span class="…-pg-ellipsis">` with `color:#475569`.

Markup convention (used by every existing pager):
```js
var b = document.createElement('button');
b.className = '<prefix>-pg-btn' + (opts.active ? ' active' : '')
                                + (opts.disabled ? ' disabled' : '');
b.textContent = label;     // 'Prev', '1', '2', …, 'Next'
```

Hard rules:
- **Never reintroduce filled "chip" pagination** (sky-blue background,
  rounded border, fixed `32×32` cells). The retired
  `button.pagination-btn` block in `sidebar-nav.css` was deliberately
  collapsed to a one-line comment pointer — don't restore it.
- New pagers MUST adopt the `-pg-btn` / `-pager-ctrls` / `-pg-ellipsis`
  suffix so the global rule applies automatically. No new bespoke CSS.
- The OpenMage legacy adminhtml `<button>` style ships a gradient + border;
  the global rule beats it via specificity + `!important`. Don't strip the
  `!important`s.

Reference implementation: dashboard master table pager
(`dashRenderPager` in `dashboard/index.phtml`).

## Grid Action column — icon-only (global rewrite)

Every adminhtml grid column declared as `'type' => 'action'` renders as
**icon buttons**, not text links or dropdowns. This is wired by a class
rewrite of `Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Action` to
`MMD_Adminhtml_Block_Widget_Grid_Column_Renderer_Action`
(see `app/code/local/MMD/Adminhtml/etc/config.xml`, key
`widget_grid_column_renderer_action`). Because the rewrite is global, you
do **not** add a `'renderer' => …` key on the column — the standard
`type => action` already resolves to the icon renderer.

How the renderer maps captions to icons:
- Caption is lowercased + stripped of HTML, then substring-matched.
- `view` / `show` → eye, `edit` → pencil, `delete` / `remove` → trash,
  `cancel` → ×, `print` / `pdf` → printer, `send` / `email` → paper plane.
- Anything unmatched falls back to the raw caption text inside the same
  styled anchor, so a new uncategorised action stays clickable.

**JS-injected per-row icons (mass-action mirror)** — grids without an
explicit `type => 'action'` column (Magento Tag, Tag Customer, etc.)
still get one icon per mass-action via
`sidebar-nav-v2.js::injectRowActions()`. It reads the mass-action
`<select>` options and emits an `.mmd-grid-actions` cell per row with
one `.mmd-grid-action--{kind}` button per option. The label → icon
mapping (`mmdMapActionIcon`) mirrors the PHP renderer's
`guessIconKey()` (view / edit / delete / cancel / print / send) and
adds `check` (approve / activate / enable / publish) and `more`
(everything unmatched). Clicking an icon checks only that row, sets
the mass-action select value, and submits — same semantics as the
old "Actions ▾" dropdown, only the trigger looks like every other
admin grid now.

When you add a new mass-action label that doesn't fit the existing
icons, extend BOTH the PHP `guessIconKey()` AND the JS
`mmdMapActionIcon()` so the icon column reads consistently whether
the grid declared a PHP action column or the JS injected one.

Per-row markup (auto-emitted):
```html
<div class="mmd-grid-actions">
  <a class="mmd-grid-action mmd-grid-action--view"   title="View"   href="…">SVG</a>
  <a class="mmd-grid-action mmd-grid-action--cancel" title="Cancel" href="…" onclick="…">SVG</a>
</div>
```

CSS is the existing `.mmd-grid-actions` / `.mmd-grid-action[--view|--edit|--delete|--cancel|--print|--send]`
block in `dark-theme.css`. Hover tints: cancel turns red (`#f87171`),
the rest tint blue (`#60a5fa`). Each anchor is a 26×26 ghost square with
a 1px border — same shape as the toolbar icon-only buttons described below.

Hard rules:
- **Never set `'renderer' => '…'` on an action column** — that bypasses
  the global rewrite and you'll get inconsistent text-link cells.
- **Never extend the icon table per-grid**. Add new icons to the
  `_icons` array in the global renderer so every grid benefits.
- Action columns should be **narrow** — 60–90px depending on icon count.
  Don't reserve the legacy 110px+ that the text-link version needed.

## Icon-only buttons (28×28 ghost pattern)

For toolbar icons (Editor/HTML mode toggle on rich-text textareas, delete row, etc.)
the canonical pattern is a **28×28 transparent square with a thin border**, holding a
14×14 SVG stroke icon. Reference implementation: `applyBtnStyle()` in
`skin/adminhtml/default/default/js/course-topics-tools.js`.

Specs:
- `28×28` exact, `border-radius: 5px`
- `background: transparent`, `border: 1px solid #475569` (active state: `border-color: #60a5fa`)
- 14×14 SVG with `stroke-width: 2`, `stroke-linecap: round`, `stroke-linejoin: round`, `fill: none`
- Inline `!important` styles to win against the generic `.admin-main button` rule

When clustering multiple icon buttons in a row, gap them with 4–6px. Group them in a
flex container above the textarea / field they control.

## Hard rule: icon > button for chrome-level actions

For anything that lives in **persistent admin chrome** — the topbar
(`.admin-topbar` / `.header-right`), sidebar headers, page header gutters, grid
toolbars — **prefer a bare icon over a rectangular button.** Buttons broadcast
"primary action, click me." Chrome actions are ambient affordances; a clean
glyph reads as part of the frame, not as a CTA competing with the page's real
primary button.

**Use an icon (no border, no background) when:**
- It's a global utility that lives on every page (theme toggle, notification
  bell, role switcher trigger, user menu trigger, dark/light, language).
- The label is communicated by the glyph alone + tooltip (a `title=` attr is
  enough; the action is recognized iconographically).
- It sits next to other icons of the same class — the row should read as a
  uniform strip of glyphs, not a cluster of pill buttons.

**Promote to a button only when:**
- The action is the page's primary task (Save, Add Course, Generate Class).
- A non-iconographic label is load-bearing ("Apply rule", "Recalculate") — i.e.
  no universally-understood icon exists.
- The action is destructive or scope-changing and benefits from a heavier
  visual weight to slow the user down.

**Canonical chrome-icon pattern** (no box, just glyph + optional badge):

> ⚠ **Override trap:** the canonical button system (`sidebar-nav.css` §18 +
> `boxes.css`) paints every `<button>` with padding / border / background /
> radius / box-shadow. A bare-glyph rule WITHOUT `!important` loses the cascade
> and renders as a rounded blue button (incident: audit bell 2026-05-29, shipped
> as a 28×28 outlined box for one push because `border:0` lost to
> `.admin-main button { border: 1px solid … }`). Force every visual property
> with `!important` and also reset `box-shadow`, `background-image`, `text-shadow`,
> `min-width`, `min-height`. The button "look" comes from a dozen properties —
> miss any one and you get a button back.

```css
.foo-icon-btn {
    position: relative !important;
    width: 28px !important; height: 28px !important;   /* hit-area, not visual size */
    min-width: 0 !important; min-height: 0 !important;
    padding: 0 !important; margin: 0 !important;
    border: 0 !important;                              /* NO border */
    border-radius: 0 !important;
    background: transparent !important;                /* NO background */
    background-image: none !important;
    box-shadow: none !important;
    text-shadow: none !important;
    color: #cbd5e1 !important;
    cursor: pointer;
    display: inline-flex !important;
    align-items: center; justify-content: center;
    line-height: 1 !important;
    font-size: 0 !important;                           /* kill text-node spacing */
    transition: color .15s ease, transform .15s ease, filter .15s ease;
    -webkit-appearance: none !important; appearance: none !important;
}
.foo-icon-btn:hover { color: #fff !important; background: transparent !important; box-shadow: none !important; transform: translateY(-1px); }
.foo-icon-btn:active { background: transparent !important; box-shadow: none !important; }
.foo-icon-btn:focus { outline: none; box-shadow: none !important; }
.foo-icon-btn:focus-visible {
    outline: 2px solid rgba(255,255,255,.35);
    outline-offset: 2px;
    border-radius: 4px;
}
.foo-icon-btn svg { display: block; pointer-events: none; }
/* Severity tint via filter:drop-shadow, NOT box-shadow — the latter draws a
   rectangle behind the glyph and reintroduces button chrome. */
.foo-icon-btn.is-critical { color: #ff3b5c; filter: drop-shadow(0 0 6px rgba(255,59,92,.55)); }
.foo-icon-btn.is-warning  { color: #f5c451; filter: drop-shadow(0 0 5px rgba(245,196,81,.45)); }
```

Reference implementation: the audit-issues bell in
`app/design/adminhtml/default/default/template/page/header.phtml` /
`dark-theme.css` (`.audit-bell-btn` + `.audit-bell-badge`). The bell sits in
`.header-right` alongside theme-toggle and user-avatar — all three are bare
glyphs, no boxes, so the strip reads as one continuous icon row.

**Notification badge over an icon** — when a chrome icon needs a count:

- Small pill anchored top-right of the glyph, `min-width: 15px; height: 15px;
  border-radius: 8px; font-size: 9.5px; font-weight: 700`.
- Use `box-shadow: 0 0 0 2px var(--d2)` (NOT a `border:`) to carve a halo against
  the topbar background — borders would shift the badge geometry every time the
  topbar bg changes.
- Severity color drives the badge fill: red `#ff3b5c` for critical, amber
  `#f5c451` for warning, slate `#8aa1bd` for info.
- Add `pointer-events: none` so the badge never eats clicks meant for the glyph.

**Motion**: a critical icon can carry a gentle attention cue (drop-shadow
intensifying, a 3s swing keyframe on the SVG itself with
`transform-origin: 50% 18%`). Don't pulse the whole element — pulsing a bare
icon stays subtle, pulsing a bordered button reads as a faulty alert dialog.

If you find yourself adding `border:`, `background:`, or `border-radius` larger
than 4px to a chrome action, you're building a button. Stop, and ask whether
the action belongs in the chrome at all — if yes, go back to the bare glyph; if
no, move it to the page body where buttons live.

## Minimalist checkbox (admin-wide — `dark-theme.css`)

Flat, no native gray inner box. The global rule is in `dark-theme.css` (the
`input[type="checkbox"]` block).

Specs:
- `16×16`, `border-radius: 4px`, `1.5px solid #475569`, transparent background
- `appearance: none` — kills the native browser checkbox entirely
- Hover: border lightens to `#64748b`
- Checked: solid `#2563eb` fill + inline white SVG checkmark (encoded as `data:image/svg+xml` so no extra HTTP request)
- Indeterminate: solid blue + horizontal dash (use `el.indeterminate = true` from JS for tri-state)
- Focus: 2px blue outline with 2px offset
- Disabled: 40% opacity

**Carve-out:** `.dcf-toggle-sw input[type="checkbox"]` resets back to invisible
(`width:0;height:0;opacity:0`) because the iOS-style slider sibling does the visual
work. If you build a new custom toggle (radio pill, switch), follow the same pattern:
hide the native input, render your own element, sync via `:checked`.

Don't reintroduce `accent-color` — once we went `appearance:none` the gray inner box
is gone and `accent-color` is moot.

## Buttons (the canonical component — `sidebar-nav.css` §18)

One language everywhere. Don't restyle buttons per page.

### Three sizes, three jobs

| Variant | Where it appears | Size | Shape | Color |
|---------|------------------|------|-------|-------|
| **Page action** (default §18) | Page-level Save / Cancel / Add New | `min-height: 38px`, `padding: 8px 20px`, `font: 13px/1`, `border-radius: 9px` | Rounded rect | Per semantic class (see below) |
| **Toolbar / mass-action Submit** (§16) | Inside `.massaction` and `[id$="_massaction"]` toolbars on every grid | `height: 24px`, `padding: 0 14px`, `font: 11px/1`, `border-radius: 999px` | **Full pill** | Light blue gradient (`--blue` → `--blue2`) on hover (`--blue2` → `--blue3`) |
| **Pagination / row action** | Pagination bar, per-row dropdown trigger | `padding: 4px 10px`, `font: 11px`, `border-radius: 6px` | Rounded rect | Quiet (`--d4` bg, `--b2` border) |

The toolbar Submit is **the same shape and size on every grid** — cache, index management, sales orders, customers, all of it. If a grid Submit looks different from the others, that's a bug, not a design choice. Don't write per-grid Submit overrides; the §16 rule already covers them via `.admin-main .massaction button.scalable` (specificity 3 — beats §18's 2-class rule, so no need to fight order in the cascade).

### Semantic color classes (page-action variant)

**HARD RULE: every backend button is the same blue.** One color across the entire admin — no red, no green, no orange, no other accents. The Tertiary admin uses contrast, weight, and placement (not hue) for emphasis. A grid full of multi-color buttons reads as a kiosk; the admin is a workbench.

- **Primary** (default `button`, `button.scalable`, `input[type=submit]`): `--btn-primary` (blue), white text, soft elevation.
- **Save / Add / Success** (`.add`, `.save`, `.success`): `--btn-primary` (blue) — same as primary.
- **Delete / Cancel** (`.delete`, `.cancel`, "Flush" / "Reset" / "Delete" header actions): **also `--btn-primary` (blue).** Confirmation is handled by a `confirm()` dialog or destructive copy ("Delete record? This cannot be undone."), not by colour. The `--btn-danger` token still exists in `dark-theme.css` for legacy reasons but **must not appear on a button**.
- **Secondary / Back** (`.back`, `.secondary`): transparent fill with a `var(--blue)` outline and `var(--blue)` text. Hover fills with `rgba(96,165,250,0.12)`. Not gray.

If you find yourself reaching for red, green, orange, or yellow on a button, that's the bug — pick blue. The legacy `--btn-success` and `--btn-danger` tokens remain in `dark-theme.css` only for status pills (badge tints), never buttons.

### Shared rules

- Exactly **one primary** per action area.
- Destructive page-level actions (Delete, Flush, Reset, Cancel) use the **same blue** as everything else — gate them with a `confirm()` prompt or strong copy, never a red button.
- Toolbar Submit uses the same light-blue pill — consistent with every other button on the page.
- `:active` press uses `translateY(1px)`.
- `:focus-visible` ring uses `--ring`.
- Disabled = `opacity: 0.5` + `cursor: not-allowed`.
- Magento wraps labels in nested `<span>` — kill legacy span backgrounds (already handled in §18 and §16), don't re-add.

### Processing state

When a mass-action Submit kicks off a long-running operation (reindex, cache flush, mass-update), show the `.mmd-processing-overlay` full-screen scrim with a spinner + the action label (e.g. "Reindex Data…"). Wired in `sidebar-nav-v2.js::wireMassactionSpinner` — auto-attaches to every `[id$="_massaction"] button` and uses the selected action label as the spinner caption. Skips when the "N items selected" counter shows 0 (Magento alerts and won't navigate; overlay would hang). Page navigation tears the overlay down naturally.

## Grids, toolbars, badges

- **Grids** (`.grid`) — ONE global flat framework, `sidebar-nav.css` §26 (single source of truth). Every admin grid renders identically regardless of the Magento table class (`table.data` / `table.border`) or zebra markup:
  - **Cells transparent** — no white/gray fill, NO alternating (zebra) row shade. §26 out-specifies the legacy `boxes.css` `!important` fills (`.grid table.border td { background:#fff }` at (0,2,2), `.grid tbody.odd/even tr` zebra) by leading every rule with `.admin-main .grid` + the same class(es), landing one class higher. Do NOT lower that specificity or a per-page override, and the legacy fills, will win back.
  - **One type ramp** — cells `var(--font-sans)` 12px, `6px 10px` padding; headers `var(--font-sans)` 11px uppercase `--t4`, `letter-spacing:0.6px`, transparent (no `sort_row_bg.gif` sprite).
  - **One record = one row** — `white-space:nowrap` on every grid `td`; wide grids scroll horizontally via the `.hor-scroll` wrapper (nothing is hidden). Don't force a `min-width` that clips columns.
  - **Separation = one hairline** between rows (`tr + tr td { border-top: 1px var(--b1) }`), never a background. Hover = subtle `rgba(96,165,250,0.06)` wash on the row (no teal text, no zebra).
  - New admin grid needs zero grid CSS — it inherits §26 automatically. Never re-add a card background, zebra, or per-grid font-size; that's the drift §26 exists to kill.
- **Custom MMD tables** (dashboard registrations, learner/trainer lists, review lists, config tables) — `sidebar-nav.css` §27 applies the SAME spec as §26 so the WHOLE backend has one table look. It is a **framework net, not a whitelist**: MMD data tables all use the `*-table` naming convention, so §27 matches `.admin-main table[class*="-table"]` (+ the one odd `.cs-tbl`) — every current and future custom table (`dash-table`, `al-table`, `at-table`, `trn-table`, `dash-detail-table`, `mm-table`, …) inherits transparent cells, `var(--font-sans)` 12px, `6px 10px` padding, single-row, hairline separators, flat 11px uppercase headers, and flat (un-carded) `*-table-wrap` wrappers — automatically. §27 does NOT force cell text color, so `.mm-table` semantic modifiers (`td.muted`/`strong`/`status`) survive. Rule for new custom tables: name it `…-table`, give it a `thead`/`tbody`, and it just works — never set your own padding/font-size/header background. Incident: page after page of bespoke `*-table` CSS (11.5–13px fonts, 4–16px padding, header cards) read as different components until the net unified them.
- **Mass-action / toolbar:** slim self-contained card, **detached** from the grid (own `margin-bottom` + full radius — don't fuse it to the grid header), single flat flex row, selection links left, Actions+Submit right with **no nested panel box**. Controls ~`30px` tall. The global rule is `sidebar-nav.css` §16; the trap is that Magento wraps Actions+Submit in a bare `<fieldset>` (no class) and the right `<td>` may contain `<form>` / nested `<div>`s that pick up `--d3` bg + 20px padding from the generic admin form rules, rendering as a doubled gray panel-in-a-panel. §16a flattens every `[id$="_massaction"] fieldset`, `.massaction fieldset`, `.massaction form`, `.massaction form > div` (transparent bg, no border, no padding). §16b strips the dark-pill background off `.massaction a` so Select All / Unselect All / Select Visible / Unselect Visible render as plain blue links — they're navigation, not buttons. §16c sets the selection-links `td` to `inline-flex; gap:14px;`. Wrapper padding stays tight at `6px 12px`. Pattern reference: the `body.adminhtml-cache-index` block at the end of `sidebar-nav.css`.
- **Status badges:** one clean pill — `padding:3px 12px`, `border-radius:999px`, tinted bg at ~15% alpha + solid semantic text color, 1px tinted ring at ~35% alpha. Token map: `notice`/`minor` → `--green`, `major` → `--yellow`, `critical` → `--red`. The global rule lives at `dark-theme.css` §19. **Don't style only the outer `.grid-severity-*`** — Magento 1's legacy `boxes.css` applies the `bg_notifications.gif` sprite to the inner `<span>` at `background-position: 100%`, and the right edge of that sprite is a serrated/torn shape that leaks through as notched edges on the pill. §19a flattens the inner span first (`.grid-severity-* span`, `.cell-status`, `.cell-status span` → `background:none`, `padding:0`, `border:0`); §19b/§19c then style the pill on the outer. If you add a new severity class, extend §19a's selector list too — otherwise the sprite re-appears.
- **KPI cards:** only where genuinely useful. The JS auto-injects them on grids via generic heuristics — opt a grid out (like `cache_grid_table`) when the labels would be wrong or the cards just add clutter.

## Section headers inside admin pages

Magento often emits a sub-section title as a bare `<h3>` (no class) inside a
layout `<table>` — the cache page's "Additional Cache Management" is the
canonical example. The global `h3` is 26px, designed for page titles, and
looks enormous as a sub-section label.

Pattern: scope to the body class, set `<h3>` to a small uppercase muted
label (`font: 700 12px/1.4 …; color: var(--t4); text-transform:uppercase;
letter-spacing:0.6px`), and flatten the wrapper table with
`table:has(> tbody > tr > td > h3)` — `:has()` is widely supported and
precisely matches only the title-bearing layout table, not adjacent
`.form-list` / `.grid` / `.massaction` tables. See the
`body.adminhtml-cache-index` block at the end of `sidebar-nav.css`.

For the `.form-list` of action rows beneath (flush buttons + descriptions),
treat it as one card: `--d3` bg, `--b1` outer border, `border-radius:10px`,
`overflow:hidden`, and use `tr + tr { border-top: 1px solid var(--b1) }`
for hairline separators instead of `tr { border-bottom: ... }` (avoids
ambiguity with `:last-child`). Buttons inside such rows shrink to
~30px height to keep the panel compact.

## Hard rule: NO gray backgrounds on inputs or table cells

**Banned across the entire admin.** The legacy Magento "gray pill" input
(`background: #4b5563 / --d5`) and any gray fill on `<td>` or `<input>` are
forbidden — they clash with the dark page surface and read as disabled even
when they're not. The matrix on Manage Currency Rates was the worst offender;
it's now flat.

Rules:

- **Inputs** (`.input-text`, `<input type=text|password|email|number|url>`, `<textarea>`) are **transparent** with a `1px var(--b2)` border. Focus gets a faint blue wash (`rgba(96,165,250,0.06)`) — never a gray fill. Readonly/disabled keep the transparent background and switch the text to `--t4`.
- **Table cells** (`<td>`, including zebra striping) are transparent. Row separation comes from `1px var(--b1)` hairlines on `tr`, not from alternating gray backgrounds. The canonical rule lives in `sidebar-nav.css` §20 (the `.admin-main .input-text` block); per-page overrides must keep `background: transparent !important` for inputs.
- **No new exceptions.** If you find yourself reaching for `background: var(--d4)`/`--d5` on a `<td>` or an `<input>`, that's the bug — pick a border, a hover ring, or a card wrapper instead.
- When adding a new admin page or overriding a core template, scope inputs explicitly: `body.<route> .grid input.input-text { background: transparent !important; }`. The global rule already handles it, but cached/merged CSS (`media/css/HASH.css`) sometimes lags — explicit per-page rules survive the cache.

## Hard rule: NO gray container behind page headers

**Banned globally.** Page-title strips and panel headers must sit flush on the
page surface — no filled gray container, no rounded gray pill, no `--d3`/`--d4`
wrapper behind the `<h1>` or `<h3>`. The legacy Magento `.page-head`,
`.entry-edit-head`, `.box-head`, and `.head` rules used to paint a gray strip;
this clutters the dark theme and makes every page look like it has a stuck
toolbar.

Rules:

- **All header containers are `background: transparent`** — `.page-head`,
  `.page-head-container`, `.entry-edit-head`, `.box-head`, `.head`, and any
  page-scoped `.section-config > .config` header wrapper. Use a `1px var(--b1)`
  bottom hairline for separation if needed — never a fill.
- **No gray on parent wrappers either.** `.col-main`, `.col-1-layout`,
  `.middle`, `.main-col-inner` stay transparent. The only legitimate filled
  surface is a true card (`--d3` bg + border + radius) wrapping form rows.
- Canonical rules live in `dark-theme.css` (`.page-head` → transparent) and
  `sidebar-nav.css` §header (`.entry-edit-head, .box-head, .head` → transparent).
  If you spot a new gray strip, patch at source — don't layer overrides.

## Branch / store filter pills (admin-wide — `admin-dashboard.css`)

When a page lets the admin filter by country / store view (Search Terms,
Search Spam cleanup, Marketing Dashboard, Registrations, etc.) the strip is
**always** the canonical pill component. Defined in
`skin/adminhtml/default/default/admin-dashboard.css` (`.dev-country-tabs` +
`.dev-country-btn`). Default state = ghost (transparent + slate border),
active state = solid `--brand` (`#2563eb`) fill with white text.

Markup (use this exact class set — no per-page CSS):

```html
<div class="dev-country-tabs" role="tablist" aria-label="Filter by branch">
    <a class="dev-country-btn active" href="?store=0"
       role="tab" aria-selected="true"  data-store-id="0">All</a>
    <a class="dev-country-btn"        href="?store=1"
       role="tab" aria-selected="false" data-store-id="1">Singapore</a>
    <!-- … one per store … -->
</div>
```

Hard rules:

- **Never invent a parallel class** (`.mmd-store-tabs`, `.search-tabs`,
  `.country-filter`, etc.). That was the v1 mistake on Search Terms; the
  retired `.mmd-store-tabs` block in `sidebar-nav.css` was deleted so the
  alternative no longer exists.
- **Never style "connected tab" markup** (shared bottom border, no gap
  between tabs, rounded only on the top corners). The canonical pill is a
  separated rounded rectangle with `gap: 6px`.
- The active pill is the **brand blue solid**, not a tinted hover state, not
  a darker gray — the contrast is intentional so admins can spot which scope
  they're in at a glance.
- The strip wraps on narrow viewports (already in the canonical rule); don't
  set `flex-wrap: nowrap` or a fixed width per-page.
- Branchscope (`MMD_Branchscope_Block_Store_Switcher`) already emits this
  exact markup on every standard Magento admin page — your new feature
  inherits the same look automatically just by reusing the class names.

Reference rendering: branch pills above the Marketing Dashboard, Lead
Manager, Registrations grid, and Search Terms page.

## Page-level button registration (admin-wide — Mage_Adminhtml_Block_Widget_Container)

Page-level action buttons in the `.content-header` toolbar (Add New, Save,
Delete, "Clean Spam", "Export CSV", etc.) are registered on the container
block via `_addButton()`, **not** emitted as raw markup in the template.

```php
// In a container block constructor or _prepareLayout():
$this->_addButton('clean_spam', array(
    'label'   => Mage::helper('catalog')->__('Clean Spam'),
    'onclick' => "setLocation('" . $this->getUrl('mmd/catalog_search_spam/index') . "')",
    'class'   => '',          // empty = default page-action style
), 0, 5);
```

The container's `getButtonsHtml()` renders all registered buttons through
the same `Mage_Adminhtml_Block_Widget_Button` pipeline — so they share the
exact §18 size, padding, border-radius, font weight, and hover state with
every other page-action button in the admin.

Hard rules:

- **Never write `<a class="button">…</a>` in a phtml** to add a new
  page-action button — that path produces a noticeably smaller, visually
  inconsistent control (the link doesn't inherit the §18 button block).
  That was the v1 mistake on Search Terms / Clean Spam.
- **Never duplicate `Add New …` markup** with a hand-rolled `<button>`
  alongside it — call `_addButton()` for both so they render identically.
- For in-form / in-card buttons (Save inside a fieldset, "Add Row" inside
  a sub-grid), use the `.mm-btn` / `.mm-btn-primary` family from the
  Minimalist button section above. Container `_addButton()` is *only* for
  the page-level toolbar.

## Per-page overrides

When a core Magento admin page needs different behavior from the global
enhancements, scope by the body class `body.adminhtml-<route>-<controller>-<action>`
(e.g. `body.adminhtml-cache-index`) and/or the grid's id (`#<grid>_table`), and
add a JS opt-out in `sidebar-nav-v2.js` if the enhancement actively breaks it.
Keep overrides in a clearly commented, numbered section at the end of
`sidebar-nav.css`. Reuse tokens — overrides change *layout*, not the palette.

## Checklist before finishing any admin UI change

1. No raw hex/px-padding that a token or §18/§14 rule already covers.
2. Buttons in **new MMD UI** use the `mm-btn` family (`.mm-btn-primary` / `.mm-btn-ghost` / `.mm-btn-sm`). One primary per area. No inline `style="background:..."`, no gradients, no shadows, no uppercase. Native Magento `.scalable` toolbar buttons stay on §18/§16.
3. Icon-only buttons follow the 28×28 ghost pattern (transparent + thin border + 14×14 stroke SVG). Reference `applyBtnStyle()` in `course-topics-tools.js`.
4. Checkboxes inherit the global minimalist style — no `accent-color`, no per-page checkbox CSS, no native gray fill. If a checkbox must look different (sliders, toggles), hide the input and render a sibling element.
5. Interactive elements have a `--ring` `:focus-visible` state.
6. New override is body-class/id scoped and won't leak to other grids.
7. **No gray backgrounds** on `<input>`, `<textarea>`, or `<td>` — transparent + border only. (See "Hard rule" section above.)
8. Verified in the dark theme at the actual page. CSS/JS merging is on in admin — after editing `sidebar-nav.css`, flush **System → Cache Management → JavaScript/CSS Cache** before hard-refresh, or the bundled `media/css/HASH.css` will still serve the old rules.
9. **Store View bar** on every store-scoped admin page uses the canonical `.dcf-store-switcher` markup (see "Store View bar" section below) — never re-implement inline. The global `MMD_Branchscope_Block_Store_Switcher` injects it into `<content>` automatically; per-page templates only render the inline version when they pre-existed the global bar (Edit Course) AND need to preserve extra URL state across switches (e.g. `course_id`, `mode`, `dev_back`). On those routes add a suppression branch in `Switcher.php`. Legacy `.dev-country-tabs` / `.dev-country-btn` is retained only for the in-panel Manage Courses filter (which doubles as a list filter), not for the universal switcher.
10. **Page-level action buttons** are registered via `_addButton()` on the container block — no raw `<a class="button">` or `<button>` markup in templates for toolbar actions.
11. Typography inherits from `dark-theme.css` — no per-page `font-family` or base `font-size` overrides; new headings/labels reuse the density-preference scale at the top of this doc.

## Store View bar (canonical)

Every store-scoped admin page renders one horizontal Store View bar — six
country pills (SG / MY / GH / NG / BT / IN), each with a 2-letter code
badge and full store name, plus a right-aligned "Scope" info link. The
active pill uses the cyan accent (`rgba(34,211,238,*)`); inactive pills
are transparent with a hover-only border.

**Source of truth:** the global block
`MMD_Branchscope_Block_Store_Switcher` (registered in
`layout/branchscope.xml` under `<default>` as `mmd.branch.pills.global`)
emits the markup. CSS lives in `skin/adminhtml/default/default/admin-dashboard.css`
under "Global Store View bar". Never re-implement either inline.

**Markup contract** (keep these classes — they are styled by the global
CSS and by the Edit Course inline fallback):

```html
<div class="dcf-store-switcher mmd-branchscope-pills" role="tablist" aria-label="Store view">
  <span class="dcf-store-switcher-label">Store View:</span>
  <a class="dcf-store-tab is-active" href="?store=1" role="tab" aria-selected="true" data-store-id="1">
    <span class="dcf-store-tab-flag">SG</span>
    <span class="dcf-store-tab-name">Singapore</span>
  </a>
  <!-- …MY / GH / NG / BT / IN… -->
  <span class="dcf-store-switcher-hint" title="…"><svg/>…<span>Scope</span></span>
</div>
```

**Edit-mode pages** (Edit Course today, Edit Category / CMS Page tomorrow)
that need a "Editing for: <Store> [CC]" affordance pair the bar with the
amber edit notice and a cyan chip:

```html
<span class="dcf-active-store-pill">
  <svg/>Editing for: <strong>Singapore</strong>
  <span class="dcf-active-store-code">SG</span>
</span>
```

**Rules**
- Six country stores only — exclude `All` (store_id 0) and `Infotech` (store_id 7).
- Helper: call `Mage::helper('branchscope')->getCountryStorePillOptions()` — it returns the canonical 6-store list with `code`. Do not iterate `core/store` directly.
- Role gating: hide for `learner` and `trainer`. All other roles (developer, marketing, admin, super-admin / training_provider) see the bar on store-scoped routes; admin + super-admin see it on every route.
- Suppress the global bar on any route that emits its own inline Store View bar (Edit Course already does this — extend the `getNameInLayout() === 'mmd.branch.pills.global'` switch in `Switcher.php` when adding new pre-existing inline bars).
- Do not invent new class names like `mmd-sv-*`, `store-view-tabs`, etc. — the canonical names are `.dcf-store-switcher` / `.dcf-store-tab` / `.dcf-store-tab-flag`.

**Universal-for-operators invariant (MANDATORY)** — the four operator
roles (developer, marketing, admin, super-admin / `training_provider`)
see the Store View bar AND the "Viewing / Editing for: <Country>"
header notice on **every** adminhtml page, full stop. This is the
"which country am I working in" anchor; hiding it on report / tax /
newsletter-template pages because those grids don't filter is a
regression, not a feature. The bar bypasses `isStoreScopedRoute()`
for these roles by design (`$isFullAdmin` branch in
[Switcher.php](app/code/local/MMD/Branchscope/Block/Store/Switcher.php)).
Learner and trainer roles are scoped to their own country and never
see the bar. If role detection returns empty (session not yet seeded,
helper exception), the bar defaults to visible — silent disappearance
is the worst failure mode.

**Filtering contract (MANDATORY)** — the bar is not decoration. If a page
renders the Store View bar, clicking a pill **must actually filter the
page data**. The pill writes `?store=N` to the URL; the page is
responsible for honouring it. The contract is broken silently on any
admin grid where stock Magento ignores the param (Reviews, Search Terms,
some Newsletter grids, Tag, several report grids). Before shipping a new
or rewritten admin list/grid, verify:

1. Load the page with `?store=0` (or no param) — all rows visible.
2. Load with `?store=3` (Ghana) — only Ghana-scoped rows remain.
3. If the underlying collection has no store filter method, add one in
   the MMD override (e.g. `MMD_Adminhtml_Block_Review_Grid::_prepareCollection`
   calls `$collection->addStoreFilter($storeId)` when `?store=` > 0).
4. For grids whose data is truly global (no store dimension — e.g.
   Permissions, Cache, Manage Stores), suppress the bar instead by
   leaving the controller out of `MMD_Branchscope_Helper_Data::isStoreScopedRoute()`.
   **Showing the bar but ignoring the param is the worst-of-both
   outcome and is forbidden.**

Reference fix: [Block/Review/Grid.php](app/code/local/MMD/Adminhtml/Block/Review/Grid.php) `_prepareCollection` — calls `addStoreFilter()` because the core review grid only joins store data for display and never filters by `?store=`.
