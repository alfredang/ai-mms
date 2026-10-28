# SEO meta rules — course + category pages (SG / MY / GH)

The standard for every `<title>`, meta description and meta keywords on the three sites. Applies to
any change that creates, renames or repurposes a course or category, to bulk meta migrations, and to
partner-DB edits. The `seo-audit` skill audits against this file.

## Title — composed at render time, stored BARE

`MMD_Seotitle_Block_Html_Head` builds every storefront title as
`[funding prefix] <stored meta_title> | Tertiary Courses <Country>`:

| Site | Page | Rendered title |
|------|------|----------------|
| SG | WSQ course (TGS-) | `Funded up to 70% WSQ <title> \| Tertiary Courses Singapore` |
| SG | IBF course (IBF badge, wins over WSQ) | `Funded up to 70% IBF <title> \| Tertiary Courses Singapore` |
| SG | CASL course (CASL badge) | `Funded up to 70% CASL <title> \| Tertiary Courses Singapore` |
| SG | non-WSQ course (C-) / category | `<title> \| Tertiary Courses Singapore` |
| MY | every course | `HRD Corp Funded <title> \| Tertiary Courses Malaysia` |
| MY | category | `<title> \| Tertiary Courses Malaysia` |
| GH | course / category | `<title> \| Tertiary Courses Ghana` |

- The postfix comes from `general/store_information/name` on each site's own DB; a stale baked
  `| Tertiary Courses …` is stripped before the site's own one is added.
- **What is STORED in `meta_title` (user directive 2026-10-28 — the Edit Course field must show it):**
  - **SG funded (TGS-), every MY course, every GH course** -> store the full rendered title, prefix and
    postfix included, e.g. `Funded up to 70% WSQ Python Fundamental Course for Beginners | Tertiary
    Courses Singapore`, `HRD Corp Funded SQL Masterclass | Tertiary Courses Malaysia`,
    `SQL Masterclass | Tertiary Courses Ghana`. GH has NO funding prefix. Use
    `MMD_Seotitle_Block_Html_Head::formatStoredCourseTitle($product, $title, $brand)` — the admin AI
    SEO generator (`aiSeoAction` / `aiSeoAllStoresAction`) already runs every title through it.
  - **SG non-WSQ (C-) courses and every category page** -> store BARE (no prefix, no brand); the
    composer adds the postfix at render time.
  - The composer is idempotent either way (a title that already starts with the prefix and ends with
    the brand renders unchanged), so nothing ever doubles.
  - Course core wording ≤ 50 chars (hard max 60), primary keyword first, the course name's own words.
- Never change product `name` or `url_key` for SEO (name is the H1, JSON-LD and order line).

## Meta description — 130–160 chars, `meta_description` is varchar(255)

- Topic (primary keyword) in the first ~8 words, 2–3 concrete skills from the course content, plain
  sentences. Written from the course's own name + description, never carried over from an old course.
- **SG funded (TGS-)**: MUST end with the funding line built from the course's approved badges —
  `Up to 70% <WSQ|IBF|CASL> funding; <SkillsFuture Credit and UTAP | SkillsFuture Credit | UTAP | SFEC> claimable.`
  Claim UTAP / SkillsFuture Credit only when the course carries that badge. (UTAP is banned in
  OUTBOUND marketing only — SG storefront meta must show it.)
- **SG non-WSQ (C-)**: no funding words at all (WSQ, SkillsFuture, SFEC, UTAP, PSEA, IBF, CASL,
  funded, funding, subsidy, grant, claimable).
- **MY**: must contain `HRD Corp claimable`; never Singapore or any SG scheme.
- **GH**: no funding language at all; never Singapore or any SG scheme.
- Plain ASCII, no em dashes, no hype words (unlock, elevate, comprehensive, cutting-edge, seamless…).

## Meta keywords — 5–8 phrases (product `meta_keyword` lives in the TEXT table)

`<topic> course`, `<topic> training <Singapore|Malaysia|Ghana>`, then specific skills/tools. SG funded:
add the scheme (`WSQ <topic> course`), `SkillsFuture Credit course`, `UTAP claimable course` per badge.
MY: one `HRD Corp claimable <topic> training` phrase. Same funding bans as the description.

## Writing the data

- SG: an SG-guarded `migrations/NNN-*.sql`; dry-run with the real `apply.php`.
- MY / GH: **DB-only on the partner server, never a repo migration**; back up the rows first.
- Bulk meta migrations must be **peer-safe** — only replace a value still equal to the one you expect
  (see `migrations/1856-*.sql`), or a later rename/repurpose gets silently reverted.
- Delete store-view overrides (store_id ≠ 0) and wrong-table orphans (meta_description in the TEXT
  table, meta_keyword in the varchar table) or they shadow the new store-0 value.
- Verify the RENDERED `<title>` / `<meta>` with curl after deploy + cache flush, not the DB row.

## Structured data + headings (head.phtml)

Homepage: `EducationalOrganization` + one `<h1>` (CMS `content_heading`). Course: `Course` +
`BreadcrumbList`. Category: `CollectionPage` + `BreadcrumbList`.
