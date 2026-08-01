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
4. **Hero** — `Helper_Image::generateHero()` renders the TITLE through
   `MMD_CourseImage_Model_Cover` (TGS- SKU adds WSQ + SkillsFuture chips) to
   R2 under `blog/auto-*`. That prefix marks pipeline-replaceable heroes;
   an admin-uploaded hero (no prefix) is NEVER overwritten.
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
