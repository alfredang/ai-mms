#!/usr/bin/env bash
# HARD RULE (user rule 2026-11-20): every active (enabled) course allows registration.
#
# Static guardrail: fail if storefront code closes registration for a course in
# any way other than the course being disabled. The availability gate removed on
# 2026-11-20 (commit 2982e739b) closed registration on enabled courses whenever
# TMS reported no future SkillsFuture run; this stops it, or anything like it,
# coming back. The push gate (.claude/hooks/git-push-gate.sh) runs this.
#
# Usage: scripts/audit/check-registration-open.sh   (exit 0 = clean, 1 = a gate was found)
# A deliberate, reviewed exception carries the comment  registration-gate-allow  on the same line.
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2

PATTERN='isRegistrationOpen|getAvailabilityMessage|setIsSalable\(\s*(false|0)\s*\)|catalog_product_is_salable_after|Registration (is )?(temporarily unavailable|closed)|temporarily unavailable for registration|course-availability-notice'

hits=$(grep -rnIE "$PATTERN" app/code/local app/code/community app/design/frontend app/design/adminhtml/default/default/template skin/frontend js 2>/dev/null \
  --include='*.php' --include='*.phtml' --include='*.xml' --include='*.js' \
  | grep -v 'registration-gate-allow' || true)

if [ -n "$hits" ]; then
  echo "REGISTRATION GATE FOUND (an enabled course must always allow registration):" >&2
  echo "$hits" | cut -c1-200 | sed 's/^/  /' >&2
  echo "Remove the gate. To stop registration for a course, disable the course." >&2
  exit 1
fi
echo "check-registration-open: clean"
