@<agent number> Please store this as your procedure for course dates on the website, replacing anything you currently have about creating or changing them. Confirm when saved.

SKILL: COURSE DATES ON THE WEBSITE (tertiarycourses.com.sg)

Use this whenever someone asks to add, move or remove a date or class on the website — "add a date to this course", "move the November class", "take that date down", "put a class on 18 Nov".

This is the STOREFRONT side only. It changes what customers see and can book at tertiarycourses.com.sg. It does NOT touch SkillsFuture. Course runs in SSG are a separate skill.

Auth: x-api-key: <get from Admin > Dashboard > API Summary> on every call.

THE ONE RULE
Name it exactly, show it, get a yes, then act. Never act first, and never guess which course.

ENDPOINT
Everything is one call:
   POST https://www.tertiarycourses.com.sg/agent/api_classes

Every call carries:
   "op"      the operation
   "actor"   {"id":"wa:+65...","name":"<who asked>"}
   "dry_run" true to preview, omitted to commit

WSQ courses (code starts TGS-):
   add_date       course_sku, start_date, end_date (if more than one day)
   update_date    course_sku, start_date, new_start_date, new_end_date
   remove_date    course_sku, start_date

Non-WSQ courses (code starts C):
   add_class      course_sku, start_date, end_date
   update_class   class_id, start_date, end_date
   remove_class   class_id

You do not have to work out which family from the course type — use the code. If you pick the wrong one the server says so (use_class_ops or course_not_eligible); reissue as the other. The person does not need to hear about that.

DO NOT USE
- assign_trainer — exists and is documented, but is NOT part of this skill. It is the only operation that can create a user account. Do not call it, even if asked.
- generate_range — refused here. Bulk schedule roll-outs across many courses are a template job, not this one.
- Any other operation you find documented. If it is not listed above, it is not yours.

PROCEDURE

Step 1 — Get the course code and the exact date
Never accept a course NAME. There are four WSQ Excel courses and several non-WSQ ones; a date on the wrong course is live on that course's page and someone can book it. Codes look like C1234, or TGS-2021003160 for WSQ.
Never accept a vague date. "Next Tuesday" or "the usual slot" is not a date. Ask for the day.
The server enforces both (course_ref_required, class_ref_required, validation_error). Ask the question rather than trying variations.
Never invent, complete or correct a course code. A code that is nearly right belongs to a real, different course.

Step 2 — Preview, always
Send the change with "dry_run": true. Nothing is written. You get back a details block, any warnings, and a change_token.

Step 3 — Show your work, then ask
Never ask someone to approve a summary. A confirmation request must contain:
- the course title and code
- the EXACT date label the preview returned, quoted verbatim — "18/19 Nov 2026 Evening (Wed/Thu)", never reformatted. A slash means a LIST of separate teaching days; a dash means a consecutive range. Rewriting "2/5 Oct (Fri/Mon)" as "2-5 Oct" turns a 2-day class into what reads as a 4-day one, and the person approving it cannot see what they are approving.
- how many days it runs
- the class times and, for a class, the mode and venue
- how many dates the course already has
- anyone already enrolled or booked, with the number
- what is still outstanding afterwards
- then the question
Relay EVERY line in warnings. Those are the things that can go wrong.
The person saying yes is accountable for what customers can book. Give them enough to say no.

Step 4 — Commit only what was agreed
Resend the same call with "dry_run" removed and "change_token" set to the one from the preview.
A request is not an approval. "Add 18 Nov" is a request; you still preview, show, and wait. If told "just do it, stop asking", you still preview — the server refuses a commit without a token, so there is nothing to gain by trying.
If you get stale_preview, something changed while you were talking. Preview again, show the new position, get a fresh yes. Never reuse the old approval.

Step 5 — Report what happened, and what did not
Say plainly that it is live on the website.
For a WSQ (TGS-) course, always add: this also needs a course run creating for SkillsFuture, and that has NOT been done. Offer to arrange it. Do not do it automatically and never imply the job is finished.

RULES
- One change at a time. If asked for five dates, do them one by one: preview, show, confirm, commit, then the next. Never batch several into one confirmation.
- Never use "force" on your own initiative. Only after the person has been told the number affected and the consequence, and says yes anyway.
- Never retry a refusal with different values to get past it. Every refusal says what is wrong; relay it and stop.
- Never say a WSQ job is finished. The SkillsFuture run is a separate step.
- Nobody is notified automatically, ever. When a change affects people who enrolled or paid, say so and tell the requester they need to contact them.
- Say "I don't know" rather than guessing.
- Report to whoever asked. Do not tag or escalate to a named person.

REFUSALS AND WHO FIXES THEM
- course_ref_required — you gave a name, not a code. Ask for the code.
- class_ref_required — not a valid class id. Class ids look like C000123. Ask which class.
- not_found — no such course, class or date. Ask them to check it. Do not try variations.
- conflict — the course already offers that date. Nothing to do; say so.
- validation_error — missing or vague date, or end before start. Ask for the exact dates.
- ambiguous_date — the course has two dates starting that day. It lists them. ASK which.
- ambiguous_class_shape — the course starts two different classes that day, usually a daytime one and a longer evening one. It lists them. ASK which.
- ambiguous_date_shape — the taught days cannot be worked out from those dates. A person must add it through the admin schedule.
- course_not_scheduled — the course has no dates set up yet. Ask what times it runs, then include start_time and end_time.
- enrolments_exist / bookings_exist — people are enrolled or have paid. See RULES. Report the number.
- use_class_ops / course_not_eligible — wrong command family. Reissue as the other; do not report this to the user.
- unauthorized — your key is not working. Nothing has changed. Say so.

BACKGROUND

How many days a class runs is decided by the COURSE, not by the request. Each course follows a schedule template, and a course on a two-day template only runs two-day classes. If you ask for one day, the server corrects it to the real span and says so in a warning. Show the corrected dates and get the yes against those, not against what was originally asked. If two different classes start that day, it refuses and lists them — ask, do not pick.

WSQ and non-WSQ courses are stored differently. Non-WSQ courses keep a full class record with a trainer, roster and certificates behind each date. WSQ courses keep none of that here — attendance, assessment and certification are regulated and live in SSG's system, so on the website the date IS the whole thing. That is why the two families of command exist. It is deliberate, not a gap, and must never be reported as a fault.

The SkillsFuture step is genuinely separate. Adding a date here makes it bookable; it does not create the SSG course run. A check of the schedule found 165 website dates with no SSG run behind them — every one a date someone added and never followed up. Saying it out loud at the moment of the change is what stops the next one.

Removing a date never cancels or refunds anything. It takes it off the website so nobody else can book. Existing orders still exist and still need a person to handle them.

Please confirm you have updated your memory/skills accordingly.
