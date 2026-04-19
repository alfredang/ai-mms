# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project Overview

OpenMage 1.x (Magento 1 LTS v20.12.3) customized as an LMS/TMS (Learning/Training Management System) for Tertiary Courses Singapore. PHP 8.2, MySQL 5.7, Apache, Docker. Deployed to Coolify; local dev via `docker-compose`.

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
| **EmailLogin** | Rewrites `admin/user` model to support email-based admin login. |
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
| **php-pro** | Writing / reviewing PHP — strict typing, PSR-12, PHPStan, typed DTOs, DI, PHPUnit. |
| **mysql** | Schema design, indexing, query tuning, migrations, transactions. |
| **web-accessibility** | Building / reviewing UI for a11y — WCAG 2.1, ARIA, contrast, keyboard nav. |
| **create-github-action-workflow-specification** | Writing / modifying GitHub Actions workflows. |
| **find-skills** | Discovering and installing new skills via `npx skills find [query]`. |
