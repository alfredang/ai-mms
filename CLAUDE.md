# CLAUDE.md

Guidance for Claude Code when working in this repository.

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
- **The admin panel is rebranded** as "Tertiary Infotech Academy — Magento Management System". Treat the admin as a TMS for instructors + operations staff, not a generic e-commerce backoffice.

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

If any of the four checks fails, **do not push** — fix locally first, re-run
the checks, then push. After pushing, watch `/version.txt` to confirm the
new build timestamp before considering the change live.

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

# Tailwind CSS (for admin panel styling — run locally)
npm run tw:build    # Build skin/adminhtml/default/default/tailwind.css
npm run tw:watch    # Rebuild on change during dev

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

- Dark theme: `skin/adminhtml/default/default/dark-theme.css`
- Role Management grid + modal: `app/design/adminhtml/default/default/template/rolemanager/management.phtml` (styles are inline; iterates roles by `getAllRoles()` order — edit `_roleLabels` in Helper/Data.php to reorder everywhere)
- Custom header (role switcher + avatar menu): `app/design/adminhtml/default/default/template/page/header.phtml`
- Custom sidebar (role-aware): `app/design/adminhtml/default/default/template/page/menu.phtml`
- Login page: `app/design/adminhtml/default/default/template/login.phtml` (standalone, not Magento layout)
- Role-selection page: `app/design/adminhtml/default/default/template/rolemanager/role-select.phtml`
- Gotcha: legacy `boxes.css` has high-specificity `#page-login` rules; use ID selectors to override.

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
- `.dockerignore` excludes `.git` and `media/` — media is volume-mounted, not baked.

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

## Skills (`.claude/skills/`)

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
