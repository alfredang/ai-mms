#!/usr/bin/env bash
# PostToolUse hook: HARD RULE (user rule 2026-11-22) - the TC LMS apps and
# MMD_MobileApi serve NON-WSQ (C-prefix) courses only. After an edit to the
# mobile API, run the static guardrail; exit 2 feeds the finding back to Claude
# so it is fixed before it can ship. The push gate runs the same check.
set -u
FILE="${1:-}"
case "$FILE" in
  */app/code/local/MMD/MobileApi/*) ;;
  *) exit 0 ;;
esac

REPO_ROOT="/Users/alfredang/projects/tertiary/ai-mms"
cd "$REPO_ROOT" || exit 0
if ! OUT="$(scripts/audit/check-mobileapi-nonwsq.sh 2>&1)"; then
  echo "$OUT" >&2
  echo "HARD RULE: the mobile API is non-WSQ (C-prefix) only. Restore the filter / remove the WSQ feature above." >&2
  exit 2
fi
exit 0
