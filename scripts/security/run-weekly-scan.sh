#!/bin/zsh
# Weekly security scan — run by launchd every Monday 13:00 SGT
# (~/Library/LaunchAgents/com.tertiaryinfotech.security-scan.plist).
# Runs the security-scanner agent headless; the Word report lands in
# security-assessment/ (gitignored, local only). Report-only: no code changes, no push.
set -u
REPO=/Users/alfredang/projects/tertiary/ai-mms
LOG_DIR=$REPO/security-assessment/logs
TODAY=$(date +%Y-%m-%d)
mkdir -p "$LOG_DIR"
export PATH="$HOME/.local/bin:/usr/local/bin:/opt/homebrew/bin:/Library/Frameworks/Python.framework/Versions/3.13/bin:/usr/bin:/bin:/usr/sbin:/sbin"
cd "$REPO" || exit 1

# Bring up the local stack if Docker is running but the containers are not (section F needs the DB).
docker info >/dev/null 2>&1 && ! docker ps --format '{{.Names}}' | grep -q '^ai-mms-web-1$' \
  && USERPROFILE=$HOME docker-compose up -d >>"$LOG_DIR/scan-$TODAY.log" 2>&1

claude -p "Run the weekly security scan for $TODAY (commit $(git rev-parse --short HEAD)). Compare against the most recent previous findings-*.json in security-assessment/. Write security-assessment/findings-$TODAY.json and security-assessment/Security-Assessment-$TODAY.docx." \
  --agent security-scanner \
  --permission-mode acceptEdits \
  --allowedTools "Read" "Grep" "Glob" "Write" "Bash" \
  >>"$LOG_DIR/scan-$TODAY.log" 2>&1
rc=$?

report="$REPO/security-assessment/Security-Assessment-$TODAY.docx"
if [[ -f "$report" ]]; then
  osascript -e "display notification \"Report saved: Security-Assessment-$TODAY.docx\" with title \"AI-MMS security scan done\"" 2>/dev/null
else
  osascript -e "display notification \"No report produced (exit $rc) — see security-assessment/logs\" with title \"AI-MMS security scan FAILED\"" 2>/dev/null
fi
exit $rc
