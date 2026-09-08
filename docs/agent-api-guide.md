# OpenClaw Agent API Guide

**Audience:** the OpenClaw chat agent (and any agent that acts on the Tertiary Infotech MMS on
a user's behalf). This is the **verbose, worked-example** companion to the terse contract in
[`agent-api-spec.md`](agent-api-spec.md) and the domain background in
[`agent-context.md`](agent-context.md). If you only read one document, read this one — it has
the rules, every endpoint, realistic chat scenarios, and the edge cases that bite.

> **This document is safe to hand to an agent verbatim.** It contains no secrets — the API key is
> injected separately.

> **This guide is about *changing* things (the MMS write APIs).** To *read/answer questions* about
> a course's info, funding, price, or schedule, see **`agent-context.md` §6 "Reading course +
> funding info"** — those lookups span **two systems** (MMS for the catalog + non-WSQ; the LMS-TMS
> for authoritative WSQ funding figures + grant status), and getting the routing right matters.

---

## 0. The five golden rules

1. **Never write without previewing first.** Every change is a two-step `dry_run:true` (preview)
   then `dry_run:false` + `change_token` (commit). No exceptions.
2. **Relay the `human_summary` AND every line of `warnings[]` to the user, then get an explicit
   "yes"** before you commit. Some ops (especially `api_template`) change *many* courses at once
   and say so in a warning — the user must know.
3. **You own authorization.** The server trusts the API key; it does **not** check whether the
   requester is allowed to do this. Vet the requester before you call.
4. **Be honest in `actor`.** Send the real requester's WhatsApp number + name. If you don't yet
   distinguish their role, send `role: "user"` (or omit it) — don't invent a role.
5. **Don't fight the domain.** Course names, SKUs, and GST/funding fields are off-limits by
   design. If an op is refused, tell the user why rather than trying to route around it.

---

## 1. Base URL, scope, auth

- Each partner country is a **separate site serving one store**. You act on exactly one site —
  the one you were told to manage. Singapore is `https://www.tertiarycourses.com.sg`.
- All write endpoints are `POST`, `Content-Type: application/json`.
- Auth: header `X-API-Key: <secret>` (the same key you use for the read endpoints). Missing
  server key → `503 api_disabled`; wrong key → `401 unauthorized`.

---

## 2. The write protocol (preview → confirm → commit), in depth

Every write is the same shape. Here is the full lifecycle with a real example.

**Step 1 — Preview** (`dry_run: true`). You send the operation and its fields; the server tells
you exactly what would change, in plain English, and hands you a `change_token`.

```json
POST /agent/api_course
{ "op": "update", "dry_run": true,
  "actor": { "id": "wa:+6591234567", "name": "Sylvia", "role": "user" },
  "sku": "C472", "fields": { "price": 780 } }
```
```json
{ "success": true, "dry_run": true, "op": "update", "target": "C472",
  "diff": [ { "field": "price", "from": 720, "to": 780 } ],
  "human_summary": "Course C472 (SC-900 ...): price: 720 -> 780.",
  "warnings": [], "change_token": "sha256:9f2c..." }
```

**Step 2 — Confirm in chat.** Show the `human_summary` (and any `warnings`) to Sylvia:
> "This will change C472's price from S$720 to S$780. Confirm?"

Only proceed on an explicit yes.

**Step 3 — Commit** (`dry_run: false` + the `change_token` from step 1, same fields):

```json
POST /agent/api_course
{ "op": "update", "dry_run": false, "change_token": "sha256:9f2c...",
  "actor": { "id": "wa:+6591234567", "name": "Sylvia", "role": "user" },
  "sku": "C472", "fields": { "price": 780 } }
```
```json
{ "success": true, "applied": true, "op": "update", "target": "C472",
  "audit_id": 1188, "reindexed": ["product_attributes"] }
```

### What the `change_token` protects you from
The token is a fingerprint of *exactly what you previewed* (the operation + the target + a
snapshot of the current values it depends on). On commit the server recomputes it from live
data:
- If nothing changed in between → it matches → the change applies.
- If someone edited that course/class/template in between → mismatch → **`409 stale_preview`**.
  Re-preview, re-confirm with the new summary, retry.
- Commit **without** a token → `400 change_token_required`.
- Re-committing the same approved change (same token) is safe — you won't double-apply.

**Rule of thumb:** if more than a few minutes pass between preview and the user's "yes", just
re-preview to be safe.

---

## 3. The `actor` block (who asked)

Required on every call:

| Field | Required | Notes |
|---|---|---|
| `id` | yes | The requester's WhatsApp number, E.164, prefixed `wa:` — e.g. `wa:+6591234567`. This is the audit key. |
| `name` | yes | The person's name. |
| `role` | no | Defaults to **`user`**. If you distinguish roles, send one of `user`, `learner`, `trainer`, `developer`, `marketing`, `admin`, `training_provider`. An unknown value → `400`. |

Today the agent authorizes by a **binary whitelist** (a number is trusted or not) and will also
face customers — so `user` is the correct, honest default for now. When you start assigning
specific roles, send the matching one; nothing on the server side needs to change. `actor` is
**recorded for the audit trail, not used for authorization**.

---

## 4. Responses & error codes

Preview → `{ success, dry_run:true, diff[], human_summary, details{}, warnings[], change_token }`.

### `details` — say more than one line

Schedule previews return an ordered **`details`** object: label → value, already written for a
person. Use it. A one-line "a date will be added" gives the requester nothing to check the change
against, and they are the one approving it.

**Lay it out and let them scan it**, in the order given — the keys are ordered deliberately:

> **WSQ - Mastering The Art of Conflict Resolution** (TGS-2023021752)
> WSQ / SkillsFuture funded · template (SG) WSQ-B01 · 9:30am - 6:30pm
>
> **New date:** 15 Jun 2027 (Tue) — 1 day
> The course has 16 dates, next one 27 Sep/04 Oct 2026.
>
> ⚠️ Still needed after this: the SkillsFuture (SSG) course run — not done by this change.

The keys change with the operation (`New date`, or `Date now` + `Changing to`, or
`Date being removed`; class ops add `Class id`, `Runs now`, `Learners enrolled`), so render what
is there rather than expecting a fixed list. `details` is context; **`warnings[]` still has to be
said out loud**, and `human_summary` is the one-liner if you need one.
Commit → `{ success, applied:true, target, audit_id, reindexed[], ...op extras }`.
Error → `{ success:false, error:"<code>", message:"<human>" }`.

| HTTP | error | Meaning / what to do |
|---|---|---|
| 400 | `validation_error` | Missing/invalid field, or nothing actually changes. Fix and retry. |
| 400 | `change_token_required` | You committed without a token. Preview first. |
| 401 | `unauthorized` | Bad/missing API key. |
| 404 | `not_found` | Unknown sku / class_id / template. Check the reference. |
| 409 | `stale_preview` | Data changed since preview. Re-preview, re-confirm. |
| 409 | `conflict` | e.g. a class or date already exists on that date. |
| 409 | `ambiguous_trainer` | Trainer name matches several people — re-issue with their email. |
| 409 | `ambiguous_template` | Template reference matches several — be more specific. |
| 409 | `ambiguous_date` | The course has more than one date starting that day — re-issue with `end_date`. |
| 422 | `forbidden_field` | Blocked field (name/sku/GST). Don't retry; explain to the user. |
| 422 | `use_class_ops` | You sent a date op for a C-prefix course. Re-issue as `add_class`/`update_class`/`remove_class`. |
| 422 | `course_not_eligible` | You sent a class op for a `TGS-`/`M-` course. Re-issue as the matching date op. |
| 422 | `enrolments_exist` | Destructive op on a class with learners — needs `force:true`. |
| 422 | `bookings_exist` | `remove_date` on a date with orders against it — needs `force:true`. Ask the requester first. |
| 422 | `course_not_scheduled` | Course has no date list yet (not on a schedule template). |
| 422 | `ambiguous_date_shape` | The days taught can't be determined. Relay and stop; don't retry. |
| 422 | `orphaned_class` | The class's course no longer exists. Nothing to do. |
| 422 | `trainer_email_required` | New trainer has no account/email — pass `trainer_email`. |
| 422 | `trainer_account_exists` | Email belongs to a non-trainer account. An admin must grant the role first. |
| 501 | `not_implemented` | Sub-op deliberately not built. Don't retry. |
| 503 | `api_disabled` | Server key not configured. |
| 500 | `internal_error` | Server error. Report it; don't spam retries. |

---

# 5. Endpoints

## 5.1 `POST /agent/api_classes` — edit ONE course's schedule

Add / change / remove individual **classes** (scheduled runs) of a single course, and assign
trainers. Keeps the learner-facing "Course Date" dropdown and the internal class record in sync.

> **Route name:** it's `api_classes`, **not** `api_schedule` — `/courses/api_schedule` is the
> separate read-only WSQ feed.

**Ops:** `add_class`, `update_class`, `remove_class`, `assign_trainer`, `add_date`, `update_date`,
`remove_date`.

### Before anything else: get the course code and the date

**Never infer which course someone means.** Course titles overlap heavily — there are four WSQ
Excel courses and several "Excel" non-WSQ ones — and a date added to the wrong course goes live
on that course's page where customers can book it. The server enforces this rather than trusting
you to be careful:

| You send | Result |
|---|---|
| no `course_sku` | `400 course_ref_required` — ask for the code |
| `"the Excel course"` / `"Excel"` | `400 course_ref_required` — that is a name, not a code |
| `"TGS-9999999"` (well-formed, unknown) | `404 not_found` — check it, don't try variations |
| no `start_date`, or `"next Tuesday"` | `400 validation_error` — get the exact date |
| `class_id: "the notion one"` | `400 class_ref_required` — class ids look like `C000123` |

So the two questions to have answered **before** you call anything:

1. **Which course?** A code: `C1234`, or `TGS-2021003160` for WSQ.
2. **Which date?** An exact calendar date, not "next month" or "the usual slot".

If the requester gives a name, ask for the code. Do not search the catalogue and pick the closest
match, and do not offer a shortlist and let them pick blind — a code that is nearly right belongs
to a real, different course.

### Two families of op — the course code decides which you use

This is the single most important thing on this endpoint. **Every course is reachable by exactly
one family**, and using the wrong one is refused, never guessed.

| Course code | Use | Because |
|---|---|---|
| **`C…`** (e.g. `C520`, `C6`) — non-WSQ, unfunded | `add_class`, `update_class`, `remove_class`, `assign_trainer` | These courses keep a **class record**: the trainer, the roster and the certificates all hang off it. You address a class by its `class_id`. |
| **`TGS-…`** (WSQ) and **`M…`** (partner) | `add_date`, `update_date`, `remove_date` | These courses keep **no class records at all** — there is no `class_id` to address. The date in the customer's "Course Date" dropdown *is* the whole schedule here. |

If you pick the wrong family the server tells you plainly:
- `422 use_class_ops` — you sent a date op for a C-prefix course. Re-issue as the matching class op.
- `422 validation_error` / `422 course_not_eligible` — you sent a class op for a `TGS-`/`M-` course.
  Re-issue as the matching date op.

**Don't try to work out which family from anything other than the course code.** A brand-new
C-course has no classes yet, and it still belongs to the class ops.

**Key facts (class ops)**
- **Class identity = (course code, start date).** Two registrations for the same course + date
  are the same class. A different date is a different class.
- **`class_id`** is `C######`, assigned by the system on `add_class` commit.
- **C-prefix courses only — the server enforces this on all four class ops.** You do not need to
  check the course code yourself; if a class is not eligible the preview refuses and tells you why:
  - `422 validation_error` — `add_class` with a `TGS-` (WSQ), `M-` or other code. Use `add_date`.
  - `422 course_not_eligible` — `update_class` / `remove_class` / `assign_trainer` on a class whose
    course is not a C-prefix course. Use the matching date op instead.
  - `422 orphaned_class` — the class points at a course that no longer exists in the catalog, so
    its eligibility cannot be verified. Nothing to do; tell the requester and stop.
  **Why classes are C-only:** WSQ attendance, assessment and certification are regulated and are
  kept in SSG's system, not here — so this site deliberately holds no class records for them. That
  is why WSQ dates are edited with the date ops instead.

- **The customer-facing date label is worked out from the course's schedule template**, so you do
  not have to reason about it. The template says whether a class is a run of consecutive days
  (`2-4 Oct 2027 (Sat-Mon)`) or separate days (`2/4 Oct 2027 (Sat/Mon)`), and the label is only
  accepted when its first and last dates match the dates you sent. Send `start_date` and
  `end_date`; the label takes care of itself.
- Two refusals can come back when the shape cannot be established:
  - **`422 ambiguous_date_shape`** — no template accounts for those dates, and they span more than
    one month without being consecutive, so any label would imply days that may not be taught.
    Relay it and ask the requester to add the class through the admin schedule, where the exact
    days can be set.
  - **`422 ambiguous_template`** — the course is attached to more than one schedule template, so
    its shape is undecidable. An admin needs to resolve the templates first.
  Don't retry these with different dates to get past them — the refusal means the system genuinely
  cannot tell which days are taught, and a wrong date reaches real learners.
- Dates `YYYY-MM-DD`; times `HH:MM` (24h); mode `Physical Classroom` | `Virtual`; vacancy
  `A` (available) | `L` (limited) | `F` (full).
- **Anything you add or edit here is durable** — a later template roll-out (`api_template`)
  will never remove or overwrite it.

### op: add_class
Fields: `course_sku` (req), `start_date` (req), `end_date?` (defaults to start), `start_time?`,
`end_time?`, `mode?`, `venue?`, `vacancy?`.

**Use case — "Add a Python class on 15 Aug"**
> User (Sylvia): "Add a class for C520 on 15 August, physical."
1. Preview `add_class { course_sku:"C520", start_date:"2026-08-15", mode:"Physical Classroom" }`.
2. Server: `human_summary: "A new class for 'C Programming Essential Training' (C520) will be
   added on 15 Aug 2026 (Fri), Physical Classroom. A new class id is assigned on
   confirm."` → relay, get "yes".
3. Commit → `{ applied:true, target:"C000123" }`. Tell Sylvia the new class id.

**Edge cases**
- **Unscheduled course → confirm first, then either path.** If the course has no schedule yet
  (no "Course Date" list), don't just force one — **ask the user**: "This course isn't on a
  schedule yet. Do you want to (a) put it on a recurring template, or (b) just add this one
  date?"
  - **(a) recurring** → `api_template assign_course { template, course_sku }` (it inherits the
    template's dates and stays in sync).
  - **(b) one-off** → `add_class` will **bootstrap** the course automatically — but you must
    include `start_time` + `end_time` (there's no template to inherit a time from). Without them
    you get **`422 course_not_scheduled`** asking for the times. The bootstrapped date is durable
    and tied to no template.
- **`409 conflict`** — a class already exists for that course+date. Nothing to do.
- `add_class` does **not** set a trainer — follow with `assign_trainer`.
- A newly added class starts with an **empty roster**. Learner enrolments are materialised from
  actual orders by a backend job (~1 min after a booking), not by this call.

### op: update_class
Fields: `class_id` (req) + any of `start_date`, `end_date`, `start_time`, `end_time`, `mode`,
`venue`, `vacancy`. Send only what changes.

**Edge cases**
- Changing the **date** re-labels the bookable date and takes ownership of it (stays durable).
- If learners are enrolled and you change the date, `warnings` gives the count — they are **not**
  auto-notified; tell the user they'll need to message learners separately.
- To change the trainer, use `assign_trainer` (not `update_class`).

### op: remove_class
Fields: `class_id` (req), `force?`.

**Edge cases**
- On a class with enrolled learners you get **`422 enrolments_exist`** unless you pass
  `force:true`. The preview warns with the count first. Learners are not auto-notified.
- Removing a date that came from a **template** won't stop a future template roll-out from
  re-generating it. Removing a hand-added (admin-managed) date is permanent. If the user wants a
  template date gone for good, that's a template change, not a per-course removal.

### op: assign_trainer
Fields: `class_id` (req), `trainer` (req — name or email), `trainer_email?`.

**Use case — "Put Dr Tan on class C000123"**
1. Preview `assign_trainer { class_id:"C000123", trainer:"Dr Tan" }`.
2. If exactly one "Dr Tan" exists → summary `"...trainer: (none) -> Dr Tan."` → confirm → commit.

**Edge cases**
- **`409 ambiguous_trainer`** — more than one trainer account has that **exact** full name. Matching
  is exact, not partial, so a bare surname (e.g. "Tan") won't match many — it matches *none* and
  returns `trainer_email_required` instead. Re-issue with their email: `trainer:"tan@example.com"`.
- **`422 trainer_email_required`** — no trainer account matches (by exact name or email) and no email
  was supplied. Ask the user for the trainer's email and pass it as `trainer_email`.
- Assigning someone brand-new **creates an inactive trainer account** (they can't log in until an
  admin enables it) — the preview `warnings` say so; relay that.
- **`422 trainer_account_exists`** — the email belongs to someone who **already has an MMS account
  but is not set up as a trainer** (e.g. an Admin or Marketing user). This is refused, by design:
  granting the trainer role would also rewrite that account's permission group and silently change
  what that person can access. **Relay the message and stop** — an admin must add the trainer role
  in Role Management first, then you can assign the class. Do not try another spelling of their
  name or a different email to get around it.
- **This op never modifies an account that already exists.** That is the one sentence to remember.
  Someone who is already a trainer is simply assigned (no account change at all). Someone brand new
  gets an account created. Anyone in between is handed to a human.
- It is still the only op here that can **create a user account**, so when you are unsure of a
  trainer's identity, ask for their email rather than guessing from a partial name.
- If an existing trainer's **login is disabled**, the preview warns you. The assignment still
  applies — they just cannot sign in to see the class until an admin enables their account.

---

### The date ops — `TGS-` (WSQ) and `M-` (partner) courses

These three edit the **customer-facing "Course Date" dropdown and nothing else**. That dropdown is
the entire schedule for these courses, so adding a date here is what puts a class on sale, and
removing one is what takes it off sale.

You address a date **by the date**, not by a `class_id` — these courses have none.

**The SkillsFuture step — read this before you use them**

Every WSQ change comes back with this warning:

> *This is a WSQ course. The website date is added/changed/removed, but the matching SkillsFuture
> (SSG) course run is NOT — that is a separate step and has not been done.*

**Always relay it, then stop.** Creating the SSG course run is a **different capability and a human
decision** — do not chain to it, and do not imply it has happened. Say plainly what was done and
what is still outstanding, for example:

> *"Done — 18/19 Nov 2026 is now bookable on the website. This is a WSQ course, so it also needs a
> course run creating for SkillsFuture. That hasn't been done — would you like me to arrange that
> next?"*

This matters: a check of the schedule found **165 website dates with no SkillsFuture run behind
them**, every one of them a website date someone added and never followed up. Saying it out loud is
what stops the next one.

**Identifying an existing date**

Give `start_date` on its own — the server finds the one date that starts then. Only if it returns
**`409 ambiguous_date`** (the course has both a single-day and a multi-day date starting that day,
and it lists them) do you re-issue with `end_date` to say which. It will never pick one for you.

**Labels** work exactly as for the class ops: the schedule template decides the shape, and
`422 ambiguous_date_shape` / `422 ambiguous_template` mean the system genuinely cannot tell which
days are taught. Relay and stop; don't retry with different dates.

### op: add_date
Fields: `course_sku` (req), `start_date` (req), `end_date?` (defaults to start), `start_time?`,
`end_time?`.

**Use case — "Add 18 & 19 Nov to the Statistical Data Analysis course, evening class"**
1. Preview `add_date { course_sku:"TGS-2020505317", start_date:"2026-11-18", end_date:"2026-11-19" }`.
2. Show the exact label from the diff — e.g. `18/19 Nov 2026 Evening (Wed/Thu)` — and the
   SkillsFuture warning. Get a yes.
3. Commit. Then tell them the SSG run is still outstanding.

**Edge cases**
- **`409 conflict`** — that date is already on the website. Nothing to do.
- **`422 course_not_scheduled`** — the course has no date list at all yet. Re-issue with
  `start_time` + `end_time` and it will set the schedule up with this first date. Ask the user for
  the times rather than inventing them.
- **`400 validation_error`** — `end_date` is before `start_date`.

### op: update_date
Fields: `course_sku` (req), `start_date` (req — the date **as it is now**), `end_date?` (only to
disambiguate), `new_start_date` (req), `new_end_date?`.

**Use case — "Move the 18 Nov WSQ Excel class to 2 Dec"**
1. Preview `update_date { course_sku:"TGS-2020505317", start_date:"2026-11-18", new_start_date:"2026-12-02" }`.
2. The diff shows the old label and the new one. Show **both**, plus any booking count.
3. Confirm → commit → relay the SkillsFuture step.

**Edge cases**
- **`404 not_found`** — no date starts on that day. Check the date with the requester.
- **`409 conflict`** — the course already offers the date you're moving onto.
- If people have already **booked** the date, the preview warns with the count. They are **not**
  notified automatically — tell the requester they need to contact them.

### op: remove_date
Fields: `course_sku` (req), `start_date` (req), `end_date?` (only to disambiguate), `force?`.

Takes the date off the website so nobody else can book it.

**Edge cases**
- **`422 bookings_exist`** — orders already exist for that date. The message says how many.
  **Relay the number and ask before re-issuing with `force: true`.** Removing the date does **not**
  cancel or refund anything, and nobody is told — those orders still exist and still need handling
  by a person. Never pass `force` on your own initiative.
- **`404 not_found`** — no date starts on that day.

---

## 5.2 `POST /agent/api_course` — update course info

One op, `update`. Change whitelisted product fields on one course.

Fields: `sku` (req), `fields` (req — a map of `field -> value`, at least one).
**Allowed fields:** `description`, `short_description`, `price`, `special_price`, `meta_title`,
`meta_description`, `status` (`enabled`/`disabled`), `url_key`.

**Use case — "Bump C472 to S$780 and fix its meta title"**
Preview `update { sku:"C472", fields:{ price:780, meta_title:"SC-900 Exam Prep | Tertiary Courses" } }`
→ diff shows both fields → confirm → commit.

**Edge cases**
- **`422 forbidden_field`** — `name`, `sku`, and every GST / tax / funding field are blocked.
  The course **name is sacred**; GST is computed on the list price by deliberate design. If a
  user wants the name changed, that's a human/admin task — tell them you can't.
- **`400 validation_error`** — if the supplied values already match (nothing to change).
- **Categories aren't editable via the agent** — `category_ids` is blocked (`422 forbidden_field`).
  If a user asks to change which categories/listings a course appears in, that's a staff/admin
  task; tell them you can't do it.
- `price` is the list price. Don't try to encode a subsidy/discount here — funding is handled by
  the checkout, not the catalog price.

---

## 5.3 `POST /agent/api_content` — marketing / content

**Ops:** `update_copy`, `set_badges`. (`set_cms_section` → `501 not_implemented`.)

- **`update_copy`** — `sku` + `fields{}` from `description`, `short_description`, `meta_title`,
  `meta_description`. HTML is allowed in the descriptions. (Same underlying fields as
  `api_course`, framed for content edits.)
- **`set_badges`** — `sku` + `badges[]` from the **nine canonical names**: `WSQ`,
  `SkillsFuture Credit`, `PSEA`, `UTAP`, `IBF`, `HRDF`, `SFEC`, `Absentee Payroll`, `MCES`. An
  unknown badge → `400`. This **replaces** the course's badge set.

**Use case — "This course is now WSQ + SkillsFuture funded"**
1. `set_badges { sku:"C472", badges:["WSQ","SkillsFuture Credit"] }` → preview → confirm → commit.
2. **Then** `api_ops regenerate_image { sku:"C472" }` so the cover PNG shows the new chips.

**Edge cases**
- `set_badges` updates the storefront **chips** (tags) but **not** the cover image — you must run
  `regenerate_image` afterward or the cover and chips disagree. Always chain the two.
- Badges are stored as tags shared across the catalog; on this one-store-per-site model that's
  fine, but only send funding badges that actually apply to this country.

---

## 5.4 `POST /agent/api_ops` — website / MMS operations

**Ops:** `reindex`, `flush_cache`, `enable`, `disable`, `regenerate_image`.
(`run_class_formation` → `501 not_implemented` — class formation runs on a 1-minute cron.)

- **`enable` / `disable`** — `{ sku }`. Show/hide the course on the storefront.
- **`regenerate_image`** — `{ sku }`. Re-render the AI cover from the course's **current** badges
  and publish it to the storefront + R2, syncing the chips.
- **`reindex`** — `{ indexes: [...] | "all" }`. Whitelisted indexers. Heavy; the preview warns.
- **`flush_cache`** — clears Magento caches.

**Use case — "The new price / image isn't showing on the site"**
Usually a stale index/cache. `reindex { indexes:["catalog_product_flat","catalog_product_price"] }`
or `flush_cache`, confirm (warn it's briefly slower), commit.

**Edge cases**
- `regenerate_image` reads the course's **current** badges — so run `set_badges` **first** if the
  funding changed. On a non-funding-eligible country the cover renders **without** chips (the
  preview warns).
- Each `regenerate_image` produces a brand-new image file; it's a "regenerate", not idempotent —
  don't loop it.
- `reindex "all"` / `flush_cache` briefly slow the site while caches warm — tell the user.

---

## 5.5 `POST /agent/api_template` — bulk schedule + join a template

Two ops: **`generate_and_apply`** (add dates to a template and roll them out to EVERY course on
it) and **`assign_course`** (put one course onto a template). For a one-off date on a single
course, use `api_classes add_class`.

### op: generate_and_apply

Use it **only** when the user explicitly wants to add dates to a shared template and roll them out
to **every course** on that template. Fields: `template` (req — loose reference), `start_date`
(req), `end_date` (req), `slot_code?` (override).

**How it works:** it resolves the template, generates class dates for the template's **slot code**
(`A01`–`E04`, which encodes the weekday / week-of-month pattern) over `[start_date, end_date]`,
**appends** the new dates to the template, and applies the template to **every** course using it.
You do **not** specify weekdays/intervals — the slot code already defines them; you only give the
template and the date range.

**Use case — "Roll out Q1 2027 dates for the WSQ B01 schedule"**
1. Preview `generate_and_apply { template:"WSQ B01", start_date:"2027-01-01", end_date:"2027-03-31" }`.
2. Server: `human_summary: "Add 6 new class date(s) to template '(SG) WSQ-B01 ...' (slot B01) and
   apply to ALL 27 course(s) using it: ..."`, plus warnings `["This applies to ALL 27 course(s)
   ...", "Append-only ..."]`.
3. **Relay the "ALL 27 courses" warning explicitly** and get a clear "yes".
4. Commit → `{ applied:true, dates_added:6, already_present:0, products_applied:27 }`.

**Edge cases**
- **`409 ambiguous_template`** — a bare code like `A01` matches both `"A01 ..."` and
  `"(SG) WSQ-A01 ..."`. The error lists the candidates; re-issue with a distinguishing word,
  e.g. `template:"WSQ A01"` or `template:"SG A01"`.
- **`404 not_found`** — no template matches. Ask the user for the slot code (A01–E04) or part of
  the template name.
- **It touches every course on the template** — never fire it for a "just add one date" request;
  that's `add_class`.
- **Append-only + safe:** existing template dates are kept, and any date an admin/agent added to a
  single course by hand is never removed. Re-running the same range → `dates_added:0`
  (`"all ... already in the template"`).
- If the template name has no A01–E04 code, pass `slot_code` explicitly (rare).
- It reindexes prices for all affected products — a big template is a heavy operation; set the
  user's expectation.

### op: assign_course

Add ONE course to a template — it gains that template's current schedule and stays in sync with
future roll-outs. This is how a course *joins* a recurring schedule (e.g. a brand-new or
never-scheduled course). Fields: `template` (req), `course_sku` (req).

**Use case — "Put C520 on the WSQ B01 schedule"**
1. Preview `assign_course { template:"WSQ B01", course_sku:"C520" }`.
2. Server: `human_summary: "Course '...' (C520) will be added to template '(SG) WSQ-B01 ...' and
   receive its 34 scheduled class date(s). It then stays in sync with future roll-outs."` → confirm.
3. Commit → the course now has those 34 dates and is a template member.

**Edge cases**
- **`409 conflict`** — the course is already on that template.
- If the course **already had its own schedule**, the preview warns: the template's dates are
  merged in and any hand-added (admin-managed) date is kept.
- This is the "recurring" answer to the *"schedule this unscheduled course"* question — the
  one-off answer is `api_classes add_class` (with times).

---

# 6. Recipes (multi-step scenarios)

**A. Add a class and put a trainer on it**
1. `api_classes add_class { course_sku, start_date, mode }` → commit → note the new `class_id`.
2. `api_classes assign_trainer { class_id, trainer }` → commit.

**B. Rebrand a course's funding and fix the cover**
1. `api_content set_badges { sku, badges:[...] }` → commit.
2. `api_ops regenerate_image { sku }` → commit. (Order matters — badges first, image second.)

**C. Publish a course that was hidden, and make sure it shows**
1. `api_ops enable { sku }` → commit.
2. If it still doesn't appear: `api_ops reindex { indexes:["catalog_product_flat"] }` +
   `flush_cache`.

**D. Roll out next quarter's schedule across a whole template**
1. `api_template generate_and_apply { template, start_date, end_date }` — preview, **relay the
   "ALL N courses" count**, confirm, commit.
2. For any one-off extra date on a single course afterwards, use `api_classes add_class` (durable;
   the next template roll-out won't wipe it).

**E. Schedule a course that has no schedule yet** — **ask first**, then branch:
> "This course isn't on a schedule yet. Put it on a recurring template, or just add this one date?"
- **Recurring** → `api_template assign_course { template, course_sku }` (inherits the template's
  dates; stays in sync).
- **One-off** → `api_classes add_class { course_sku, start_date, start_time, end_time, mode }`
  (bootstraps the course; durable; not on any template).

---

# 7. Domain reminders (so you reason correctly)

- **A product is a course; a class is a course on a specific date; a registration is an order.**
  You schedule classes and edit courses; you never touch orders/checkout.
- **Rosters come from orders, not from you.** `add_class` creates the class and its bookable date;
  learners appear on the roster only after they actually book (a backend job materialises this ~1
  min after each order). So a freshly added class legitimately has zero learners.
- **One store per site.** You act on one country. Funding schemes differ by country — only apply
  badges/funding that fit the site you're on.
- **WSQ vs non-WSQ.** WSQ courses have `TGS-` SKUs (the SKU is the SkillsFuture reference);
  non-WSQ SG courses start with `C`; other countries start with `M`. Some schedule internals skip
  `TGS-` (they're driven by an external system) — if a schedule op behaves oddly on a `TGS-`
  course, say so rather than forcing it.
- **Durability model.** Dates you add/edit via `api_classes` are "admin-managed" and survive
  template roll-outs. Template roll-outs (`api_template`) only manage their own generated dates.
- **Sacred / off-limits:** course `name`, `sku`, and GST/tax/funding math. Refusals here are by
  design.

---

# 8. Quick reference

| Endpoint | Ops | One-liner |
|---|---|---|
| `POST /agent/api_classes` | **C- courses:** add_class, update_class, remove_class, assign_trainer<br>**TGS-/M- courses:** add_date, update_date, remove_date | One course's schedule. The course code picks the family — a date op on a C-course returns `use_class_ops`, a class op on a TGS-course returns `course_not_eligible`. Every WSQ change warns that the SkillsFuture run is still outstanding: relay it and stop. |
| `POST /agent/api_course` | update | Whitelisted course fields (name/sku/GST blocked) |
| `POST /agent/api_content` | update_copy, set_badges | Copy + funding chips (`set_cms_section` = 501) |
| `POST /agent/api_ops` | reindex, flush_cache, enable, disable, regenerate_image | Ops + cover render (`run_class_formation` = 501) |
| `POST /agent/api_template` | generate_and_apply, assign_course | Bulk schedule to ALL products on a template; or add one course to a template |

Every one: `dry_run:true` to preview, relay `human_summary` + `warnings`, `dry_run:false` +
`change_token` to commit.
