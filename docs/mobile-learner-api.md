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
| POST | `/mobileapi/learner/attendance` | ✓ | `{run_id, signature?}` — self-mark the current session (same rules as the web self-mark). `signature` = base64 PNG of the learner's finger signature (app 1.5+), kept in `mmd_attendance_signature`; `learner/class` → `attendance.signed` |
| GET | `/mobileapi/learner/survey?run_id=` | ✓ | the active in-house survey template, class fields prefilled |
| POST | `/mobileapi/learner/survey` | ✓ | `{run_id, answers:{field_id:value}}` — once per learner per class |
| GET | `/mobileapi/learner/quiz?quiz_id=&run_id=` | ✓ | a lesson quiz: `{quiz:{quiz_id,title,questions:[{id,question,options[]}]}, previous}`; correct answers are never sent |
| POST | `/mobileapi/learner/quiz` | ✓ | `{quiz_id, run_id, answers:{question id: option index}}` → `{score, total, breakdown[]}`; scored on the server, one row per attempt |
| GET | `/mobileapi/learner/certificates` | ✓ | issued/sent certificates with the token download link |
| GET | `/mobileapi/learner/billing` | ✓ | orders with C-prefix items: status, totals, currency, invoices |
| GET | `/mobileapi/profile` | ✓ | `{learner}`: name, `phone`, `theme` (`system`/`light`/`dark`), `roles` (`learner`, plus `trainer` when the account teaches) |
| POST | `/mobileapi/profile` | ✓ | any of `{first_name, last_name, phone, theme}` → `{learner, message}`; 422 on invalid input |
| GET | `/mobileapi/trainer/classes` | ✓ trainer | `{today, current[], upcoming[], past[]}`: the classes the trainer teaches, every SKU (WSQ and non-WSQ); items carry `role:"trainer"` and `learner_count` |
| GET | `/mobileapi/trainer/class?run_id=` | ✓ trainer | sessions, `roster[]` (`present` = session keys), `attendance_open`, `current_session`, `checkin_url` (learner QR), trainer + learner courseware, `survey_responses` |
| POST | `/mobileapi/trainer/attendance` | ✓ trainer | `{run_id, session_key, records:[{email, present}]}`: roster members only, while the class is running |
| POST | `/mobileapi/trainer/sign` | ✓ trainer | `{run_id, session_key, signer, signature}`: a finger signature on the trainer's phone (app 1.5+). `signer` = `trainer` (the trainer's own signature for the session) or a roster learner's email (the learner signs and is marked present). Same open-window rules as `trainer/attendance`. `trainer/class` → `roster[].signed`, `trainer_signed` (session keys) |
| GET | `/mobileapi/site/samplecertificate` | – | the App Review account's sample certificate PDF |
| POST | `/mobileapi/trainer/announcement` | ✓ trainer | `{run_id, message}` posts a text announcement to the class; `{run_id, delete_id}` deletes one → `{announcements[]}` |
| GET | `/mobileapi/staff/classes?role=admin[&from=&to=]` | ✓ admin | `{today, kpis:{running_today, next_30_days, learners_today}, current[], upcoming[]}`; with `from`/`to` (≤ 62 days) `{classes[]}` for the calendar. Non-WSQ (C-prefix) only. |
| GET | `/mobileapi/staff/courses?role=developer` | ✓ developer / admin | `{today, kpis:{courses, with_classes, disabled}, courses[{id, sku, title, enabled, course_type, training_hours, assessment_hours, upcoming_classes, next_class}]}`; non-WSQ (C-prefix) only |
| GET | `/mobileapi/staff/course?role=developer&id=` | ✓ developer / admin | `{course:{id, sku, title, enabled, course_type, funding_validity_start, funding_validity_end, training_hours, assessment_hours, duration_days, courseware[{key, label, url}], practice_exam_setting:{configured, enabled, exam_slug, exam_code, exams[{slug, code, title, vendor}], warning}, …}}`. Funding validity is null on a non-WSQ course (the web shows NA). `duration_days` = ceil((training + assessment hours) / 8), as the web course page. The older fields (price, description, topics, upcoming classes, SEO) stay for app 1.7 and earlier. Non-WSQ (C-prefix) only |
| POST | `/mobileapi/staff/practiceexam` | ✓ developer / admin | `{role, id, exam_slug}` links the course to that practice exam (a slug from `exams[]`), `exam_slug: ""` turns it off — the web Edit Course → Course Settings switch → `{setting}` (same shape as `practice_exam_setting`). 400 `practice_exam` when the site has no exams token, the exams site is unreachable or the exam is gone. Logged to `mmd_practiceexam.log` |
| GET | `/mobileapi/support` | ✓ | `{support:{email, phone, whatsapp, address, feedback}}` for the Support tab |
| POST | `/mobileapi/support` | ✓ | `{subject, message, app_version?}` emailed to the academy with the sender's name and email; 5 per account per hour |

## Rules worth knowing

- **Class page sections (app 1.6).** `learner/class` and `trainer/class` follow the
  website's class page: `announcements[]` (`id, message, file_name, file_url,
  posted_by, posted_at`, oldest first, from `mmd_class_announcement`) and
  `lesson[]` (`title, subtopics[{title, links[{type: web|document|activity|video|quiz,
  title, url, quiz_id?, questions?, previous?}]}]`; a trainer's quiz `url` is the
  QR link, a learner's is empty). Both add `practice_exam` (`exam_code, exam_url,
  self_register_url, open, registered`, or null). The apps show NO QR code (that
  stays on the web class page): they open `self_register_url`, the self-register
  form, which for a learner comes pre-filled (`?name=&email=`). A trainer of the
  class is registered on the exams site automatically (`registered` true once
  done), as on the web Practice Exam panel. `trainer/class` adds `feedback_summary`
  (`count, overall, questions[{label, average}], comments[]`, or null); for a class
  handed over from the LMS/TMS it is read from the TMS over the bridge
  (`/api/internal/class-feedback`, env LMSTMS_BRIDGE_URL + MOBILE_BRIDGE_SECRET). Every class item's `venue` is the run's own venue, else
  the academy's address (`general/store_information/address`, SG falls back to
  12 Woodlands Square); Live Online classes have none.

- **Lesson quizzes (`MMD_LessonQuiz`).** `learner/class` lists the class's
  quizzes in `quizzes[]` (`quiz_id`, `title`, `questions` count, `url`,
  `previous` = the learner's latest `{score,total,completed_at}`). A quiz is
  open to a learner enrolled in the class whose course Lesson holds it, or to
  any signed-in account that sends `k`, the signature in the trainer's quiz QR
  link (`/lessonquiz/index/index/q/<quiz id>/run/<run id>/k/<sig>/`, also in
  `url`). The public quiz page behind the QR code is a web client of these two
  endpoints (it sends `platform:"web"`). Every submit is a new attempt; the
  trainer's results show each learner's latest. The App Review account's
  sample classes carry one sample quiz (`quiz_id` 900101); its answers are
  scored but never recorded.
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
