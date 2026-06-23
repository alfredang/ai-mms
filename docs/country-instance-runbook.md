# Country Instance Deployment Runbook

Operational guide for standing up any non-SG country instance of the MMS on its
own Coolify server. Written for Ghana (GH) as the pilot — substitute values for
MY / NG / BT / IN as needed.

Prerequisite reading: `docs/country-instance-deployment-implementation-plan.md`

---

## 1. Pre-flight checklist

Before touching Coolify, confirm these are in place:

- [ ] `seed/country-base.sql.gz` is current — see §2 for rebuild instructions.
- [ ] `compose.coolify.yml` is the compose file being deployed.
- [ ] `MMS_CRYPT_KEY` has been generated (`php -r "echo bin2hex(random_bytes(16));"`).
- [ ] `SG_SYNC_API_KEY` matches `mmd/course_sync/api_key` in SG's `core_config_data`.
- [ ] The country domain DNS is pointing at the target server (or you plan to set
  `MMS_BASE_URL` to the IP first, then switch to the domain).

---

## 2. Rebuild the seed (if needed)

The seed should be rebuilt when migrations have been added since the last seed commit.
Run on any machine with access to a recent SG production dump:

```bash
./scripts/provision/build-country-seed.sh /path/to/sg-dump.sql
# → writes seed/country-base.sql.gz
# All assertions must pass before committing.
git add seed/country-base.sql.gz
git commit -m "chore(seed): rebuild country-base.sql.gz (<N> migrations)"
git push
```

The seed contains **zero** business data and **zero** secrets — it is safe to commit.

---

## 3. Set up a new country in Coolify

### 3.1 Create the application

1. Log into the country's Coolify server.
2. **New Resource → Docker Compose**.
3. Source: **GitHub** → select the `ai-mms` repo → branch `main`.
4. Compose file: `compose.coolify.yml` (leave the file path field as `compose.coolify.yml`).
5. Click **Next** — do not deploy yet.

### 3.2 Set environment variables

In the Coolify "Environment Variables" tab, add every variable from
`.env.country.example`, substituting real values. Minimum required set:

| Variable | Example value |
|----------|--------------|
| `MMS_MODE` | `country` |
| `MMS_COUNTRY_CODE` | `GH` |
| `MMS_BASE_URL` | `https://ai-mms-gh.tertiaryinfo.tech/` |
| `MMS_ADMIN_FRONTNAME` | `tigerdragon` |
| `MMS_CRYPT_KEY` | *(generate: `php -r "echo bin2hex(random_bytes(16));"`)* |
| `MYSQL_ROOT_PASSWORD` | *(strong password)* |
| `MYSQL_DATABASE` | `mms_gh` |
| `MYSQL_USER` | `magento` |
| `MYSQL_PASSWORD` | *(strong password)* |
| `SG_SYNC_URL` | `https://ai-mms.tertiaryinfo.tech/` |
| `SG_SYNC_API_KEY` | *(matches SG's `mmd/course_sync/api_key`)* |

Leave `R2_*` variables blank — country instances use local-disk media.

### 3.3 Configure persistent volumes

In the Coolify "Persistent Storage" or "Volumes" tab, ensure these volumes are attached:

| Compose volume | Mount path | Notes |
|---------------|-----------|-------|
| `mysql_data` | `/var/lib/mysql` | DB data — **never delete** |
| `media` | `/var/www/html/media` | ALL instance media (course covers, uploads, email logo) |

### 3.4 Configure auto-deploy via the Coolify GitHub App source

Don't use a manually-pasted GitHub webhook — it requires repo-admin access on
GitHub every time, and Coolify already has a self-managing alternative.

1. In Coolify, open the application → **Configuration → Git Source**.
2. Under **Change Git Source**, select the existing GitHub App source (e.g.
   `ai-mms-gh`, listed under "Personal Account") instead of "Public GitHub".
3. Click **Save**.
4. Open the **Webhooks** tab to confirm — it should say *"You are using an
   official Git App. You do not need manual webhooks."* If you still see a
   manual "Deploy Webhook URL" prompt instead, the source switch didn't take;
   re-check step 2.

Now every push to `main` redeploys **both** SG and this country instance
automatically — no GitHub Settings → Webhooks entry needed at all.

### 3.5 First deploy

1. Click **Deploy** in Coolify.
2. Watch the build logs:
   - `generate-local-xml: generated .../local.xml` — local.xml was created from env.
   - `generate-local-xml: *** WARNING — generated new crypt key ***` — note the printed
     key and **immediately** add it as `MMS_CRYPT_KEY` in Coolify env (redeploy to lock it).
   - `applying: NNN-*.sql ... OK` — migrations applied.
   - `Apache ready.` — app is up.
3. Hit the admin URL: `https://<domain>/tigerdragon/` — confirm the login page loads.
4. Check `/version.txt` for the build timestamp.

---

## 4. Post-deploy: first-time setup

### 4a. Pin the crypt key

If the first deploy printed a new crypt key (warning message in logs):

1. Copy the key from the build log.
2. Add `MMS_CRYPT_KEY=<that-key>` to Coolify env.
3. Redeploy — the key is now stable across future deploys.

### 4b. Rotate the seed admin password

The seed ships a default admin account. Change its password immediately:

1. Admin → System → Configuration → Advanced → Admin → Security → set a new password
   (or use the admin user edit grid).

### 4c. Create real admin users

Admin → Role Management → Create User — add the Ghana team's accounts with the
`admin` or `marketing` role as appropriate.

### 4d. Sync courses from SG

1. Admin → Manage Courses → **Sync Courses from SG** button.
2. Wait for the run to complete — the status card shows fetched / created / updated /
   disabled / skipped / errors.
3. Spot-check several C-courses: name, description, category, image.
4. Confirm images are served from the instance's own domain (no `r2.dev` or SG URLs).

### 4e. Optionally enable the daily sync cron

On the same Manage Courses panel, toggle the **Auto-sync daily** pill to ON.
This enables a daily 03:00 SGT cron that re-syncs all C-courses from SG.
Leave it OFF if you prefer manual control.

---

## 5. Validation checklist

Run through this after the first full deploy and after any major change:

### 5a. Fresh-volume boot

```bash
# Destroy volumes and redeploy — confirms seed + migrations work from scratch.
# WARNING: this wipes the DB.
docker compose -f compose.coolify.yml -f compose.coolify.local-test.yml \
  --env-file .env.gh -p ai-mms-gh down -v
docker compose -f compose.coolify.yml -f compose.coolify.local-test.yml \
  --env-file .env.gh -p ai-mms-gh up -d --build
```

After boot: admin loads, no fatals, `/version.txt` has the correct timestamp.

### 5b. No-secrets audit

```bash
CONTAINER=ai-mms-gh-db-1
docker exec "$CONTAINER" mysql -umagento -p<pass> mms_gh \
  -e "SELECT path FROM core_config_data WHERE path LIKE '%api_key%'
      OR path LIKE '%oauth%' OR path LIKE 'smtppro/%' OR path LIKE '%client_secret%';"
# Expected: empty result set
```

### 5c. No-data audit (before first sync)

```bash
CONTAINER=ai-mms-gh-db-1
docker exec "$CONTAINER" mysql -umagento -p<pass> mms_gh \
  -e "SELECT 'products', COUNT(*) FROM catalog_product_entity
      UNION ALL SELECT 'customers', COUNT(*) FROM customer_entity
      UNION ALL SELECT 'orders', COUNT(*) FROM sales_flat_order
      UNION ALL SELECT 'classes', COUNT(*) FROM course_runs;"
# Expected: 0, 0, 0, 0
```

### 5d. Sync correctness

Pick three C-courses from SG and verify field-by-field on the country instance:
- Name, short description, price matches SG (price was set on first import).
- Category assignment matches.
- `course_image_url` is an instance-relative URL (no `r2.dev` / SG domain).
- Image loads correctly in the browser.

### 5e. Safety invariant

Create a local course with a `GH`-prefix SKU (e.g. `GH-TEST-001`). Run the sync
twice. Confirm the local course is untouched after both runs and the sync count
is stable (idempotent — same created/updated/skipped counts on run 2).

### 5f. Mode isolation

Verify these behaviours on the country instance:
- The SG export endpoint (`/sync/courses-export`) returns 403 or 404.
- Trying to create a course with a `C`-prefix SKU shows an error.
- The SkillsFuture / WSQ funding tiles are hidden.
- The store view bar shows only SG + the instance's own country.

### 5g. Auto-deploy

Push a trivial change to `main` (e.g. update a comment). Confirm:
- Both SG and the country Coolify trigger a rebuild.
- Both show the new `/version.txt` timestamp after the build completes.

---

## 6. Fleet rollout — adding more countries

Repeat §3 and §4 for each new country, substituting:

| Country | `MMS_COUNTRY_CODE` | `MYSQL_DATABASE` | Domain example |
|---------|-------------------|-----------------|---------------|
| Ghana | `GH` | `mms_gh` | `ai-mms-gh.tertiaryinfo.tech` |
| Malaysia | `MY` | `mms_my` | `ai-mms-my.tertiaryinfo.tech` |
| Nigeria | `NG` | `mms_ng` | `ai-mms-ng.tertiaryinfo.tech` |
| Bhutan | `BT` | `mms_bt` | `ai-mms-bt.tertiaryinfo.tech` |
| India | `IN` | `mms_in` | `ai-mms-in.tertiaryinfo.tech` |

Each country gets its **own** Coolify application, its **own** MySQL volume, and
its **own** `MMS_CRYPT_KEY`. They share the same repo + `main` branch and the
same `compose.coolify.yml`.

---

## 7. Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Admin shows "Please wait, loading..." indefinitely | Redis session not connecting | Check `redis` container is healthy; confirm `Cm_RedisSession.xml` is active |
| `local.xml` error on boot | `generate-local-xml.sh` can't find required env | Check `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD` are set in Coolify |
| Images don't load after sync | `course_image_url` still pointing at SG/R2 | Re-run sync; confirm `MMS_MODE=country` is set so `LocalDisk` driver is used |
| `apply.php` fails: `error 1366 Incorrect string value` | Invalid UTF-8 bytes in migration data | See CLAUDE.md "Pre-push verification" — filter with `WHERE LENGTH(col) = CHAR_LENGTH(col)` |
| Crypt key changes after redeploy | `MMS_CRYPT_KEY` not pinned, `media` volume recreated | Pin the key in Coolify env; ensure `media` volume is persistent and never deleted |
| Sync: "API key invalid" | `SG_SYNC_API_KEY` doesn't match SG's `mmd/course_sync/api_key` | Update the key on either end to match |
| Store bar shows all 6 countries | `MMS_MODE` or `MMS_COUNTRY_CODE` not set | Add both env vars in Coolify and redeploy |
| Webhook not firing | GitHub webhook URL expired or misconfigured | Regenerate from Coolify Webhooks tab and re-add to GitHub |

---

## 8. Reference

- Implementation plan: `docs/country-instance-deployment-implementation-plan.md`
- Env template: `.env.country.example`
- Compose stack: `compose.coolify.yml`
- Seed builder: `scripts/provision/build-country-seed.sh`
- Seed file: `seed/country-base.sql.gz`
- CLAUDE.md pre-push protocol: `CLAUDE.md` → "Pre-push verification"
