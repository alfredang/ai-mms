#!/usr/bin/env bash
# PreToolUse hook (Bash matcher): blocks `git push` from Claude sessions.
# Pushing to main auto-deploys EVERY country instance via Coolify, so a push
# requires (a) localhost fully verified per CLAUDE.md pre-push checks and
# (b) explicit admin approval for THIS push.
#
# Approval is one-shot: the admin runs
#     touch .claude/.push-approved
# and the very next git push consumes the marker. No marker → push blocked.
set -u
CMD="$(cat | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$CMD" ] && exit 0

# Only gate actual pushes (not push --dry-run, not grep strings mentioning it).
echo "$CMD" | grep -qE '(^|[;&|]\s*)git\s+([^;&|]*\s)?push(\s|$)' || exit 0
echo "$CMD" | grep -q -- '--dry-run' && exit 0

REPO_ROOT="/Users/alfredang/projects/tertiary/ai-mms"
MARKER="$REPO_ROOT/.claude/.push-approved"

if [ -f "$MARKER" ]; then
  rm -f "$MARKER"
  echo "push-gate: admin approval marker found and consumed — push allowed." >&2
  exit 0
fi

cat >&2 <<'EOF'
PUSH BLOCKED by .claude/hooks/git-push-gate.sh.
Pushing to main deploys production on every country instance (Coolify).
Policy: the ADMIN decides when to push.

Required before any push:
  1. Full CLAUDE.md pre-push verification on localhost (lint, block
     instantiation, route curl, apply.php dry-run, git status for untracked
     files referenced by config.xml).
  2. Admin approval for THIS push:  touch .claude/.push-approved
     (the marker is consumed by one push).

Do not retry the push; report the verified state to the admin instead.
EOF
exit 2
