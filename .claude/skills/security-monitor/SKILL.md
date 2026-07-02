---
name: security-monitor
description: Daily security monitoring runbook for the Tertiary Courses LMS (runs scheduled at 7am, or on demand via /security-monitor). Checks production HTTP security posture across all 6 country domains, exposed-file probes, SSL expiry, admin login surface, suspicious DB signals, and diffs the repo for newly introduced risky patterns. Writes a dated report to var/security-reports/ and raises an admin notification on CRITICAL findings. Use when asked to "run the security monitor", "daily security check", "morning security sweep", or by the scheduled job.
---

# Daily Security Monitor

Read-only sweep + report. NEVER modify production, never attempt logins, never run exploits. Everything here is observation. Total budget: keep it under ~10 minutes of work; this runs unattended every morning.

## 1. Production HTTP posture (all 6 domains)

Domains: `www.tertiarycourses.com.sg`, `www.tertiarycourses.com.my`, `www.tertiarycourses.com.ng`, `www.tertiarycourses.com.gh`, `www.tertiarycourses.bt`, `www.tertiarycourses.co.in`, plus admin host `www.tertiaryinfotech.edu.sg`.

Per domain:
- `curl -sI https://<host>/` → record HTTP status and presence of: `Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options` (or CSP `frame-ancestors`), `Referrer-Policy`. Missing header = MEDIUM finding (compare to yesterday's report — only escalate on regression).
- SSL expiry: `echo | openssl s_client -servername <host> -connect <host>:443 2>/dev/null | openssl x509 -noout -enddate`. < 21 days = HIGH, < 7 days = CRITICAL.

## 2. Exposed-file probes (SG + admin host)

Each of these must NOT return 200 with real content (200 = CRITICAL):
```
/app/etc/local.xml  /.env  /.git/config  /.git/HEAD  /composer.json  /composer.lock
/var/log/system.log  /var/log/exception.log  /downloader/  /RELEASE_NOTES.txt
/errors/local.xml  /phpinfo.php  /info.php  /media/migrations-status.json (200 OK is EXPECTED for this one — check it shows no failures instead)
```
Also confirm `/tigerdragon/` (admin) still serves the login page (200, has password field) and that `/admin` and `/index.php/admin` do NOT reveal a second admin route.

## 3. Repo drift since last run

- `git -C /Users/alfredang/projects/tertiary/ai-mms log --since=yesterday --oneline` — list new commits.
- If there are new commits, grep the diff for risky patterns:
  `git diff <last-report-commit>..HEAD -- '*.php' '*.phtml'` piped through checks for: `eval(`, `base64_decode(`, `system(`, `exec(`, `shell_exec(`, `$_GET`/`$_POST` concatenated into SQL, `echo $this->` without `escapeHtml`, new file-upload handling, hardcoded credentials/API keys (`sk_live`, `AKIA`, `password =`).
- Any hit → launch the `openmage-security-auditor` agent scoped to those files for a proper verdict; don't raw-report grep noise.

## 4. Local DB signals (only if local Docker is up — skip silently otherwise)

Read-only queries via `docker exec ai-mms-db_mysql-1`:
- New admin users in 24h: `SELECT username,email,created FROM admin_user WHERE created > NOW() - INTERVAL 1 DAY` — any row not explainable by the learner shadow-account sync (MMD_AccountSync creates `is_active=0` learner rows; those are expected) = HIGH.
- Admin role escalations: rows in `mmd_user_role_map` created in 24h with role_code IN ('admin','super_admin','developer').
- `api_user` table changes.

## 5. Report + alert

1. Write the report to `var/security-reports/security-YYYY-MM-DD.md` (repo `var/` is gitignored). Format: **Status: GREEN/AMBER/RED** headline, then a per-check table (check | result | delta vs yesterday), then findings with severity.
2. Compare with the previous report file (if present) and lead with what CHANGED — an unchanged missing-header should be one line, not a daily wall of text.
3. On any CRITICAL: insert a Critical row into `adminnotification_inbox` (reuse the pattern in `.claude/hooks/verify-leads-capture.sh` — dedup before insert) so operators see a banner, and use the PushNotification tool to alert the user.
4. NEVER auto-fix, never push, never restart anything. This skill observes and reports; remediation is a human-approved follow-up.
