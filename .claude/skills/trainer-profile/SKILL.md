---
name: trainer-profile
description: Write or fix a trainer profile (bio) on the storefront Trainers tab of a Tertiary Courses course page (SG / MY / GH). HARD RULE - every profile is exactly two paragraphs and about 500 characters in total. Use when asked to "write a trainer profile", "update the trainer bio", "shorten the trainer profile", "the trainer profile is too long", "add a trainer to the Trainers tab", "follow the trainer profile skill", or whenever a course is created, repurposed or gets a new trainer. Includes trainer_bio.py, which checks the length and emits the stored HTML.
---

# Trainer profile (storefront Trainers tab)

## The rule (user rule 2026-11-20)

Every trainer profile shown on a course page is:

- **exactly two paragraphs**;
- **about 500 characters in total**: 450 to 550, counting spaces and the LinkedIn line, not counting the name label.

`trainer_bio.py check` enforces both. A profile that fails the check is not finished.

## What goes in each paragraph

1. **Paragraph 1: the trainer and this course.** Who they are (current role, what they do every day) and what they teach in this course, in the course's own words.
2. **Paragraph 2: credentials.** Degree, certifications and trainer qualification that matter for this course. Dr. Alfred Ang's profile ends with `Connect with Dr. Alfred Ang on LinkedIn at https://www.linkedin.com/in/angchewhoe/`.

Writing rules:

- Facts only from the trainer's existing profile (`courses_trainers.description`, `admin_user.trainer_description`), their LinkedIn page or the user. Old SG blobs hold conflicting years and certificates: leave a number out when sources disagree.
- Third person, plain sentences, plain ASCII, no HTML, no hype words (unlock, elevate, comprehensive, passionate, seasoned).
- Pick the two or three credentials that fit the course. Do not list every title.
- Dr. Alfred Ang on a Claude course: state "a Claude Certified Architect and a Claude Certified Associate".
- Partner sites: no WSQ, IBF, SkillsFuture or Singapore funding words on MY / GH.

## Build and check

Write the two paragraphs to a text file with one blank line between them, then:

```bash
python3 ~/.claude/skills/trainer-profile/trainer_bio.py check bio.txt
python3 ~/.claude/skills/trainer-profile/trainer_bio.py html  bio.txt "Dr. Alfred Ang"
```

`html` prints the chunk to store:

```html
<p><strong data-course-bio>Name:</strong> paragraph one</p>

<p>paragraph two</p>
```

- **Keep the blank line between the two `<p>` blocks.** The Trainers tab (`catalog/product/view/trainers.phtml`) strips the tags and keeps the line breaks, so that blank line is the only thing that shows the paragraph gap. Without it the two paragraphs run together.
- `data-course-bio` makes this course's bio win over the trainer's shared profile. Use it on SG. On MY / GH use plain `<strong>` (add `--shared-profile`), because those sites have no matching shared profile row.
- Second paragraph must not contain `<strong>`: the template starts a new trainer at every `<strong>`.

## Where it is stored

- Product attribute `trainerprofile` (id 153 on SG), table `catalog_product_entity_text`. One chunk per trainer, in display order, at most 5 trainers.
- Update every store row the course has (SG store 0 and sometimes 1; GH 0 and 3). The template prefers the store row.
- Replace only the one trainer's chunk; keep the other trainers' chunks in their order.

## Apply (data only, no migration, no push)

1. Read the current value and its `MD5(value)`.
2. Back up the row on the server: `/root/<site>_trainerprofile_backup_<date>_<sku>.sql.gz`.
3. `UPDATE ... SET value = CONVERT(FROM_BASE64('<b64>') USING utf8mb4) WHERE value_id = <id> AND MD5(value) = '<md5>'`; expect 1 row.
4. In the web container as `www-data`: `Mage::app()->cleanCache(array('catalog_product_<id>'))`, then clean cache types `block_html` and `full_page`.
5. Verify the rendered page with curl: the `tacc-body` holds the two paragraphs with `<br /><br />` between them, and `tacc-name` lists the right trainers in the right order.

Saving the course in the Edit Course editor can drop the blank line; check the live page after any such save.

## Checklist

- [ ] `trainer_bio.py check` prints `OK` (2 paragraphs, 450-550 characters)
- [ ] every fact has a source
- [ ] blank line between the two `<p>` blocks in the stored value
- [ ] every store row updated; other trainers untouched
- [ ] row backed up before the update
- [ ] live page checked with curl after the cache clean
