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
| 💰 **Funding & subsidy hooks** | SG SkillsFuture Credit / WSQ / IBF, MY HRDC — funding tiers (Baseline, MCES) auto-calculated. On WSQ courses the funding card is **checkbox-driven**: six Edit Course checkboxes (WSQ/CASL, MCES/SME, SFEC, UTAP, PSEA, Absentee Payroll) write the funding badge tags, and the card renders canonical per-scheme copy with SkillsFuture links generated from the course's own code. Every WSQ course page shows its SSG **Funding Validity** window (seeded from the TPG master list, editable per course in the admin General tab). The funding card's scheme links are proper buttons (SFC / SFEC / UTAP / PSEA), and learners submit their filled PSEA withdrawal form via a dedicated `/psea-submission/` page that emails the attached form straight to admissions (no DB record). |
| 📋 **Course-page section cards** | Six per-course CMS block sections — Learning Outcomes, Brochure, Skills Framework, Certification, About IBF Certification, Funding — render as styled cards on every course page (block-first, with regex fallback from the description) and are edited per course in the Course Details tab. |
| 🧾 **Pro Forma Invoices** | On-demand, self-sponsored SkillsFuture-claim pro formas with GST settled on the pre-subsidy list price. |
| 🏫 **Automatic class formation** | Orders materialise into classes & rosters out-of-band via cron — the storefront HTTP path stays untouched. |
| 📝 **Course feedback → Reviews** | QR-linked per-class feedback form (customisable via the Course Reviews → Form Builder) whose submissions save straight into the Magento review system as approved course reviews with per-question star ratings (Learning Outcome / Trainer Quality / Training Environment), browsable per course in the editor's Course Review tab with expandable full messages. Trainers show the QR from the **Course Feedback** section on their class page; the form auto-fills the course title, code, run ID and class dates from the scanned class. |
| ⭐ **Featured testimonials** | Admins hand-pick marketing-worthy course reviews from the All Reviews grid (Featured column, filter, and bulk "Mark as Featured"), then manage the curated set on **Course Reviews → Featured Reviews** — a dedicated page showing exactly what the public sees, with live/hidden KPIs and one-click removal. The homepage shows 4 **random** featured reviews in a band directly under the blog strip, and `/testimonials` lists them all — each card showing the star rating, the quote and a link to the course the learner took. |
| 🔗 **Social share & likes** | Every course page carries a share bar (LinkedIn, X, Facebook, WhatsApp, Email, copy-link) and a one-per-visitor thumbs-up Like counter beside the pill-styled review summary — the same share row as the blog. |
| 👥 **Six-role admin** | Learner / Trainer / Developer / Marketing / Admin / Training Provider with session-based role switching. |
| 🎒 **Learner login** | Dedicated `/learnerlogin` page on every site — learners sign in with their storefront email + password and land straight on the learner dashboard (no role selection); staff keep using the admin portal. |
| 🔁 **SG → partner sync** | One-way export of non-WSQ (C-prefix) courses to MY/GH — bulk "Sync All" or per-course "Sync One" from the partner admin, or triggered remotely from SG's Franchise Management (Course / Category / Schedule Sync via each partner's `api_sync_trigger`). Partner-owned course fees, schedules and trainer info are never overwritten on a course update; Schedule Sync explicitly replaces partner Course Date/Time options with SG's. |
| 🧲 **Recommended Courses rail** | Every SG course page shows at least 5 "Recommended Courses" (Upsell links); shortfalls are topped up with related WSQ courses by category affinity via `scripts/maintenance/backfill-course-upsells.php` (idempotent, no-op on partner sites). |
| 🌏 **Franchise Management** | Super Admin sidebar group with four pages: **Franchise Report** (confirmed + completed classes pulled from the MY/GH partner sites — class code, course, dates, trainer, attendance-marked learners — with filters, Sunday 10am auto-pull + Pull Now) and **Course / Category / Schedule Sync** (one-way SG → franchisee push triggers with per-partner selection; partners can never write back to SG). |
| 🛡️ **Deploy safety guards** | `apply.php` gives every migration an explicit `@mms_instance` identity, enforces the one-store-per-site topology invariant (a corrupting migration fails the deploy), and a daily 2AM maintenance cron publishes `/media/health.json`. |
| 🎟️ **Payments** | Stripe, HitPay, PayNow and bank transfer. |
| 📜 **Certificates & attendance** | Per-session (AM/PM) e-attendance per class day, plus certificate-of-achievement generation — auto-sent at 6:30pm when attendance exceeds 70%, with a trainer-managed per-learner delivery roster for manual sends. |
| 📣 **Autonomous newsletter** | SG-only agentic-flyer pipeline: designs a course flyer Mon & Thu 10am → manager approval (either manager, via email **or** admin) → MailerLite blast Mon & Thu 8am with a static R2-hosted registration QR. Hard cap **2 flyers/week**; nothing sends without approval. |
| 📧 **Newsletter subscriber sync** | Daily 4am cron adds new order emails to the site's own MailerLite subscriber group, plus a one-shot historical backfill. Learners who previously unsubscribed are never re-added. API key, group, source store and on/off are all Company Settings, so every franchise site points at its **own** list. |
| ✍️ **Agentic lead-magnet blog** | `/blog` with slug URLs, SEO meta + Article JSON-LD, Magento-tag reuse, likes, social share, R2 hero images. An agent team writes 2 posts/week: a research agent (Claude web search) scouts the latest AI topics, a writer agent produces an in-depth post with a branded auto-generated hero, managers approve via email or the admin timeline, and approved posts publish Tue & Fri 9am, then auto-share to LinkedIn + Facebook. Admins queue the next courses from the Blog pipeline panel. |
| 🔌 **Course catalog APIs** | Key-authenticated read-only JSON feeds of the SG catalog — `/courses/api_wsq` (TGS- courses) and `/courses/api_nonwsq` (C- courses), kept as separate endpoints so the two funding tracks never mix. Add `?fields=full` for the long description, suitability, prerequisites and assessment. Per-course and schedule lookups live at `/courses/api_courses?sku=` and `/courses/api_schedule`. Every endpoint is documented in the admin **API Summary** panel. |
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
│   class_id = C000042 …)                idempotent INSERT IGNORE)            │
└──────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  ADMIN  (Training Management System · dark theme · six-role ACL)            │
│  Classes · Rosters · Trainers · Attendance · Certificates · Pro Formas      │
└──────────────────────────────────────────────────────────────────────────┘
```

**Franchise data model — six axioms:** Product = Course · Class identity = `(course_code, title, start_date)` · Class storage = one `course_runs` row (`class_id` like `C000042` — uniform per-site sequence) · Order = Registration · Roster = `course_run_enrolments` · Users = six-role union with unified accounts.

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
| **CourseImage** | AI cover-image renderer + funding-badge tags (the same tags drive the storefront chips, the cover, and the WSQ Funding card). |
| **EmailLogin** | Email-only admin login. |
| **FlatCategoryUrl** | Flat category URLs (`/<url_key>.html`) across all stores. |
| **CustomOptions** | Enhanced product options with SKU upgrade policies. |
| **Enhancedsalesgrid** | Admin sales-grid filters & rendering. |
| **BankPayment** | Bank-transfer payment method. |
| **Branchscope** | Legacy per-country store-view switcher — superseded by the one-store-per-site franchise model; retained for backward compatibility. |
| **Certificate / Attendance** | Certificates of achievement + e-attendance. |
| **AccountSync** | Unified learner ↔ shadow admin accounts. |
| **Courses / Leads** | Course CRUD + admin grid; read-only catalog/schedule/search JSON APIs (`api_wsq`, `api_nonwsq`, `api_courses`, `api_schedule`, `api_search`, `api_faq`, `api_contact`) sharing one auth + envelope via `Helper/Catalogfeed.php`; contact-form lead capture with auto-reply and MailerLite auto-subscribe on capture (opt-outs never re-added), plus a "Send to MailerLite" mass-action and per-lead sync checkbox in the Leads grid. |
| **Marketing** | Autonomous agentic-flyer newsletter pipeline — cron design (Mon/Thu 10am), signed email + backend manager approval, guarded MailerLite scheduling (Blastguard: 2 blasts/week, Mon/Thu 8am), subscriber-growth + campaign KPIs. Also hosts the daily 4am order-email → MailerLite subscriber sync (`Model/Cron/Subscribersync.php`, backfill `scripts/maintenance/mailerlite-import-order-emails.php`) — per-site config, opt-outs never re-added. |
| **Reviews** | Featured reviews as storefront testimonials — an `is_featured` flag on the stock `review` table (no parallel testimonial table), driven from the All Reviews grid (Featured column + filter + "Mark as Featured" mass action), the review edit form, and a dedicated **Course Reviews → Featured Reviews** admin page (curated list + KPIs + one-click remove). Renders 4 random featured reviews on the homepage after the blog strip, and all of them at `/testimonials`. |
| **Blog** | CMS-style lead-magnet blog — Marketing → Blog admin with the agentic pipeline timeline (research agent → writer + auto hero → approval → Tue/Fri 9am slots → LinkedIn/Facebook share), a drag-to-reorder next-course queue, and a rich in-admin article preview modal (desktop/mobile viewports, works for unpublished posts); `/blog/<slug>` storefront with likes + share. |

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
  `recommended-courses`, `linkedin-posts`, `mysql`, `web-accessibility`, …).
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
