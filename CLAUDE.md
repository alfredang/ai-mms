# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OpenMage 1.x (Magento 1 LTS v20.12.3) customized as an LMS/TMS (Learning/Training Management System) for Tertiary Courses Singapore. PHP 8.2, MySQL 5.7, Apache, Docker.

## Development Commands

```bash
# Start local environment
docker-compose up -d

# Access the app
# Frontend: http://localhost:8080
# Admin: http://localhost:8080/index.php/<frontName>/ (check app/etc/local.xml for frontName)

# Run database migrations (after first setup or schema changes)
docker exec -i <mysql_container> mysql -u magento -p courses_backupDB < migrations/001-remove-orphan-eav-entity-types.sql

# Code quality (run inside web container or with local PHP)
composer php-cs-fixer:test    # Check code style
composer php-cs-fixer:fix     # Auto-fix code style
composer phpstan              # Static analysis
composer phpmd                # Mess detector
composer phpunit:test         # Run tests
composer rector:test          # Dry-run refactoring
composer rector:fix           # Apply refactoring
```

## Architecture

### Custom Modules (`app/code/local/MMD/`)

| Module | Purpose |
|--------|---------|
| **RoleManager** | Multi-role admin system: 5 roles (learner, trainer, marketing, admin, training_provider) with role selection UI, session-based role switching, and ACL mapping via `mmd_user_role_map` table |
| **EmailLogin** | Rewrites `admin/user` model to support email-based admin login |
| **Courses** | Course/provider CRUD management with admin grid and export |
| **BankPayment** | Bank transfer payment method with configurable accounts |
| **CustomOptions** | Enhanced product options with SKU policies (multi-version upgrades) |
| **Enhancedsalesgrid** | Admin sales grid filters and rendering enhancements |

### RoleManager Flow (Most Complex Module)

1. **Login** → Observer (`Model/Observer.php::onAdminLogin`) loads roles from `mmd_user_role_map`
2. **Single role** → Applied immediately via `Helper/Data.php::applyRoleAcl`
3. **Multiple roles** → Session flagged, predispatch observer redirects to role selection page
4. **Role selection** → `RoleselectController` validates and applies ACL group
5. **Role switching** → `RoleswitchController` handles AJAX role changes from header dropdown

**Current state**: All roles temporarily inherit "Administrators" group (full access). Per-role ACL restrictions are TODO — search for `applyRoleAcl` TODO comments.

### Two-Layer Role System

- `mmd_user_role_map` table: Maps user_id → role_code (custom)
- `admin_role` + `admin_rule` tables: Standard Magento ACL groups
- `applyRoleAcl()` bridges the two by updating the user's parent_id in `admin_role`

### Admin Theme

- Dark theme: `skin/adminhtml/default/default/dark-theme.css`
- Custom header: `app/design/adminhtml/default/default/template/page/header.phtml` (role switcher dropdown)
- Custom sidebar: `app/design/adminhtml/default/default/template/page/menu.phtml` (role-aware)
- Login page: `app/design/adminhtml/default/default/template/login.phtml` (standalone, not Magento layout)
- Role selection: `app/design/adminhtml/default/default/template/rolemanager/role-select.phtml`
- **Gotcha**: `boxes.css` has legacy Magento styles with high specificity (`#page-login`) — use ID selectors to override

### Database Migrations

Manual SQL scripts in `migrations/` applied via Docker exec (not Magento's Varien setup). Module install/upgrade scripts use standard `sql/<setup>/mysql4-install-X.Y.Z.php` pattern.

### Deployment

- GitHub Actions (`.github/workflows/deploy.yml`) triggers Coolify API on push to `main`
- Docker build creates the production image; `version.txt` tracks build timestamp shown in admin footer
- `.dockerignore` excludes `.git` and `media/` — media files are served via volume mount, not baked into image

### Key Config

- `app/etc/local.xml`: DB credentials, encryption key, admin frontName (gitignored — use `local.xml.example`)
- `.env`: MySQL passwords, API keys (gitignored — use `.env.example`)
- `docker/php.ini`: 512M memory, 300s timeout, Asia/Singapore timezone
- `composer.json`: OpenMage LTS + PHP 8.x polyfills

### Community Modules

- **Stripe_Payments** + **Hitpay_Pay**: Payment gateways
- **Aschroder_SMTPPro**: SMTP email transport
- **Infortis_Ultimo**: Premium frontend theme (in `skin/frontend/ultimo/`)

## Skills (`.claude/skills/`)

Skills provide domain-specific coding standards and patterns. Load them when working in their domain.

| Skill | When to Use |
|-------|------------|
| **php-pro** | Writing or reviewing PHP code — enforces strict typing, PSR-12, PHPStan level 9, typed DTOs, constructor DI, and PHPUnit patterns |
| **mysql** | Creating/modifying tables, indexes, or queries; diagnosing slow queries or locking; planning migrations; writing SQL in `migrations/` folder |

Source repos:
- php-pro: `github.com/Jeffallan/claude-skills`
- mysql: `github.com/planetscale/database-skills`
