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
4. **Never ship the same generic lines on every flyer, and NEVER re-send an
   identical design after a change-request.** The copy (hook / outcomes /
   learning journey) is **AI-generated per course** from the course's own
   content — and, on a rework, from the manager's feedback. It is **not a
   template**. "Start from zero", "learn by doing", "build something real" and
   any line that could apply to any course are BANNED — name the actual tools,
   concepts and deliverables of THIS course. A regeneration that produces the
   same flyer the manager just rejected is the bug this loop exists to prevent.
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

## Copy is AI-GENERATED, not templated (the core mechanism)

`Flyer.php::regenerateCopy($productId, $feedback)` is the generator. It builds a
prompt from **(a)** the course's own content (title, SKU, WSQ flag, duration,
short description, parsed syllabus topics), **(b)** the manager's change-request
feedback, and **(c)** the post-blast design learnings (the winning subject
patterns), then calls `mmd_rolemanager/aiSeo::invokeClaude()` and asks for strict
JSON: `{ hook, outcomes[5], journey[{label,do}] }`. The result is persisted into a
per-SKU **design refinements** store (`core_config
mmd_marketing/newsletter/design_refinements`, JSON keyed by SKU), which
`_mergedPitch()` overlays on top of the curated code so `render()` picks it up on
the next call — **no redeploy** to change a course's copy.

**When it regenerates:**
- **Change-request (feedback present) → ALWAYS regenerates.** This is what makes
  a rework differ from the rejected version. `regenerateOnChanges()` calls
  `regenerateCopy($pid, $row['review_feedback'])` *before* rendering.
- **Fresh proposal (no feedback) → reuses** the SKU's existing AI copy if present
  (no API burn); generates once if not. `createProposal()` calls
  `regenerateCopy($pid, '')`.

**Fallback order** when Claude is unavailable (returns null — never a crash):
1. **AI-generated** copy for the SKU (primary) →
2. **Curated** pitch `_curatedPitch()` (hand-written seed / safety net) →
3. **Reframed** from the course's own parsed topics →
4. **Generic** benefit frame (last resort — treat its appearance as a defect to fix).

`_curatedPitch()` is now a **fallback seed**, not the primary path. Keep a curated
entry for flagship courses so a Claude outage still yields course-specific copy,
but the live copy should be the AI-generated refinement. Curated seeds exist for
`TGS-2025052468` (Claude Code), `TGS-2023035977` (n8n), `TGS-2020505042` (React).

**The learning journey** (`journey` field, rendered as a numbered timeline): each
step is `[label, what-you-do]` — for a multi-day course label them `Day 1 · AM`
etc. (day count = duration ÷ 8h). Concrete "here's what you'll build in this
block", never abstract.

**Anthropic credential note:** prod's key is an `sk-ant-oat…` OAuth token, so
`invokeClaude()` uses the `claude` CLI path (the `sk-ant-api…` direct-API path is
skipped for OAuth tokens). Same client the Blog autoblog cron uses; if the CLI is
down, generation falls back to the curated seed.

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
manager feedback ─┐
course content ───┼─► regenerateCopy (Claude) ──► render ──► approve ──►
design learnings ─┘        │
   MailerLite blast ──► syncBlasts/webhook capture ──► analyseBlast ──►
   designLearnings log ──► (feeds) regenerateCopy of the NEXT design
```

- **Generator** (`regenerateCopy($pid, $feedback)`): the render-time step that
  turns course content + manager feedback + learnings into fresh copy (above).
- **Pre-design hook** (`preDesignHook($pid)`, runs inside `createProposal`):
  reads the accumulated learnings and surfaces the best past open-rate subject as
  the bar to beat; logs the recommendation.
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

- **Don't hard-code course copy as a template.** Copy is AI-generated per course
  from its own content + manager feedback + learnings (`regenerateCopy`). A
  hand-written pitch is only a fallback seed, never the live copy.
- **Don't re-send a design after a change-request without regenerating from the
  feedback.** If the manager rejected it, the next email MUST be visibly
  different and MUST address what they said.
- Don't hand-write a bespoke `<style>`/layout per course — vary via accent/logo/
  copy, keep one renderer.
- Don't add a design lever the post-blast hook can't see (subject, course, WSQ,
  accent, curated) — if you can't measure it, you can't learn from it.
- Don't chase a single blast's noise; act on patterns across several.
- Don't bypass the caps or the approval gate to "just send" a design.
