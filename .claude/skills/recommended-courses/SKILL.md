---
name: recommended-courses
description: Ensure every SG course (WSQ TGS- and non-WSQ C-) shows at least 5 "Recommended Courses" on its product page, topping up any shortfall with related WSQ courses. Use when the user says "recommended courses", "related courses", "upsell", "make sure courses have 5 recommendations", "the recommended courses section is empty/short", "add related courses", or after bulk-importing/enabling courses that may lack upsells. SG production only (partner sites are a no-op).
---

# Recommended Courses (upsell) top-up

Guarantee the storefront **"Recommended Courses"** rail on every SG course page
renders **at least 5** courses, filling any shortfall with **related WSQ
courses**. This is a data-only operation on the SG catalog — no code, no
migration.

## What the rail actually is (read first)

- The "Recommended Courses" rail = the product's **Upsell** links.
- Storage: `catalog_product_link` with `link_type_id = 4` (`up_sell`).
  Position lives in `catalog_product_link_attribute_int`, attribute id `4`.
- The storefront **only renders links whose target is enabled + catalog/search
  visible**. A link to a disabled/deleted product is invisible and does **not**
  count toward the 5. So "how many recommendations does this course show" =
  count of upsell links whose target is currently enabled + visible — never the
  raw `catalog_product_link` row count.
- It is NOT the Related-products (`link_type_id = 1`) or Cross-sell (`5`) rail.
  Do not confuse them.

## The invariant

Every **SG course** — SKU starts with `TGS-` (WSQ) **or** `C` (non-WSQ) —
enabled and visible, has **≥ 5 valid upsell links**. Shortfalls are topped up to
**exactly 5** with **related WSQ (`TGS-`) courses only** (per the standing
requirement — WSQ courses are the fill source, never non-WSQ, never M-prefix).

## The tool

`scripts/maintenance/backfill-course-upsells.php` does the whole thing and is the
canonical implementation. Reuse it — do not hand-write ad-hoc SQL.

What it does, per SG course with `< 5` valid upsells:
1. Compute `need = 5 - validCount` (valid = existing link target enabled+visible).
2. Build a WSQ candidate pool sharing the course's categories, **excluding self
   and already-linked**.
3. Rank: **# shared direct categories desc → review count desc → entity_id asc**
   (most on-topic, then most popular, then deterministic).
4. If the direct-category pool can't supply `need`, **broaden** to the parent
   (ancestor) categories — excluding the root (1) and store-root (2).
5. Append the top `need` as upsell links with position after the existing ones.
   Existing links are never removed or reordered.

Safety properties:
- **Dry-run by default**; `--commit` writes then flushes `block_html` + FPC.
- **Idempotent**: unique key `(link_type_id, product_id, linked_product_id)` +
  `INSERT IGNORE`; re-runs only fill whatever is still short.
- **SG-only by construction**: it only ever *adds* `TGS-` courses, so on a
  partner DB (MY/GH, no WSQ) the candidate pool is empty and it's a pure no-op.
  This is why it's a **one-shot maintenance script, not a repo migration** — run
  it on the SG server only.

## Run it (local first, then prod SG)

### 1. Verify locally (dev container)

```bash
docker exec ai-mms-web-1 php -l /var/www/html/scripts/maintenance/backfill-course-upsells.php
docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/backfill-course-upsells.php     # dry run
```
Note: the local `courses_backupDB` still carries M-prefix products as visible;
prod SG does not — so local counts differ from prod. Local is only for proving
the script runs, not for the real scope.

### 2. Dry-run on prod SG (read-only, safe)

Prod SG DB is `default` in the mysql8 container; the web container name **changes
every deploy** — find it by its `com.sg` Traefik label. SSH creds are in `.env`
under `# SG SSH` (`root@76.13.180.29`). See memory `reference_sg_server_access`.

```bash
export SSHPASS='<SG password from .env>'
# discover the ai-mms web container
WEB=$(sshpass -e ssh -o StrictHostKeyChecking=no root@76.13.180.29 \
  "for c in \$(docker ps --format '{{.Names}}'); do \
     docker inspect \$c --format '{{json .Config.Labels}}' 2>/dev/null \
       | grep -qi 'tertiarycourses.com.sg' && echo \$c; done")
# copy the script into the container's webroot (relative require needs the real path)
sshpass -e scp -o StrictHostKeyChecking=no \
  scripts/maintenance/backfill-course-upsells.php root@76.13.180.29:/tmp/bcu.php
sshpass -e ssh -o StrictHostKeyChecking=no root@76.13.180.29 \
  "docker cp /tmp/bcu.php ${WEB}:/var/www/html/scripts/maintenance/backfill-course-upsells.php && \
   docker exec ${WEB} php /var/www/html/scripts/maintenance/backfill-course-upsells.php"   # dry run
```

Report the scope (how many courses short, how many links to add, any "still
short" thin-category cases) to the user before writing.

### 3. Commit on prod SG

```bash
sshpass -e ssh -o StrictHostKeyChecking=no root@76.13.180.29 \
  "docker exec ${WEB} php /var/www/html/scripts/maintenance/backfill-course-upsells.php --commit"
```
`--commit` flushes `block_html` + FPC. Add `--no-flush` to skip and flush later.

### 4. Verify

```bash
# idempotency: should print "SG courses short of 5: 0"
sshpass -e ssh -o StrictHostKeyChecking=no root@76.13.180.29 \
  "docker exec ${WEB} php /var/www/html/scripts/maintenance/backfill-course-upsells.php" | grep 'short of'
# live page: fetch a fixed course and confirm 5 tiles render in the rail
curl -sS -A Mozilla/5.0 '<course url>' -o /tmp/c.html -w 'HTTP=%{http_code}\n'
```

Finally `rm -f /tmp/bcu.php` on the SG host. The docker-cp'd copy in the
container vanishes on the next redeploy — that's fine, the links persist in the
DB.

## Do NOT

- Do not write this as a `migrations/NNN-*.sql` — it would run on every partner
  server, and hardcoded entity_ids don't port across DBs. The script resolves
  everything live by SKU/category on whatever DB it runs on.
- Do not add non-WSQ or M-prefix courses as the fill. WSQ (`TGS-`) only.
- Do not remove or reorder a course's existing upsells.
- Do not count raw `catalog_product_link` rows — count only links whose target
  is enabled + visible.

See memory `reference_recommended_courses_upsell_backfill`,
`reference_sg_server_access`, `reference_wsq_course_tgs_sku`.
