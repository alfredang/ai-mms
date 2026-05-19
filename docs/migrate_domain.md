# Migrate / Point a Domain to a Magento Store on Coolify

How to wire a new domain (registered externally) to an existing Magento store served by the Coolify-hosted app. Worked example: `www.tertiarycourses.com.ng` → Nigeria store.

Reference store/domain already wired this way: `www.tertiaryinfotech.edu.sg` → Infotech store.

---

## Step 1 — Add external domain to Hostinger

In Hostinger control panel → **Domains → Domain portfolio** → scroll to **External domains** → **Add external domain** → enter the domain (e.g. `tertiarycourses.com.ng`).

This registers the domain in your Hostinger account so its DNS editor and zone become available.

> **Note:** Hostinger may take a few hours to provision the DNS zone after this step. If the DNS editor returns "Domain not found" when adding records, wait 2–24 h and retry. Verify the zone exists with:
> ```bash
> dig SOA <domain> @helios.dns-parking.com +short
> ```
> A response containing `dns.hostinger.com` means the zone is live on Hostinger's NS.

---

## Step 2 — Point the domain's nameservers to Hostinger

At the **registrar** where the domain is registered (NOT Hostinger), change nameservers to:

```
helios.dns-parking.com
aster.dns-parking.com
```

Verify propagation:

```bash
dig NS <domain> +short
# expect: helios.dns-parking.com. / aster.dns-parking.com.
```

NS propagation usually takes 15 min – 24 h depending on the registrar.

---

## Step 3 — Set up A records in Hostinger DNS

Find the Coolify server IP (same server already hosts other domains on this app):

```bash
dig +short ai-mms.tertiaryinfo.tech
# → 76.13.180.29
```

In **Hostinger → Domains → Domain portfolio → External domains → Manage DNS** for the new domain, add:

| Type | Name | Points to     | TTL   |
|------|------|---------------|-------|
| A    | `@`  | `76.13.180.29`| 14400 |
| A    | `www`| `76.13.180.29`| 14400 |

Use TTL `300` while testing, raise to `14400` once stable.

Verify:

```bash
dig +short www.<domain>
dig +short <domain>
# both should return 76.13.180.29
```

---

## Step 4 — Add domain to Coolify and redeploy

In Coolify → app → **Configuration → General → Domains**, append (comma-separated, no spaces):

```
https://<domain>,https://www.<domain>
```

Direction: **Allow www & non-www** (already set on this app). Click **Save**, then **Redeploy** (only after DNS resolves, otherwise Let's Encrypt cert issuance will fail).

Traefik will request Let's Encrypt certs automatically on redeploy. Watch Coolify logs for cert issuance.

Verify:

```bash
curl -I https://www.<domain>/
# expect: HTTP/2 200 with valid cert
```

---

## Step 5 — Magento-side wiring (code + DB)

Steps 1–4 get traffic to the server. To make Magento serve the **correct store** for the new host, two more changes are needed:

### 5a. `.htaccess` host → store mapping

Add to `.htaccess` (mirrors the existing Infotech block at lines 17–25):

```apache
## <domain> → <Store Name> store view
SetEnvIf Host ^(www\.)?<domain-escaped>$ MAGE_RUN_CODE=<store_code>
SetEnvIf Host ^(www\.)?<domain-escaped>$ MAGE_RUN_TYPE=store

## Redirect non-www to www
RewriteCond %{HTTP_HOST} ^<domain-escaped>$ [NC]
RewriteRule ^(.*)$ https://www.<domain>/$1 [L,R=301]
```

Where:
- `<domain-escaped>` = domain with dots escaped (e.g. `tertiarycourses\.com\.ng`)
- `<store_code>` = the Magento Store View code from **System → Manage Stores** (e.g. `nigeria`, `infotech`)

### 5b. Set base URLs in DB (via migration)

Create `migrations/0XX-set-<storecode>-store-base-url.sql`:

```sql
-- Set base URLs for <Store Name> store view
-- Auto-resolves store_id via core_store.code lookup.
INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/unsecure/base_url', 'https://www.<domain>/'
FROM core_store s WHERE s.code = '<store_code>'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/base_url', 'https://www.<domain>/'
FROM core_store s WHERE s.code = '<store_code>'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/use_in_frontend', '1'
FROM core_store s WHERE s.code = '<store_code>'
ON DUPLICATE KEY UPDATE value = VALUES(value);
```

The migration auto-applies on the next deploy via `docker/entrypoint.sh` → `migrations/apply.php`.

### 5c. Commit & push

```bash
git add .htaccess migrations/0XX-set-<storecode>-store-base-url.sql
git commit -m "Wire www.<domain> to <Store Name> store"
git push origin main
```

GitHub Actions triggers a Coolify rebuild.

### 5d. Post-deploy flush cache

Admin → **System → Cache Management → Flush Magento Cache**.

---

## Verification checklist

- [ ] `dig NS <domain>` → Hostinger nameservers
- [ ] `dig +short www.<domain>` → `76.13.180.29`
- [ ] `curl -I https://www.<domain>/` → 200 OK, valid cert
- [ ] Browser loads the **correct store** (catalog, theme, currency) — not the Singapore default
- [ ] `/version.txt` shows the new build
- [ ] `/media/migrations-status.json` count went up by 1

---

## Rollback

- DNS: remove A records in Hostinger.
- Coolify: remove the domain entries from the Domains field, redeploy.
- Magento: revert the `.htaccess` block. Migration row can stay (idempotent) or be deleted with a follow-up SQL migration.

---

## Worked example — Nigeria (commit `95b89a87`)

| Item | Value |
|------|-------|
| Domain | `www.tertiarycourses.com.ng` |
| Registrar | External (.com.ng) |
| Nameservers | `helios.dns-parking.com`, `aster.dns-parking.com` (Hostinger) |
| Server IP | `76.13.180.29` |
| Magento Website / Store / View code | `nigeria` / `nigeria` / `nigeria` |
| `.htaccess` block | [.htaccess:27-34](../.htaccess#L27-L34) |
| Migration | [migrations/059-set-nigeria-store-base-url.sql](../migrations/059-set-nigeria-store-base-url.sql) |
