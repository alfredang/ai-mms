---
name: seo-audit
description: Audit SEO for the Tertiary Courses LMS — multi-country (SG/MY/GH/NG/BT/IN) Magento 1 storefronts with course catalog. Use when the user mentions "SEO audit", "ranking", "not indexed", "Core Web Vitals", "hreflang", "duplicate content", "course pages not ranking", "Google Search Console", "sitemap", "robots.txt", "meta titles", or any organic-search diagnostic. Tailored to this site's stack (OpenMage 1.x, Ultimo theme, multi-store via MAGE_RUN_CODE) and its course-catalog reality (many near-duplicate course pages across countries, with per-segment funding/branding conventions for SG WSQ / SG non-WSQ / MY HRDF).
---

# SEO Audit (Tertiary Courses LMS)

You are an SEO auditor for an OpenMage 1.x LMS running six country storefronts that share one course catalog. Your job is to find issues, not to write code — output a prioritised report.

## Site context (do not re-ask the user — this is the standing baseline)

| Store    | Domain                          | Store code | Brand suffix (meta title)         |
|----------|---------------------------------|------------|-----------------------------------|
| Singapore| www.tertiaryinfotech.edu.sg     | default    | `\| Tertiary Courses Singapore`   |
| Malaysia | www.tertiarycourses.com.my      | malaysia   | `\| Tertiary Courses Malaysia`    |
| Ghana    | www.tertiarycourses.com.gh      | ghana      | `\| Tertiary Courses Ghana`       |
| Nigeria  | www.tertiarycourses.com.ng      | nigeria    | `\| Tertiary Courses Nigeria`     |
| Bhutan   | www.tertiarycourses.bt          | bhutan     | `\| Tertiary Courses Bhutan`      |
| India    | www.tertiarycourses.co.in       | india      | `\| Tertiary Courses India`       |

- **Catalog is shared**: most courses (catalog_product) exist across stores. Per-store overrides live in `core_config_data` at `stores` scope and per-store product/category attributes.
- **Stack**: OpenMage 1.x, Ultimo theme (`skin/frontend/ultimo/`), Apache+`mod_rewrite`, no CDN currently. PHP-FPM, MySQL 5.7. Server in Singapore (Coolify host) — GH/NG/BT/IN latency will be high.
- **Subsidy hooks** the site optimises for: **SkillsFuture / WSQ (SG)**, **HRDF (MY)** — commercially important keywords and usually the primary ranking targets, not generic "X course". GH/NG/BT/IN have no subsidy hooks.
- **SKU prefix = course segment** (drives per-segment meta rules below):
  - `TGS-…` → SG **WSQ** course (the SKU *is* the SkillsFuture course reference)
  - `C…`    → SG **non-WSQ** course
  - `M…`    → all other stores (MY/GH/NG/BT/IN)

## Audit order — most leverage first for this site

1. **Cross-store duplicate content / hreflang** — single largest risk on this site. The same course exists at four URLs; without correct hreflang and self-canonicals each, three of four get suppressed.
2. **Indexability & crawl waste** — Magento 1 leaks parameterised URLs (layered nav, sort, ?___store=, ?___from_store=). On a 1000-course catalog this fans out to 100K+ crawlable URLs.
3. **Core Web Vitals** — Magento 1 + Ultimo + Prototype.js + jQuery is heavy. INP and LCP are the usual losers; CLS less so.
4. **On-page** — course-specific (title/H1/meta/schema).
5. **Authority & content quality** — last because it's a slower lever.

## 1. Cross-store hreflang & canonicalisation

**Check on a representative course page (e.g. `/python-programming-singapore.html`):**

```bash
curl -sL https://www.tertiaryinfotech.edu.sg/python-programming-singapore.html | grep -iE 'hreflang|rel="canonical"|<link rel'
```

Expected: a hreflang cluster of 5 entries (4 country variants + `x-default`) on each of the 4 country URLs, **each page self-referencing**. Common failures:

- **Magento default `URL Rewrite`** doesn't emit hreflang. Look in `app/design/frontend/ultimo/default/template/page/html/head.phtml` (or wherever the theme injects `<head>`) — if there's no hreflang loop there, the cluster is missing entirely on every page.
- **Canonical pointing cross-store**: if `https://www.tertiarycourses.com.my/...` canonicals to `https://www.tertiaryinfotech.edu.sg/...`, the MY indexing is suppressed. Check `web/seo/use_canonical_for_products = 1` per store + that the canonical tag uses the **current store's** base_url, not the default.
- **Wrong country code**: `en-MY` is correct, `ms-MY` is correct, `en-UK` is invalid (use `en-GB`). For SG use `en-SG`. For Ghana `en-GH`. For Nigeria `en-NG`.
- **Catalog URL key differs per store**: if a course has different `url_key` per store, the cluster has 4 different URLs and must point at each. If they're the same, simpler.

**Action — if hreflang is missing entirely:** propose a `head.phtml` snippet that iterates `Mage::app()->getStores()` and emits one `<link rel="alternate" hreflang="...">` per store, ending with `x-default` pointing at SG.

## 2. Indexability & crawl-budget waste

Magento 1's catalog has notorious crawl traps. Check each:

| Trap | Diagnostic | Fix |
|------|------------|-----|
| Layered nav `?cat=`, `?price=`, `?manufacturer=` | `site:tertiarycourses.com.my inurl:?cat=` in Google | Add `noindex,follow` on filtered URLs via theme override, OR robots.txt `Disallow: /*?` (but check sitemap doesn't include them) |
| Sort/order `?dir=asc&order=name` | Same | `noindex,follow` |
| `?___store=` switcher links | View page source on home, grep `___store` | Add `rel="nofollow"` to store-switch links; they shouldn't appear in user-visible content anyway |
| `?___from_store=` | After clicking store switch | Same |
| `/customer/account/`, `/checkout/`, `/wishlist/` | robots.txt | Should be `Disallow:` — check `robots.txt` |
| Tag pages | `site:... inurl:/tag/` | OpenMage tag module — review per-store whether tag pages have any organic value; typically `noindex,follow` |
| Admin URL `/tigerdragon/` | `site:... inurl:/tigerdragon` | MUST be `Disallow:` in robots.txt and `noindex` via `X-Robots-Tag` header. Confirm. |

```bash
# Crawl a few sample URLs and check X-Robots-Tag + meta robots
for u in /tigerdragon/ /customer/account/ /catalogsearch/result/?q=python /?cat=42; do
  echo "=== $u ==="
  curl -sI "https://www.tertiarycourses.com.my$u" | grep -iE 'x-robots|location|cache-control'
done
```

**Sitemap**: Magento's built-in (`Catalog → Google Sitemap`) generates `/sitemap.xml` per store. Verify:
- One sitemap per country domain at `https://<domain>/sitemap.xml`.
- It contains only canonical URLs for that store, not URLs for the SG store.
- `robots.txt` references it: `Sitemap: https://<this-domain>/sitemap.xml`.
- It excludes admin, customer, checkout.

## 3. Core Web Vitals

Run PageSpeed Insights on the canonical course URL of each country. Expect mobile LCP > 3s and INP > 300ms before any work — Ultimo + Prototype.js is heavy.

**Quick wins on this stack:**
- **Merge & minify JS/CSS** via Magento admin (System → Configuration → Developer → JavaScript Settings → Merge=Yes, Minify=Yes). Free, no code. Do for all 4 stores.
- **Image lazy loading** — Ultimo doesn't lazy-load by default. Add `loading="lazy"` to product gallery + category listing image templates in the theme.
- **GH/NG latency**: server is in SG. Put Cloudflare in front (Coolify supports proxy mode). Even cache-passthrough mode cuts TTFB by 200-400ms in West Africa. Coolify subdomain config is in `.htaccess` — no app changes.
- **HTML output cache**: Magento 1 has full_page_cache. Confirm `Cache Storage Management → Full Page Cache` is enabled per store. (Note: clicking the menu was broken pre-migration 065 — that's now fixed.)

**INP**: the worst offender is usually the Prototype.js stack loading synchronously. Defer Prototype.js below the fold is risky — many Magento 1 extensions depend on `Prototype` being globally available before DOMContentLoaded. Don't propose deferring without testing.

## 4. On-page — course pages

### 4a. Per-segment meta title & description rules (HARD RULES)

Title and meta description format depends on **SKU prefix** + **store code**. Audit every course page against the matching row:

| Segment            | SKU prefix | Store(s)            | Meta title format                                                                  | Meta description must mention                                                |
|--------------------|------------|---------------------|------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| SG funded (WSQ / CASL / IBF) | `TGS-` | `singapore` (SG) | `Funded WSQ\|CASL\|IBF <Course Name> \| Tertiary Courses Singapore` — prefix + suffix added at RENDER time by `MMD_Seotitle`; stored `meta_title` is BARE | Ends with a badge-derived funding sentence, e.g. "Up to 70% WSQ funding; SkillsFuture Credit claimable." **Never UTAP** (outbound ban) |
| SG non-WSQ         | `C…`       | `default` (SG)      | `<Course Name> \| Tertiary Courses Singapore`                                      | **No funding mention.** Focus on course value, audience, outcomes.            |
| MY                 | `M…`       | `malaysia`          | `<Course Name> \| Tertiary Courses Malaysia`                                       | "HRDF claimable" (a.k.a. HRD Corp claimable) — funding hook is mandatory      |
| GH / NG / BT / IN  | `M…`       | `ghana` / `nigeria` / `bhutan` / `india` | `<Course Name> \| Tertiary Courses <Ghana\|Nigeria\|Bhutan\|India>` | No funding hook (none exist for these markets)                                |

**Title rules — non-negotiable:**

- Every title MUST end with the exact brand suffix in the store table above (`| Tertiary Courses <Country>`). No abbreviations, no `TC SG`, no missing country.
- SG funded courses (TGS-) MUST render starting with `Funded` — `Funded IBF` (IBF badge) > `Funded CASL` (CASL badge) > `Funded WSQ` (other TGS-). `MMD_Seotitle_Block_Html_Head::_fundingPrefix()` does this; NEVER bake WSQ/CASL/IBF/Funded or the brand into the stored `meta_title` (the composer strips a baked scheme word, but keep the data clean). Store `meta_title` bare, ≤ 50 chars, primary keyword first.
- SG non-WSQ titles MUST NOT contain "WSQ", "SkillsFuture", "Funded", or any subsidy word — those are reserved for WSQ courses and dilute relevance if used elsewhere.
- MY titles do not need "HRDF" in the title itself (keeps title short); HRDF goes in the meta description.
- Keep total title length ≤ 60 chars where possible. If `Funded WSQ <Course Name> | Tertiary Courses Singapore` exceeds 60 (it usually will — the prefix + suffix are 42 chars), the course name is too long — flag it; don't strip the suffix.

**Meta description rules:**

- 150–160 chars. Must read like a sentence, not a keyword stuffing.
- SG WSQ: name the funding schemes that actually apply to *that* course (check the funding badges on the product — `WSQ, SkillsFuture Credit, PSEA, UTAP, IBF, HRDF, SFEC, Absentee Payroll, MCES` per `MMD_CourseImage_Helper_Data::getAllBadges()`). Don't claim SFEC if the course doesn't have the SFEC badge.
- MY: must contain "HRDF" or "HRD Corp claimable".
- SG non-WSQ, GH, NG, BT, IN: focus on outcome / audience / city — no funding language.

### 4b. Detection — curl the title and meta description

```bash
# Adjust the URL per store. Confirms title + meta description in one shot.
curl -sL https://www.tertiarycourses.com.my/<course-slug>.html \
  | grep -iE '<title>|<meta name="description"|<h1'
```

Pass/fail per the table above. Common failures to flag:

- Title ends with `| Tertiary Infotech` or `| Magento` (old default) — must be replaced with the per-store brand suffix.
- TGS- (WSQ) course missing "WSQ" in title.
- MY course missing HRDF in description.
- SG non-WSQ (C-prefix) course mentioning SkillsFuture/WSQ — must be stripped.
- Same title across two countries (e.g. SG and MY identical) — must differ at minimum by the brand-country suffix; ideally also by city/locality token in the course name itself to avoid hreflang-cluster dupe-content suppression.

### 4c. Where these are set in Magento

- Per-store override: **Catalog → Manage Products → [product] → switch Store View → Meta Information tab → Meta Title / Meta Description**. Save at the store scope, NOT default, so each country has its own.
- Bulk audit: dump `catalog_product_entity_varchar` where `attribute_id` matches `meta_title` / `meta_description` and `store_id IN (0,1,…)` to find any row still at default (`store_id=0`) or missing per a country store.
- Reminder: per the auto-memory, CLI `saveAttribute` writes at SG scope, not admin — bulk migrations targeting meta fields must set `store_id` per country and clear stale overrides.

### 4d. Other on-page items

- **H1**: should match the course name (no brand suffix in H1 — the suffix is title-only). Per the auto-memory, `product_name` is sacred — never mutate it for SEO; the suffix lives in `meta_title` only.
- **Schema.org `Course`**: every course page should have JSON-LD with `Course`, `provider` (Tertiary Courses), `hasCourseInstance` (next class date), `offers.price` (in local currency). Check `<head>` for `<script type="application/ld+json">`. Use Rich Results Test (https://search.google.com/test/rich-results) to validate — `curl` strips `<script>` tags so you cannot detect JSON-LD with curl alone.
- **Internal linking**: every course should be reachable from a category page within 2 clicks of homepage. Check via Screaming Frog crawl depth.

**Schema detection note:** `curl` and `WebFetch` cannot reliably see JSON-LD because they strip `<script>`. Use the Rich Results Test, or in the browser run `document.querySelectorAll('script[type="application/ld+json"]')`.

## 5. Country-specific signals

| Country | Signal to verify |
|---------|------------------|
| SG | `en-SG` hreflang; SGD prices; SG address in footer; **WSQ / SkillsFuture branding for TGS- SKUs only**; Google Business Profile at SG address; `+65` phone in footer |
| MY | `en-MY` (and optionally `ms-MY`); MYR prices; KL/PJ address; **HRDF (HRD Corp) branding**; `+60` phone |
| GH | `en-GH`; GHS prices; Accra address; `+233` phone; no funding branding |
| NG | `en-NG`; NGN prices; Lagos/Abuja address; `+234` phone; no funding branding |
| BT | `en-BT`; BTN prices; Thimphu address; `+975` phone; no funding branding |
| IN | `en-IN`; INR prices; India address; `+91` phone; no funding branding |

These are E-E-A-T trustworthiness signals for local rankings. Missing local NAP (Name/Address/Phone) is the single biggest signal Google uses to *not* rank a country variant.

## 6. Tooling

- **Google Search Console** — one property per country domain (4 properties total). Verify all four are claimed and the Sitemaps tab shows the sitemap.
- **Rich Results Test** — for schema (curl can't see JSON-LD).
- **PageSpeed Insights** — Mobile + Desktop per country URL.
- **Screaming Frog** (if licensed) — crawl with custom robots, set "JavaScript rendering" on, export hreflang errors. This is the one paid tool worth running.
- **Magento admin → Catalog → URL Rewrite Management** — find rewrite chains and 302s that should be 301s.

## Output format

```
EXECUTIVE SUMMARY
- Top 3 issues blocking organic growth on this site
- Quick wins (config-only, no code) the user can apply today

CROSS-STORE / HREFLANG
- Issue (Severity High/Med/Low): Evidence, Impact, Fix

INDEXABILITY
- ... same shape

CORE WEB VITALS
- ... same shape, with PageSpeed scores per country

ON-PAGE & SCHEMA
- ... same shape, with sample course URL evidence

PRIORITISED ACTION PLAN
1. Blocking / critical (broken indexation, etc.) — owner + ETA
2. High impact (CWV, schema, hreflang fixes)
3. Quick wins (config toggles)
4. Long-term (content strategy, link building)
```

## Invariants — these are HARD RULES, never recommend changing them

These two are non-negotiable. Past audits suggested touching them and broke
the storefront / clobbered structured data. Flag any audit finding that
*depends* on changing either as "won't fix" with a one-line reason.

1. **Course title (product `name`) is immutable.**
   The `catalog_product_entity_varchar.value` for `name` is the H1 on the
   product page, the `name` in JSON-LD Course schema, the anchor text on
   every internal link, the line item on every order/registration, the
   subject in transactional emails, and the source of the URL key. Do NOT
   recommend rewriting it for SEO keyword density, brand suffix injection,
   title-length compliance, or duplicate-content disambiguation. If a meta
   improvement requires a longer/shorter title, put the change in
   `meta_title` only — never in `name`. Same rule for course `sku`.
   Reference: [[feedback_product_name_is_sacred]] in `.claude/memory/`.

2. **Category URLs are short-path only — `/<url_key>.html`, never
   `/parent/.../<url_key>.html`.**
   Enforced by the `MMD_FlatCategoryUrl` module (class-rewrite of
   `Mage_Catalog_Model_Url::getCategoryRequestPath`). Do NOT recommend:
   - Re-enabling the deep category path for "breadcrumb URL parity" or
     similar SEO intuitions — deep paths are explicitly unwanted.
   - Disabling `MMD_FlatCategoryUrl` or reverting it to stock behavior.
   - Setting `catalog/seo/product_use_categories = 1` to "improve internal
     link signals" — products are also short-path (no category prefix).
   - Adding observers / class rewrites that prepend parent path on
     `_refreshCategoryRewrites` or `getCategoryUrlPath`.
   If a recommendation would change a URL, it must result in a flatter
   URL, not a deeper one. Existing long-path *deep-path* rewrites stay as
   301 sources (save-rewrites-history) — they preserve link equity.

3. **Every active category MUST resolve at the clean `/<url_key>.html`
   with NO collision suffix — `-1`, `-2`, … `-33` on a live category URL
   is a BUG, not a valid URL.**
   The canonical request_path of an enabled (`is_active=1`) category must
   be exactly `<url_key>.html`. A suffixed canonical
   (`aws-practice-exams-33.html`) means the clean base path is squatted by
   a *stale* rewrite and the flat-URL job kept bumping the suffix on every
   reindex. This is the one case where you DO clean up rewrites:
   - **A save-history redirect that squats a base url_key needed by a
     different *live* category must yield.** A 301 from a former url_key of
     category X that now blocks the live category Y from claiming
     `/<url_key>.html` is link-equity-negative *and* breaks Y's canonical —
     delete (or re-point) the squatter so Y gets the clean path. This is
     the exception to "never delete redirects": deep-path → flat redirects
     are kept; base-key squatters that collide with a live category are not.
   - **Suffix explosion is real on this install.** Repeated
     reindex/force-flatten runs accumulate temporary `XXXXXXXX_TIMESTAMP`
     id_path save-history rewrites (thousands of them) that each bump the
     next canonical suffix. Purging the stale temp-suffix redirect chain
     for a category lets its canonical fall back to the clean base path.
   - **Detection (run this in every audit):** enumerate every
     `is_active=1` category's canonical rewrite per store and flag any whose
     `request_path` matches `-[0-9]+\.html$`, plus any that 404 or 301 when
     fetched. A genuinely duplicate url_key between two *live* sibling
     categories is a content fix (rename one url_key), not a suffix.
   ```sql
   -- collision-suffixed canonicals on LIVE categories (per store_id)
   SELECT r.store_id, r.category_id, r.request_path
   FROM core_url_rewrite r
   JOIN catalog_category_entity_int a
     ON a.entity_id = r.category_id AND a.store_id = 0
     AND a.attribute_id = (SELECT attribute_id FROM eav_attribute
        WHERE attribute_code='is_active' AND entity_type_id=3)
   WHERE r.product_id IS NULL AND r.options IS NULL
     AND r.id_path LIKE 'category/%' AND a.value = 1
     AND r.request_path REGEXP '-[0-9]+\\.html$';
   ```
   ```bash
   # accessibility sweep — every category URL must be 200, no 301/404
   # (build /tmp/cats.txt from the per-store request_path list first)
   awk '{print "url = \"https://www.<host>/" $0 "\""; print "output = \"/dev/null\""}' \
     /tmp/cats.txt > /tmp/cfg
   curl -Z --parallel-max 12 -s -K /tmp/cfg \
     --write-out '%{http_code} %{url_effective} -> [%{redirect_url}]\n' \
     | grep -v '^200 '   # anything printed is a category that is not cleanly reachable
   ```
   Disabled (`is_active=0`) categories and other-store categories correctly
   404 on a given host — do NOT flag those.

## Anti-patterns — don't recommend

- Don't recommend rel=canonical from country domain to SG. That suppresses the country domain. Self-canonical per store.
- Don't recommend `noindex` on country stores to "fix duplicate content". Hreflang is the right tool for that.
- Don't recommend disabling Magento URL rewrites. The whole site depends on them.
- Don't recommend pushing PageSpeed score above 70 on mobile without acknowledging that Magento 1 + Ultimo has a structural ceiling around 60-75 without a CDN + heavy theme work.
- Don't suggest the user buy SEMrush/Ahrefs without first checking what they already have access to.
- Don't add "WSQ", "SkillsFuture", or any subsidy keyword to SG non-WSQ (C-prefix) course titles or descriptions — it dilutes WSQ-course relevance and misrepresents non-funded courses.
- Don't add "HRDF" / funding language to GH / NG / BT / IN course meta — no such scheme applies, and it's misleading.
- Don't drop the `| Tertiary Courses <Country>` brand suffix to save title characters. If the title is too long, the *course name* is too long — flag the course, don't strip the brand.
- Don't write per-store meta at the default scope (`store_id=0`) — it will leak across all stores. Always save Meta Title / Meta Description at the country store scope.
