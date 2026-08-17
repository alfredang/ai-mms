---
name: blog-pipeline
description: Operate, extend or debug the SG agentic blog pipeline (MMD_Blog) — the 2-posts/week agent team (research agent with web search → writer + auto hero → manager approval → Tue/Fri 9am publish → LinkedIn/Facebook share), the admin timeline panel, the next-course queue, and prod content operations (create a post pending review, retarget a publish slot, test the approval loop). Use when asked to "create a blog post", "schedule/reschedule a blog", "approve a blog", "the blog pipeline is stuck", "change blog topics/slots", or to author a case-study post from actual work.
---

# Agentic blog pipeline (MMD_Blog)

Built 2026-07 (commits 45a84527b → 11d029a60). SG production runs the review
flow; partner sites (MY/GH) keep legacy immediate auto-publish. Everything
below was learned from the actual production build — trust it over guesswork,
verify against code when versions drift.

## The agent team (daily 09:00 SGT cron `mmd_blog_autoblog`)

1. **Course pick** — `mmd_blog_queue` head first (admin-curated, row DELETED on
   pop), else best-selling unblogged course (`source_sku` tracks coverage;
   SG auto-pick is WSQ `TGS-` only, queued courses are exempt).
2. **Research agent** — `Autoblog::_researchTopic()` calls Claude with the
   server `web_search_20250305` tool over the `mmd_blog/autoblog/topics` focus
   pool. Returns topic/angle/whyNow/keyPoints/sources JSON. Returns null
   (writer goes evergreen) when the API key/org lacks web search — check
   `var/log/mmd_blog.log` for `web-search call failed`.
3. **Writer agent** — 1200–1800-word in-depth post as strict JSON
   (title/slug/excerpt/contentHtml/meta/tags), cites ≥2 research sources,
   ≥2 CTA links to the course URL, WSQ/SkillsFuture funding hooks, FAQ.
4. **Hero** — `Helper_Image::generateHero($title, $sku, $kicker)` renders the
   TITLE through **`MMD_Blog_Model_Hero`** (the EDITORIAL renderer — see
   "Hero images" below; NOT the course cover) to R2 under `blog/auto-*`. That
   prefix marks pipeline-replaceable heroes; an admin-uploaded hero (no
   prefix) is NEVER overwritten.
5. **Approval** — `sendForReview()` emails both managers HMAC-token links
   (`blog|id|email` domain-prefixed, can't cross with newsletter tokens).
   ONE approval books the next free **Tue/Fri 09:00 SGT** slot via an atomic
   conditional UPDATE (`scheduleApproved`). 24h reminder once; 5-day expiry
   back to draft. Admin-side buttons hit `adminhtml/blog/reviewDecision`.
6. **Publish + share** — `publishDue` cron (*/10) flips due posts live and
   shares once to LinkedIn + Facebook, deduped by `linkedin_urn` /
   `facebook_post_id` (retries are no-ops).

## Statuses (`mmd_blog_post.status`)

0 draft · 1 published · 2 pending review · 3 scheduled · 4 changes requested.

## Admin timeline panel (newsletter parity)

`Block_Adminhtml_Pipeline` + `template/blog/pipeline.phtml` (bp-* copy of the
dashboard's mn-* component) renders above the grid at `adminlogin/blog/`:
flow steppers (Research & Write → Approval sent → Approved → Scheduled →
Published) + ghost next-flow, caps (Posts x/2, Next slot, Queue), the merged
stage table (12 rows, stage badges, approval-sent, schedule, LinkedIn link),
and the drag-reorder queue (endpoints: `queueList/queueAdd/queueRemove/
queueReorder/searchCourses`, per-row Run Now = queueRemove then
`generate?course_id=`). Gotcha: never use a bare `<h3>` in the panel — the
global admin h3 rule inflates it; use a classed div (`.bp-queue-title`).

## Prod content ops (SG server — see memory reference_sg_server_access)

Find the web container fresh each time (deploys rename it):
`for c in $(docker ps -q); do docker exec $c test -f /var/www/html/app/Mage.php && docker ps --format '{{.Names}}' -f id=$c; done`

- **Create a hand-written post through the real approval loop** — write a PHP
  script locally (post with STATUS_PENDING_REVIEW + `related_skus`/`source_sku`,
  `syncTags`, `generateHero`, then `sendForReview($post)`) and pipe it:
  `ssh sg "docker exec -i <web> php" < script.php`. Verify the hero URL and the
  CTA course URL return HTTP 200 BEFORE inserting.
- **Retarget a publish slot** (e.g. admin wants Thursday, not the Tue/Fri
  default): after approval flips it to status 3, set
  `scheduled_publish_at = 'YYYY-MM-DD 09:00:00'` (SGT wall clock — publishDue
  compares against Asia/Singapore local time). publishDue fires on ANY
  scheduled datetime, not just Tue/Fri; the Tue/Fri constraint lives only in
  `nextPublishSlot()`.
- **Test the approval loop headlessly** — insert as pending review, confirm
  the managers got "[Approval needed] Blog: …", then either click the email
  link or POST to `adminhtml/blog/reviewDecision`. `scheduleApproved` returns
  "Publishing on <slot>"; a concurrent second approval sees "Already
  scheduled" (atomic claim).

## Hard-won rules

- Every write idempotent (INSERT IGNORE, share dedup markers); every failure
  degrades (no research → evergreen; no hero → post ships without).
- `_mayEmailReviewers()` blocks non-SG-production hosts from emailing the real
  managers; local tests need `mmd_marketing/newsletter/allow_local_review_email`.
- One review at a time: `_tendPendingReview` only tends the NEWEST pending
  post — don't stack pendings programmatically.
- Config defaults (e.g. `topics`) are invisible until the Redis-backed config
  cache is flushed (`rm var/cache` is NOT enough).
- Case-study posts from actual client work are the top performers (MSIG,
  MINDEF, Qualcomm pattern): concrete build log + "skills we learned" section
  + WSQ funding CTA to the best-matching TGS- course.

## Hero images (read before generating or fixing any post hero)

**A blog hero is EDITORIAL, not a course cover.** This is the single rule to
remember. `MMD_CourseImage_Model_Cover` renders the Tertiary logo lockup plus a
"FUNDING AVAILABLE / WSQ / SkillsFuture Credit" chip row — correct on a product
tile, wrong on an article card. When the blog listing mixed the two, the
course-cover posts read as ad tiles sitting among real editorial cards (admin
feedback 2026-08-17: *"it looks like the course product image"*).

Heroes now render through **`MMD_Blog_Model_Hero`** (`Model/Hero.php`):

- **1600×900** (16:9) — matches the `.mmd-blog-card-hero` crop and the
  `og:image` ratio social platforms expect. The course cover is 1600×900 too
  but composed for a product grid, not a wide card.
- **8 topic themes** (`THEMES`), each = 2 background stops + accent + motif +
  the keywords that select it. Picked by scanning `title + kicker`, first hit
  wins, so **order specific topics above generic ones**. Themes exist so the
  listing is not one repeated blue block: security=teal, seo=violet,
  marketing=pink, automation=green, code=cyan, data=amber, video=rose,
  funding=sky.
- **A generated motif** per theme (shield / magnifier / funnel / terminal /
  chart / play / rosette / node-graph) in the right column. This is what makes
  a card look designed rather than typeset — do not drop it back to text-only.
- **No logo, no funding chips, ever.** If a hero needs to advertise funding,
  that belongs in the post body's CTA, not the image.

Adding a theme = append to `THEMES` (above the generic ones) + write a
`motifX()` method + add the `case` in `drawMotif()`. Reuse the primitives
(`thickLine`, `thickPolygon`, `roundedRect`) rather than raw GD calls.

**Every post should have a real hero.** A NULL `hero_image_url` falls back to
the CSS gradient card (`.mmd-blog-hero-fallback`), which next to rendered
artwork reads as a missing image. Backfill with
`scripts/maintenance/regenerate-blog-heroes.php` (`--dry-run` first;
`--only-empty` to touch just the NULL ones). It targets `hero_image_url LIKE
'%/blog/auto-%'` **OR** NULL/empty, so admin-uploaded and external heroes (e.g.
a YouTube thumbnail) are preserved. Kickers come from
`Helper_Data::getPostTags()`, skipping the generic `WSQ`/`SkillsFuture` labels.
Note it also picks up **drafts and scheduled posts**, not just published ones —
query `status=1` separately if you only meant to count live cards.

`mmd_blog_post` is a **flat** table, so the EAV `array(array('attribute'=>…))`
OR syntax fatals in `prepareSqlCondition` ("Array to string conversion"). The
flat-collection OR form is one field name plus an array of conditions:
`addFieldToFilter('hero_image_url', array(array('like'=>…), array('null'=>true)))`.

### Title fitting — fit on BOTH axes

Auto-fitting on **line count alone lets long titles run off the canvas**: 4
lines at 82px needs ~420px, more than the band below the kicker, so the
headline rendered past the bottom edge and under the card's fade (admin
feedback 2026-08-17: *"seems to be cropped or clipped for those with long blog
title"*). The shrink loop must ALSO test the rendered block height against the
available band. Current settings: max 64px (not 82), min 34px, up to 5 lines —
course-style titles like "Lean Six Sigma Green Belt Training Singapore: WSQ
CLSSGB Guide" then step down and wrap rather than clip. Cards render ~380px
wide, so 64px on a 1600px canvas is still comfortably legible.

**Same-theme posts must not render identical art.** Several "Agentic AI" posts
all drew the same green node graph and looked duplicated in the grid. A
title-derived seed (`md5` → int, set in `render()`) varies the node-graph spoke
count (5–8), its rotation and the gradient's lighter stop. Deterministic: the
same title always renders the same image, so re-running the backfill is stable.

### Hand-copied container files DO NOT survive a deploy

To apply a renderer change immediately (rather than waiting on Coolify), the
working move is `docker cp` of the changed PHP into the running web container
plus a re-run of the backfill. **But the next deploy overwrites those files with
whatever is in its build**, and Coolify often has several builds queued, so a
build from an OLDER commit can land after your fix and silently revert it.

Symptom: the course-cover images come back. Diagnose with, not by guessing —

```
docker exec <web> grep -c 'mmd_blog/hero'      app/code/local/MMD/Blog/Helper/Image.php   # want 2
docker exec <web> grep -c 'courseimage/cover'  app/code/local/MMD/Blog/Helper/Image.php   # want 0
```

`Hero.php` present but `Helper/Image.php` still calling `courseimage/cover` is
exactly this race — the build carried the new file but not the commit that
rewired the caller. Fix: re-`docker cp` both files, re-run the backfill, and
check `application_deployment_queues` for builds still queued behind you. The
regenerated R2 URLs are stored in the DB, so **already-rendered heroes are not
lost** by a bad build — only newly generated ones would revert.

### GD traps these renderers hit (both cost a debug cycle)

- **`imagesetthickness` is ignored by `imageellipse`** on most GD builds. A
  "thin, aliased ring" is not a colour problem — build the stroke by stacking
  ~20 concentric `imageellipse` calls at decreasing diameter.
- **Never build a translucent rounded rect from overlapping shapes.** The
  classic two-rectangles-plus-four-corner-ellipses construction double-blends
  every pixel in the overlap when alpha < 127, so the corners render darker and
  read as four "bumps" on the pill. Draw it **scanline by scanline** (one
  `imageline` per row, x-inset from the circle equation) so each pixel is
  touched exactly once — see `roundedRect()`. Stroking the pill on top makes it
  worse, because `imagearc` corners never land exactly on the filled edge.

Verify a hero by **rendering it to a PNG and looking at it**, never by reading
the code — every defect above (bumps, thin rings, text colliding with the
motif) is invisible in source and obvious in the image.

## Article HTML rendering (read before authoring post content)

Two traps that silently mangle a post that looks perfect in the SQL.

### 1. Lists have NO markers unless the theme paints them

Ultimo's `styles.css:46` sets a global `ul,ol { list-style:none }`. Any `<ol>`
you write renders as an **unnumbered** stack of lines — fatal for a
step-by-step guide, where "Step 5" silently becomes indistinguishable from
"Step 4". `.mmd-blog-post-body` therefore paints its own markers with CSS
counters (`skin/frontend/ultimo/default/css/blog.css`, "Lists" block):

- `<ol> > li::before` — numbered **blue circular badge** (`counter(mb-step)`);
  use `<ol>` for every sequential click-path / install step list.
- `<ul> > li::before` — **blue disc**; use for non-sequential lists.
- `li` carries `padding-left: 34px` + `position: relative`; the marker is
  absolutely positioned, so text wraps flush instead of under the bullet.

Never re-add `list-style` to fix a missing marker — the global reset beats it
in the cascade at equal specificity. Extend the `::before` rules instead.
Verify with a **screenshot**, not source grep: the markup looks identical
whether or not the markers paint.

### 2. `<pre>` newlines die in the one-line collapse

Post content must be ONE line (apply.php splits on semicolon-at-EOL), but a
naive `' '.join(html.split())` also eats the newlines **inside `<pre>`**, so
multi-line shell commands render as one unbroken line and are not
copy-pasteable. Protect `<pre>` regions and encode their newlines as `&#10;`,
which survives the collapse and renders as a real break inside the
`white-space: pre` block:

```python
def collapse(html):
    parts = re.split(r'(<pre>.*?</pre>)', html, flags=re.S)
    return ' '.join(
        (p.replace('\n', '&#10;') if i % 2 else ' '.join(p.split()))
        for i, p in enumerate(parts)
    )
```

Code blocks style as a dark terminal card and **scroll inside themselves**
(`overflow-x:auto`) so a long `docker run` never forces the page body to
scroll sideways on mobile. Incident: migration 864 shipped with every command
collapsed to one line; fixed by 865 (content re-write) + the blog.css `pre`
rules, which did not exist at all before.

Escaping: write `&amp;&amp;` for `&&` and `&gt;` for `>` inside `<pre>`, and
double every `'` for the SQL literal.

### 3. FAQ sections ship as `<details>` accordions

A six-question FAQ written flat as `<h3>Q</h3><p>A</p>` runs ~900px and buries
the closing CTA below the fold. Author the FAQ as native
`<details>`/`<summary>` instead — the same content collapses to ~280px:

```html
<h2>Frequently asked questions</h2>
<div class="mmd-faq">
  <details class="mmd-faq-item">
    <summary class="mmd-faq-q">Question text?</summary>
    <div class="mmd-faq-a"><p>Answer.</p></div>
  </details>
</div>
```

Native `<details>` over a JS accordion, deliberately: no JS to load or break,
keyboard + screen-reader accessible for free, and the answers stay in the DOM
so Google still indexes them for FAQ rich results (a `display:none` JS
accordion risks the answer text being discounted). Styling lives in
`blog.css` under "FAQ accordion" — the default disclosure triangle is removed
(`list-style:none` + `::-webkit-details-marker`) and replaced with a rotating
chevron.

### 4. NEVER round-trip post content through a `errors='replace'` decode

Migration 866 read each post's existing content out of MySQL with
`.decode('utf-8', 'replace')`, transformed it, and wrote it back. Every
em-dash (U+2014) became U+FFFD — 60 corrupted bytes in one post, 72 in the
other — and shipped as black-diamond `�` on the storefront.

When rewriting existing post content, **rebuild it from the pristine committed
migration**, never from a DB read. Decode strictly (no `errors=` kwarg, so bad
bytes raise instead of silently substituting) and gate the output before
writing:

```python
assert '�' not in new, 'transform introduced U+FFFD'
assert new.count('—') == original.count('—'), 'em-dash count changed'
```

Verify after applying with a byte-level check, not a visual one —
`LENGTH(content) - LENGTH(REPLACE(content, CHAR(0xEF,0xBF,0xBD USING utf8mb4), ''))`
must be 0. See [[feedback_migration_applyphp_utf8_outage]] for the related
apply.php failure mode.
