<div align="center">

# Tertiary Courses LMS (ai-mms)

[![OpenMage](https://img.shields.io/badge/OpenMage-LTS%20v20.12.3-f46f25)](https://www.openmage.org/)
[![PHP](https://img.shields.io/badge/PHP-8.2-777BB4?logo=php&logoColor=white)](https://www.php.net/)
[![MySQL](https://img.shields.io/badge/MySQL-5.7-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Apache](https://img.shields.io/badge/Apache-2.4-D22128?logo=apache&logoColor=white)](https://httpd.apache.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Deploy](https://img.shields.io/badge/Deploy-Coolify-8b5cf6)](https://coolify.io/)

**An end-to-end, full-fledged Learning Management System for instructor-led, funded training — run as a franchise.**

[Live Site](https://www.tertiarycourses.com.sg/) · [Report Bug](https://github.com/alfredang/ai-mms/issues) · [Request Feature](https://github.com/alfredang/ai-mms/issues)

</div>

## Screenshot

![Screenshot](screenshot.png)

## Admin Guide

Step-by-step, screenshot-driven guides for running the LMS from the admin
panel — see **[docs/admin-guide/](docs/admin-guide/)**:

- [Admin guide index](docs/admin-guide/README.md) — logging in, managing the store
- [Changing a course fee](docs/admin-guide/changing-course-fees.md)
- [Changing the currency conversion rate](docs/admin-guide/changing-currency-conversion.md)

## About

**Tertiary Courses LMS** is a complete, production-grade course-registration and learning-management platform built on OpenMage 1.x (Magento 1 LTS) and customised for **Tertiary Infotech Academy**. Every product is a *course* (instructor-led trainings, workshops, certifications) — there is no physical inventory or shipping. The storefront *is* the course-registration portal, and the admin panel is rebranded as a Training Management System for instructors and operations staff.

This system runs as a **franchise model**:

- 📚 **Courseware is supplied and supported by Tertiary Courses Singapore.** Franchisees plug into a ready-made catalogue of WSQ / IBF / SkillsFuture-aligned courses — they don't have to author content from scratch.
- 🛠️ **Each franchise partner hosts their own server.** The **same codebase** (this repo) is deployed to every partner's own server + database — **one store per website**, fully independent (own domain, currency, language, pricing, funding hooks). No shared multi-store install, no shared catalogue, no cross-site redirects.
- 🌏 **Live partner sites:** 🇸🇬 `tertiarycourses.com.sg` · 🇲🇾 `tertiarycourses.com.my` · 🇬🇭 `tertiarycourses.com.gh`.

> ### 🤝 Become a franchise partner
> Want to run an AI-powered future-tech training academy in your country — with a ready-made WSQ / IBF / SkillsFuture-aligned catalogue and this LMS set up on your own server?
> **[👉 Apply to become a franchise partner](https://www.tertiarycourses.com.sg/franchising-application.html)** — fill in the application form on the website and our team will be in touch.

### Key Features

| Feature | Description |
|---------|-------------|
| 🎓 **Course = Product** | Catalogue of instructor-led / live-online / hybrid courses — no stock, weight, or shipping. |
| 🌐 **Franchise model** | Same codebase deployed to each partner's own server — **one store per website** (SG, MY, GH), each fully independent (own domain, currency, language, pricing). |
| 💰 **Funding & subsidy hooks** | SG SkillsFuture Credit / WSQ / IBF, MY HRDC — funding tiers (Baseline, MCES) auto-calculated. |
| 🧾 **Pro Forma Invoices** | On-demand, self-sponsored SkillsFuture-claim pro formas with GST settled on the pre-subsidy list price. |
| 🏫 **Automatic class formation** | Orders materialise into classes & rosters out-of-band via cron — the storefront HTTP path stays untouched. |
| 📝 **Course feedback → Reviews** | QR-linked per-class feedback form (customisable via the Course Reviews → Form Builder) whose submissions save straight into the Magento review system as approved course reviews with per-dimension star ratings. |
| 👥 **Six-role admin** | Learner / Trainer / Developer / Marketing / Admin / Training Provider with session-based role switching. |
| 🎒 **Learner login** | Dedicated `/learnerlogin` page on every site — learners sign in with their storefront email + password and land straight on the learner dashboard (no role selection); staff keep using the admin portal. |
| 🔁 **SG → partner course sync** | Manual-only, one-way export of non-WSQ (C-prefix) courses to MY/GH — bulk "Sync All" or per-course "Sync One" from the partner admin. Partner-owned course fees, schedules and trainer info are never overwritten on update. |
| 🧲 **Recommended Courses rail** | Every SG course page shows at least 5 "Recommended Courses" (Upsell links); shortfalls are topped up with related WSQ courses by category affinity via `scripts/maintenance/backfill-course-upsells.php` (idempotent, no-op on partner sites). |
| 🌏 **Franchise Report** | Super Admin sidebar page showing confirmed + completed classes pulled from the MY/GH partner sites (class code, course, dates, trainer, attendance-marked learners) with date/title/search filters. Auto-pull every Sunday 10am + on-demand Pull Now. |
| 🛡️ **Deploy safety guards** | `apply.php` gives every migration an explicit `@mms_instance` identity, enforces the one-store-per-site topology invariant (a corrupting migration fails the deploy), and a daily 2AM maintenance cron publishes `/media/health.json`. |
| 🎟️ **Payments** | Stripe, HitPay, PayNow and bank transfer. |
| 📜 **Certificates & attendance** | E-attendance and certificate-of-achievement generation. |
| 📣 **Autonomous newsletter** | SG-only agentic-flyer pipeline: designs a course flyer Mon & Thu 10am → manager approval (either manager, via email **or** admin) → MailerLite blast Mon & Thu 8am with a static R2-hosted registration QR. Hard cap **2 flyers/week**; nothing sends without approval. |
| 📧 **Newsletter subscriber sync** | Daily 4am cron adds new order emails to the site's own MailerLite subscriber group, plus a one-shot historical backfill. Learners who previously unsubscribed are never re-added. API key, group, source store and on/off are all Company Settings, so every franchise site points at its **own** list. |
| ✍️ **Lead-magnet blog** | `/blog` with slug URLs, SEO meta + Article JSON-LD, Magento-tag reuse, star ratings, social share, R2 hero images. Every post funnels readers to course sign-up with the WSQ funding / SkillsFuture Credit hook. Monday 9am cron auto-writes a post (Claude) for the top unblogged course, auto-publishes, and shares it on LinkedIn. |
| 🎨 **Ultimo storefront** | Premium responsive theme + a custom dark admin theme. |

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Platform** | OpenMage LTS v20.12.3 (Magento 1.x) |
| **Language** | PHP 8.2 |
| **Database** | MySQL 5.7 |
| **Web Server** | Apache 2.4 |
| **Frontend Theme** | Infortis Ultimo (responsive) |
| **Caching** | Redis (config / full-page / block) |
| **Payments** | Stripe, HitPay, PayNow, Bank Transfer |
| **Email** | Aschroder SMTP Pro |
| **Containerisation** | Docker Compose |
| **Deployment** | Coolify (auto-deploy on push to `main`) + Cloudflare R2 (media) |

## Architecture

```
        FRANCHISE PARTNERS — same codebase, each on its own server + DB
           🇸🇬 com.sg          🇲🇾 com.my          🇬🇭 com.gh
        (one store per site · independent · no cross-site redirects)
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  STOREFRONT  (Ultimo theme · course-registration portal)                   │
│  Browse courses → register (cart/checkout) → pay → confirmation email       │
└──────────────────────────────────────────────────────────────────────────┘
                                       │  order = registration
                                       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  BACKEND  (cron, every 1 min — out-of-band, frontend untouched)            │
│  ClassFormation → CourseRunEnrolmentService                                 │
│        │                                   │                                │
│        ▼                                   ▼                                │
│  course_runs  (class instance,        course_run_enrolments (roster,        │
│   class_id = SG000042 …)               idempotent INSERT IGNORE)            │
└──────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  ADMIN  (Training Management System · dark theme · six-role ACL)            │
│  Classes · Rosters · Trainers · Attendance · Certificates · Pro Formas      │
└──────────────────────────────────────────────────────────────────────────┘
```

**Franchise data model — six axioms:** Product = Course · Class identity = `(course_code, title, start_date)` · Class storage = one `course_runs` row (`class_id` like `SG000042`) · Order = Registration · Roster = `course_run_enrolments` · Users = six-role union with unified accounts.

## Project Structure

```
ai-mms/
├── app/
│   ├── code/
│   │   ├── core/Mage/      # OpenMage LTS core
│   │   ├── local/MMD/      # Custom franchise modules (see below)
│   │   └── community/      # Stripe, HitPay
│   ├── design/             # Storefront + admin templates (.phtml)
│   └── etc/                # local.xml, modules/
├── skin/                   # Ultimo theme + dark admin theme (CSS/JS)
├── lib/                    # Varien / Zend / Magento libraries
├── migrations/             # Numbered *.sql applied by apply.php on deploy
├── scripts/                # local-dev fixups + maintenance scripts
├── docker/                 # entrypoint.sh, php.ini, Apache config
├── docker-compose.yml      # Local dev stack (web + MySQL)
└── Dockerfile              # Production image
```

### Custom Modules (`app/code/local/MMD/`)

| Module | Purpose |
|--------|---------|
| **RoleManager** | Six-role admin system + class/roster management + class-id generation. |
| **Proforma** | On-demand Pro Forma Invoice PDF (self-sponsored SFC claims; WSQ funding breakdown). |
| **CourseImage** | AI cover-image renderer + funding-badge tags. |
| **EmailLogin** | Email-only admin login. |
| **FlatCategoryUrl** | Flat category URLs (`/<url_key>.html`) across all stores. |
| **CustomOptions** | Enhanced product options with SKU upgrade policies. |
| **Enhancedsalesgrid** | Admin sales-grid filters & rendering. |
| **BankPayment** | Bank-transfer payment method. |
| **Branchscope** | Per-country store-view switcher in admin. |
| **Certificate / Attendance** | Certificates of achievement + e-attendance. |
| **AccountSync** | Unified learner ↔ shadow admin accounts. |
| **Courses / Leads** | Course CRUD + admin grid; contact-form lead capture. |
| **Marketing** | Autonomous agentic-flyer newsletter pipeline — cron design (Mon/Thu 10am), signed email + backend manager approval, guarded MailerLite scheduling (Blastguard: 2 blasts/week, Mon/Thu 8am), subscriber-growth + campaign KPIs. Also hosts the daily 4am order-email → MailerLite subscriber sync (`Model/Cron/Subscribersync.php`, backfill `scripts/maintenance/mailerlite-import-order-emails.php`) — per-site config, opt-outs never re-added. |
| **Blog** | CMS-style lead-magnet blog — Marketing → Blog Posts admin (WYSIWYG, SEO meta, tags, R2 hero upload), `/blog/<slug>` storefront with ratings + share, Monday 9am Claude auto-blog with LinkedIn auto-share. |

## Getting Started

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- A base database dump (`courses_mysql2.sql`) placed in the project root

### Installation (recommended: Docker Compose)

```bash
# 1. Clone
git clone https://github.com/alfredang/ai-mms.git
cd ai-mms

# 2. Configure environment
cp .env.example .env                       # set MySQL passwords + API keys
cp app/etc/local.xml.example app/etc/local.xml   # match DB credentials to .env

# 3. Build and start the stack
docker compose up -d --build

# 4. Import the base database
docker exec -i ai-mms-db_mysql-1 \
  mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < courses_mysql2.sql

# 5. Apply migrations (schema + data) via the real runner
docker exec ai-mms-web-1 php /var/www/html/migrations/apply.php

# 6. Apply local-dev fixups (localhost URLs, disable admin captcha, enable products)
for f in scripts/local-dev/*.sql; do
  docker exec -i ai-mms-db_mysql-1 mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < "$f"
done

# 7. Install Composer dependencies + clear cache
docker exec ai-mms-web-1 bash -c 'cd /var/www/html && composer install --no-dev --optimize-autoloader'
docker exec ai-mms-web-1 bash -c 'rm -rf /var/www/html/var/cache/* /var/www/html/var/full_page_cache/*'
```

### Access

| Service | URL |
|---------|-----|
| Storefront | http://localhost:8080/ |
| Admin Panel | http://localhost:8080/`<frontName>`/ (the `frontName` is set in `app/etc/local.xml`) |
| MySQL | `localhost:3307` (credentials in `.env`) |

### Docker Services

| Service | Image | Port |
|---------|-------|------|
| `web` | PHP 8.2 / Apache 2.4 | 8080 |
| `db_mysql` | MySQL 5.7 | 3307 |

## Deployment

Every franchise partner's server deploys automatically via its **own Coolify instance** on every push to `main` (each connected through Coolify's GitHub App git source):

1. Coolify rebuilds the image from the pushed commit.
2. `docker/entrypoint.sh` clears Magento runtime cache, then runs `migrations/apply.php` (with retry/backoff while the DB comes up).
3. If migrations fail, the container exits non-zero so Coolify keeps the previous container — traffic is never served against a stale schema.
4. Build timestamp is written to `/version.txt`; public migration status at `/media/migrations-status.json`.

User-uploaded media (catalog product/category galleries) is served from **Cloudflare R2**; theme-baked assets ship inside the image.

> **Note for contributors:** never `git push` until localhost is verified error-free — production redeploys on every push. Lint changed PHP, confirm rewrites instantiate, hit affected routes, and **dry-run new migrations through `migrations/apply.php`** (not the `mysql` client) before pushing.

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-change`
3. Make your changes and verify locally (lint + route checks + migration dry-run)
4. Commit and open a Pull Request

Issues and feature requests are welcome via [GitHub Issues](https://github.com/alfredang/ai-mms/issues).

### Shared AI-assistant tooling (`.claude/` + `.codex/`)

This repo ships its **AI coding tooling in-repo** so every team member uses the same
setup. Committed and ready to use after a clone:

- **`.claude/skills/`** — domain skills (`openmage-code-reviewer`, `openmage-module-developer`,
  `openmage-frontend-developer`, `backend-design`, `seo-audit`, `lead-magnets`, `add-country-store`,
  `recommended-courses`, `mysql`, `web-accessibility`, …).
- **`.claude/agents/`** — specialised subagents (security auditor, caching/speed optimiser,
  mysql tuner, admin-design-consistency, site-health-checker, `newsletter-designer`, …).
- **`.claude/hooks/`** — pre/post-tool hooks (PHP lint-on-edit, web-health,
  leads-capture and newsletter-flyer verifiers) wired via `.claude/settings.json`.
- **`.codex/`** + **`AGENTS.md`** — the Codex-CLI counterparts of the same guidance.

`CLAUDE.md` / `AGENTS.md` are the behavioural guardrails both assistants load automatically.

## Developed By

**Tertiary Infotech Academy Pte. Ltd.**
🌐 [tertiarycourses.com.sg](https://www.tertiarycourses.com.sg/) · ✉️ enquiry@tertiaryinfotech.com · ☎️ +65 6100 0613

## Acknowledgements

- [OpenMage LTS](https://www.openmage.org/) — the maintained Magento 1 fork this platform is built on
- [Infortis Ultimo](https://infortis.github.io/) — storefront theme
- SkillsFuture Singapore (SSG), IBF, and HRD Corp — funding frameworks the catalogue aligns to

---

<div align="center">

**🤝 Bring this academy to your country** — [apply to become a franchise partner »](https://www.tertiarycourses.com.sg/franchising-application.html)

⭐ **Star this repo if you find it useful!**

</div>
