#!/usr/bin/env bash
# PostToolUse hook: after edits to theme/skin/layout files, curl the affected
# surface (storefront homepage or admin login) on localhost and fail loudly on
# fatals or non-200. Protects the "frontend must look the same / site must
# stay healthy" invariant without a full manual test after every edit.
set -u
FILE="${1:-}"
[ -z "$FILE" ] && exit 0

CONTAINER="ai-mms-web-1"
docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER}$" || exit 0

check_url() {
  local url="$1" label="$2" tmp code
  tmp="$(mktemp /tmp/claude-webhealth.XXXXXX)"
  # No -L and no prod Host header: localhost must be verified locally
  # (memory: feedback_localhost_curl_host_header_redirects).
  code="$(curl -sS -o "$tmp" -w '%{http_code}' --max-time 30 "$url" 2>/dev/null || echo 000)"
  if [ "$code" != "200" ]; then
    echo "WEB HEALTH FAILED after editing $FILE: $label returned HTTP $code ($url)" >&2
    rm -f "$tmp"; exit 2
  fi
  if grep -q "Fatal error\|Uncaught \|There has been an error processing your request" "$tmp"; then
    echo "WEB HEALTH FAILED after editing $FILE: $label renders a PHP fatal ($url)" >&2
    grep -m2 "Fatal error\|Uncaught " "$tmp" >&2
    rm -f "$tmp"; exit 2
  fi
  rm -f "$tmp"
}

case "$FILE" in
  *skin/frontend/*|*app/design/frontend/*)
    check_url "http://localhost:8080/" "storefront homepage"
    ;;
  *skin/adminhtml/*|*app/design/adminhtml/*)
    check_url "http://localhost:8080/adminlogin/" "admin login page"
    ;;
esac
exit 0
