# MMS Agent API Spec

**Audience:** the OpenClaw agent. Read [`agent-context.md`](agent-context.md) first - it
explains the domain (courses, classes, funding, invariants). This document is the **callable
contract**: how to authenticate, the preview->confirm->commit protocol every write follows, the
request/response envelopes, and a detailed spec per endpoint.

> Status: all five endpoints below are **built and live** - `api_classes`, `api_course`,
> `api_content`, `api_ops`, `api_template`. A few sub-ops are intentionally not implemented and
> say so explicitly (`api_content set_cms_section`, `api_ops run_class_formation`).

---

## 1. Base URL & scope

Each partner site is a separate deployment serving one store. Call the site you were told to
manage. Singapore:

```
https://www.tertiarycourses.com.sg
```

All endpoints below are **`POST`**, `Content-Type: application/json`, and return JSON. Scope is
that site's single store (SG = store 1).

## 2. Authentication

Send the shared external API key as a header (the same key you already use for the read
endpoints such as `GET /courses/api_schedule`):

```
X-API-Key: <secret>
```

- Missing/blank server-side key -> `503 api_disabled`.
- Wrong key -> `401 unauthorized`.

The key identifies **you (the agent)** as a trusted caller. It does **not** identify the human
who asked - that is the `actor` field (below), which you must always supply.

## 3. The write protocol: preview -> confirm -> commit

**Every write is a two-call sequence.** Never commit a change the user hasn't seen and approved.

```
1. PREVIEW   POST ... { "dry_run": true,  "op": ..., "actor": ..., <fields> }
             <- { diff, human_summary, change_token, warnings }

2. (in chat) Show human_summary + warnings to the requester. Get explicit "yes".

3. COMMIT    POST ... { "dry_run": false, "op": ..., "actor": ..., <same fields>,
                      "change_token": "<from step 1>" }
             <- { applied: true, ... , audit_id }
```

- `change_token` binds the commit to exactly what was previewed. On commit the server
  recomputes it from live data; if the underlying data changed in between, you get
  `409 stale_preview` - re-preview, re-confirm, retry.
- If you commit **without** a `change_token`, you get `400 change_token_required`.
- Always relay `human_summary` **and every line in `warnings[]`** to the user before confirming.
  Some ops (notably `api_template`) act on many courses at once and say so in a warning.

## 4. Common request envelope

Every request includes:

| Field | Type | Required | Notes |
|---|---|---|---|
| `op` | string | yes | The operation (per endpoint) |
| `actor` | object | yes | Who asked - see below |
| `dry_run` | bool | no | `true` = preview; omit/`false` = commit |
| `change_token` | string | on commit | The token returned by the matching preview |
| ...op fields... | - | - | Per operation |

### `actor` (required on every call)

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes | The requester's **WhatsApp number** in E.164, prefixed `wa:` (e.g. `wa:+6591234567`). This is the canonical identity + audit key. |
| `name` | string | yes | The person's name (how you refer to them) |
| `role` | string | no | Defaults to `user`. If you distinguish the requester's role, send one of: `user`, `learner`, `trainer`, `developer`, `marketing`, `admin`, `training_provider`. An unknown value is rejected (`400`). |

```json
{ "id": "wa:+6591234567", "name": "Sylvia", "role": "user" }
```

**On `role`:** until you distinguish requesters by role, send `user` (or omit it) - that is the
universal default and is honest for both staff and customers on the shared whitelist. Once you
assign specific roles, send the matching one (it needs no backend change). The server records
`actor` in the audit log but does **not** re-check authorization - vetting the requester is
**your** responsibility before you ever call.

## 5. Standard responses

### Preview (dry_run) - `200`
```json
{
  "success": true,
  "dry_run": true,
  "op": "update_class",
  "target": "SG000042",
  "diff": [ { "field": "course_start_date", "from": "2026-06-06", "to": "2026-06-13" } ],
  "human_summary": "Class SG000042 (Data Analytics with RapidMiner): start_date 2026-06-06 -> 2026-06-13.",
  "warnings": ["3 learner(s) are enrolled on this class; they will NOT be auto-notified of the date change."],
  "change_token": "sha256:9f2c..."
}
```

### Commit - `200`
```json
{ "success": true, "applied": true, "op": "update_class", "target": "SG000042",
  "audit_id": 1187, "reindexed": ["option_value"] }
```

### Error
```json
{ "success": false, "error": "<code>", "message": "<human-readable>" }
```

| HTTP | `error` | Meaning |
|---|---|---|
| 400 | `validation_error` | Missing/invalid field, or nothing to change |
| 400 | `change_token_required` | Commit without a token |
| 401 | `unauthorized` | Bad/missing `X-API-Key` |
| 404 | `not_found` | Unknown `sku` / `class_id` / template |
| 409 | `stale_preview` | Data changed since preview - re-preview |
| 409 | `conflict` | e.g. a class already exists for that date |
| 409 | `ambiguous_trainer` | Trainer name matches more than one person - use email |
| 409 | `ambiguous_template` | Template reference matches more than one template - be more specific |
| 422 | `forbidden_field` | Attempt to change a blocked field (name/sku/GST) |
| 422 | `enrolments_exist` | Destructive op on a class with learners, without `force` |
| 422 | `course_not_scheduled` | Course has no date list yet (not on a schedule template) |
| 422 | `trainer_email_required` | New trainer has no account/email on file - pass `trainer_email` |
| 501 | `not_implemented` | Sub-op deliberately not built yet |
| 503 | `api_disabled` | Server API key not configured |
| 500 | `internal_error` | Server error |

## 6. Reindexing

Writes that change course options or attributes trigger the needed storefront re-index; the
commit response lists what ran in `reindexed[]`. You don't manage this - but if a change "isn't
showing on the site," an `api_ops reindex` (or `flush_cache`) is the remedy.

---

# Endpoint: `POST /agent/api_classes` - edit course schedule (per course)

Add, change, or remove **individual classes** (scheduled runs) of ONE course, and assign
trainers. Keeps the learner-facing "Course Date" option and the internal class record in sync,
and re-indexes. (Named `api_classes`, not `api_schedule`, to avoid confusion with the read-only
WSQ feed at `GET /courses/api_schedule`.)

`op` is one of: `add_class`, `update_class`, `remove_class`, `assign_trainer`.

> **There is no bulk "generate a range" op here.** To add several dates to one course, call
> `add_class` once per date. To roll out a whole schedule across MANY courses at once, use
> `api_template` (below). Every date you add/edit here is **admin-managed** and durable: a later
> template roll-out will never remove or overwrite it.

### Shared behaviour
- **Class identity = (course code, start date).** You never create two classes for the same
  course + start date; `add_class` on an existing date returns `409 conflict`.
- **`class_id`** is `SG######`, assigned by the system. For `add_class` the exact id is assigned
  **on commit**; for the other ops you reference an existing `class_id`.
- **Dates** are `YYYY-MM-DD`. **Times** are `HH:MM` 24h. **Mode** is `Physical Classroom` or
  `Virtual`. **Vacancy** is `A` (available) | `L` (limited) | `F` (full).
- **Enrolment safety:** if a class has enrolled learners, `update_class` (date change) and
  `remove_class` include the enrolment count in `warnings`; `remove_class` additionally requires
  `force: true`. v1 does **not** notify learners - tell the requester the count.
- **Unscheduled courses:** if a course has no "Course Date" list yet, `add_class` will
  **bootstrap** one — but only if you supply `start_time` + `end_time` (there's no template to
  inherit a time from). Without them it returns `422 course_not_scheduled`. The bootstrapped date
  is a one-off (not on any template). Prefer asking the user first: "put it on a recurring
  template (`api_template assign_course`), or just add this one date?"

### `op: add_class`
| Field | Type | Required | Notes |
|---|---|---|---|
| `course_sku` | string | yes | Existing course code |
| `start_date` | string | yes | `YYYY-MM-DD` |
| `end_date` | string | no | defaults to `start_date` (single day) |
| `start_time`, `end_time` | string | no | `HH:MM` |
| `mode` | string | no | `Physical Classroom` \| `Virtual` (default Physical) |
| `venue` | string | no | - |
| `vacancy` | string | no | `A`\|`L`\|`F` (default `A`) |
| `start_time`, `end_time` | string | conditionally | Normally optional, but **required** when bootstrapping a not-yet-scheduled course (see above). |

To set the trainer, follow with `assign_trainer` (add_class does not take a trainer).

```json
POST /agent/api_classes
{ "op":"add_class", "dry_run":true,
  "actor":{"id":"wa:+6591234567","name":"Sylvia","role":"marketing"},
  "course_sku":"C520", "start_date":"2026-08-15", "mode":"Physical Classroom" }
```
Commit returns the new `class_id` in `target`.

### `op: update_class`
| Field | Type | Required | Notes |
|---|---|---|---|
| `class_id` | string | yes | `SG######` |
| `start_date`, `end_date` | string | no | changing the date warns if enrolments exist |
| `start_time`, `end_time` | string | no | - |
| `mode` | string | no | `Physical Classroom` \| `Virtual` |
| `venue` | string | no | - |
| `vacancy` | string | no | `A`\|`L`\|`F` |

Provide only the fields you want to change. Changing the date re-labels the learner-facing
"Course Date" and marks it admin-managed (durable). To change the trainer, use `assign_trainer`.

### `op: remove_class`
| Field | Type | Required | Notes |
|---|---|---|---|
| `class_id` | string | yes | `SG######` |
| `force` | bool | conditionally | must be `true` to remove a class that has enrolled learners |

Without `force` on a class with learners -> `422 enrolments_exist` (the preview `warnings` tells
you the count first). v1 does not notify enrolled learners.

### `op: assign_trainer`
| Field | Type | Required | Notes |
|---|---|---|---|
| `class_id` | string | yes | `SG######` |
| `trainer` | string | yes | Trainer name **or** email. |
| `trainer_email` | string | conditionally | Required when assigning a brand-new trainer (no account, no email on file). |

- If the name matches several trainers -> `409 ambiguous_trainer` (re-issue with the email).
- Assigning someone with no MMS account creates an **inactive** trainer account (login disabled
  until an admin enables it); the preview `warnings` say so.

---

# Endpoint: `POST /agent/api_course` - update course info

`op: update`. Change whitelisted product fields on one course.

| Field | Type | Required | Notes |
|---|---|---|---|
| `sku` | string | yes | Course code |
| `fields` | object | yes | Map of `field -> value`, at least one |

**Allowed fields:** `description`, `short_description`, `price`, `special_price`, `meta_title`,
`meta_description`, `status` (`enabled`/`disabled`), `url_key`, `category_ids` (array of category
ids).
**Hard-blocked** (`422 forbidden_field`): `name`, `sku`, and all GST / tax / funding fields - the
course name is sacred and funding math is deliberate.

```json
{ "op":"update", "dry_run":true, "actor":{...},
  "sku":"C472", "fields":{ "price": 780, "meta_title": "SC-900 Exam Prep | Tertiary Courses" } }
```
Preview returns a `diff` of each changed field (`from`/`to`); unchanged supplied values are
ignored, and if nothing actually changes you get `400 validation_error`.

---

# Endpoint: `POST /agent/api_content` - marketing / content

| `op` | Fields | Notes |
|---|---|---|
| `update_copy` | `sku`, `fields{}` from `description`, `short_description`, `meta_title`, `meta_description` | Same as `api_course` copy fields, framed for content authors. |
| `set_badges` | `sku`, `badges: []` | Sets funding badges from the canonical nine (see `agent-context.md`). Written as tags so storefront chips match. **After this, run `api_ops regenerate_image`** to refresh the cover to match. |
| `set_cms_section` | - | **`501 not_implemented`** - per-course CMS sections aren't wired yet. |

Product reviews are created via the separate existing review API (`POST /kael_review_api.php`),
not here.

```json
{ "op":"set_badges", "dry_run":true, "actor":{...},
  "sku":"C472", "badges":["WSQ","SkillsFuture Credit"] }
```

---

# Endpoint: `POST /agent/api_ops` - website / MMS operations

| `op` | Fields | Notes |
|---|---|---|
| `reindex` | `indexes: [] \| "all"` | Whitelisted indexers (`catalog_product_flat`, `catalog_product_price`, `catalog_url`, `catalog_category_product`, `catalogsearch_fulltext`, `tag_summary`, ...). Resource-intensive - the preview warns. |
| `flush_cache` | - | Flush all Magento caches. |
| `enable` | `sku` | Show the course on the storefront. |
| `disable` | `sku` | Hide the course from the storefront. |
| `regenerate_image` | `sku` | Re-render the AI cover from the course's **current** funding badges, publish it to storefront + R2, and sync badge chips. Use right after `api_content set_badges`. On a non-funding-eligible site the cover renders without badges (the preview warns). |
| `run_class_formation` | - | **`501 not_implemented`** - class formation is cron-driven (runs every minute); not exposed. |

```json
{ "op":"regenerate_image", "dry_run":true, "actor":{...}, "sku":"C472" }
```

---

# Endpoint: `POST /agent/api_template` - bulk schedule across ALL products

Bulk / all-products scheduling, plus assigning a course to a template. Use `generate_and_apply`
**only** when the user explicitly wants to add dates to a shared template and roll them out to
**every course** on it. Use `assign_course` to put one course onto a template. For a one-off date
on a single course, use `api_classes add_class` instead.

**Ops:** `generate_and_apply`, `assign_course`.

## op: generate_and_apply

| Field | Type | Required | Notes |
|---|---|---|---|
| `template` | string | yes | A loose reference to the template - a slot code (`A01`-`E04`), or code + words (`"WSQ A01"`, `"SG B01"`), or part of the template name. |
| `start_date` | string | yes | `YYYY-MM-DD` |
| `end_date` | string | yes | `YYYY-MM-DD`; must be >= `start_date` |
| `slot_code` | string | no | Override the slot code if the template name doesn't contain one. Normally derived from the template. |

**How it works:** it resolves the template, generates class dates for the template's slot code
over `[start_date, end_date]` (the academy's standard schedule logic), **appends** the new dates
to the template (never removes or rewrites existing ones), and applies the template to **every**
course using it.

**Resolution & disambiguation:** a bare code is often ambiguous (e.g. `A01` matches both
`"A01 ..."` and `"(SG) WSQ-A01 ..."`) -> `409 ambiguous_template`, whose message lists the
candidates; re-issue with a distinguishing word (`"WSQ A01"`). No match -> `404 not_found`.

**Safety:** append-only. Existing template dates are kept, and any date an admin added to a
single course by hand (via `api_classes` or the admin UI) is **never** touched. The preview's
`warnings` always state **how many courses** this will affect - relay that to the user before
confirming.

**Preview**
```json
POST /agent/api_template
{ "op":"generate_and_apply", "dry_run":true, "actor":{...},
  "template":"WSQ B01", "start_date":"2027-01-01", "end_date":"2027-03-31" }
```
```json
{ "success":true, "dry_run":true, "op":"generate_and_apply",
  "target":"(SG) WSQ-B01 Mon-Tues/Sat-Sun 1st wk",
  "diff":[{"field":"template_dates","from":null,"to":["4/5 Jan 2027 (Mon/Tue)", "..."]}],
  "human_summary":"Add 6 new class date(s) to template \"(SG) WSQ-B01 ...\" (slot B01) and apply to ALL 27 course(s) using it: ...",
  "warnings":[
    "This applies to ALL 27 course(s) assigned to this template, not just one course.",
    "Append-only: existing template dates are kept, and any date an admin added to a single course by hand is never removed."
  ],
  "change_token":"sha256:..." }
```
**Commit** returns `dates_added`, `already_present`, and `products_applied`.

## op: assign_course

Add ONE course to a template and apply the template's current schedule to it — the course gains
that template's dates and stays in sync with future `generate_and_apply` roll-outs. This is how a
course *joins* a template (a not-yet-scheduled course, or moving one onto a recurring schedule).

| Field | Type | Required | Notes |
|---|---|---|---|
| `template` | string | yes | Same loose reference + disambiguation as above |
| `course_sku` | string | yes | The course to add |

- Already on that template → `409 conflict`.
- The preview states how many dates the course will receive and warns if it already had its own
  schedule (those hand-added dates are kept — the template's dates are merged in).

```json
POST /agent/api_template
{ "op":"assign_course", "dry_run":true, "actor":{...}, "template":"WSQ B01", "course_sku":"C520" }
```
```json
{ "success":true, "dry_run":true, "op":"assign_course", "target":"C520",
  "human_summary":"Course '...' (C520) will be added to template '(SG) WSQ-B01 ...' and receive its 34 scheduled class date(s). ...",
  "change_token":"sha256:..." }
```
