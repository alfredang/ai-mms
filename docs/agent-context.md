# MMS Agent Context

**Audience:** the OpenClaw agent. **You do not have access to the source code.** Everything
you need to reason about this system is in this document, in the API spec
([`agent-api-spec.md`](agent-api-spec.md)), in the JSON the APIs return, and in what trusted
users (especially the tech lead) tell you over time. When something here conflicts with what
a user tells you, ask - do not assume.

This document explains **what the system is and how it thinks**, so that when a user asks you
to change something you can (a) judge whether it's sensible, (b) draft an accurate
plain-English changelist, and (c) call the right API. The API spec is the *how to call*; this
is the *what it means*.

---

## 1. What this system is

It is the **MMS (Magento Management System)** - the course-registration + course-management
back office **and** the shared storefront/registration for *all* courses at a training academy,
built on top of an e-commerce engine. Read that literally:

- **Every "product" is a course** - an instructor-led training/workshop/certification. There
  is **no physical stock, no shipping, no inventory**. "Price" is the **course fee**.
- **Every "order" is a registration** - a learner signing up for a class on a date.
- **Every "customer" is a learner.**

So when you see e-commerce words in API responses (product, order, customer, catalog), map
them to **course, registration, learner, course list**.

> **"MMS" vs "LMS" - important terminology.** This system is the **MMS**. In this company the
> word **"LMS" (also "LMS-TMS" / "TMS-LMS") means a *separate* system** that handles **WSQ
> course administration** (the government-funded `TGS-` courses). The **MMS** owns the **non-WSQ**
> course admin and is the **shared storefront + registration for *all* courses** (WSQ and non-WSQ
> alike). So if a user says "the LMS", they mean that **other** system - not this one, and not
> these APIs. You only ever act on the **MMS** through the APIs in the spec. If a request really
> belongs in the LMS-TMS (e.g. WSQ-only administration a user says "should be done in the LMS"),
> say so rather than forcing it here.

**One site = one store.** Each partner country runs its own separate copy of this system on
its own server. The APIs you call serve **exactly one store** (currently Singapore). You never
address more than one country through a single site's API.

---

## 2. The core objects you will work with

### 2.1 Course (the "product")
A course has:

| Field | Meaning | Can you change it? |
|---|---|---|
| `sku` | **Course code** - the stable identifier (e.g. `TGS-2024048318`, `C520`, `M1043`) | **No - read-only, sacred** |
| `name` | **Course title** | **No - read-only, sacred** |
| `price` | Course fee (before GST/subsidy) | Yes (with confirmation) |
| `description`, `short_description` | Marketing copy (HTML) | Yes |
| `meta_title`, `meta_description` | SEO fields | Yes |
| `status` | Enabled / disabled on the storefront | Yes |
| `url_key` | The page slug | Yes (carefully) |
| `category_ids` | Which categories it appears in | Yes |
| funding badges | Coloured chips shown on the course (see Sec 5) | Yes |

> **Course code (`sku`) and title (`name`) are never changed by you.** Certificates,
> external funding systems, and class identity all key off them. If a user asks to rename a
> course, tell them that has to be done manually by staff - you cannot and must not do it.

### 2.2 Course custom options
Each course carries **custom options** the learner picks at registration. The ones that matter:

- **Course Date** - a dropdown of the scheduled class dates (e.g. `29 Mar - 2 Apr 2027 (Mon-Fri)`).
  **This is the schedule.** Editing the schedule means editing these values (and the matching
  class records, see Sec 3).
- **Course Time** - the daily timing (e.g. `9:30am - 6:30pm`).
- **Mode of Training** - **Physical Classroom** or **Virtual** (live online). (Hybrid is
  deprecated - do not create it.)
- **Sponsorship** - `Self-Sponsored` or `Employer-Sponsored`. Drives whether the learner gets
  a pro forma invoice (see Sec 5).
- **Funding Eligibility** - an age-band radio (`Singaporean above 40 yrs old`,
  `Singaporean below 40 yrs old`, `Singapore PR`, `non Singaporean`, `SME (...)`). **Only present
  on courses configured for funding.** Its selection is what applies the subsidy (see Sec 5).

### 2.3 Class (a scheduled run of a course)
A **class** is one scheduled instance of a course. Its identity is the triple:

> **(course code, course title, course start date)**

Two registrations for the same course on the same start date are the **same class**. A
different start date is a **different class**, even for the same course.

Each class is stored as one **class record** with these fields you can read/affect:

| Field | Meaning |
|---|---|
| `class_id` | Human label, format `SG######` (e.g. `SG000042`). SG = the store; the number is zero-padded. **Never invent or reformat this** - downstream links + certificates depend on it. |
| `course_sku` | The course code |
| `course_start_date` / `course_end_date` | The class dates (YYYY-MM-DD) |
| `course_start_time` / `course_end_time` | The class times |
| `trainer` | The assigned trainer (stored internally as a trainer option id; APIs show the name) |
| `mode` | Physical Classroom / Virtual |
| `venue` | Venue/building |
| `vacancy` | `A` available - `L` limited - `F` full - `-` unknown |

### 2.4 Roster / enrolments
Each class has a **roster** - the learners registered for it. Roster rows are keyed uniquely
by (course, class, learner email), so they never duplicate. **You do not edit the roster** -
it is materialised from real registrations in the background. You may *read* enrolment counts
(the schedule API surfaces them) to warn a user before a schedule change.

---

## 3. How the schedule actually works (important)

When you "edit a course's schedule," two things are linked and must stay in sync:

1. The **Course Date option values** on the course (what a learner sees + can pick).
2. The **class records** (one per scheduled date), which carry trainer, vacancy, mode, venue.

The schedule API handles keeping these two in sync for you - you express the intent
("add a class on 13 Jun 2026", "move class SG000042 to 20 Jun 2026", "assign trainer X to
SG000042") and it does the correct writes on both sides and re-indexes the storefront.

**Class identity is immutable in spirit:** moving a class's *date* effectively changes its
identity, so the API treats it carefully and warns you if learners are already enrolled.
**In v1, schedule changes that affect enrolled learners are recorded and audited, but the API
does not notify the learners** - you should tell the requesting user, in chat, how many
learners are affected (the preview gives you the count) so they can arrange notification.

---

## 4. Course code (SKU) conventions - use these to reason

The prefix of the course code tells you the segment:

| Prefix | Segment | Notes |
|---|---|---|
| `TGS-` | **Singapore WSQ** (government-funded) course. The SKU *is* the SkillsFuture course reference. | WSQ course administration largely lives in the **separate LMS-TMS system** + the government SSG system; the MMS still owns their storefront + schedule. Be extra careful. |
| `C` | **Singapore non-WSQ** course (e.g. `C520`, `C009`) | Full-price; **not** WSQ-subsidised. |
| `M` | **Other-country** course (e.g. `M1043`) | Belongs to a non-SG store. |

Do not assume "all SG = WSQ" or "all `C` = SG-only" - key off the prefix **and** the store.

---

## 5. Money: fees, GST, funding, badges (read this before touching price or funding)

Singapore has deliberately non-standard money rules. **Do not try to "correct" them.**

- **GST (9%) is charged on the original course *list* price** (the fee before any subsidy),
  **not** on the discounted amount. This is intentional (funded learners still settle GST on
  the pre-subsidy amount). So in registration data you will see `tax = 9% x list price`, which
  lets the list price be recovered even when the learner paid a subsidised fee.
- **Funding/subsidy is applied only when the learner selects a "Funding Eligibility" age band**
  on a course configured for funding. The bands map to a discount: *above 40* -> 70% off
  (= 50% Baseline + 20% MCES), *below 40 / PR* -> 50% (Baseline only), etc. A course **without**
  the Funding Eligibility option is **full price** - it cannot show a subsidy, and that is
  correct, not a bug.
- **`C`-prefix (non-WSQ) courses are full price** and are **not** meant to carry WSQ subsidies.
- **Pro forma invoices** (for SkillsFuture Credit claims) are generated **only for
  self-sponsored** registrations; employer/company-sponsored ones do not get one.
- **You must never change GST, tax, or the funding math** through the API. Those fields are
  hard-blocked. If a user asks, explain it's deliberate and out of scope for you.

### Funding badges
Courses show coloured **badges** (chips) advertising funding schemes. There is a fixed
vocabulary of **nine** badge names:

> `WSQ`, `SkillsFuture Credit`, `PSEA`, `UTAP`, `IBF`, `HRDF`, `SFEC`, `Absentee Payroll`, `MCES`

You may set/clear these on a course (they are stored as tags and drive both the storefront
chips and the course cover image). Anything outside the nine names is invalid.

---

## 6. Invariants you must always respect

These are hard rules. Breaking them corrupts data or the storefront:

1. **Never change a course code (`sku`) or title (`name`).**
2. **Never change GST / tax / funding-math fields.**
3. **Never invent or reformat a `class_id`** - it is always `SG######`.
4. **Class identity is (course code, title, start date).** Do not create a duplicate class for
   a date that already exists.
5. **Do not edit rosters/enrolments directly** - they come from real registrations.
6. **You do not touch the checkout / payment / order flow at all** - only the
   course/schedule/content surfaces the API exposes.
7. When in doubt about whether a change is safe or intended, **ask the user** (especially the
   tech lead) rather than guessing.

---

## 7. How you should make changes (summary - full detail in the API spec)

1. **Authorize the requester yourself** by their role (you know who they are from their
   WhatsApp number; you refer to them by name).
2. **Preview first.** Call the endpoint in `dry_run` mode. It returns the exact diff, a
   plain-English `human_summary`, and a `change_token`, plus any `warnings` (e.g. "3 learners
   enrolled").
3. **Draft the changelist in plain English** for the user (use the `human_summary` + warnings),
   and get **that same user's explicit confirmation**.
4. **Commit** by calling the endpoint again with the `change_token`. If the course changed
   since your preview, the commit is rejected (`stale_preview`) - re-preview and re-confirm.
5. Every call carries an **`actor`** (the requester's WhatsApp number, name, role) so the change
   is logged against a named human.

---

## 8. Glossary

| Term | Means |
|---|---|
| MMS | **This system** (Magento Management System): non-WSQ course admin + the shared storefront/registration for *all* courses. What these APIs act on. |
| LMS / LMS-TMS / TMS-LMS | A **separate** system that handles **WSQ** course administration. **Not** this system - if a user says "the LMS", they mean that one. |
| Course / product | A training course |
| Class / run | One scheduled instance of a course on a specific start date |
| `class_id` | `SG######` label for a class |
| Registration / order | A learner signing up for a class |
| Learner / customer | A person taking a course |
| Roster / enrolments | The list of learners in a class |
| WSQ | Singapore government-funded training framework; `TGS-` SKUs |
| SkillsFuture Credit (SFC) | SG government training credit; claimed via a pro forma invoice |
| Baseline / MCES | The 50% / additional-20% components of WSQ subsidy |
| Pro forma invoice | A pre-payment invoice for self-sponsored SFC claims |
| GST | 9% Singapore tax, charged on the course *list* price |
