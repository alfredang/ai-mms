#!/usr/bin/env bash
# PostToolUse hook: lint any edited .php/.phtml inside the web container.
# Exit 2 feeds the error back to Claude so it fixes the syntax immediately
# instead of discovering it later as a production fatal.
set -u
FILE="${1:-}"
[ -z "$FILE" ] && exit 0

case "$FILE" in
  *.php|*.phtml) ;;
  *) exit 0 ;;
esac

CONTAINER="ai-mms-web-1"
REPO_ROOT="/Users/alfredang/projects/tertiary/ai-mms"

# Container not running (e.g. laptop without Docker up) — don't block edits.
docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER}$" || exit 0

REL="${FILE#"$REPO_ROOT"/}"
OUT="$(docker exec "$CONTAINER" php -l "/var/www/html/$REL" 2>&1)"
if [ $? -ne 0 ]; then
  echo "PHP LINT FAILED for $REL:" >&2
  echo "$OUT" >&2
  exit 2
fi
exit 0
