#!/usr/bin/env bash
# PostToolUse hook: HARD RULE (user rule 2026-11-20) - every active (enabled)
# course allows registration. After an edit to storefront code, run the static
# guardrail; exit 2 feeds the finding back to Claude so the gate is removed
# before it can ship. The push gate runs the same check.
set -u
FILE="${1:-}"
[ -z "$FILE" ] && exit 0

case "$FILE" in
  */app/code/*|*/app/design/*|*/skin/frontend/*|*/js/*) ;;
  *) exit 0 ;;
esac
case "$FILE" in
  *.php|*.phtml|*.xml|*.js) ;;
  *) exit 0 ;;
esac

REPO_ROOT="/Users/alfredang/projects/tertiary/ai-mms"
cd "$REPO_ROOT" || exit 0
if ! OUT="$(scripts/audit/check-registration-open.sh 2>&1)"; then
  echo "$OUT" >&2
  echo "HARD RULE: an enabled course must always allow registration. Remove the gate above." >&2
  exit 2
fi
exit 0
