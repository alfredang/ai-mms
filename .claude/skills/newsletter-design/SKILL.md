---
name: newsletter-design
description: Design and continuously improve the SG agentic-flyer newsletter (the MailerLite course flyer). Use when writing/curating a course's flyer pitch, adding a per-course pitch or accent/logo, changing the flyer copy or layout, or working the open-rate/click-rate improvement loop (pre-design + post-blast hooks, learnings log). Covers the HARD RULES, the per-course pitch registry, colour/logo variation, and the data-driven optimisation process. SG-only; the render/flow code is MMD_Marketing.
---

# Newsletter (agentic-flyer) design

The agentic-flyer is the single approved course-flyer the autonomous pipeline
renders for **MailerLite blasts** and the admin **Live Preview**. One renderer
feeds all three surfaces (backend preview, reviewer approval email, MailerLite
blast) so they are always identical. The goal of every design decision is the
**highest open rate and click rate** — measured, not guessed.

**Load this skill** whenever you touch the flyer copy, add/curate a course
pitch, change the colour/logo, or run the improvement loop.

## Where it lives

| Piece | File |
|-------|------|
| Renderer (copy, accent, logo, layout) | `app/code/local/MMD/Marketing/Helper/Flyer.php` |
| Curated per-course pitch registry | `Flyer.php::_curatedPitch()` |
| Topic reframing + generic fallback | `Flyer.php::courseOutcomes()` / `courseHook()` / `parseTopics()` |
| Pipeline (propose/schedule/blast/hooks) | `app/code/local/MMD/Marketing/Model/Cron/Flyer.php` |
| Pre-design hook | `Cron/Flyer.php::preDesignHook()` |
| Post-blast hook + learnings | `Cron/Flyer.php::analyseBlast()` / `designLearnings()` |
| Blast stats capture | `Cron/Flyer.php::syncBlasts()` + webhook `/newsletter-review/index/mlhook` |
| Dashboard "Recent blasts" | `template/dashboard/index.phtml` (mn-blasts) |

## HARD RULES (never break)

1. **Unsubscribe footer** — every design carries the MailerLite `{$unsubscribe}`
   link in the footer. Non-negotiable (also enforced in code).
2. **Classroom only** — the format line says Classroom; never advertise "Live
   Online" (admin decision).
3. **Never lift the syllabus verbatim.** The value stack is *outcomes*
   ("what you'll walk out able to do"), not the course-page topic list.
4. **Never ship the same generic lines on every flyer.** Each course's copy is
   either curated or reframed from *its own* topics, so no two flyers read alike.
5. **One active flow per course** — `createProposal()` refuses a second live
   flyer for a course already pending/scheduled.
6. **Non-production never emails the managers** — `sendForReview()` no-ops on any
   non-`tertiarycourses.com.*` base_url (localhost), so a dev/test run can't
   spam angch@/tansc@ with broken links. Override for a test env only via
   `mmd_marketing/newsletter/allow_local_review_email=1`.
   See [[feedback_local_sendforreview_sends_real_emails]].
7. **Max 2 blasts/week, Mon/Thu 08:00 SGT** — Blastguard enforces it. All time
   math uses `Blastguard::nowLocal()` (Magento forces PHP to UTC — see
   [[feedback_mysql_utc_php_sgt_time_mismatch]]).

## Copy philosophy — make the pitch appealing

- **Benefit-driven, pain-point-led, plain English.** Each line is a tangible
  result the reader can picture, not a feature or a buzzword. "Ship your first
  useful tool before lunch," not "Module 3: Tool Use."
- **Funnel, not brochure.** Hero hook → value stack (outcomes) → funding offer →
  intakes → CTA. The price/value story lands early.
- **Specific > clever.** Name the real thing the course unlocks (webhooks, RAG,
  deployment) — specificity is what converts a technical buyer.
- **Vary the frames.** The topic-reframing frames rotate so lines don't read
  as a template.

## Per-course pitch registry (living — keep improving)

Curated flyer voice lives in `Flyer.php::_curatedPitch()`, keyed by SKU:

```php
'TGS-XXXXXXXXXX' => array(
    'accent'   => array('#solid', '#lightBg', '#lightBorder'), // optional
    'logo'     => 'n8n',                                        // optional text badge
    'hook'     => '<one-sentence hero hook>',
    'outcomes' => array('<benefit 1>', '<benefit 2>', ...),     // 4-5 lines
),
```

Resolution order for any course:
1. **Curated** pitch (best — hand-written) →
2. **Reframed** from the course's own parsed topics (varied frames) →
3. **Generic** benefit frame (only when a course has no parseable topics).

**Current curated pitches** (extend this list as courses are promoted):

| SKU | Course | Angle |
|-----|--------|-------|
| `TGS-2025052468` | Agentic AI Applications with Claude Code | Build your own apps in plain English; terracotta accent |
| `TGS-2023035977` | Agentic AI Automation with n8n | Webhooks + RAG → real agentic apps/workflows; n8n-pink accent + logo badge |

**To add a course:** append an entry to `_curatedPitch()` with a hook + 4-5
outcome lines (+ optional accent/logo). Verify the SKU against the catalog
first — a wrong SKU silently falls through to the reframed path.

## Colour + logo variation

- **Accent palette** per curated course: `array($solid, $lightBg, $lightBorder)`.
  Threaded through the whole flyer (`$accent/$accentBg/$accentBr` in `render()`).
  Default is brand blue `#2563eb / #eaf0fe / #c7d7fe`. Pick a colour that reads
  as the course's own identity (Claude terracotta `#c2410c`, n8n pink `#ea4b71`).
- **Logo** — set `'logo' => '<mark>'` to render an email-safe white pill with the
  mark in the accent colour (no hosted image needed — data-URI/remote images are
  unreliable in Gmail). For a real raster logo, host it in `media/` or R2 and
  extend the render to `<img>` it; a text badge is the safe default.

## The improvement loop (goal: max open + click rate)

The pipeline is a closed learning loop:

```
preDesignHook ──► render (curated/reframed pitch + accent) ──► approve ──►
   MailerLite blast ──► syncBlasts/webhook capture ──► analyseBlast ──►
   designLearnings log ──► (feeds) preDesignHook of the NEXT design
```

- **Pre-design hook** (`preDesignHook($pid)`, runs inside `createProposal`):
  checks whether the course has a curated pitch and reads the accumulated
  learnings — surfaces the best past open-rate subject as the bar to beat, and
  logs the recommendation. Read-only; the render already honours the curated
  pitch/accent it points to.
- **Post-blast hook** (`analyseBlast($id, $stats)`, runs when a blast is
  captured): compares this blast's open/click rate against the running average
  of all prior blasts, tags it **win / mixed / loss**, and appends a structured
  entry (subject, course, WSQ, accent, curated?, rates, verdict) to
  `mmd_marketing/newsletter/design_learnings` (JSON, last 24).
- **Applying learnings each cycle** (what YOU do when designing the next one):
  1. Read `designLearnings()` (or the "Recent blasts" dashboard).
  2. Rank by open rate, then click rate. Prefer same funding type (WSQ vs not).
  3. Adopt the **winners'** patterns — subject formula, hook angle, accent,
     pitch structure — into the next curated pitch. Retire **loss** patterns.
  4. Every new design should aim to beat the best past open + click rate.

**Reading the numbers:** open rate is driven by the **subject + preheader**
(optimise those first); click rate + click-to-open by the **hook, offer and
CTA**. A high open / low click blast = the subject worked but the body didn't —
tighten the value stack and CTA. Low open = rework the subject.

## Anti-patterns

- Don't hand-write a bespoke `<style>`/layout per course — vary via accent/logo/
  copy, keep one renderer.
- Don't add a design lever the post-blast hook can't see (subject, course, WSQ,
  accent, curated) — if you can't measure it, you can't learn from it.
- Don't chase a single blast's noise; act on patterns across several.
- Don't bypass the caps or the approval gate to "just send" a design.
