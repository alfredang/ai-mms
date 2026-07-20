---
name: ai-vibe-coding-series
description: Repurpose an SG non-WSQ (C-prefix) course into the "AI Vibe Coding Series" and manage that series — rename to "AI Vibe Coding for/with <topic>", rewrite overview + 4 topics (2 per day), set 2 days / 15h / $700, regenerate the branded cover, add the red "AI Vibe Coding Series" badge, and point the Funding block at the matching WSQ/IBF course. Also covers disabling retired courses. Use when asked to "replace this course with AI Vibe Coding for X", "add to the AI vibe coding series", "add the vibe coding badge", "make it 2 days $700 4 topics", "change the funding link", or "disable this course". SG production only, delivered as idempotent migrations/NNN-*.sql.
---

# AI Vibe Coding Series (SG non-WSQ)

Playbook for the **non-WSQ AI Vibe Coding course series** on the SG storefront
(`www.tertiarycourses.com.sg`). These are **C-prefix** (SG non-WSQ) courses that
have been repurposed into a consistent "AI Vibe Coding for/with `<topic>`" line.

**Never** touch WSQ (`TGS-`) or partner (`M`-prefix / MY / GH) rows — this series
is SG non-WSQ only. Everything ships as **idempotent migrations** in `migrations/`
(reviewable, auto-deploys to SG prod on push to `main`). Read the repo `CLAUDE.md`
"Pre-push verification" section before pushing.

## The series standard

Every course in the series conforms to:

| Field | Value |
|-------|-------|
| Name | `AI Vibe Coding for <topic>` (or `AI Vibe Coding with <topic>`) — capital "AI" |
| Duration | `15` (2 days) — `duration` varchar attribute |
| Price | `$700` (2 days @ $350/day) — every store-scoped `price` decimal row |
| Topics | **exactly 4**, 2 per day |
| Overview | 2 paragraphs (`short_description`) |
| Badge | red pill "AI Vibe Coding Series" after the Course Code |
| Cover | branded GD cover rendered from the new name, on R2 |
| Funding | Funding block points to the matching WSQ (or IBF) course |
| url_key | **unchanged** (keep the old slug — preserves URL + SEO) |

Assistants named consistently in copy: **Cursor, GitHub Copilot, Claude**.

### Topic HTML format (must match existing courses)

```html
<h3 class="course-topic-h3">Topic 1 <Title></h3>
<ul>
<li><subtopic></li>
...
</ul>
<h3 class="course-topic-h3">Topic 2 ...</h3>
...
```

4 `<h3 class="course-topic-h3">` blocks, each with a `<ul><li>` list. Do NOT use
the LSN_DATA-comment / `<p><em>` format — these courses use the h3 format.

## Repurpose one course — steps

For SKU `C###`, entity `<eid>`:

1. **Render + upload the cover** (R2 creds live in the container env, so this
   works from localhost). Pass the NEW title literally:
   ```php
   $png = Mage::getModel('mmd_courseimage/cover')->render('<NEW NAME>', 'C###', []);
   $up  = Mage::helper('mmd_courseimage/r2')->putObject(
            'course-covers/C###-'.gmdate('Ymd-His').'.png', $png, 'image/png');
   // $up['url'] -> bake into the content migration's course_image_url row
   ```
   Non-WSQ courses pass `[]` badges → clean title card (no funding chips).

2. **Content migration** `migrations/NNN-repurpose-c###-ai-vibe-coding-<topic>.sql`
   — idempotent `INSERT ... ON DUPLICATE KEY UPDATE` at `store_id 0` for:
   `name`, `short_description`, `description` (4 topics), `meta_title`,
   `meta_description`, `meta_keyword`, `duration` (`15`), `course_image_url`
   (the R2 url from step 1). Look up each `attribute_id` via
   `SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code=...`.
   Copy an existing one (e.g. `343-repurpose-c384-...sql`) as the template.

3. **Price** — add the SKU to the shared price migration
   `347-ai-vibe-coding-prices-700.sql` (updates *every* store-scoped decimal row,
   so a stale per-store override like C384's store_id=1 $300 is cleaned up too).

4. **Badge** — add the SKU to the `sku IN (...)` list in
   `342-course-series-badge-attr-and-c1143.sql`.

5. **Funding block** — content-only `UPDATE cms_block SET content='...' WHERE
   identifier='course_C###_funding_and_grant'`. Point to the matching course:
   - Full-stack/web/React/Flutter → `WSQ - Build Full Stack React Web App with Vibe Coding`
     (`https://www.tertiarycourses.com.sg/wsq-build-full-stack-react-web-app-with-vibe-coding.html`)
   - Python → `WSQ - Python Fundamental Course for Beginners`
     (`.../wsq-python-fundamental-course-for-beginners.html`)
   - Machine Learning → `IBF - Machine Learning 101 for Financial Trading`
     (`.../ibf-machine-learning-101-for-financial-trading.html`) — use "IBF funding" wording
   - **Validate the target returns 200** on `www.tertiarycourses.com.sg` first.
   - NEVER `->save()` a cms/block model (wipes `cms_block_store` mapping → 404s the
     page). Content-only SQL `UPDATE` is safe.

## The badge mechanism

- **Attribute** `course_series_badge` (varchar, global) — created + assigned to the
  **General** group of every product attribute set in
  `342-course-series-badge-attr-and-c1143.sql`. **The attribute-set assignment is
  mandatory** — without it the product model doesn't load the attribute and the
  badge silently never renders. See [[series-badge-needs-attribute-set-assignment]].
- **Template** `app/design/frontend/ultimo/default/template/catalog/product/view.phtml`
  — renders `<span class="course-series-badge">` right after `.course-code-inline`
  when `getData('course_series_badge')` is non-empty.
- **CSS** `.course-series-badge` in `skin/frontend/ultimo/default/css/custom.css`
  (red `#dc2626`, white, pill).

## Apply + verify (localhost) before pushing

apply.php ledger tracks by filename. If you edited an **already-applied** migration
(342/347/350 accumulate SKUs), clear its row so it re-runs (all statements are
idempotent):

```bash
docker exec ai-mms-web-1 php -r "require '/var/www/html/app/Mage.php'; Mage::app();
  Mage::getSingleton('core/resource')->getConnection('core_write')
    ->query(\"DELETE FROM schema_migrations WHERE filename IN ('342-...sql','347-...sql')\");"
docker exec ai-mms-web-1 php /var/www/html/migrations/apply.php   # must print '... OK'
```

Then reindex the flat catalog + flush caches for the touched products (EAV writes
leave the storefront stale — flat catalog is enabled here):

```php
$flat = Mage::getResourceSingleton('catalog/product_flat_indexer');
foreach ($ids as $id) foreach (Mage::app()->getStores() as $s) $flat->updateProduct((int)$id,(int)$s->getId());
Mage::app()->getCacheInstance()->cleanType('eav');        // needed after attribute-set change
Mage::app()->getCacheInstance()->cleanType('block_html');
Mage::app()->getCacheInstance()->cleanType('full_page');
Mage::app()->getCacheInstance()->cleanType('collections');
```

Verify each page via curl: `HTTP=200`, `0` fatals, correct `<h1 itemprop="name">`,
`<span class="course-series-badge">AI Vibe Coding Series</span>`, 4 topics, correct
funding link, price. On prod after deploy, flush Redis / run the reindex API so the
flat + block/FPC caches pick up the change.

## Disabling a retired course

Add the SKU to `350-disable-numpy-keras-courses.sql` (sets `status=2` on the
default row + flips any per-store override), re-run, reindex + flush. Verify the
course's `url_key.html` returns **404**.

## Current series members (SG non-WSQ, badged)

Repurposed to "AI Vibe Coding for/with X": **C138** (Python), **C384** (Full Stack
Development), **C430** (Machine Learning), **C683** (Flutter), **C1143** (React),
**C1800** (Full Stack Web).
Already "Vibe Coding for X" + badged: **C349, C576, C603, C818, C989, C1074, C1231**.

Extend the `sku IN (...)` lists in migrations 342 (badge) and 347 (price) as new
courses join.
