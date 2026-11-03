# Learner app API (`MMD_MobileApi`)

JSON API behind the native learner apps:

| App | Site | iOS bundle | Android package |
|---|---|---|---|
| TC LMS SG | www.tertiarycourses.com.sg | `com.tertiaryinfotech.tertiarycoursesapp` | `com.tertiaryinfotech.tertiarycoursesapp` |
| TC LMS MY | www.tertiarycourses.com.my | `com.tertiaryinfotech.tertiarycoursesmyapp` | `sg.com.tertiarycourses.tertiarycoursesmyapp` |
| TC LMS GH | www.tertiarycourses.com.gh | `com.tertiaryinfotech.tertiarycoursesghapp` | `sg.com.tertiarycourses.tertiarycoursesghapp` |

Every site runs the same module against its own database, so each app talks
only to its own country's site. Non-WSQ (C-prefix) classes only.

## Endpoints

All responses are `{"ok":true,...}` or `{"ok":false,"error":"<learner-facing message>","code":"..."}`.
Authenticated calls send `Authorization: Bearer <token>`.

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/mobileapi/site` | – | site name, country, currency, time zone, contacts |
| GET | `/mobileapi/catalog` | – | public C-prefix catalog, grouped into ~12 categories (cached 3 h, warmed by cron every 2 h) |
| POST | `/mobileapi/auth/password` | – | `{email, password, platform?, app_version?}` → `{token, learner, site}` |
| POST | `/mobileapi/auth/otpsend` | – | `{email}` — always ok for a valid email (no account probing); 3 per email per 10 min |
| POST | `/mobileapi/auth/otpverify` | – | `{email, code}` → `{token, learner, site}`; single use, 10 min, 5 guesses |
| GET | `/mobileapi/auth/me` | ✓ | learner profile + site |
| POST | `/mobileapi/auth/logout` | – | revokes the presented token |
| POST | `/mobileapi/auth/delete` | ✓ | `{confirm:"DELETE"}` — deletes the login account (customer + learner-only shadow admin); staff accounts refused |
| GET | `/mobileapi/learner/classes` | ✓ | `{today, current[], upcoming[], past[]}` — enrolled runs + unpaid registrations |
| GET | `/mobileapi/learner/class?run_id=` | ✓ | sessions (+ own attendance), attendance window, learner materials, documents, survey state, certificate |
| POST | `/mobileapi/learner/attendance` | ✓ | `{run_id}` — self-mark the current session (same rules as the web self-mark) |
| GET | `/mobileapi/learner/survey?run_id=` | ✓ | the active in-house survey template, class fields prefilled |
| POST | `/mobileapi/learner/survey` | ✓ | `{run_id, answers:{field_id:value}}` — once per learner per class |
| GET | `/mobileapi/learner/certificates` | ✓ | issued/sent certificates with the token download link |
| GET | `/mobileapi/learner/billing` | ✓ | orders with C-prefix items: status, totals, currency, invoices |
| GET | `/mobileapi/site/samplecertificate` | – | the App Review account's sample certificate PDF |

## Rules worth knowing

- **Enrolment gate.** Every class read joins `course_run_enrolments` on the
  learner's email; another class's `run_id` returns 404. (The web dashboard
  will render any course's courseware; the API will not.)
- **Learner courseware only:** `learner_slides_url`, `learner_guide_url`,
  `lesson_plan_url`, `lab_url`. Trainer columns are never selected.
- **Store-local "today"** (`core/date`) for buckets, attendance and survey.
- **Survey** opens on the first day of class; saved through
  `MMD_FeedbackForm_Helper_Data::saveSubmission` exactly like the web form,
  plus a `mmd_mobile_feedback` row so it can't be answered twice.
- **App Review account** (`appreview@tertiarycourses.com.sg`): password checked
  against `mmd_mobileapi/general/demo_password_hash`; every endpoint answers
  from `MMD_MobileApi_Helper_Demo` (sample classes dated around today) and no
  write is stored. The password lives only in the app repos' gitignored `.env`
  and the private store review notes.
