# OpenClaw Agent API - Scoping & Implementation Plan

**Status:** Draft for review - **Owner:** (you) - **Consumer:** OpenClaw agent (chat-group driven)

This plan scopes a set of **write / operation APIs** that expose MMS features to an
external OpenClaw agent, across four capability areas:

1. Edit course schedule
2. Update course info
3. Marketing / content updates
4. Related website / MMS / API operations

It records what already exists, the gaps, the interaction/approval model, the proposed
endpoints, and the cross-cutting safety design.

**This file is the internal build plan (developer-facing).** The agent itself has **no
repo access** - it reasons only from API calls, the DB shape, and what users (esp. the tech
lead) explain to it over time. So the agent gets **two dedicated agent-facing docs**, kept
deliberately separate from this plan:

- **[`agent-context.md`](agent-context.md)** - high-level, repo-wide domain + data-model
  context so the agent can reason correctly (what MMS is, courses=products, class identity,
  funding/GST rules, SKU conventions, the invariants it must respect).
- **[`agent-api-spec.md`](agent-api-spec.md)** - the callable contract: auth, the
  preview->confirm->commit protocol, the request envelope, and a detailed spec per endpoint.

---

## 1. Context & constraints

- **One store per site (franchise model).** Each partner site runs this same codebase
  against its own DB and serves exactly one store. The agent points at a specific
  site's API; all endpoints are single-store scoped (SG = `store_id 1`), mirroring the
  existing read APIs. No cross-site fan-out.
- **The storefront/registration HTTP path is sacred.** These APIs are backend/admin-side
  mutations only. They must never wire observers into `checkout_*` /
  `sales_order_place_after`, and never touch the sales tables (see `CLAUDE.md` axioms).
- **Reuse, don't fork.** Schedule writes reuse the existing `course_runs` +
  `CourseRunEnrolmentService` + `nextClassId()` machinery and the CustomOptions
  "Manage Templates" scheduler - no parallel schedule/class tables.
- **Everything is a course.** No stock/shipping/inventory. Price = course fee.

---

## 2. Interaction & approval model (decided)

Approval is handled **in the chat by the agent**, not by a backend review queue.

```
Chat user --asks--> OpenClaw agent
                        | 1. authorize: check the requesting user's chat-group role
                        |    (agent-side; the backend trusts the agent's API key)
                        | 2. PREVIEW: call the endpoint with dry_run=1
                        v
                   MMS API --returns--> { diff, human_summary, change_token }
                        | 3. agent renders `human_summary` as a plain-English
                        |    changelist and asks the SAME user to confirm
                        | 4. user confirms in chat
                        | 5. COMMIT: call the endpoint again with the change_token
                        v
                   MMS API -- applies iff token still valid --> { applied, audit_id }
```

Consequences for the API design:

- **`dry_run=1` is a first-class mode on every write endpoint.** It computes and returns
  the exact diff plus a `human_summary` string the agent can relay verbatim, and a
  `change_token` (a hash over the exact computed change + a snapshot of the current
  values it depends on).
- **Commit requires the `change_token`.** On commit the backend recomputes the token from
  live data; if the underlying values changed since preview (someone edited the course in
  the meantime), the token mismatches and the write is **rejected** (`409 stale_preview`).
  This guarantees "what the user approved in chat" == "what gets applied."
- **`actor` is required on every call.** The **WhatsApp number is the canonical identity**
  (`id`) - it is what the agent authorizes against and what the audit log keys on. The
  **`name`** is the human the agent refers to in conversation (tied to that number), carried
  for readable audit trails; `role` is that user's assigned role. Example:
  `{"actor":{"id":"wa:+6591234567","name":"Sylvia","role":"marketing"}}`. The backend does
  **not** enforce authorization from it (that's the agent's job) but **records all three in
  the audit log** - so every change is traceable to a named human + their number.
- **Authorization is the agent's responsibility.** The backend's trust boundary is the
  API key: whoever holds it can write. This is a deliberate simplification given the
  agent owns role logic. See Sec 7 "Trust boundary & audit" for the risk and mitigations.

> The per-endpoint specs will each carry an **"Agent protocol"** section telling the
> agent: which role(s) may invoke it, to always preview first, to show the
> `human_summary` and get explicit confirmation, and to commit with the token.

---

## 3. Existing API inventory

All live endpoints are `MMD_Courses` **frontend controllers** at `/courses/api_*`, authed
by an `X-API-Key` header vs a store-config value, JSON responses. They are almost entirely
**read/export**.

| Endpoint | Method | Auth key | R/W | Notes |
|---|---|---|---|---|
| `/courses/api_courses` | GET | `courses/general/wsq_schedule_api_key` | read | course export |
| `/courses/api_schedule` (`?sku=`) | GET | same | read | dates from "Course Date" option + `course_runs` |
| `/courses/api_search` | GET | same | read | course search |
| `/courses/api_trainers` | GET | same | read | trainer data |
| `/courses/api_reminders` | GET | same / trainer key | trigger | sends class/trainer reminders |
| `/courses/api_contact` | POST | same | write | contact/lead form |
| `/courses/api_faq` | GET | same | read | FAQ export |
| `/courses/api_completed_classes` | GET | `mmd/course_sync/api_key` | read | completed classes |
| `/courses/api_sync_export` | GET | `mmd/course_sync/api_key` | read | bulk course sync |
| `POST /kael_review_api.php` (root) | POST | `KAEL_REVIEW_API_KEY` env | **write** | creates an approved product review - see [kael-review-api.md](kael-review-api.md) |

**Only the review API writes.** The read APIs are a strong foundation the agent (and these
new write endpoints) build on for previews and lookups.

---

## 4. Gap analysis by category

| Category | Already covered (read) | To build (write / op) |
|---|---|---|
| **1. Edit course schedule** | `api_schedule` reads dates + `course_runs` | add / update / remove a class date; assign-reassign trainer; set vacancy / mode / venue / time; **bulk-generate a schedule from a date-range rule** (native port of the GAS `generateDates()`); keep `course_runs` in sync |
| **2. Update course info** | `api_courses`, `api_trainers` | edit description / short description / price / meta title+desc / status / category assignment / whitelisted attributes |
| **3. Marketing / content** | `api_faq`, review API (write) | edit marketing copy; per-course CMS block sections; funding **badges** (via tags); (later) CMS pages / blog posts |
| **4. Website / MMS / API ops** | `api_sync_export`, `api_search`, `api_reminders` | reindex (flat catalog / price / URL rewrites); cache flush; regenerate cover image + badges; enable / disable a course; trigger class-formation / roster backfill |

---

## 5. Proposed module: `MMD_AgentApi`

A **new dedicated module** rather than extending `MMD_Courses`, so the agent surface is
isolated:

- **API key - reuse the existing shared external key** `courses/general/wsq_schedule_api_key`
  (the same `X-API-Key` the agent already presents to the read APIs, e.g. `api_schedule`,
  which the WhatsApp bot already consumes). No new key unless the agent turns out to hold a
  different one - then match that. **Security note:** reusing the read key means one secret
  now also grants writes; the blast radius is capped by field allowlists + hard-blocked
  fields + preview/token + audit, but a dedicated, independently-rotatable write key is the
  safer long-term option if/when we split scopes.
- **Own audit table** - `mmd_agent_api_audit` (see Sec 7).
- **Own frontName** - `agent`, so routes are `/agent/api_<controller>`.
- **Shared base controller** - `MMD_AgentApi_Controller_Abstract` centralises: key check,
  `actor` parsing, `dry_run` handling, `change_token` compute/verify, JSON envelope,
  audit write, and the reindex helper. Every endpoint extends it -> uniform behaviour.

Routing examples: `/agent/api_schedule`, `/agent/api_course`, `/agent/api_content`,
`/agent/api_ops`.

---

## 6. Endpoint catalog

Each endpoint is `POST`, JSON in/out, `X-API-Key` + `actor` + optional `dry_run` +
`change_token` on commit. Verb selected by an `op` field so one controller covers a
capability. Full field tables live in the per-endpoint specs; this is the shape.

### 6.1 `POST /agent/api_schedule` - Edit course schedule
`op` in:
- `add_class` - append a "Course Date" (+ "Course Time") option value to a course and
  create the matching `course_runs` row. Keyed by `(course_sku, start_date)` -> idempotent.
- `update_class` - change date / time / trainer / vacancy / mode / venue of a class by
  `class_id`.
- `remove_class` - disable/remove a class date (guard: refuse if it has enrolments unless
  `force`). **v1: record-only** - an enrolment-affecting move/removal is applied + audited,
  but the API does **not** notify learners; existing reminder flows handle notification
  separately. The preview `warnings[]` surfaces the enrolment count so the agent can tell
  the user in chat.
- `assign_trainer` - set/replace `trainer_option_id` for a class.
- `generate_range` - bulk-create classes from a rule (start date, weekday pattern,
  interval, count / until) - the native `generateDates()` port. Returns the full generated
  list in the preview so the user approves the whole set.

**Guardrails:** class identity `(course_code, title, start_date)`; never duplicate a run;
reuse `nextClassId()` for `class_id`; reindex flat catalog + URL after option writes;
date strings validated through the existing 20+-format parser.

### 6.2 `POST /agent/api_course` - Update course info
`op: update`, `sku`, `fields{}` restricted to an **allowlist**:
`description, short_description, price, special_price, meta_title, meta_description,
status, url_key, category_ids, <whitelisted attrs>`.

**Guardrails:** **`name` and `sku` are NOT writable** (product name is sacred -
[feedback_product_name_is_sacred](lessons/feedback_product_name_is_sacred.md)); GST /
`enable_sg_funding` / tax fields are **off-limits** (funding math is deliberate); EAV
writes at the correct scope ([feedback_eav_save_attribute_scope](lessons/feedback_eav_save_attribute_scope.md));
reindex flat + price after save ([feedback_flat_catalog_reindex](lessons/feedback_flat_catalog_reindex.md)).

### 6.3 `POST /agent/api_content` - Marketing / content updates
`op` in:
- `update_copy` - marketing description / short description / meta (overlaps `api_course`
  but framed for content authors; same allowlist + guardrails).
- `set_badges` - set funding badges from the 9-name canonical vocabulary; written as tags
  ([feedback_funding_badges_via_tags](lessons/feedback_funding_badges_via_tags.md)) so
  storefront chips + cover image stay in sync.
- `set_cms_section` - per-course CMS block sections
  ([feedback_per_course_cms_block_sections](lessons/feedback_per_course_cms_block_sections.md)).
- `create_review` - thin proxy to the existing review API (or leave the review API
  standalone and just reference it).

**Guardrails:** badge names validated against `getAllBadges()`; HTML sanitised; per-segment
funding copy not stripped.

### 6.4 `POST /agent/api_ops` - Website / MMS / API operations
`op` in: `reindex` (`catalog_url` | `catalog_product_flat` | `catalog_product_price` |
`all`), `flush_cache`, `regenerate_image` (CourseImage cover + badge tags), `enable` /
`disable` (course status by sku), `run_class_formation` (nudge the materialisation cron /
backfill for a course).

**Guardrails:** the powerful ops (reindex all, flush cache) are rate-limited and audited;
`regenerate_image` reuses `CourseImage` so cover + chips match.

---

## 7. Cross-cutting design

### Request envelope (all write endpoints)
```json
{
  "op": "update_class",
  "actor": { "id": "wa:6591234567", "name": "Sylvia", "role": "marketing" },
  "dry_run": true,
  "change_token": null,
  "...op-specific fields..."
}
```

### Preview response (dry_run)
```json
{
  "success": true,
  "dry_run": true,
  "diff": [ { "field": "course_start_date", "from": "2026-06-06", "to": "2026-06-13" } ],
  "human_summary": "Class SG000042 (Data Analytics with RapidMiner) will move from 6 Jun 2026 to 13 Jun 2026. Trainer unchanged. 3 learners are enrolled and will be notified separately.",
  "change_token": "sha256:...",
  "warnings": [ "3 enrolments exist on this class" ]
}
```
The agent shows `human_summary` to the user, gets confirmation, then re-POSTs with
`dry_run:false` + the returned `change_token`.

### Commit response
```json
{ "success": true, "applied": true, "class_id": "SG000042", "audit_id": 1187, "reindexed": ["catalog_product_flat"] }
```

### `change_token` (preview<->commit integrity)
`token = sha256( canonical(op + target_ids + new_values + snapshot(current_values)) )`.
Recomputed on commit from live data; mismatch -> `409 stale_preview` (someone changed the
record between preview and approval). Prevents applying anything other than what was
approved in chat.

### Idempotency
Natural keys (`class_id`, `sku`) + an optional caller `idempotency_key` recorded in the
audit table; a repeated commit with the same key returns the original result instead of
re-applying.

### Trust boundary & audit
The API key fully trusts the agent; the backend does **not** re-verify the chat user's
role. Mitigations:
- **`mmd_agent_api_audit`** row per call: `actor_wa_number, actor_name, actor_role, op,
  target, before_json, after_json, dry_run, result, ip, created_at` (WhatsApp number is the
  stable actor key; name + role stored for readable traceability).
- API key stored **encrypted** in config, rotatable, revocable; served only over HTTPS.
- Field **allowlists** + hard-blocked fields (name/sku/GST) cap the blast radius even if
  the key leaks.
- Rate limiting on `api_ops`.

### Reindex discipline
Any op that writes EAV/options enqueues the needed reindex and reports it in `reindexed[]`.
Flat catalog + price indexers must run for storefront to reflect changes
([feedback_flat_catalog_reindex](lessons/feedback_flat_catalog_reindex.md)).

### Error envelope
`{ "success": false, "error": "<code>", "message": "<human>", "actor_echo": {...} }` with
codes: `unauthorized(401)`, `api_disabled(503)`, `validation_error(400)`,
`not_found(404)`, `forbidden_field(422)`, `stale_preview(409)`, `conflict(409)`,
`internal_error(500)`.

---

## 8. Guardrails & invariants (must-not-break)

- **Product name / SKU are read-only** to the agent - never rename a course via API.
- **GST / funding fields off-limits** - the SG GST-on-list-price and funding math are
  deliberate; not agent-writable.
- **Class identity = `(course_code, title, start_date)`**; `class_id` = `SG######` via
  `nextClassId()`; never invent an ID scheme or duplicate a run.
- **No parallel tables**; reuse `course_runs` / `course_run_enrolments` /
  `CourseRunEnrolmentService`.
- **Reindex after writes**; **sanitise HTML**; **validate dates** through the existing
  parser; **badges via tags** only.
- **Never touch sales tables or the storefront checkout path.**

---

## 9. Phasing / roadmap

- **Phase 0 - scaffolding:** DONE. `MMD_AgentApi` module, dispatch helper (key + actor +
  dry_run + change_token + audit), audit table migration.
- **Phase 1 - Edit course schedule** (`api_classes`): DONE. add/update/remove class +
  assign_trainer, fully verified. (Route is `api_classes`, not `api_schedule`, to avoid
  clashing with the read-only WSQ feed at `/courses/api_schedule`.)
- **Phase 2 - Update course info** (`api_course`): DONE.
- **Phase 3 - Marketing / content** (`api_content`): DONE (`update_copy`, `set_badges`;
  `set_cms_section` deliberately stubbed 501).
- **Phase 4 - website/MMS ops** (`api_ops`): DONE (`reindex`, `flush_cache`, `enable`,
  `disable`, `regenerate_image`; `run_class_formation` stubbed 501).
- **Phase 5 - admin-managed date protection:** DONE. Migration 780 + `saveProductOptions`
  guard: a schedule-template Apply reconciles only its own generated dates and never removes
  admin/agent-added ones. Made agent schedule writes durable + let the "template can undo
  this" warning be dropped.
- **Phase 6 - bulk template lane** (`api_template`): DONE. `generate_and_apply` (forgiving
  resolver, GAS-ported generation, append-only, applies to all products, admin_managed-safe).

Remaining: `set_cms_section` + `run_class_formation` (both stubbed by choice), and the two
hardening calls in Sec 10 (per-capability keys, `actor.role` enum).

---

## 10. Open questions

1. ~~**Key granularity**~~ **RESOLVED** - reuse the existing shared external key
   `courses/general/wsq_schedule_api_key` the agent already holds; revisit splitting into a
   dedicated write key later.
2. ~~**`actor` schema**~~ **RESOLVED** - identity is the **WhatsApp number** (`id`, the
   authz + audit key); `name` (the person tied to that number) + `role` are carried for
   readable traceability. Audit keys on the WA number.
3. ~~**Enrolment-affecting schedule edits**~~ **RESOLVED** - **record-only in v1**: apply +
   audit the change, surface the enrolment count in the preview `warnings[]`, but do **not**
   trigger learner notifications from the API (existing reminder flows handle that).
4. ~~**Review API**~~ **RESOLVED** - left standalone at `/kael_review_api.php`; `api_content`
   references it rather than proxying.
5. ~~**Bulk `generate_range`**~~ **RESOLVED** - there is no per-course range op. Per-course =
   `api_classes add_class` once per date (each durable/admin-managed). Bulk across all
   products = `api_template generate_and_apply`, which reuses the native GAS port
   (`mmd/schedule_generator`) driven by a slot code (A01-E04, derived from the template) +
   start/end date. "Rule inputs" turned out to be just the slot code + range - the GAS logic
   already encodes weekday/week-of-month patterns.

### Still open (the remaining decisions)

6. **`set_cms_section` (api_content)** - deferred; needs the per-course CMS-section storage
   model defined first. Currently returns `501 not_implemented`.
7. **`run_class_formation` (api_ops)** - **skipped for now.** Class formation already runs on
   a 1-minute cron; the only real value would be a narrow failure-recovery re-run. Currently
   `501 not_implemented`.
8. ~~**`actor.role` vocabulary**~~ **DONE.** Fixed enum
   `user,learner,trainer,developer,marketing,admin,training_provider`, validated in
   `_parseActor` (case-insensitive; unknown -> `400`). `role` is optional and defaults to
   `user` - the universal value for the current binary-whitelist phase (the agent will face
   customers too, not just staff). When the agent starts distinguishing operators it sends the
   specific canonical role; no backend change needed.
9. ~~**Per-capability API keys**~~ **DECIDED - ship the shared key in v1.** All endpoints keep
   the single shared key for now; split into per-capability / dedicated write keys only later
   if needed. When that happens, `api_template` (highest blast radius - touches every product
   on a template) is the first op to move behind its own/elevated key. Blast radius meanwhile
   is capped by field allowlists + hard-blocked fields (name/sku/GST) + admin_managed
   protection + the full audit trail.
```
