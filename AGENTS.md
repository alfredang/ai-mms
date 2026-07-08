# AGENTS.md

Guidance for Codex when working in this repository.

## Behavioral Guidelines

Four core principles for reducing coding mistakes (adapted from
[andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/AGENTS.md)).
They govern *how* to work in this repo and sit above the project-specific rules below.

1. **Think before coding.** *"Don't assume. Don't hide confusion. Surface
   tradeoffs."* State assumptions explicitly, present multiple interpretations
   rather than silently picking one, and raise confusion **before**
   implementation begins.

2. **Simplicity first.** *"Minimum code that solves the problem. Nothing
   speculative."* No unrequested features, unnecessary abstractions, premature
   error handling, or speculative flexibility. If the code could be
   significantly shorter, rewrite it.

3. **Surgical changes.** *"Touch only what you must. Clean up only your own
   mess."* Match the current style of the file you're editing, don't refactor
   unrelated code, and only remove imports/functions that *your* change made
   obsolete — not pre-existing dead code. (In this repo: prefer a small,
   reviewable migration or a scoped override over a sweeping rewrite.)

4. **Goal-driven execution.** *"Define success criteria. Loop until verified."*
   Convert a vague task into testable objectives with explicit verification
   steps; for multi-step work, lay out a brief plan with checkpoints rather
   than relying on continuous back-and-forth. (Here, "verified" means the
   mandatory pre-push checks below pass — lint, instantiation, route, migration
   dry-run.)

The aim: fewer unnecessary diffs, no overengineered rewrites, and clarifying
questions raised *before* a mistake is committed.

## Project Overview

OpenMage 1.x (Magento 1 LTS v20.12.3) customized as a Course Registration + LMS (Learning Management) system for **Tertiary Infotech Academy**. PHP 8.2, MySQL 5.7, Apache, Docker. Deployed to Coolify; local dev via `docker-compose`.

**Business reality — keep this in mind for every change:**

- **All products are courses** (instructor-led trainings, workshops, certifications). There is **no physical inventory and no shipping**. Stock, weight, dimensions, shipping methods, tracking numbers, and similar Magento concepts do not apply — if a feature surfaces them, hide / disable / repurpose them rather than wiring them up.
- **All deliveries are virtual or classroom-based** (in-person classroom, live online, or hybrid). The "shopping" flow is really a course-registration flow; prefer renaming labels to match (e.g. "Order" → "Registration", "Customer" → "Learner") rather than fighting the underlying schema.
- **Multi-country operation** with one Magento install and one shared course catalog. Each country is a Magento website / store view with its own domain, currency, language defaults, and pricing:
  - 🇸🇬 Singapore — `tertiarycourses.com.sg` (default website)
  - 🇲🇾 Malaysia — `tertiarycourses.com.my`
  - 🇳🇬 Nigeria — `tertiarycourses.com.ng`
  - 🇬🇭 Ghana — `tertiarycourses.com.gh`
  - 🇧🇹 Bhutan — `tertiarycourses.bt`
  - 🇮🇳 India — `tertiarycourses.co.in`
- **No shipping cost, ever.** Shipping is disabled across all stores and there is no shipping line on any quote, order, invoice, or email template. If you see code that adds, calculates, or displays shipping_amount / shipping_method / shipping_tax_amount, treat it as legacy noise — leave it at zero or remove the surfacing.
- **GST is non-standard for Singapore** and intentionally diverges from Magento's tax engine. SG GST is calculated on the **original course list price** (the catalog price before any discount), **not** the discounted subtotal and **not** any custom-option adjustments. Don't "fix" this to match Magento's stock behavior — the override is deliberate so funded learners (SkillsFuture / WSQ subsidies discount the fee but GST still settles on the pre-subsidy amount as the tax authority expects). Other countries (MY/NG/GH/BT/IN) use their own logic per their tax regimes.
- **Country-specific funding hooks** matter for marketing & checkout: SG SkillsFuture / WSQ / IBF, MY HRDC. Don't strip these references when refactoring storefront templates.
- **Course code (SKU) prefix conventions** — use these to gate per-segment storefront/template logic:
  - 🇸🇬 SG **WSQ** courses: SKU starts with `TGS-` (the SKU *is* the SkillsFuture course reference).
  - 🇸🇬 SG **non-WSQ** courses: SKU starts with `C` (e.g. `C6`, `C009`).
  - 🌏 All **other stores** (MY/NG/GH/BT/IN): SKU starts with `M`.
  When a feature should only fire for one segment (funding tiles, subsidy badges, WSQ-specific copy), key off the SKU prefix **and** `Mage::app()->getStore()->getCode()` together — never assume "all SG = WSQ" or "all C-prefix = SG".
- **The admin panel is rebranded** as "Tertiary Infotech Academy — Magento Management System". Treat the admin as a TMS for instructors + operations staff, not a generic e-commerce backoffice.

### LMS data model — single source of truth

This is an **LMS** built on Magento, not a generic e-commerce store. The storefront IS the course-registration portal. Read this before touching any code that involves users, orders, classes, trainers, or rosters.

**Frontend invariant (do not break)**: the storefront cart, checkout, payment, success page, and transactional emails follow stock Magento + Ultimo. No observer is wired on `sales_order_place_after` or `checkout_*` events for class formation. All LMS materialisation happens out-of-band in the BACKEND.

**Six axioms** (every future change must preserve these):

1. **Product = Course.** `catalog_product_entity` rows are courses. `sku` = course code; `name` = course title.
2. **Class identity = `(course_code, course_title, course_start_date)`.** Two orders for the same SKU on the same date join the same class. A different date = a different class even if the course is identical.
3. **Class storage = one `course_runs` row.** Columns: `product_id`, `course_sku`, `course_start_date`, `course_start_time`, `course_end_date`, `course_end_time`, `trainer_option_id`, `vacancy`. PK `run_id`. Human label `class_id` formatted `<STORE_CODE>######` (e.g. `SG000042`, `MY000017`, `GH000003`, `NG000005`, `BT000001`, `IN000002`). Prefix derives from the originating order's `store_id`; counter is zero-padded and scoped per prefix. Generated by `MMD_RoleManager_Helper_Data::nextClassId()` — reuse this helper, do not invent another ID scheme.
4. **Order = Registration.** A `sales_flat_order_item` carrying the "Course Date" + "Course Time" custom-option values IS the learner registering for that class. The Magento order table is the registration table — never add a parallel registration table.
5. **Roster = `course_run_enrolments`** rows for a given `run_id`. `UNIQUE KEY (product_id, run_id, learner_email)` means inserts are idempotent — re-running materialisation never duplicates.
6. **Users = the six-role union, with unified accounts.** The Users admin page (`adminhtml/rolemanagement/index`) lists `admin_user` (Trainer / Developer / Marketing / Admin / Super Admin operators) plus `customer_entity` (Learners). **As of the 2026-06 account-unification refactor, every storefront learner ALSO gets a shadow `admin_user`** (username = email, `learner` role in `mmd_user_role_map`, created `is_active = 0`) with its password kept in sync with the customer account — so learners can eventually log into the dashboard. This is handled by **`MMD_AccountSync`** (observers on `customer_save_after` + `admin_user_save_after`) and the backfill `scripts/maintenance/backfill-learner-dashboard-accounts.php`. The Users page excludes pure-learner shadow `admin_user`s from its operator list (`HAVING roles <> 'learner'`) so each person shows once. See memory `project-account-unification`.

**Materialisation flow** (backend-only — no storefront code path runs this):

```
Storefront                  Backend (cron, every 1 min)
    │
    ▼
customer_entity ────► sales_flat_order ────► [MMD_RoleManager_Model_Cron_ClassFormation]
  (Learner)            (Registration)              │
                                                   ▼
                                          CourseRunEnrolmentService::assignOrderItem()
                                                   │
                              ┌────────────────────┼────────────────────┐
                              ▼                                         ▼
                       course_runs                              course_run_enrolments
                       (Class instance,                         (Roster row,
                        keyed by class_id)                       UNIQUE on product/run/email)
```

**Controlling files** (modify with care — these are the load-bearing pieces):

- `app/code/local/MMD/RoleManager/Model/CourseRunEnrolmentService.php` — parses date/time custom options, finds or creates `course_runs`, inserts into `course_run_enrolments`. 20+ date-format fallbacks. Idempotent via `INSERT IGNORE`. Skips TGS- SKUs (external system) and bundle/configurable children.
- `app/code/local/MMD/RoleManager/Model/Cron/ClassFormation.php` — the backend worker that calls the service for every new order. Reads `sales_flat_order` only; tracks "last processed" in `core_config_data['mmd/class_formation/last_processed_order_id']`. Never modifies sales tables.
- `app/code/local/MMD/RoleManager/Helper/Data.php::nextClassId()` + `countryCodeForProduct()` — generate the `SG000042`-style identifiers.
- `app/code/local/MMD/RoleManager/controllers/Adminhtml/ClassesController.php` + `template/rolemanager/classes.phtml` — admin grid (Class Management → All Classes) listing every class with roster count, date, trainer, state.
- `app/design/adminhtml/default/default/template/rolemanager/management.phtml` — Users page; UNIONs `admin_user` + `customer_entity` and joins `sales_flat_order` for learner's home store + first-order date.
- `scripts/maintenance/backfill-class-rosters.php` — one-shot CLI to materialise historical orders. Resumable via `core_config_data['mmd/class_formation/backfill_last_id']`.

**Hard "don't" list**:
- Don't add a parallel registration / class / learner table.
- Don't add an observer on storefront `checkout_*` or `sales_order_place_after` events — class formation is cron-driven specifically to keep the frontend HTTP path untouched.
- Don't rename `class_id` or alter the `<STORE_CODE>######` format — downstream UI deep-links and learner-facing certificates depend on it.
- ~~Don't auto-create admin_user rows for storefront customers~~ — **reversed by the 2026-06 account-unification refactor.** Storefront learners now DO get a shadow `admin_user` (learner role, `is_active = 0`, synced password) via `MMD_AccountSync`. Don't strip that module or the sync observers. Learner shadow accounts stay **inactive** until the learner-role ACL is locked down (so an active learner login can't reach full admin) — see memory `project-account-unification`.

## Pre-push verification (MANDATORY)

**Never `git push` until localhost is verified error-free.** Production redeploys
on every push to `main` (Coolify) and a broken push takes the whole admin down
for the build window. Localhost is the safety net.

Before `git push`:

1. **Lint every changed PHP file** inside the container:
   ```bash
   docker exec ai-mms-web-1 php -l /var/www/html/<path>
   ```
   Repeat per file. Lint clean ≠ runtime clean (next step matters more).

2. **For class rewrites / block overrides / observers** — confirm the class
   actually instantiates against the live config:
   ```bash
   docker exec ai-mms-web-1 php -r "
     require_once '/var/www/html/app/Mage.php';
     Mage::app();
     \$b = Mage::app()->getLayout()->createBlock('<alias>');
     var_dump(get_class(\$b));   // must print the rewritten class
   "
   ```
   If `createBlock` returns `bool(false)` the class is broken / missing / its
   parent fails to load. Common cause: registering a rewrite in `config.xml`
   without committing the matching class file (`git status` will show the
   file as untracked).

3. **Hit the affected route via HTTP** and confirm no fatal:
   ```bash
   curl -sS -o /tmp/p.html -w "HTTP=%{http_code}\n" -L \
       'http://localhost:8080/tigerdragon/<route>'
   grep -c "Fatal error\|Uncaught" /tmp/p.html   # must print 0
   ```

4. **Check that every new file is tracked** before pushing:
   ```bash
   git status --short | grep '^??'   # nothing config.xml-referenced should appear here
   ```
   A common failure: editing config.xml to register a rewrite, creating the
   class file alongside it, but never running `git add` on the new file. The
   rewrite ships without its implementation and production fatals.

5. **For ANY new/changed migration — dry-run the REAL `apply.php`, never the
   `mysql` client.** Production runs `apply.php`, whose PDO DSN is
   `charset=utf8` and which **aborts the whole chain on the first failed
   statement** → the container exits non-zero → **every host 502s** until a
   fixed build deploys. `mysql < file` connects latin1 and silently tolerates
   bad bytes, giving false confidence.
   ```bash
   docker exec ai-mms-web-1 php /var/www/html/migrations/apply.php   # must print "applying: NNN ... OK"
   ```
   - **Any INSERT that pulls data from a legacy table** (`catalogsearch_query`,
     old EAV values, anything historically written over a latin1 connection)
     **MUST be UTF-8-sanitised**, or `apply.php` dies on `error 1366 Incorrect
     string value: '\x96…'`. Cheapest safe filter for ASCII data:
     `WHERE LENGTH(col) = CHAR_LENGTH(col)`. `QUOTE()` does NOT fix this — the
     bytes are invalid UTF-8, not an escaping problem. (Real outage 2026-06-05;
     see memory `feedback_migration_applyphp_utf8_outage`.)
   - **Search-term redirect migrations specifically** (`catalogsearch_query.redirect`):
     restore/remap is data-only, never code. Validate every target returns
     200/302 on **its own store domain** (SG→com.sg, MY→com.my, GH→com.gh,
     BT→tertiarycourses.bt) before shipping — a target that 404s or 301-chains
     re-introduces the dead-ends. Prefer **product page > flat category page >
     empty** (let Magento search); skip homepage bounces. **Only fill
     `redirect IS NULL/''`** — never overwrite an existing intentional
     (product-page) redirect. Match quality: stopword-filtered token overlap,
     drop low-confidence matches rather than ship a wrong redirect.

If any of the five checks fails, **do not push** — fix locally first, re-run
the checks, then push. After pushing, watch `/version.txt` to confirm the
new build timestamp **and** poll `https://www.tertiarycourses.com.sg/` until it
returns 200 (a failed migration shows up here as a sustained 502).

## Development Commands

```bash
# Start local environment
docker-compose up -d

# Local access
# Frontend: http://localhost:8080
# Admin:    http://localhost:8080/<frontName>/  (frontName is in app/etc/local.xml — currently "tigerdragon")

# Production
# Admin: https://www.tertiaryinfotech.edu.sg/tigerdragon/  (also reachable at https://ai-mms.tertiaryinfo.tech/tigerdragon/)
# Build timestamp: /version.txt
# Migration status (public, counts only): /media/migrations-status.json

# Run / author DB migrations
# - Drop new *.sql files into migrations/ (numbered prefix, e.g. 017-foo.sql).
# - On deploy, docker/entrypoint.sh runs migrations/apply.php automatically against the container's DB,
#   applying only unseen files and tracking them in the schema_migrations table.
# - Manual local run: docker exec ai-mms-web-1 php /var/www/html/migrations/apply.php
# - First-time bootstrap against an existing DB: php migrations/apply.php --bootstrap (marks all as applied without running).

# Admin panel styling is **plain CSS** in skin/adminhtml/default/default/*.css
# — no node / npm / Tailwind build step. Edit the CSS files directly.

# Code quality (inside web container)
composer php-cs-fixer:fix
composer phpstan
composer phpunit:test
```

## Architecture

### Custom Modules (`app/code/local/MMD/`)

| Module | Purpose |
|--------|---------|
| **RoleManager** | Multi-role admin system: 6 roles (learner, trainer, developer, marketing, admin, training_provider) with role selection UI, session-based role switching, and ACL mapping via `mmd_user_role_map`. Canonical display order is defined by `_rolePriority` in `Helper/Data.php`. |
| **EmailLogin** | Rewrites `admin/user` model to support email-based admin login. **Admin login is email-only** in this portal — never expose a username input in the UI. The `admin_user.username` column is still NOT NULL in the schema but is treated as a write-only mirror of `email` (the Role Management create-user flow sets `username = email` automatically). |
| **Courses** | Course/provider CRUD management with admin grid and export. |
| **BankPayment** | Bank transfer payment method with configurable accounts. |
| **CustomOptions** | Enhanced product options with SKU policies (multi-version upgrades). |
| **Enhancedsalesgrid** | Admin sales grid filters and rendering enhancements. |
| **FlatCategoryUrl** | **HARD RULE — category URLs are always flat.** Class-rewrite of `Mage_Catalog_Model_Url::getCategoryRequestPath` that strips the parent path so every category resolves at `/<url_key>.html`, never `/parent/grandparent/<url_key>.html`. Applies to ALL categories in ALL 6 country stores. Do NOT disable this module, do NOT add code that prepends parent paths, do NOT "fix" it back to stock behavior — the long deep paths are explicitly unwanted (SEO + UX decision). After deploy, `Catalog URL Rewrites` + `Category Flat Data` indexers must run for the change to take effect on existing data. Collision handling for sibling url_keys is delegated to stock `getUnusedPathByUrlKey` (auto `-1`/`-2`). |
| **CourseImage** | AI cover-image renderer + funding-badge tags. The cover dialog's badge checkboxes drive both the rendered PNG **and** Magento tag writes (`syncProductTags`), so the storefront chips and the cover are guaranteed to match. Storefront catalog list / product view read `getProductBadges()` (filtered to the 9 canonical names) and render colored pills under the course title. Canonical vocabulary: `WSQ, SkillsFuture Credit, PSEA, UTAP, IBF, HRDF, SFEC, Absentee Payroll, MCES` — defined in `Helper/Data.php::getAllBadges()`. CSS palette in `skin/frontend/ultimo/default/css/custom.css` keyed off `getBadgeCssClass()`. Adding a new badge means: append to `getAllBadges()`, add CSS class, seed a `tag` row. |

### RoleManager Flow

1. **Login** → `Model/Observer.php::onAdminLogin` loads roles from `mmd_user_role_map` into the admin session.
2. **Single role** → Applied immediately via `Helper/Data.php::applyRoleAcl`.
3. **Multiple roles** → Session flagged, predispatch observer redirects to role selection page.
4. **Role selection** → `RoleselectController` validates and applies the chosen role's ACL group.
5. **Role switching** → `RoleswitchController` handles AJAX role switches from the header dropdown.

Current state: all roles temporarily inherit the "Administrators" ACL group (full access). Per-role ACL restrictions are TODO — search for `applyRoleAcl` TODO comments.

### Two-Layer Role System

- `mmd_user_role_map` (custom): maps `user_id → role_code` (+ `is_primary` flag).
- `admin_role` + `admin_rule` (standard Magento ACL): groups & rules.
- `applyRoleAcl()` bridges the two by updating the admin user's `parent_id` in `admin_role` to point at the matching ACL group.

### Admin Theme

**MANDATORY: every admin page must follow the `backend-design` skill.** When building or modifying any adminhtml UI — new modules, dashboards, grids, modals, buttons, badges, pagers — load the `backend-design` skill first and align to its design tokens (color palette, button styles, grid density, badge shapes, pagination treatment). The skill encodes the visual conventions of this dark admin theme; ignoring it produces pages that look like third-party Magento modules instead of part of the LMS. This applies even for tiny additions like a new pagination strip or a single button — small components that drift quickly turn into visual noise across screens. If a design decision isn't covered by the skill, propose the addition there first rather than ad-libbing.

**Store View bar = `.dcf-store-switcher` (canonical, no duplicates).** Every store-scoped admin page must surface the same Store View bar (six country pills SG/MY/GH/NG/BT/IN with code badge, `Scope` link on the right, cyan-tinted active state) that the Edit Course page uses. The global `MMD_Branchscope_Block_Store_Switcher` injects it automatically — do NOT re-implement it inline. CSS lives in `skin/adminhtml/default/default/admin-dashboard.css` under "Global Store View bar"; markup contract + role gating live in the `backend-design` skill ("Store View bar" section). If a route already renders an inline bar (Edit Course preserves `course_id`/`mode`/`dev_back` across switches), add a suppression branch in `Switcher.php::_toHtml()` for that route so the global one doesn't double up.

- Dark theme: `skin/adminhtml/default/default/dark-theme.css`
- Role Management grid + modal: `app/design/adminhtml/default/default/template/rolemanager/management.phtml` (styles are inline; iterates roles by `getAllRoles()` order — edit `_roleLabels` in Helper/Data.php to reorder everywhere)
- Custom header (role switcher + avatar menu): `app/design/adminhtml/default/default/template/page/header.phtml`
- Custom sidebar (role-aware): `app/design/adminhtml/default/default/template/page/menu.phtml`
- Login page: `app/design/adminhtml/default/default/template/login.phtml` (standalone, not Magento layout)
- Role-selection page: `app/design/adminhtml/default/default/template/rolemanager/role-select.phtml`
- Gotcha: legacy `boxes.css` has high-specificity `#page-login` rules; use ID selectors to override.

### Admin CSS — known traps

These are non-obvious lessons from real incidents. Read before editing any admin-theme CSS.

**Cascade order matters: `sidebar-nav.css` loads AFTER `dark-theme.css`.** Both files declare `!important` rules for the same selectors (`.admin-main`, `.admin-main .middle`, `.admin-main .main-col-inner`). Because they have equal specificity, the later file wins. Edits to dark-theme.css that look correct will silently lose to sidebar-nav.css. When overriding admin-shell layout rules, put the override in `sidebar-nav.css` itself (preferred) or use body-prefixed selectors at the end of the file. Incident: a "flush-left" override added to dark-theme.css had zero visible effect for the entire session until the actual rules in sidebar-nav.css were edited.

**Never extract page-scoped inline CSS into a shared admin stylesheet without re-scoping global selectors (`body`, `html`, `*`).** `rolemanager.css` is loaded on FOUR admin pages via `layout/rolemanager.xml` (`adminhtml_rolemanagement_index`, `_roleselect_index`, `_cpgenerator_index`, `_seometadata_index`). When `role-select.phtml`'s inline `<style>` was extracted into rolemanager.css, its `body { display: flex; justify-content: center; ... }` and `* { margin:0; padding:0 }` rules lost their natural page-scope and bled onto every page that loaded the file. The body flex-center pushed `.admin-sidebar-layout` into the viewport middle, producing a "huge dead space" between the sidebar and the content that no `.admin-main` padding override could ever fix. Always scope extracted rules with `body:has(.<page-marker>)` or a unique parent class. Incident: hours of chasing phantom padding while the real centerer was 100 lines above in the same file.

**Diagnose layout bugs by computed style, not source grep.** Source-grepping CSS files misses three categories: rules added by merged bundles, body-class-specific rules at the bottom of large files, and rules in files the page actually loads but you didn't search. Use playwright (`browser_evaluate`) to dump computed `marginLeft`/`paddingLeft`/`width`/`left` for every ancestor of the offending element, AND list every matched CSS rule from `document.styleSheets`. That found the role-select bleed in 60 seconds after hours of `grep`. Pattern: walk up `el.parentElement`, log each ancestor's box geometry, then enumerate `[...document.styleSheets].flatMap(s => [...s.cssRules]).filter(r => r.selectorText matches target)`.

### Storefront — banner / theme media

**`.dockerignore` for `media/` must use negation patterns.** A blanket `media/` exclusion fixes Coolify build timeouts (350MB+ context was failing the build with silent `build.sh` exit 255) but silently breaks theme-baked assets — banner images, certification logos, transactional email logo. The repo commits ~358MB under `media/`, of which:
- `media/wysiwyg/` (~1MB) — banners, cert logos, theme decorations. **Required in image.**
- `media/email/`, `media/favicon/`, `media/whatsapp.png` — small, required.
- `media/catalog/category/` (~250MB), `media/catalog/product/` (~107MB) — user-uploaded galleries; served from Cloudflare R2 at runtime, **must stay excluded**.

Current `.dockerignore` excludes `media/` then re-includes the small theme dirs by negation. Don't revert to a blanket exclusion — it'll restore the build OOM. Don't revert to no exclusion — it'll restore the 350MB-context-timeout. The negation form is the only correct shape.

**Magento CSS/JS merge bundles need their target dirs to exist and be www-data-writable on every container start.** `docker/entrypoint.sh` clears `media/css/*`, `media/css_secure/*`, `media/js/*` so deploys pick up new CSS. But on a fresh Coolify volume (or one where the volume was mounted root-owned), Magento's first-request bundle write fails silently — `<link href="/media/css/<hash>.css">` then 404s and the whole admin renders as unstyled HTML. Entrypoint now `mkdir -p` and `chown -R www-data` those three dirs on every boot. If you ever see the storefront or admin lose all styling after a deploy, check those dirs first (`ls -la /var/www/html/media/css/`).

**Storefront banners use Ultimo's `.owl-wrapper-outer.autoHeight` — pin a fixed height in `custom.css`.** Without it, a slow/broken/swapped banner image collapses the slideshow row and reflows the whole homepage. The current rule (`custom.css`, search for "Storefront homepage banner") locks the slide AND `<img>` to 404px with `object-fit:cover` so any image state preserves the layout band.

### Database Migrations

- Repo dirs:
  - `migrations/` — production-bound numbered `*.sql` + `apply.php` runner.
  - `scripts/local-dev/` — local-only fixups (e.g. set localhost base URL, disable admin CAPTCHA). Never auto-applied on deploy.
- `apply.php` uses a `schema_migrations` ledger so each `.sql` runs at most once per DB.
- On first-run against a pre-existing production DB (no ledger yet, `admin_user` already populated), `apply.php` enters **tolerant mode** and swallows idempotency errors (MySQL 1050/1051/1060/1061/1068/1091) for that single run so previously-applied DDL doesn't abort the chain. Future runs are strict.
- Keep new migrations idempotent anyway (`INSERT IGNORE`, `ON DUPLICATE KEY UPDATE`, etc.) — safer on re-runs.

### Deployment

- `.github/workflows/deploy.yml` triggers the Coolify API on push to `main` (force rebuild).
- `Dockerfile` builds the image; `docker/entrypoint.sh` runs at container start:
  1. Clears Magento runtime cache (`var/cache`, `var/full_page_cache`, `var/tmp`, `var/locks`).
  2. Runs `migrations/apply.php` with retry/backoff while DB comes up.
  3. `exec apache2-foreground`.
- If migrations fail after retries, the container exits non-zero so Coolify keeps the previous container — never serve traffic against a stale schema.
- Build timestamp written to `version.txt` at build time; visible at `/version.txt` and in the admin footer.
- `.dockerignore` excludes `.git` and the bulk of `media/`. Small theme-baked subdirs (`media/wysiwyg/`, `media/email/`, `media/favicon/`, `media/whatsapp.png`, `media/.htaccess`) are re-included by negation so banners + cert logos + transactional email logo are present at the served path. User-uploaded `catalog/product` and `catalog/category` galleries stay excluded (R2-served).

### Key Config

- `app/etc/local.xml`: DB credentials, encryption key, admin frontName. **Gitignored** — start from `local.xml.example`.
- `.env`: MySQL passwords, API keys. **Gitignored** — start from `.env.example`.
- `docker/php.ini`: 512M memory, 300s timeout, Asia/Singapore tz, OPcache with `validate_timestamps=1`, session lifetime effectively forever.
- `docker/entrypoint.sh`: runtime cache clear + auto-migration.
- `composer.json`: OpenMage LTS + PHP 8.x polyfills.

### Community Modules

- **Stripe_Payments** + **Hitpay_Pay** — payment gateways.
- **Aschroder_SMTPPro** — SMTP email transport.
- **Infortis_Ultimo** — premium frontend theme (`skin/frontend/ultimo/`).

## Self-improvement journal (MANDATORY)

This project has a real history of repeating the same non-obvious bugs
(flat-catalog stale reads, admin-theme overrides that silently break stock
Magento UX, etc.). To stop relearning the same lessons, every Codex
session works against a persistent journal at
`~/.Codex/projects/-Users-alfredang-projects-tertiary-ai-mms/memory/`.

**At the start of every task**, scan `MEMORY.md` for entries whose
description matches the work area (anything touching product attribute
saves, indexing, admin grids, or storefront caching must consult the
flat-catalog / admin-checkbox entries before suggesting an approach).
If a memory contradicts what the code seems to show, verify against
current code before acting — memories are point-in-time, not live state.

**After every non-obvious fix** — i.e. anything where the surprise came
from invisible behavior (cache layer, indexer, theme override, hidden
ACL, env-var injection, gateway quirk) rather than from a syntax/logic
bug visible in the diff — write or update a `feedback`-type memory
capturing:

- The rule (what to do or avoid)
- **Why:** the concrete incident or constraint that justifies the rule
- **How to apply:** when this rule kicks in, and the working code
  pattern (link to the file:line that demonstrates it)

Then add a one-line pointer to `MEMORY.md` so the index stays current.

The system-reminder context loads `MEMORY.md` into every new conversation
automatically — so a lesson written once carries forward to every future
session, without the human having to re-explain it. This is the
"self-improvement" loop: **read first, fix, write what was learned,
never repeat.**

## Skills (`.Codex/skills/`)

| Skill | When to use |
|-------|-------------|
| **openmage-code-reviewer** | Reviewing OpenMage 1.x / MMD module code — local-codepool, ACL, migration patterns specific to this repo. Not Magento 2. |
| **openmage-module-developer** | Scaffolding a new MMD module — controllers, models, observers, class rewrites, migrations. |
| **openmage-frontend-developer** | Customer-facing storefront work — Ultimo theme, layout XML, phtml, Prototype/jQuery, hreflang. |
| **backend-design** | Styling or reviewing any adminhtml UI — design tokens, buttons, grids, toolbars, badges. Use to keep the dark admin theme visually consistent. |
| **seo-audit** | Multi-country (SG/MY/GH/NG) SEO audit — hreflang, indexability, Core Web Vitals, schema for course pages. |
| **lead-magnets** | Planning lead-magnet content for course sales — SkillsFuture/HRDC hooks, course syllabus PDFs, trial classes. |
| **add-country-store** | Wiring a new country domain to its Magento store view — .htaccess block, base_url migration, Coolify + DNS handoff, all in the SG/MY/GH/NG/BT/IN shape. |
| **mysql** | Schema design, indexing, query tuning, migrations, transactions. |
| **web-accessibility** | Building / reviewing UI for a11y — WCAG 2.1, ARIA, contrast, keyboard nav. |
| **find-skills** | Discovering and installing new skills via `npx skills find [query]`. |
