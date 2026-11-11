#!/usr/bin/env bash
# Fail if any code file under the deployed trees exists locally but is git-ignored.
#
# Why: `git status | grep '^??'` (pre-push check #4) never lists IGNORED files.
# On the case-insensitive macOS checkout (core.ignorecase=true) the old rule
# `info.php*` silently matched app/code/local/RS/Sfec/Block/Info.php, so the
# class shipped to nobody and SG checkout fataled with
# `Class "RS_Sfec_Block_Info" not found` (2026-11-11, fixed in 0732806df).
#
# Usage: scripts/audit/check-ignored-code.sh   (exit 0 = clean, 1 = ignored code found)
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2

# Paths that are ignored ON PURPOSE (local-only overrides / secrets).
ALLOW='^(app/code/local/Mage/|app/code/local/Mage_BACKUP/|app/etc/local\.xml$)'

hits=$(git status --short --ignored --untracked-files=all -- app/code app/design app/etc lib skin js 2>/dev/null \
  | sed -n 's/^!! //p' \
  | grep -Ev "$ALLOW" \
  | grep -Ei '\.(php|phtml|xml|js|css)$' || true)

if [ -n "$hits" ]; then
  echo "IGNORED CODE FILES (exist locally, will NOT ship):" >&2
  echo "$hits" | sed 's/^/  /' >&2
  echo "Check each with: git check-ignore -v <file>  — then fix the .gitignore rule or allowlist it here." >&2
  exit 1
fi
echo "check-ignored-code: clean"
