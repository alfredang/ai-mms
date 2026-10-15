---
description: Publish a training-course repository to GitHub with a learner-facing courseware README (hero + registration link, outcomes, topics/labs, repository structure, course details, contact), verified GitHub About metadata, and a secure push that never exposes assessments or answer keys.
argument-hint: "[optional: non-WSQ repo URL, or 'pr' to open a pull request]"
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, AskUserQuestion, Skill
---

# /github-push-course — publish a course repo with the courseware README

Load and follow the **`github-push-course`** skill — it owns the authoritative
procedure (course facts, README standard, GitHub About, public boundary, commit/push
verification). This command is the invocation plus the **courseware README structure**
the repo must end up with.

**Arguments:** `$ARGUMENTS` — an optional destination repo URL (used when publishing a
newly converted non-WSQ twin), or `pr` to open a pull request instead of pushing to the
active branch.

This is a **course** workflow. Do not invoke or modify the general `github-push` skill.
An explicit invocation authorizes the README, About-metadata, commit and push for
*this* course repo — it does not authorize publishing assessments, answer keys,
credentials, private build tooling or unrelated local changes.

## 1. Establish the course facts — never invent one

Resolve from the repo's own authoritative courseware before writing: exact course title
and code; **WSQ or non-WSQ** status; duration (days + hours); the canonical
registration URL; course purpose; learning outcomes; topics/modules; the real
`labs/` or `activities/` names; courseware version.

Source precedence: an explicit user-provided value → the official course page →
`course_data.py` / Learner Guide / Lesson Plan → the legacy README. If a fact is not
available from those, **ask — do not fill the gap**.

**Verify the registration link returns 200 before using it.** It is the course's own
deep link on `www.tertiarycourses.com.sg`, never the bare domain:

```bash
curl -s -o /dev/null -w '%{http_code}\n' -L "<registration-url>"
```

Resolve it **once** here — the same verified URL is reused as the repo homepage in §4.

Funding is time-sensitive: re-verify it against the current official course page on
every run, state it as `up to N%` with a short eligibility/terms disclaimer, and
**omit it entirely** if the page does not currently support the claim. For a **non-WSQ**
course there is no WSQ funding, no TSC code and no assessment — leave those rows out
rather than writing "N/A".

## 2. Write README.md to the courseware structure

The README is the course's public landing page, not a developer readme. Clean, visual,
GitHub-flavoured Markdown, every path and link real:

- **Centred hero** — course badge/emoji, the **course title** as H1, a one-line hook,
  and a row of shields.io badges (a **Register** badge linking to the verified URL,
  plus duration, level, lab count, and — WSQ only — funding, TSC code, assessment
  type). Follow the badges with a bold **[📝 Register for this course →](<url>)** line.
- **Course detail table** — code, programme (WSQ / non-WSQ), duration, registration
  link, funding (when verified).
- **About This Course** — 2–3 sentences: what it covers and who it is for.
- **Learning Outcomes** — a table (LO1…LOn), taken **verbatim** from the courseware.
- **Course Topics & Labs** — a table mapping each topic to its labs, one linked entry
  per lab, noting each lab has its own folder. Use whichever of *Labs* / *Activities*
  the course actually uses.
- **Tools** — installed tools and interactive/browser practice tools, as tables with
  clickable links.
- **Repository Structure** — a tree, with an explicit note that the confidential
  `assessment/` folder is **not** in the repo.
- **Course Details** — title, course code, TSC (WSQ only), duration, level, assessment
  (WSQ only), mode, certification, provider — plus a Funding blurb linking to the
  registration page when applicable.
- **Building the Courseware** — the single-source build command(s).
- **Contact** — website (the registration deep link), email, tel, LMS/TMS.
- **Footer** — a closing centred **Register** call-to-action and
  `© <year> Tertiary Infotech Academy Pte Ltd · UEN 201200696W`.

**The registration link must appear at the top and at the bottom.** A course README
without a working, verified-200 registration link is incomplete — do not finish.

Keep procedures in the Learner Guide and the lab files; do not expand step-by-step
instructions into the README. No website screenshots, no GitHub Pages section, no app
setup, no technology badges — this repo has no web UI.

## 3. Protect the public boundary — before staging

Inspect `git status`, `.gitignore`, the tracked files and the exact diff. Normally
exclude:

```text
.env / .env.*        .claude/        .codex/
assessment/          reference/      answer keys
credentials, tokens, connection strings
build-only assets, archives, QA renders
source-wsq/          (a converted non-WSQ repo must never carry the WSQ source)
```

Scan every candidate and staged file for private keys, API tokens, credentials and
sensitive filenames. On any hit — or any assessment artifact — **stop and report
`file:line`; do not commit or push**.

Stage **named public files only**. Never `git add .` or `git add -A`. Preserve
unrelated user changes.

## 4. Commit, push, verify

Confirm the remote is the **intended course repo** before the first push — for a
converted non-WSQ course, `origin` must be the non-WSQ repo, never the TGS remote:

```bash
git remote -v
gh repo view OWNER/REPO --json description,homepageUrl,repositoryTopics,hasDiscussionsEnabled
```

If the remote is non-empty and holds a **different** course, stop and ask whether to
replace `main`, push a branch, or use another repo. Never force-push on your own
judgement; when the user does confirm a replacement, use
`--force-with-lease=<branch>:<verified-remote-sha>`.

```bash
git status --short
git diff -- <candidate files>
git add <specific public files>
git diff --cached --check
git diff --cached --stat
git commit -m "docs: standardize course repository details"
git push origin <active-branch>          # do NOT assume the branch is main
```

Then set GitHub About and read it back:

- **Description** — short, plain-language, the actual course: WSQ/non-WSQ, title or
  subject, code where space permits, duration, practical format. No long URL.
- **Homepage** — the exact verified registration URL from §1.
- **Topics** — a small accurate set (`wsq` or `courseware`, the subject, the real lab
  technologies). Remove stale topics from older repo content; keep an existing topic
  only while it is still accurate.
- **Discussions** — enable unless the user says not to.

Confirm local `HEAD` equals the remote branch SHA. The run succeeds only when the
README, homepage registration link, description, topics, Discussions setting and the
remote commit are **all verified**.

## 5. Report

Repository URL, branch and commit SHA; README sections added/updated; the verified
registration URL; About description / homepage / topics / Discussions; the
security-scan result; and every file deliberately excluded as private. State plainly
if any requested change could not be verified.
