# MMS Agent API Spec

**Audience:** the OpenClaw agent. Read [`agent-context.md`](agent-context.md) first - it
explains the domain (courses, classes, funding, invariants). This document is the **callable
contract**: how to authenticate, the preview->confirm->commit protocol every write follows, the
request/response envelopes, and a detailed spec per endpoint.

> Status: **`api_schedule` is fully specified below** (the reference endpoint). The other
> three (`api_course`, `api_content`, `api_ops`) are outlined and will be filled to the same
> shape. `generate_range` is deferred pending a decision on its rule inputs.

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
  recomputes it from live data; if the course/class changed in between, you get
  `409 stale_preview` - re-preview, re-confirm, retry.
- If you commit **without** a `change_token`, you get `400 change_token_required`.
- Re-committing the same approved change (same token) is safe - it returns the original result
  rather than applying twice (idempotent).

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
| `role` | string | yes | Their assigned role (you decide authorization from this before calling) |

```json
{ "id": "wa:+6591234567", "name": "Sylvia", "role": "marketing" }
```

The server records `actor` in the audit log but does **not** re-check authorization - vetting
the requester's role is **your** responsibility before you ever call.

## 5. Standard responses

### Preview (dry_run) - `200`
```json
{
  "success": true,
  "dry_run": true,
  "op": "update_class",
  "target": "SG000042",
  "diff": [
    { "field": "course_start_date", "from": "2026-06-06", "to": "2026-06-13" }
  ],
  "human_summary": "Class SG000042 (Data Analytics with RapidMiner) will move from 6 Jun 2026 to 13 Jun 2026. Trainer and time unchanged. 3 learners are already enrolled.",
  "warnings": ["3 learners are enrolled on this class"],
  "change_token": "sha256:9f2c..."
}
```

### Commit - `200`
```json
{
  "success": true,
  "applied": true,
  "op": "update_class",
  "target": "SG000042",
  "audit_id": 1187,
  "reindexed": ["catalog_product_flat", "catalog_url"]
}
```

### Error
```json
{ "success": false, "error": "<code>", "message": "<human-readable>", "actor_echo": { "id": "wa:+6591234567" } }
```

| HTTP | `error` | Meaning |
|---|---|---|
| 400 | `validation_error` | Missing/invalid field |
| 400 | `change_token_required` | Commit without a token |
| 401 | `unauthorized` | Bad/missing `X-API-Key` |
| 404 | `not_found` | Unknown `sku` / `class_id` |
| 409 | `stale_preview` | Data changed since preview - re-preview |
| 409 | `conflict` | e.g. a class already exists for that date |
| 422 | `forbidden_field` | Attempt to change a blocked field (name/sku/GST) |
| 422 | `enrolments_exist` | Destructive op on a class with learners, without `force` |
| 503 | `api_disabled` | Server API key not configured |
| 500 | `internal_error` | Server error |

## 6. Reindexing

Writes that change course options or attributes automatically trigger the needed storefront
re-index; the commit response lists what ran in `reindexed[]`. You don't manage this - but if a
change "isn't showing on the site," a `reindex` op (`api_ops`) is the remedy.

---

# Endpoint: `POST /agent/api_schedule` - edit course schedule

Add, change, or remove **classes** (scheduled runs) of a course, and assign trainers. Keeps the
learner-facing "Course Date" option and the internal class record in sync, and re-indexes.

`op` is one of: `add_class`, `update_class`, `remove_class`, `assign_trainer`,
`generate_range` (deferred). All follow the preview->confirm->commit protocol in Sec 3.

### Shared behaviour
- **Class identity = (course code, title, start date).** You never create two classes for the
  same course + start date; `add_class` on an existing date returns `409 conflict`.
- **`class_id`** is `SG######`, assigned by the system. For `add_class` the exact id is assigned
  **on commit** (the preview says "new class, id assigned on commit"); for the other ops you
  reference an existing `class_id`.
- **Dates** are `YYYY-MM-DD`. **Times** are `HH:MM` 24h (or a label like `9:30am - 6:30pm` for
  display fields). **Mode** is `Physical Classroom` or `Virtual`.
- **Enrolment safety:** if a class has enrolled learners, `update_class` (date change) and
  `remove_class` include the enrolment count in `warnings`; `remove_class` additionally requires
  `force: true`. v1 does **not** notify learners - tell the requester the count.

---

### `op: add_class`
Add a new scheduled class to a course.

| Field | Type | Required | Notes |
|---|---|---|---|
| `course_sku` | string | yes | Existing course code |
| `start_date` | string | yes | `YYYY-MM-DD` |
| `end_date` | string | no | `YYYY-MM-DD`; defaults to `start_date` (single day) |
| `start_time` | string | no | Defaults to the course's usual time |
| `end_time` | string | no | - |
| `mode` | string | no | `Physical Classroom` \| `Virtual` |
| `venue` | string | no | - |
| `trainer` | string | no | Trainer name (or id) to assign |
| `vacancy` | string | no | `A`\|`L`\|`F`; default `A` |

**Preview**
```json
POST /agent/api_schedule
{ "op":"add_class", "dry_run":true,
  "actor":{"id":"wa:+6591234567","name":"Sylvia","role":"marketing"},
  "course_sku":"C520", "start_date":"2026-08-15", "end_date":"2026-08-15",
  "mode":"Physical Classroom", "trainer":"Dr Tan" }
```
```json
{ "success":true, "dry_run":true, "op":"add_class", "target":"C520",
  "diff":[{"field":"class","from":null,"to":"C520 @ 2026-08-15 (Physical Classroom, Dr Tan)"}],
  "human_summary":"A new class for 'C Programming Essential Training' (C520) will be added on 15 Aug 2026, Physical Classroom, trainer Dr Tan. A new SG-series class id is assigned when you confirm.",
  "warnings":[], "change_token":"sha256:..." }
```
**Commit** - resend with `"dry_run":false` + `change_token`. Response includes the new
`class_id` in `target`.

---

### `op: update_class`
Change fields of an existing class.

| Field | Type | Required | Notes |
|---|---|---|---|
| `class_id` | string | yes | `SG######` |
| `start_date`,`end_date` | string | no | Changing the date changes the class's effective identity - warns if enrolments exist |
| `start_time`,`end_time` | string | no | - |
| `mode` | string | no | `Physical Classroom` \| `Virtual` |
| `venue` | string | no | - |
| `vacancy` | string | no | `A`\|`L`\|`F` |

Provide only the fields you want to change. (To change the trainer, prefer `assign_trainer`.)
See Sec 5 for the preview/commit example.

---

### `op: remove_class`
Remove/disable a class date.

| Field | Type | Required | Notes |
|---|---|---|---|
| `class_id` | string | yes | `SG######` |
| `force` | bool | conditionally | Must be `true` to remove a class that has enrolled learners |

Without `force` on a class with learners -> `422 enrolments_exist` (the preview `warnings` tells
you the count first). v1 does not notify enrolled learners.

---

### `op: assign_trainer`
Set or replace the trainer on a class.

| Field | Type | Required | Notes |
|---|---|---|---|
| `class_id` | string | yes | `SG######` |
| `trainer` | string | yes | Trainer name (or id). Must resolve to a known trainer. |

Preview shows `{from: <old trainer>, to: <new trainer>}`.

---

### `op: generate_range` - **deferred**
Bulk-create a series of classes from a rule (e.g. every Saturday for 8 weeks). **Not yet
specified** - pending a decision on the exact rule inputs (weekday pattern, session length,
whether to skip public holidays). This mirrors the existing native date-generation logic and
will be added here once those inputs are confirmed. Until then, use repeated `add_class` calls.

---

# Endpoint: `POST /agent/api_course` - update course info *(outline)*

`op: update`, `sku`, `fields{}` from an **allowlist**: `description`, `short_description`,
`price`, `special_price`, `meta_title`, `meta_description`, `status`, `url_key`, `category_ids`.
**Hard-blocked:** `name`, `sku`, and all GST/tax/funding fields (`422 forbidden_field`). Same
preview->confirm->commit protocol. Full field table to follow.

# Endpoint: `POST /agent/api_content` - marketing / content *(outline)*

`op`: `update_copy` (description/short/meta), `set_badges` (from the nine canonical badge names
in `agent-context.md` Sec 5), `set_cms_section` (per-course content blocks). Product reviews are
created via the separate existing review API (`POST /kael_review_api.php`). Full spec to follow.

# Endpoint: `POST /agent/api_ops` - website / MMS operations *(outline)*

`op`: `reindex` (`catalog_url`|`catalog_product_flat`|`catalog_product_price`|`all`),
`flush_cache`, `regenerate_image` (course cover + badge chips), `enable`/`disable` (by `sku`),
`run_class_formation`. Powerful ops are rate-limited + audited. Full spec to follow.
