---
name: trainer-profile
description: Write or fix a trainer profile (bio) on the storefront Trainers tab of a Tertiary Courses course page (SG / MY / GH). HARD RULE - every profile is exactly two paragraphs, at least 2000 characters, written for the course it sits on, with the course's SEO keywords embedded and the trainer's LinkedIn link at the end; the model is Dr. Alfred Ang's profile on wsq-agentic-ai-applications-with-claude-code. Use when asked to "write a trainer profile", "update the trainer bio", "the trainer profile is too short", "make the profile like the Claude Code course", "add a trainer to the Trainers tab", "follow the trainer profile skill", or whenever a course is created, repurposed or gets a new trainer. Includes trainer_bio.py, which checks the profile and emits the stored HTML.
---

# Trainer profile (storefront Trainers tab)

## The rule (user rule 2026-11-20, final version)

Every trainer profile shown on a course page:

- is **exactly two paragraphs**;
- is **at least 2000 characters in total** (2000 to 3600, each paragraph at least 800), counting spaces and links, not counting the name label;
- is **contextualised to the course**: it is written for this course and could not be pasted onto another one;
- **embeds the course's SEO keywords**;
- **ends with the trainer's LinkedIn profile link** (Dr. Alfred Ang: `https://www.linkedin.com/in/angchewhoe/`).

The model is Dr. Alfred Ang's profile on
https://www.tertiarycourses.com.sg/wsq-agentic-ai-applications-with-claude-code.html. A worked example for another
course is in `reference/model_profile.md`; read it before writing.

The rule covers every trainer on the Trainers tab, including a course's default (starred) trainer set on the LMS.
`trainer_bio.py` enforces it. A profile that fails the check is not finished.

## What goes in each paragraph

1. **Paragraph 1: the trainer's own work in this course's subject, then credentials.**
   - Open with how the trainer uses the course's subject in daily work.
   - Name real, checkable work that matches the course: public repositories, published apps, products, client projects. For Dr. Alfred Ang list his public GitHub repositories with `curl -s "https://api.github.com/users/alfredang/repos?per_page=100&page=N"` and pick the ones on the course's subject; say what each one does, from its repository description.
   - Then role and titles, degrees, publications and patents, and the certifications that fit the course.
2. **Paragraph 2: this course.**
   - Start "In this course, ..." and walk through the course's own topics in order (Topic 1 covers ..., Topic 2 ...), taken from the course description on the page (`LSN_DATA` topics).
   - Say what the trainer's own work lets them show learners in class.
   - Give the trainer qualification (ACTA / ACLP, DACE) and how the class runs.
   - End with the portfolio link if there is one, and the LinkedIn link last.

SEO keywords:

- Read them from the live page: `curl -s <course url> | grep -i '<meta name="keywords"'`.
- Use the topic phrases (for example "mobile app development", "iOS app development", "Android app development", "AI vibe coding", "mobile app development training", "Singapore") in natural sentences, each at least once. Strip the word "course" where it reads badly.
- Leave out the funding phrases (CASL, WSQ, SkillsFuture Credit, UTAP): funding is not a fact about the trainer.
- Pass the phrases to the checker with `--keywords=`.

Writing rules:

- Facts only from the trainer's existing profile (`courses_trainers.description`, `admin_user.trainer_description`), an approved profile on another course, their public GitHub or LinkedIn page, or the user. Old SG blobs hold conflicting years and certificates: leave a number out when sources disagree. Never pad to reach 2000 characters with invented experience; use the course topics and real work.
- Third person, plain sentences, plain ASCII, no HTML, no hype words (unlock, elevate, comprehensive, passionate, seasoned).
- Dr. Alfred Ang: state "a Claude Certified Architect and a Claude Certified Associate".
- Partner sites: no WSQ, IBF, CASL, SkillsFuture or Singapore funding words on MY / GH, and "Malaysia" / "Ghana" in place of "Singapore".

## Build and check

Write the two paragraphs to a text file with one blank line between them, then:

```bash
python3 ~/.claude/skills/trainer-profile/trainer_bio.py check bio.txt \
    --keywords="mobile app development,iOS app development,Android app development" \
    --linkedin=https://www.linkedin.com/in/angchewhoe/
python3 ~/.claude/skills/trainer-profile/trainer_bio.py html bio.txt "Dr. Alfred Ang" --keywords=... --linkedin=...
```

`html` prints the chunk to store:

```html
<p><strong data-course-bio>Name:</strong> paragraph one</p>

<p>paragraph two</p>
```

- **Keep the blank line between the two `<p>` blocks.** The Trainers tab (`catalog/product/view/trainers.phtml`) strips the tags and keeps the line breaks, so that blank line is the only thing that shows the paragraph gap. Without it the two paragraphs run together.
- `data-course-bio` makes this course's bio win over the trainer's shared profile. Use it on SG. On MY / GH use plain `<strong>` (add `--shared-profile`), because those sites have no matching shared profile row.
- Second paragraph must not contain `<strong>`: the template starts a new trainer at every `<strong>`.

## Catalogue rule: every WSQ course that lists Dr. Alfred Ang (user rule 2026-11-20)

On every enabled TGS- course (WSQ, CASL, IBF) where he is a trainer, his profile meets the standard above and ends with
his LinkedIn link. Audit: export the `trainerprofile` rows that contain "Alfred Ang", split each blob the way
`trainers.phtml` does (on `<strong>`), and flag his chunk when it is under 2000 characters, not two paragraphs, or does
not end with the LinkedIn link. Rewrite only the failures; leave a passing profile alone.

What hides or breaks a profile on the live page (check each after a rewrite):

- **Five-trainer cap.** Only the first five `<strong>` names render. A bolded phrase inside another trainer's bio (for
  example `<strong>A+, Network+, and Server+</strong>`) counts as a trainer and pushes real ones off the tab: unwrap it.
- **Leftover tail.** An old bio with a `<strong>` in the middle leaves its second half behind as a fake trainer after the
  swap. Delete the tail.
- **Store row override.** A store-1 row with a different trainer set shadows the store-0 row; a profile written to store
  0 then never shows. Read every store row before writing.
- When swapping one chunk, confirm by parsing the new blob: same other trainers, same order, their text unchanged, the
  rewritten trainer present once.

## Where it is stored

- Product attribute `trainerprofile` (id 153 on SG), table `catalog_product_entity_text`. One chunk per trainer, in display order, at most 5 trainers.
- Update every store row the course has (SG store 0 and sometimes 1; GH 0 and 3). The template prefers the store row.
- Replace only the one trainer's chunk; keep the other trainers' chunks in their order.

## Apply (data only, no migration, no push)

1. Read the current value and its `MD5(value)`.
2. Back up the row on the server: `/root/<site>_trainerprofile_backup_<date>_<sku>.sql.gz`.
3. `UPDATE ... SET value = CONVERT(FROM_BASE64('<b64>') USING utf8mb4) WHERE value_id = <id> AND MD5(value) = '<md5>'`; expect 1 row.
4. In the web container as `www-data`: `Mage::app()->cleanCache(array('catalog_product_<id>'))`, then clean cache types `block_html` and `full_page`.
5. Verify the rendered page with curl: the `tacc-body` holds the two paragraphs with `<br /><br />` between them, the links are clickable, and `tacc-name` lists the right trainers in the right order.

Saving the course in the Edit Course editor can drop the blank line; check the live page after any such save.

## Checklist

- [ ] `trainer_bio.py check` prints `OK` with `--keywords` and `--linkedin` (2 paragraphs, 2000-3600 characters)
- [ ] paragraph 1 names real work on the course's subject; paragraph 2 walks through this course's topics
- [ ] the course's SEO keywords appear; the LinkedIn link is last
- [ ] every fact has a source
- [ ] blank line between the two `<p>` blocks in the stored value
- [ ] every store row updated; other trainers untouched
- [ ] row backed up before the update
- [ ] live page checked with curl after the cache clean
