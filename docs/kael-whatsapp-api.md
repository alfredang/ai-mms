# Kael WhatsApp Ops — proposed API surface (`MMD_KaelApi`)

Kael is the OpenClaw agent sitting behind the **TIA Operation Support**
WhatsApp Operation Group. Admin-side, operators reach it via the floating
launcher in the admin header (`template/page/header.phtml`, roles: admin /
developer / marketing / super-admin), which sends structured fill-in-the-blank
requests. This document proposes the HTTP API Kael calls back into this
Magento install to actually execute those requests — mirroring how the
AI-LMS-TMS project exposes `/api/external/*` endpoints to its external agent.

**Status: PROPOSAL — none of these endpoints exist yet.** The launcher widget
works today (messages land in the group; Kael can act manually or via admin
automation). Implement endpoints incrementally, most-used first.

## Conventions

- **Module**: new `MMD_KaelApi` under `app/code/local/MMD/`, frontend route
  `/kaelapi/<controller>/<action>` (pattern: `MMD_Reindex`'s
  `/reindex/api/run` token API — see
  `app/code/local/MMD/Reindex/controllers/ApiController.php`).
- **Auth**: shared-secret token per install in
  `core_config_data['mmd_kaelapi/api/token']`, sent as
  `Authorization: Bearer <token>` (accept `?token=` as fallback). 403 JSON on
  mismatch. Rotate per partner site — each franchise install has its own DB
  and its own token.
- **Format**: JSON in (POST body) / JSON out. Every response:
  `{"ok": true|false, "data": …, "error": "…"}`.
- **Idempotency**: follow the LMS axioms — enrolment inserts are
  `INSERT IGNORE` against `course_run_enrolments`'s unique key; class
  create finds-or-creates by `(course_sku, course_start_date)`; re-sending a
  WhatsApp request must never duplicate data.
- **Identity**: classes are addressed by `class_id` (`SG000042` style) OR by
  `sku` + `start_date`; courses by `sku` (course code); learners by email.
- **Audit**: every mutating call appends to a `mmd_kaelapi_log` table
  (endpoint, payload, actor note, result) so ops can trace what Kael changed.
- **Guardrails**: reuse existing services — never reimplement class-ID
  generation (`MMD_RoleManager_Helper_Data::nextClassId()`), enrolment
  parsing (`CourseRunEnrolmentService`), or add parallel tables. Course
  attribute writes must target store 0 and be followed by a flat/product
  reindex (the existing `/reindex/api/run?token=…&flush=1` covers this).
  TGS- (WSQ) SKUs: enrolment mutations are skipped by the existing service
  (external SSG system) — the API should return a clear error, not silently
  no-op.

## Endpoints

### Classes (course runs — `course_runs`)

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/kaelapi/classes/list?from=&to=&sku=` | Upcoming/past classes with roster counts (mirrors admin All Classes grid). |
| GET | `/kaelapi/classes/get?class_id=` | One class + roster + trainer. |
| POST | `/kaelapi/classes/create` | `{sku, start_date, end_date, start_time, end_time, trainer, vacancy}` → finds-or-creates the `course_runs` row, labels via `nextClassId()`. |
| POST | `/kaelapi/classes/update` | `{class_id, …fields}` — dates/times/vacancy/trainer. |
| POST | `/kaelapi/classes/cancel` | `{class_id, reason, notify_learners}` — marks cancelled; optional learner email. |

### Enrolments (roster — `course_run_enrolments`)

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/kaelapi/enrolments/list?class_id=` | Roster for a class. |
| POST | `/kaelapi/enrolments/add` | `{class_id, learner_email, learner_name}` — idempotent INSERT IGNORE. Creates the customer + shadow admin_user via `MMD_AccountSync` if the email is new. |
| POST | `/kaelapi/enrolments/remove` | `{class_id, learner_email, reason}`. |
| POST | `/kaelapi/enrolments/move` | `{learner_email, sku, from_start_date, to_start_date}` — remove + add across runs (reschedule). |
| POST | `/kaelapi/enrolments/resend-confirmation` | `{class_id, learner_email}` — re-send the registration email. |

### Trainers

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/kaelapi/trainers/list` | Trainer `admin_user`s (role `trainer` in `mmd_user_role_map`). |
| POST | `/kaelapi/classes/assign-trainer` | `{class_id, trainer_email}` → sets `course_runs.trainer_option_id`. |
| POST | `/kaelapi/classes/remove-trainer` | `{class_id}`. |
| POST | `/kaelapi/classes/replace-trainer` | `{class_id, new_trainer_email}`. |

### Course schedule (the "Course Date" / "Course Time" custom options learners pick at registration)

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/kaelapi/schedule/list?sku=` | Bookable dates/times for a course (its custom-option values). |
| POST | `/kaelapi/schedule/add` | `{sku, date, time}` — append an option value (via `MMD_CustomOptions` policies). |
| POST | `/kaelapi/schedule/update` | `{sku, old_date, new_date, new_time}`. |
| POST | `/kaelapi/schedule/delete` | `{sku, date}` — remove a bookable date (existing registrations keep their run). |

### Courses (products)

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/kaelapi/courses/get?sku=` | Title, status, price, dates, categories, badges. |
| POST | `/kaelapi/courses/update` | `{sku, fields:{short_description, description, price, duration, …}}` — store-0 EAV write + reindex. `name` changes should be refused by default (product `name` is sacred — H1/JSON-LD/tiles echo it) unless `force:true`. |
| POST | `/kaelapi/courses/set-status` | `{sku, enabled:0|1}` — disable/retire a course. |
| POST | `/kaelapi/courses/set-cover` | `{sku, image_url}` or prompt-driven via `MMD_CourseImage`. |

### Blog (`mmd_blog_post`)

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/kaelapi/blog/list?status=` | Posts + status. |
| POST | `/kaelapi/blog/create` | `{title, excerpt, content, related_skus, meta_title, meta_description, publish_at}` — lands as draft in the existing review pipeline. |
| POST | `/kaelapi/blog/update` | `{url_key, …fields}`. |
| POST | `/kaelapi/blog/set-status` | `{url_key, status}` — publish / unpublish. |

### Reports / utility

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/kaelapi/reports/registrations?from=&to=&sku=` | Registrations (orders) in a window. |
| GET | `/kaelapi/reports/upcoming-classes?days=` | Classes starting soon, with fill rate. |
| GET | `/kaelapi/health` | Version + DB + cron heartbeat (Kael's liveness probe). |
| GET | `/reindex/api/run?token=…&flush=1` | **Already exists** — flat/product reindex + cache flush after data writes. |

## Rollout order (suggested)

1. `health`, `classes/list`, `classes/get`, `enrolments/list` — read-only, lets Kael answer questions safely.
2. `enrolments/add|remove|move`, `classes/assign-trainer|remove-trainer` — the highest-volume ops asks.
3. `classes/create|update|cancel`, `schedule/*`.
4. `courses/update|set-status`, `blog/*` — content writes, gate behind an ops-confirm step in Kael.

## Widget ↔ API mapping

Each template in the admin launcher (header.phtml `TEMPLATES` array) names its
fields to match the endpoint payloads above, so Kael can parse a filled
template directly into an API call — e.g. the "Add learner to a class"
message maps 1:1 onto `POST /kaelapi/enrolments/add`.
