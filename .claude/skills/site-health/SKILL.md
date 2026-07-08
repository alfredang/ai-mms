---
name: site-health
description: Run the "anything broken?" sweep for the LMS — localhost Docker stack and/or production HTTP — and get a PASS/FAIL table. Use when asked to "check site health", "is anything broken", "smoke test", "verify localhost before push", after container restarts, after theme/CSS changes, or as the mandatory verification gate before the admin decides to push. Delegates to the site-health-checker agent.
---

# Site Health Check

1. Determine scope from the request: `localhost`, `prod`, or `both` (default: both if Docker is up, else prod-only).
2. Launch the **site-health-checker** agent (Agent tool, `subagent_type: site-health-checker`) with the scope and, if the check follows a specific change, the list of changed files so it weights the affected routes.
3. Relay the agent's PASS/FAIL table to the user verbatim, then add a one-paragraph verdict: **healthy** / **degraded (what + why)** / **broken (what to fix first)**.
4. If the check was requested as a pre-push gate and everything passes, remind the user: pushing to `main` deploys to production via Coolify — the ADMIN decides whether to push; do not push automatically. If anything fails, the push gate stays closed.
5. For failures, route the fix: styling → backend-design skill; caching/speed → caching-speed-optimizer agent; DB → mysql-memory-optimizer agent; security header/exposure → openmage-security-auditor agent; broken route/fatal → fix inline with the pre-push checklist from CLAUDE.md.

Frontend invariant: any change made in this repo must keep the customer-facing storefront looking IDENTICAL. If the health check follows storefront-adjacent edits (skin/frontend/**, app/design/frontend/**, layout XML), additionally screenshot the homepage + one course page with Playwright at 1440px and 390px widths and compare against `var/health-baseline/` screenshots (create them on first run) — flag any visual diff.
