# Learner app API (`MMD_MobileApi`)

JSON API behind the native learner apps:

| App | Site | iOS bundle | Android package |
|---|---|---|---|
| TC LMS SG | www.tertiarycourses.com.sg | `com.tertiaryinfotech.tertiarycoursesapp` | `com.tertiaryinfotech.tertiarycoursesapp` |
| TC LMS MY | www.tertiarycourses.com.my | `com.tertiaryinfotech.tertiarycoursesmyapp` | `sg.com.tertiarycourses.tertiarycoursesmyapp` |
| TC LMS GH | www.tertiarycourses.com.gh | `com.tertiaryinfotech.tertiarycoursesghapp` | `sg.com.tertiarycourses.tertiarycoursesghapp` |

Every site runs the same module against its own database, so each app talks
only to its own country's site. Learners see their non-WSQ (C-prefix) classes;
trainers see every class they teach.

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
| GET | `/mobileapi/profile` | ✓ | `{learner}`: name, `phone`, `theme` (`system`/`light`/`dark`), `roles` (`learner`, plus `trainer` when the account teaches) |
| POST | `/mobileapi/profile` | ✓ | any of `{first_name, last_name, phone, theme}` → `{learner, message}`; 422 on invalid input |
| GET | `/mobileapi/trainer/classes` | ✓ trainer | `{today, current[], upcoming[], past[]}`: the classes the trainer teaches, every SKU (WSQ and non-WSQ); items carry `role:"trainer"` and `learner_count` |
| GET | `/mobileapi/trainer/class?run_id=` | ✓ trainer | sessions, `roster[]` (`present` = session keys), `attendance_open`, `current_session`, `checkin_url` (learner QR), trainer + learner courseware, `survey_responses` |
| POST | `/mobileapi/trainer/attendance` | ✓ trainer | `{run_id, session_key, records:[{email, present}]}`: roster members only, while the class is running |
| GET | `/mobileapi/site/samplecertificate` | – | the App Review account's sample certificate PDF |

## Rules worth knowing

- **Roles (1.4).** Learners (storefront customers, learner-role accounts) and
  trainers sign in to the same app. A trainer is an active account with the
  `trainer` role, or an email on an active `courses_trainers` record. The
  `learner` object in every auth reply lists `roles`; trainer endpoints answer
  403 `not_trainer` to anyone else.
- **Trainer class match = the web LMS rule** (`MMD_Attendance_Helper_Data::_filterToTrainer`
  plus `Handover::canAccessRun`): the run's `trainer_user_id`, the legacy
  `trainer_option_id` whose `courses_trainers.email` is the trainer's, the
  trainer's full name, or a co-trainer named in the TMS handover. Another
  trainer's `run_id` returns 404. Past classes go back 365 days.
- **Trainer attendance** writes the same `mmd_course_run_attendance` rows as the
  website. It is open from the first day until the day after the class ends;
  a finished Malaysia class or a confirmed final attendance is corrected on the
  website (where the reason is logged). A class handed over from the TMS can
  only be marked for the session in progress.
- **Trainer courseware** adds `trainer_slides_url`, `facilitator_guide_url` and
  `assessment_plan_url` to the learner links. Learner endpoints still never
  select them.
- **Appearance** is stored per account in `mmd_mobile_profile.theme` (migration
  1944) so the iOS and Android apps follow the same choice. The website keeps
  its own per-browser choice in `localStorage['admin-theme']`; it does not read
  or write this column yet.
- **Learner class lists are still non-WSQ only** (WSQ classes keep no
  `course_run_enrolments` rows); every class item now carries `role`.
- **Enrolment gate.** Every class read joins `course_run_enrolments` on the
  learner's email; another class's `run_id` returns 404. (The web dashboard
  will render any course's courseware; the API will not.)
- **Learner courseware only:** `learner_slides_url`, `learner_guide_url`,
  `lesson_plan_url`, `lab_url`, `lab_simulator_url`, `practice_exam_url`; a
  blank link is not returned. Trainer columns are never selected.
- **Store-local "today"** (`core/date`) for buckets, attendance and survey.
- **Survey** opens on the first day of class; saved through
  `MMD_FeedbackForm_Helper_Data::saveSubmission` exactly like the web form,
  plus a `mmd_mobile_feedback` row so it can't be answered twice.
- **App Review account** (SG `appreview@tertiarycourses.com.sg`, MY
  `appreview@tertiarycourses.com.my`, GH `appreview@tertiarycourses.com.gh`, set
  in `mmd_mobileapi/general/demo_emails` on each site's own DB): password checked
  against `mmd_mobileapi/general/demo_password_hash`; every endpoint answers
  from `MMD_MobileApi_Helper_Demo` (sample classes dated around today, plus one
  sample class the reviewer teaches with a five-name roster) and no
  write is stored. The password lives only in the app repos' gitignored `.env`
  and the private store review notes.
